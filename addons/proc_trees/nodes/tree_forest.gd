@tool
@icon("res://addons/proc_trees/icons/tree_forest.svg")
class_name TreeForest
extends TreeInstances
## Simple scatter: fills a rectangle (centred on this node, XZ) with trees from a list of profiles, snapped to the
## ground colliders, and draws them through TreeInstances (chunked MultiMeshes, LOD crossfade, cheap shadows).
## Placement is deterministic (random_seed) and recomputed on load, so the scene only stores the settings.
## Rebuilds live in the editor when a setting or a profile changes.
## This is also the reference for a forest/scatter plugin: decide positions, then add_tree() + commit().

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

@export_tool_button("Rebuild", "Reload") var rebuild_action := rebuild

## Optional code filter: func(world_pos: Vector3) -> bool. Return false to reject a tree.
var placement_filter: Callable

var _sig := 0
var _sig_poll := 0.0
var _building := false


func _init() -> void:
	auto_refresh_items = false  # rebuild() already watches the profiles


func _ready() -> void:
	rebuild.call_deferred()


func _process(delta: float) -> void:
	super(delta)
	if Engine.is_editor_hint():
		_sig_poll += delta
		if _sig_poll > 0.4:
			_sig_poll = 0.0
			if _signature() != _sig:
				rebuild()


func rebuild() -> void:
	if _building or not is_inside_tree():
		return
	_building = true
	_sig = _signature()
	clear_trees()
	var types := profiles.filter(func(p): return p != null)
	if not types.is_empty() and snap_to_ground and not Engine.is_editor_hint():
		await get_tree().physics_frame  # let the level's colliders register before raycasting
	if not types.is_empty():
		_scatter(types)
	commit()
	_building = false


func _scatter(types: Array) -> void:
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
			add_tree(types[t], vari, inv * Transform3D(basis, wp - up * 0.05 * scl), Vector3(lum + hue, lum, lum - hue), phase)


func _signature() -> int:
	var vals := [global_transform]
	for prop in get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and prop.usage & PROPERTY_USAGE_STORAGE:
			vals.append(get(prop.name))
	for p in profiles:
		vals.append(p.cache_key() if p else 0)
	return hash(vals)
