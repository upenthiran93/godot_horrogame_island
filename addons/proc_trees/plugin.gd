@tool
extends EditorPlugin
## Proc Trees editor plugin: registers the shader globals, adds a "Trees" menu to the 3D editor toolbar
## (add a tree from a preset, add a forest / wind, bake selected trees, clear the mesh cache) and makes
## TreeProfile resources emit `changed` when edited in the inspector (so other plugins can listen).

const PRESET_DIR := "res://addons/proc_trees/presets/"
enum { ADD_FOREST = 1000, ADD_WIND, BAKE_SELECTED, CLEAR_CACHE, OPEN_DEMO }

var _menu: MenuButton
var _presets := PopupMenu.new()
var _preset_paths: Array[String] = []


func _enable_plugin() -> void:
	_ensure_shader_globals()


func _enter_tree() -> void:
	_ensure_shader_globals()
	_menu = MenuButton.new()
	_menu.text = "Trees"
	_menu.tooltip_text = "Proc Trees: add procedural trees, forests and wind"
	_menu.icon = load("res://addons/proc_trees/icons/proc_tree.svg")
	var pop := _menu.get_popup()
	_presets.name = "Presets"
	_presets.id_pressed.connect(_on_preset)
	pop.add_child(_presets)
	pop.add_submenu_node_item("Add Tree", _presets)
	pop.add_item("Add Tree Forest", ADD_FOREST)
	pop.add_item("Add Tree Wind", ADD_WIND)
	pop.add_separator()
	pop.add_item("Bake Selected Trees to Meshes", BAKE_SELECTED)
	pop.add_item("Clear Tree Mesh Cache", CLEAR_CACHE)
	pop.add_separator()
	pop.add_item("Open Demo Scene", OPEN_DEMO)
	pop.id_pressed.connect(_on_menu)
	pop.about_to_popup.connect(_fill_presets)
	add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, _menu)
	EditorInterface.get_inspector().property_edited.connect(_on_property_edited)


func _exit_tree() -> void:
	if EditorInterface.get_inspector().property_edited.is_connected(_on_property_edited):
		EditorInterface.get_inspector().property_edited.disconnect(_on_property_edited)
	if _menu:
		remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, _menu)
		_menu.queue_free()
		_menu = null


func _ensure_shader_globals() -> void:
	var changed := false
	for n: String in TreeMaterials.GLOBALS:
		var key := "shader_globals/" + n
		if not ProjectSettings.has_setting(key):
			var g: Array = TreeMaterials.GLOBALS[n]
			ProjectSettings.set_setting(key, {"type": g[1], "value": g[2]})
			changed = true
	if changed:
		ProjectSettings.save()
	TreeMaterials.ensure_globals()


func _on_property_edited(_property: String) -> void:
	var obj := EditorInterface.get_inspector().get_edited_object()
	if obj is TreeProfile:
		obj.emit_changed()


func _fill_presets() -> void:
	_presets.clear()
	_preset_paths.clear()
	for f in DirAccess.get_files_at(PRESET_DIR):
		if f.ends_with(".tres") or f.ends_with(".res"):
			_preset_paths.append(PRESET_DIR + f)
			_presets.add_item(f.get_basename().replace("_", " ").capitalize(), _preset_paths.size() - 1)


func _on_preset(id: int) -> void:
	var src: TreeProfile = load(_preset_paths[id])
	var tree := ProcTree.new()
	tree.name = src.resource_name.to_pascal_case() if src.resource_name else "ProcTree"
	var copy := src.duplicate(true) as TreeProfile  # the scene gets its own editable copy; the preset stays as is
	copy.resource_path = ""
	tree.profile = copy
	_add_node(tree)


func _on_menu(id: int) -> void:
	match id:
		ADD_FOREST:
			var forest := TreeForest.new()
			forest.name = "TreeForest"
			var profs: Array[TreeProfile] = []
			for n in ["realistic_broadleaf", "realistic_pine"]:
				profs.append(load(PRESET_DIR + n + ".tres"))
			forest.profiles = profs
			forest.area = Vector2(60, 60)
			_add_node(forest)
		ADD_WIND:
			var wind := TreeWind.new()
			wind.name = "TreeWind"
			_add_node(wind, false)
		BAKE_SELECTED:
			var n := 0
			for node in EditorInterface.get_selection().get_selected_nodes():
				if node is ProcTree and not (node as ProcTree).bake().is_empty():
					n += 1
			if n == 0:
				push_warning("Proc Trees: select one or more ProcTree nodes to bake.")
		CLEAR_CACHE:
			TreeBuilder.clear_cache()
			print("Proc Trees: mesh cache cleared")
		OPEN_DEMO:
			EditorInterface.open_scene_from_path("res://addons/proc_trees/demo/tree_demo.tscn")


## Add a node under the selected 3D node (or the scene root), placed where the editor camera looks. Undoable.
func _add_node(node: Node, place := true) -> void:
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		push_warning("Proc Trees: open a 3D scene first.")
		node.free()
		return
	var parent: Node = root
	var sel := EditorInterface.get_selection().get_selected_nodes()
	if sel.size() == 1 and sel[0] is Node3D and sel[0] != node and not (sel[0] is ProcTree):
		parent = sel[0]
	if place and node is Node3D and parent is Node3D:
		(node as Node3D).position = (parent as Node3D).to_local(_camera_target(root))
	var ur := get_undo_redo()
	ur.create_action("Add " + node.name)
	ur.add_do_method(parent, "add_child", node, true)
	ur.add_do_method(node, "set_owner", root)
	ur.add_do_reference(node)
	ur.add_undo_method(parent, "remove_child", node)
	ur.commit_action()
	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(node)


func _camera_target(root: Node) -> Vector3:
	var cam := EditorInterface.get_editor_viewport_3d(0).get_camera_3d()
	if cam == null:
		return Vector3.ZERO
	var from := cam.global_position
	var to := from - cam.global_transform.basis.z * 500.0
	if root is Node3D:
		var hit := (root as Node3D).get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
		if not hit.is_empty():
			return hit.position
	return from - cam.global_transform.basis.z * 12.0
