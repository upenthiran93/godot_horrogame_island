@tool
class_name ProcTree
extends MeshInstance3D
## One procedural tree for hand placement (hero trees, set dressing). Rebuilds live in the editor when the
## profile changes. The mesh is generated on load and never saved into the scene. For many trees use TreeForest.

@export var profile: TreeProfile:
	set(v):
		profile = v
		_queue_rebuild()
## Different seeds of the same profile.
@export var variant := 0:
	set(v):
		variant = v
		_queue_rebuild()
## Preview a lower LOD (0 = full detail).
@export_range(0, 2) var lod := 0:
	set(v):
		lod = v
		_queue_rebuild()
## Trunk collider (runtime only).
@export var collision := true
@export_flags_3d_physics var collision_layer := 1

var _key := 0
var _poll := 0.0
var _queued := false
var _body: StaticBody3D


func _validate_property(property: Dictionary) -> void:
	if property.name == "mesh":
		property.usage &= ~PROPERTY_USAGE_STORAGE


func _ready() -> void:
	_rebuild()
	set_process(Engine.is_editor_hint())


func _process(delta: float) -> void:
	_poll += delta
	if _poll > 0.3:
		_poll = 0.0
		if profile and profile.cache_key() != _key:
			_rebuild()


func _queue_rebuild() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		_rebuild.call_deferred()


func _rebuild() -> void:
	_queued = false
	mesh = TreeBuilder.build(profile, variant, lod) if profile else null
	_key = profile.cache_key() if profile else 0
	if _body:
		_body.queue_free()
		_body = null
	if collision and profile and not Engine.is_editor_hint():
		var info := TreeBuilder.info(profile, variant)
		var shape := CylinderShape3D.new()
		shape.radius = info.trunk_radius
		shape.height = minf(info.height, 8.0)
		var cs := CollisionShape3D.new()
		cs.shape = shape
		cs.position.y = shape.height * 0.5
		_body = StaticBody3D.new()
		_body.collision_layer = collision_layer
		_body.collision_mask = 0
		_body.add_child(cs)
		add_child(_body, false, INTERNAL_MODE_FRONT)
