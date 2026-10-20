@tool
@icon("res://addons/proc_trees/icons/proc_tree.svg")
class_name ProcTree
extends MeshInstance3D
## One procedural tree for hand placement (hero trees, set dressing). Rebuilds live in the editor when the
## profile changes. The mesh is generated on load and never saved into the scene. For many trees use TreeForest.
## Tip: the plugin's "Trees" menu (3D toolbar) adds one with its own editable copy of a preset.

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
@export_tool_button("New variant", "RandomNumberGenerator") var new_variant_action := new_variant

@export_group("Bake")
## Where "Bake mesh" saves. Empty = res://baked_trees/<profile>_v<variant>_lod<lod>.res
@export_file("*.res", "*.tres") var bake_path := ""
@export_tool_button("Bake mesh to file", "Save") var bake_action := bake

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


func new_variant() -> void:
	variant = randi() % 1000


## Save the current mesh as a normal mesh resource (use it anywhere, no plugin needed to display it,
## though the tree shaders still need the shader globals: TreeMaterials.ensure_globals()). Returns the path.
func bake() -> String:
	if mesh == null:
		push_warning("ProcTree: nothing to bake (no profile)")
		return ""
	var path := bake_path
	if path.is_empty():
		var nm := profile.resource_name if profile.resource_name else (profile.resource_path.get_file().get_basename() if profile.resource_path else "tree")
		path = "res://baked_trees/%s_v%d_lod%d.res" % [nm.validate_filename(), variant, lod]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var err := ResourceSaver.save(mesh.duplicate(true), path)
	if err != OK:
		push_error("ProcTree: could not save %s (%s)" % [path, error_string(err)])
		return ""
	print("ProcTree: baked %s" % path)
	if Engine.is_editor_hint():
		var ei := Engine.get_singleton("EditorInterface")
		if ei:
			ei.get_resource_filesystem().scan()
	return path
