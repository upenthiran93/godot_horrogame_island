@tool
class_name TreeForest
extends Node3D
## Scatters procedural trees over a rectangle (centred on this node, XZ) and draws them cheaply:
## - one MultiMesh per chunk per tree type per LOD (no node per tree); far LODs use bigger chunks (fewer draws),
## - 3 LODs that dither-crossfade per tree in the shader (no popping, stays opaque), plus coarse chunk culling
##   through visibility ranges, so out-of-band chunks cost nothing,
## - trunk collision straight on the PhysicsServer (no nodes), runtime only.
## Placement is deterministic (random_seed) and recomputed on load, so the scene only stores the settings.
## Rebuilds live in the editor when a setting or a profile changes.

@export var profiles: Array[TreeProfile] = []
## Relative pick weight per profile (missing entries = 1).
@export var profile_weights := PackedFloat32Array()
## Seeds per profile. Each one is its own mesh/draw call, so keep this small (2-3).
@export_range(1, 8) var variants := 2
@export var area := Vector2(120.0, 120.0)
## Grid spacing; trees are jittered inside their cell so they never clump closer than ~10% of this.
@export_range(1.0, 50.0, 0.1, "suffix:m") var spacing := 7.0
@export_range(0.0, 1.0) var density := 0.75
@export var random_seed := 1
@export var scale_range := Vector2(0.8, 1.2)
@export_range(0.0, 0.3) var tint_variation := 0.1
## Optional greyscale mask over the area (white = trees, black = none), e.g. painted around paths and clearings.
@export var density_mask: Texture2D

@export_group("Ground")
@export var snap_to_ground := true
@export_flags_3d_physics var ground_mask := 1
@export_range(0.0, 90.0) var max_slope := 35.0
## No trees below this world height (beach / sea level) or above max_height.
@export var min_height := -1000.0
@export var max_height := 10000.0
@export_range(0.0, 1.0) var align_to_ground := 0.1
@export var ray_height := 500.0

@export_group("LOD")
## Camera distance where LOD0 -> LOD1, LOD1 -> LOD2, and where LOD2 fades out completely.
@export var lod_distances := Vector3(30.0, 80.0, 260.0)
@export_range(0.5, 30.0) var lod_fade := 6.0
@export_range(8.0, 256.0) var chunk_size := 32.0
## LOD1 trees cast their shadow from the cheap LOD2 mesh (shadows are most of the cost of a forest).
@export var cheap_shadows := true
## LOD2 trees cast shadows at all (usually beyond the sun's shadow distance anyway).
@export var far_shadows := false

@export_group("Collision")
@export var collision := true
@export_flags_3d_physics var collision_layer := 1

@export_tool_button("Rebuild", "Reload") var rebuild_action := rebuild

## Optional code filter: func(world_pos: Vector3) -> bool. Return false to reject a tree.
var placement_filter: Callable
## Trees placed by the last rebuild.
var instance_count := 0

var _nodes: Array[Node] = []
var _bodies: Array[RID] = []
var _shapes := {}
var _sig := 0
var _poll := 0.0
var _building := false

static var _view_frame := -1


func _ready() -> void:
	rebuild.call_deferred()


func _exit_tree() -> void:
	_free_physics()


func _process(delta: float) -> void:
	update_view_position(self)
	if Engine.is_editor_hint():
		_poll += delta
		if _poll > 0.4:
			_poll = 0.0
			if _signature() != _sig:
				rebuild()


## Feeds the camera position to the tree shaders (LOD fades must use the real camera, also in shadow passes).
## Every TreeForest calls this; it runs once per frame. Call it yourself if you use ProcTree LOD bands only.
static func update_view_position(from: Node) -> void:
	var frame := Engine.get_process_frames()
	if frame == _view_frame:
		return
	_view_frame = frame
	var cam: Camera3D = null
	if Engine.is_editor_hint():
		var ei := Engine.get_singleton("EditorInterface")
		if ei:
			var vp: SubViewport = ei.get_editor_viewport_3d(0)
			if vp:
				cam = vp.get_camera_3d()
	elif from.is_inside_tree():
		cam = from.get_viewport().get_camera_3d()
	if cam:
		RenderingServer.global_shader_parameter_set("tree_view_pos", cam.global_position)


func rebuild() -> void:
	if _building or not is_inside_tree():
		return
	_building = true
	_clear()
	_sig = _signature()
	var types := profiles.filter(func(p): return p != null)
	if not types.is_empty():
		if snap_to_ground and not Engine.is_editor_hint():
			await get_tree().physics_frame  # let the level's colliders register before raycasting
		var records := _scatter(types)
		instance_count = records.size()
		_build_draws(records, types)
		_build_collision(records, types)
	_building = false


# --- placement ---------------------------------------------------------------------------------------------

func _scatter(types: Array) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed
	var weights := PackedFloat32Array()
	var total := 0.0
	for i in types.size():
		var w := profile_weights[i] if i < profile_weights.size() else 1.0
		total += maxf(w, 0.0)
		weights.append(total)
	var mask: Image = null
	if density_mask:
		mask = density_mask.get_image()
		if mask and mask.is_compressed():
			mask.decompress()
	var space := get_world_3d().direct_space_state
	var gx := global_transform
	var inv := gx.affine_inverse()
	var cos_slope := cos(deg_to_rad(max_slope))
	var nx := maxi(1, int(area.x / spacing))
	var nz := maxi(1, int(area.y / spacing))
	var records := []  # [type id, local Transform3D, custom Color]
	for ix in nx:
		for iz in nz:
			# always draw the same randoms per cell, so changing one filter doesn't reshuffle the whole forest
			var roll := rng.randf()
			var jx := rng.randf()
			var jz := rng.randf()
			var pick := rng.randf() * total
			var vari := rng.randi() % variants
			var yaw := rng.randf() * TAU
			var scl := rng.randf_range(scale_range.x, scale_range.y)
			var lum := rng.randf_range(-tint_variation, tint_variation)
			var hue := rng.randf_range(-tint_variation, tint_variation) * 0.6
			var phase := rng.randf()
			var local := Vector3((ix + 0.05 + jx * 0.9) * spacing - area.x * 0.5, 0.0, (iz + 0.05 + jz * 0.9) * spacing - area.y * 0.5)
			var keep := density
			if mask:
				var px := clampi(int((local.x / area.x + 0.5) * mask.get_width()), 0, mask.get_width() - 1)
				var pz := clampi(int((local.z / area.y + 0.5) * mask.get_height()), 0, mask.get_height() - 1)
				keep *= mask.get_pixel(px, pz).r
			if roll >= keep:
				continue
			var wp := gx * local
			var up := Vector3.UP
			if snap_to_ground:
				var q := PhysicsRayQueryParameters3D.create(wp + Vector3.UP * ray_height, wp + Vector3.DOWN * ray_height, ground_mask)
				var hit := space.intersect_ray(q)
				if hit.is_empty() or (hit.normal as Vector3).y < cos_slope:
					continue
				wp = hit.position
				up = Vector3.UP.lerp(hit.normal, align_to_ground).normalized()
			if wp.y < min_height or wp.y > max_height:
				continue
			if placement_filter.is_valid() and not placement_filter.call(wp):
				continue
			var t := 0
			while t < weights.size() - 1 and pick > weights[t]:
				t += 1
			var basis := Basis(Quaternion(Vector3.UP, up)) * Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scl)
			var xf := inv * Transform3D(basis, wp - up * 0.05 * scl)
			records.append([t * variants + vari, xf, Color(lum + hue, lum, lum - hue, phase)])
	return records


# --- drawing -----------------------------------------------------------------------------------------------

func _band(lod: int) -> Vector4:
	var d := lod_distances
	match lod:
		0:
			return Vector4(-2.0, -1.0, d.x, d.x + lod_fade)
		1:
			return Vector4(d.x, d.x + lod_fade, d.y, d.y + lod_fade)
	return Vector4(d.y, d.y + lod_fade, d.z, d.z + lod_fade)


func _build_draws(records: Array, types: Array) -> void:
	for lod in TreeBuilder.LOD_COUNT:
		var cs := chunk_size * float(1 << lod)
		var groups := {}
		for i in records.size():
			var o: Vector3 = records[i][1].origin
			var key := Vector3i(floori(o.x / cs), floori(o.z / cs), records[i][0])
			if not groups.has(key):
				groups[key] = []
			groups[key].append(i)
		var band := _band(lod)
		for key: Vector3i in groups:
			var idxs: Array = groups[key]
			var prof: TreeProfile = types[key.z / variants]
			var vari := key.z % variants
			var lo := Vector3.INF
			var hi := -Vector3.INF
			for i in idxs:
				var o: Vector3 = records[i][1].origin
				lo = lo.min(o)
				hi = hi.max(o)
			var center := (lo + hi) * 0.5
			var reach: float = (hi - lo).length() * 0.5 + TreeBuilder.info(prof, vari).height * scale_range.y
			var buf := PackedFloat32Array()
			buf.resize(idxs.size() * 16)
			var k := 0
			for i in idxs:
				var xf: Transform3D = records[i][1]
				var c: Color = records[i][2]
				var b := xf.basis
				var o := xf.origin - center
				buf[k] = b.x.x; buf[k + 1] = b.y.x; buf[k + 2] = b.z.x; buf[k + 3] = o.x
				buf[k + 4] = b.x.y; buf[k + 5] = b.y.y; buf[k + 6] = b.z.y; buf[k + 7] = o.y
				buf[k + 8] = b.x.z; buf[k + 9] = b.y.z; buf[k + 10] = b.z.z; buf[k + 11] = o.z
				buf[k + 12] = c.r; buf[k + 13] = c.g; buf[k + 14] = c.b; buf[k + 15] = c.a
				k += 16
			var tag := "%s_v%d_lod%d_%d_%d" % [prof.resource_name if prof.resource_name else "tree", vari, lod, key.x, key.y]
			var shadow := GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			if (lod == 2 and not far_shadows) or (lod == 1 and cheap_shadows):
				shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_add_chunk(tag, TreeBuilder.build(prof, vari, lod), buf, idxs.size(), center, reach, band, shadow)
			if lod == 1 and cheap_shadows:
				_add_chunk(tag + "_shadow", TreeBuilder.build(prof, vari, 2), buf, idxs.size(), center, reach, band,
					GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY)


func _add_chunk(tag: String, mesh: Mesh, buf: PackedFloat32Array, count: int, center: Vector3, reach: float,
		band: Vector4, shadow: GeometryInstance3D.ShadowCastingSetting) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = mesh
	mm.instance_count = count
	mm.buffer = buf
	var mmi := MultiMeshInstance3D.new()
	mmi.name = tag
	mmi.multimesh = mm
	mmi.position = center
	# coarse culling: draw the chunk only while some tree in it can be inside this LOD's band
	mmi.visibility_range_begin = maxf(0.0, band.x - reach)
	mmi.visibility_range_end = band.w + reach
	mmi.set_instance_shader_parameter("lod_fade", band)
	mmi.cast_shadow = shadow
	add_child(mmi, false, INTERNAL_MODE_FRONT)
	_nodes.append(mmi)


func _build_collision(records: Array, types: Array) -> void:
	if not collision or Engine.is_editor_hint():
		return
	var space := get_world_3d().space
	var bodies := {}
	for r in records:
		var xf: Transform3D = r[1]
		var key := Vector2i(floori(xf.origin.x / chunk_size), floori(xf.origin.z / chunk_size))
		if not bodies.has(key):
			var body := PhysicsServer3D.body_create()
			PhysicsServer3D.body_set_mode(body, PhysicsServer3D.BODY_MODE_STATIC)
			PhysicsServer3D.body_set_space(body, space)
			PhysicsServer3D.body_set_collision_layer(body, collision_layer)
			PhysicsServer3D.body_set_collision_mask(body, 0)
			PhysicsServer3D.body_set_state(body, PhysicsServer3D.BODY_STATE_TRANSFORM, global_transform)
			PhysicsServer3D.body_attach_object_instance_id(body, get_instance_id())
			bodies[key] = body
			_bodies.append(body)
		var info := TreeBuilder.info(types[r[0] / variants], r[0] % variants)
		var s := xf.basis.get_scale().y
		var radius: float = info.trunk_radius * s
		var h := minf(info.height * s, 8.0)
		var skey := Vector2i(int(radius * 50.0), int(h * 4.0))
		if not _shapes.has(skey):
			var shape := PhysicsServer3D.cylinder_shape_create()
			PhysicsServer3D.shape_set_data(shape, {"radius": skey.x / 50.0 + 0.01, "height": skey.y / 4.0})
			_shapes[skey] = shape
		PhysicsServer3D.body_add_shape(bodies[key], _shapes[skey], Transform3D(Basis(), xf.origin + Vector3.UP * h * 0.5))


func _clear() -> void:
	for n in _nodes:
		if is_instance_valid(n):
			n.queue_free()
	_nodes.clear()
	_free_physics()
	instance_count = 0


func _free_physics() -> void:
	for b in _bodies:
		PhysicsServer3D.free_rid(b)
	_bodies.clear()
	for s in _shapes.values():
		PhysicsServer3D.free_rid(s)
	_shapes.clear()


func _signature() -> int:
	var vals := [global_transform]
	for prop in get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and prop.usage & PROPERTY_USAGE_STORAGE:
			vals.append(get(prop.name))
	for p in profiles:
		vals.append(p.cache_key() if p else 0)
	return hash(vals)
