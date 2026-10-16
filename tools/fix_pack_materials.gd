extends SceneTree
## One-off: set import material overrides on the Synty Prototype FBX files.
##  - Pieces whose name matches a CATEGORY prefix get that blockout material
##    (the pack's stylised orange/purple prototype colours don't read in a night-time horror previs).
##  - Any other untextured material falls back to the shared atlas, so nothing imports white.
## Run:  godot --headless --path . --script res://tools/fix_pack_materials.gd
## then: godot --headless --path . --import

const FBX_DIR := "res://assets/packs/synty_prototype/FBX/"
const MAT_DIR := "res://assets/packs/synty_prototype/materials/"
const TEX_DIR := "res://assets/packs/synty_prototype/textures/"
const ATLAS := MAT_DIR + "synty_prototype_atlas.tres"

# prefix -> [material file, colour, grid texture (world triplanar) or ""]. First match wins.
const CATEGORY := {
	"SM_Buildings_Column": ["blockout_wood.tres", Color(0.36, 0.27, 0.19), ""],
	"SM_Buildings_Door": ["blockout_door.tres", Color(0.3, 0.24, 0.18), ""],
	"SM_Buildings_": ["blockout_grid.tres", Color(0.55, 0.55, 0.52), "PolygonPrototype_Texture_Grid_01.png"],
	"SM_Prop_Tree_Pine": ["blockout_pine.tres", Color(0.13, 0.2, 0.13), ""],
	"SM_Prop_Tree_Bush": ["blockout_bush.tres", Color(0.16, 0.22, 0.13), ""],
	"SM_Generic_TreeDead": ["blockout_deadwood.tres", Color(0.3, 0.27, 0.22), ""],
	"SM_Generic_TreeStump": ["blockout_deadwood.tres", Color(0.3, 0.27, 0.22), ""],
	"SM_Generic_Small_Rocks": ["blockout_rock.tres", Color(0.38, 0.38, 0.36), ""],
	"SM_Prop_Crate": ["blockout_crate.tres", Color(0.45, 0.35, 0.22), ""],
	"SM_Prop_Barrel": ["blockout_barrel.tres", Color(0.32, 0.34, 0.22), ""],
	"SM_Prop_Ladder": ["blockout_metal_dark.tres", Color(0.25, 0.26, 0.28), ""],
	"SM_Prop_Microphone": ["blockout_metal_dark.tres", Color(0.25, 0.26, 0.28), ""],
	"SM_Pawn_Idle_Female": ["pawn_protagonist.tres", Color(0.26, 0.33, 0.45), ""],
	"SM_Pawn_Walk_Female": ["pawn_protagonist.tres", Color(0.26, 0.33, 0.45), ""],
	"SM_Pawn_Run_Female": ["pawn_protagonist.tres", Color(0.26, 0.33, 0.45), ""],
	"SM_Pawn_Cower_Female": ["pawn_protagonist.tres", Color(0.26, 0.33, 0.45), ""],
	"SM_Pawn_LadderClimb_Female": ["pawn_protagonist.tres", Color(0.26, 0.33, 0.45), ""],
	"SM_Pawn_Cover_Female": ["pawn_protagonist.tres", Color(0.26, 0.33, 0.45), ""],
	"SM_Pawn_Handsup_Female": ["pawn_protagonist.tres", Color(0.26, 0.33, 0.45), ""],
	"SM_Pawn_Dead_Female": ["pawn_protagonist.tres", Color(0.26, 0.33, 0.45), ""],
	"SM_Pawn_Idle_Male": ["pawn_captain.tres", Color(0.62, 0.5, 0.18), ""],
	"SM_Pawn_Dead_Male": ["pawn_reyes.tres", Color(0.32, 0.35, 0.22), ""],
	"SM_Pawn_": ["pawn_default.tres", Color(0.5, 0.5, 0.5), ""],
}


func _init() -> void:
	if not ResourceLoader.exists(ATLAS):
		var m := StandardMaterial3D.new()
		m.resource_name = "synty_prototype_atlas"
		m.albedo_texture = load(TEX_DIR + "PolygonPrototype_Texture_01.png")
		m.roughness = 0.9
		ResourceSaver.save(m, ATLAS)
	for prefix in CATEGORY:
		var spec: Array = CATEGORY[prefix]
		var path: String = MAT_DIR + spec[0]
		if ResourceLoader.exists(path):
			continue
		var m := StandardMaterial3D.new()
		m.resource_name = spec[0].get_basename()
		m.albedo_color = spec[1]
		m.roughness = 0.92
		if spec[2] != "":
			m.albedo_texture = load(TEX_DIR + spec[2])
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3.ONE * 0.5
		ResourceSaver.save(m, path)

	var fixed := 0
	for f in DirAccess.get_files_at(FBX_DIR):
		if not f.ends_with(".fbx"):
			continue
		var path := FBX_DIR + f
		var target := ""
		for prefix in CATEGORY:
			if f.begins_with(prefix):
				target = MAT_DIR + CATEGORY[prefix][0]
				break
		var cfg := ConfigFile.new()
		if cfg.load(path + ".import") != OK:
			continue
		var sub: Dictionary = cfg.get_value("params", "_subresources", {})
		var mats: Dictionary = sub.get("materials", {})
		var names := {}
		for n in mats:  # names already overridden on a previous run
			names[n] = true
		var ps := load(path) as PackedScene
		if ps:
			var inst := ps.instantiate()
			_collect(inst, names, target != "")
			inst.free()
		if names.is_empty():
			continue
		for n in names:
			mats[n] = {"use_external/enabled": true, "use_external/path": target if target != "" else ATLAS}
		sub["materials"] = mats
		cfg.set_value("params", "_subresources", sub)
		cfg.save(path + ".import")
		fixed += 1
	print("[fix_pack_materials] patched %d FBX files" % fixed)
	quit()


## Collect material names. all = false → only untextured ones.
func _collect(n: Node, out: Dictionary, all: bool) -> void:
	if n is MeshInstance3D and n.mesh:
		for s in n.mesh.get_surface_count():
			var m: Material = n.mesh.surface_get_material(s)
			if m == null or m.resource_name.is_empty() or m.resource_path.begins_with(MAT_DIR):
				continue
			var textured: bool = m is BaseMaterial3D and m.albedo_texture != null
			if all or not textured:
				out[m.resource_name] = true
	for c in n.get_children():
		_collect(c, out, all)
