@tool
@icon("res://addons/proc_trees/icons/tree_instances.svg")
class_name TreeInstances
extends Node3D
## Draws any number of trees cheaply. You decide WHERE they go; this node handles HOW they are drawn:
## - one MultiMesh per chunk per item/variant per LOD (no node per tree); far LODs use bigger chunks,
## - per-tree dithered LOD crossfade in the shader (no popping, stays opaque) + chunk culling via visibility ranges,
## - LOD1 trees cast shadows from the cheapest LOD (shadows are most of a forest's cost),
## - trunk collision straight on the PhysicsServer (no nodes, runtime only).
##
## Use from code (e.g. a forest/scatter plugin):
##     var trees := TreeInstances.new()
##     add_child(trees)
##     trees.add_tree(profile, variant, Transform3D(...))   # transform is local to this node
##     trees.commit()
## An "item" is any Resource with the scatter-item API (TreeProfile has it; see README "Scatter-item API"):
##     get_lod_count() -> int, get_lod_mesh(variant, lod) -> Mesh, get_item_info(variant) -> Dictionary
## In the editor it re-commits by itself when an item's settings change (items with get_cache_key()).

@export_group("LOD")
## Camera distance where LOD0 -> LOD1, LOD1 -> LOD2, and where the last LOD fades out completely.
@export var lod_distances := Vector3(30.0, 80.0, 260.0)
@export_range(0.5, 30.0) var lod_fade := 6.0
@export_range(8.0, 256.0) var chunk_size := 32.0
## LOD1 trees cast their shadow from the cheapest LOD mesh.
@export var cheap_shadows := true
## The last LOD casts shadows at all (usually beyond the sun's shadow distance anyway).
@export var far_shadows := false

@export_group("Collision")
@export var collision := true
@export_flags_3d_physics var collision_layer := 1

## Trees in the last commit().
var instance_count := 0
## Editor only: re-commit when an item's settings change. Subclasses that rebuild themselves turn this off.
var auto_refresh_items := true

var _items: Array[Resource] = []       # distinct items, index = item id
var _item_keys := PackedInt64Array()   # their cache keys at commit time (editor auto-refresh)
var _records := []                     # [item id, variant, local Transform3D, custom Color]
var _nodes: Array[Node] = []
var _bodies: Array[RID] = []
var _shapes := {}
var _poll := 0.0

static var _view_frame := -1


func _exit_tree() -> void:
	_free_draws()


func _process(delta: float) -> void:
	update_view_position(self)
	if Engine.is_editor_hint() and auto_refresh_items and not _items.is_empty():
		_poll += delta
		if _poll > 0.4:
			_poll = 0.0
			for i in _items.size():
				if _items[i].has_method("get_cache_key") and _items[i].get_cache_key() != _item_keys[i]:
					commit()
					break


## Queue one tree. `tint` is an RGB offset (0 = none, ±0.1 = subtle), `phase` offsets its wind (random if < 0).
func add_tree(item: Resource, variant: int, local_transform: Transform3D, tint := Vector3.ZERO, phase := -1.0) -> void:
	assert(item and item.has_method("get_lod_mesh"), "TreeInstances: item needs the scatter-item API")
	var id := _items.find(item)
	if id < 0:
		id = _items.size()
		_items.append(item)
	if phase < 0.0:
		phase = fposmod(local_transform.origin.x * 0.137 + local_transform.origin.z * 0.291, 1.0)
	_records.append([id, variant, local_transform, Color(tint.x, tint.y, tint.z, phase)])


## Remove all queued trees (call commit() afterwards to clear what is drawn).
func clear_trees() -> void:
	_items.clear()
	_records.clear()


## Build the draws and colliders for everything queued. Safe to call again after more add_tree() calls.
func commit() -> void:
	_free_draws()
	instance_count = _records.size()
	_item_keys.resize(_items.size())
	for i in _items.size():
		_item_keys[i] = _items[i].get_cache_key() if _items[i].has_method("get_cache_key") else 0
	if _records.is_empty() or not is_inside_tree():
		return
	_build_draws()
	_build_collision()


## Feeds the camera position to the tree shaders (LOD fades use the real camera, also in shadow passes).
## Every TreeInstances calls this once per frame; call it yourself if you draw trees some other way.
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
		TreeMaterials.ensure_globals()
		RenderingServer.global_shader_parameter_set("tree_view_pos", cam.global_position)


## LOD fade band (fade-in start/end, fade-out start/end in metres) for `lod` of an item with `count` LODs.
static func lod_band(lod: int, count: int, distances: Vector3, fade: float) -> Vector4:
	var d := [-2.0, distances.x, distances.y]
	var start: float = d[mini(lod, 2)]
	var out: float = distances.z if lod >= count - 1 else [distances.x, distances.y, distances.z][mini(lod, 2)]
	return Vector4(start, start + 1.0 if lod == 0 else start + fade, out, out + fade)


func _build_draws() -> void:
	var max_lods := 1
	for it in _items:
		max_lods = maxi(max_lods, it.get_lod_count())
	for lod in max_lods:
		var cs := chunk_size * float(1 << lod)
		var groups := {}
		for i in _records.size():
			var r: Array = _records[i]
			if lod >= _items[r[0]].get_lod_count():
				continue
			var o: Vector3 = r[2].origin
			var key := [floori(o.x / cs), floori(o.z / cs), r[0], r[1]]
			if not groups.has(key):
				groups[key] = []
			groups[key].append(i)
		for key: Array in groups:
			var idxs: Array = groups[key]
			var item: Resource = _items[key[2]]
			var vari: int = key[3]
			var count: int = item.get_lod_count()
			var band := lod_band(lod, count, lod_distances, lod_fade)
			var lo := Vector3.INF
			var hi := -Vector3.INF
			var max_scale := 0.0
			for i in idxs:
				var xf: Transform3D = _records[i][2]
				lo = lo.min(xf.origin)
				hi = hi.max(xf.origin)
				max_scale = maxf(max_scale, xf.basis.get_scale().y)
			var center := (lo + hi) * 0.5
			var reach: float = (hi - lo).length() * 0.5 + float(item.get_item_info(vari).get("height", 10.0)) * max_scale
			var buf := PackedFloat32Array()
			buf.resize(idxs.size() * 16)
			var k := 0
			for i in idxs:
				var xf: Transform3D = _records[i][2]
				var c: Color = _records[i][3]
				var b := xf.basis
				var o := xf.origin - center
				buf[k] = b.x.x; buf[k + 1] = b.y.x; buf[k + 2] = b.z.x; buf[k + 3] = o.x
				buf[k + 4] = b.x.y; buf[k + 5] = b.y.y; buf[k + 6] = b.z.y; buf[k + 7] = o.y
				buf[k + 8] = b.x.z; buf[k + 9] = b.y.z; buf[k + 10] = b.z.z; buf[k + 11] = o.z
				buf[k + 12] = c.r; buf[k + 13] = c.g; buf[k + 14] = c.b; buf[k + 15] = c.a
				k += 16
			var last := lod == count - 1
			var shadow_proxy := cheap_shadows and lod == 1 and count > 2
			var shadow := GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			if (last and lod > 0 and not far_shadows) or shadow_proxy:
				shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var tag := "%s_v%d_lod%d_%d_%d" % [item.resource_name if item.resource_name else "item%d" % key[2], vari, lod, key[0], key[1]]
			_add_chunk(tag, item.get_lod_mesh(vari, lod), buf, idxs.size(), center, reach, band, shadow)
			if shadow_proxy:
				_add_chunk(tag + "_shadow", item.get_lod_mesh(vari, count - 1), buf, idxs.size(), center, reach, band,
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


func _build_collision() -> void:
	if not collision or Engine.is_editor_hint():
		return
	var space := get_world_3d().space
	var bodies := {}
	for r in _records:
		var info: Dictionary = _items[r[0]].get_item_info(r[1])
		if not info.has("collision_radius"):
			continue
		var xf: Transform3D = r[2]
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
		var s := xf.basis.get_scale().y
		var skey := Vector2i(int(float(info.collision_radius) * s * 50.0), int(float(info.collision_height) * s * 4.0))
		if not _shapes.has(skey):
			var shape := PhysicsServer3D.cylinder_shape_create()
			PhysicsServer3D.shape_set_data(shape, {"radius": skey.x / 50.0 + 0.01, "height": maxf(skey.y / 4.0, 0.5)})
			_shapes[skey] = shape
		PhysicsServer3D.body_add_shape(bodies[key], _shapes[skey], Transform3D(Basis(), xf.origin + Vector3.UP * skey.y / 8.0))


func _free_draws() -> void:
	for n in _nodes:
		if is_instance_valid(n):
			n.queue_free()
	_nodes.clear()
	for b in _bodies:
		PhysicsServer3D.free_rid(b)
	_bodies.clear()
	for s in _shapes.values():
		PhysicsServer3D.free_rid(s)
	_shapes.clear()
