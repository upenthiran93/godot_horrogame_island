extends SceneTree
## Asset generator for the Proc Trees plugin (res://addons/proc_trees/):
##   textures/leaf_atlas.png       painted leaf/needle/frond/moss atlas
##   presets/<name>.tres           every TreeProfile preset, to drag into ProcTree / TreeForest and tweak
##   demo/tree_demo.tscn           showcase + benchmark scene (+ demo/terrain_mesh.res, terrain_shape.res)
## Run:  godot --headless --path . --script res://addons/proc_trees/tools/build_assets.gd [-- --force]
## Never overwrites existing files unless --force is passed (presets and the demo are meant to be edited).

const DIR := "res://addons/proc_trees/"
const TERRAIN_SIZE := 520.0
const TERRAIN_RES := 130

var force := false
var _noise := FastNoiseLite.new()


func _init() -> void:
	force = "--force" in OS.get_cmdline_user_args()
	_noise.frequency = 0.006
	_noise.fractal_octaves = 4
	build_atlas()
	build_presets()
	build_demo()
	quit()


func _keep(path: String) -> bool:
	if FileAccess.file_exists(path) and not force:
		print("  keep   %s (exists; pass --force to rebuild)" % path)
		return true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	return false


func build_atlas() -> void:
	var path := TreeMaterials.ATLAS_PATH
	if _keep(path):
		return
	var t := Time.get_ticks_msec()
	var img := TreeMaterials.paint_leaf_atlas(1024)
	img.clear_mipmaps()
	img.save_png(ProjectSettings.globalize_path(path))
	# import with mipmaps + VRAM compression (needed for alpha-cut foliage at distance)
	var imp := FileAccess.open(ProjectSettings.globalize_path(path + ".import"), FileAccess.WRITE)
	imp.store_string('[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n[params]\n\ncompress/mode=2\n'
		+ 'compress/high_quality=false\nmipmaps/generate=true\nprocess/fix_alpha_border=true\ndetect_3d/compress_to=0\n')
	imp.close()
	print("  create %s (%d ms)" % [path, Time.get_ticks_msec() - t])


func build_presets() -> void:
	for n in TreeProfile.PRESET_NAMES:
		var path: String = DIR + "presets/%s.tres" % n
		if _keep(path):
			continue
		var err := ResourceSaver.save(TreeProfile.preset(n), path)
		assert(err == OK, "save failed " + path)
		print("  create %s" % path)


func _height(x: float, z: float) -> float:
	var r := Vector2(x, z).length()
	var hills := _noise.get_noise_2d(x, z) * 16.0 + sin(x * 0.02) * 3.0
	return hills * smoothstep(70.0, 140.0, r)


func build_demo() -> void:
	var path := DIR + "demo/tree_demo.tscn"
	if _keep(path):
		return
	var t0 := Time.get_ticks_msec()
	# terrain: flat showcase in the middle, hills around it
	var n := TERRAIN_RES + 1
	var cell := TERRAIN_SIZE / TERRAIN_RES
	var heights := PackedFloat32Array()
	heights.resize(n * n)
	for j in n:
		for i in n:
			heights[j * n + i] = _height(-TERRAIN_SIZE * 0.5 + i * cell, -TERRAIN_SIZE * 0.5 + j * cell)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in n:
		for i in n:
			st.set_uv(Vector2(i, j) / 8.0)
			st.add_vertex(Vector3(-TERRAIN_SIZE * 0.5 + i * cell, heights[j * n + i], -TERRAIN_SIZE * 0.5 + j * cell))
	for j in TERRAIN_RES:
		for i in TERRAIN_RES:
			var a := j * n + i
			st.add_index(a)
			st.add_index(a + 1)
			st.add_index(a + n)
			st.add_index(a + 1)
			st.add_index(a + n + 1)
			st.add_index(a + n)
	st.generate_normals()
	var tmesh := st.commit()
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.27, 0.3, 0.17)
	gm.roughness = 1.0
	tmesh.surface_set_material(0, gm)
	ResourceSaver.save(tmesh, DIR + "demo/terrain_mesh.res")
	var shape := HeightMapShape3D.new()
	shape.map_width = n
	shape.map_depth = n
	var scaled := PackedFloat32Array()
	for h in heights:
		scaled.append(h / cell)  # the collision node is scaled uniformly by `cell`
	shape.map_data = scaled
	ResourceSaver.save(shape, DIR + "demo/terrain_shape.res")

	var root := Node3D.new()
	root.name = "TreeDemo"
	root.set_script(load(DIR + "demo/tree_demo.gd"))

	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	var env := Environment.new()
	var sky := Sky.new()
	var psky := ProceduralSkyMaterial.new()
	psky.sky_top_color = Color(0.36, 0.48, 0.62)
	psky.sky_horizon_color = Color(0.68, 0.72, 0.74)
	psky.ground_horizon_color = Color(0.5, 0.52, 0.5)
	sky.sky_material = psky
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.62, 0.68, 0.72)
	env.fog_density = 0.004
	env.fog_sky_affect = 0.4
	we.environment = env
	root.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-42, 35, 0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 140.0
	root.add_child(sun)

	var ground := StaticBody3D.new()
	ground.name = "Ground"
	root.add_child(ground)
	var gmi := MeshInstance3D.new()
	gmi.name = "Mesh"
	gmi.mesh = load(DIR + "demo/terrain_mesh.res")
	ground.add_child(gmi)
	var gcs := CollisionShape3D.new()
	gcs.name = "Shape"
	gcs.shape = load(DIR + "demo/terrain_shape.res")
	gcs.scale = Vector3.ONE * cell
	ground.add_child(gcs)

	var wind := TreeWind.new()
	wind.name = "TreeWind"
	wind.strength = 0.6
	root.add_child(wind)

	# showcase rows: realistic at z = -14, stylized at z = +14
	var showcase := Node3D.new()
	showcase.name = "Showcase"
	root.add_child(showcase)
	var rows := [
		[["realistic_broadleaf", "realistic_jungle", "realistic_pine", "realistic_palm", "realistic_dead"], -14.0, 20.0],
		[["stylized_broadleaf", "stylized_pine", "stylized_palm", "stylized_dead"], 14.0, 16.0],
	]
	for row in rows:
		var names: Array = row[0]
		for i in names.size():
			var x: float = (i - (names.size() - 1) * 0.5) * row[2]
			var tree := ProcTree.new()
			tree.name = (names[i] as String).to_pascal_case()
			tree.profile = load(DIR + "presets/%s.tres" % names[i])
			tree.position = Vector3(x, 0.0, row[1])
			showcase.add_child(tree)
			var lbl := Label3D.new()
			lbl.name = tree.name + "Label"
			lbl.text = (names[i] as String).replace("_", " ")
			lbl.position = Vector3(x, 0.6, row[1] + 4.5)
			lbl.font_size = 64
			lbl.pixel_size = 0.006
			lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			lbl.modulate = Color(1, 1, 0.9)
			lbl.outline_size = 12
			showcase.add_child(lbl)

	var forests := [
		["RealisticForest", Vector3(0, 0, -150), ["realistic_broadleaf", "realistic_jungle", "realistic_palm", "realistic_pine", "realistic_dead"],
			PackedFloat32Array([3.0, 1.0, 2.0, 1.5, 0.5])],
		["StylizedForest", Vector3(0, 0, 150), ["stylized_broadleaf", "stylized_pine", "stylized_palm", "stylized_dead"],
			PackedFloat32Array([3.0, 2.0, 1.5, 0.4])],
	]
	for f in forests:
		var forest := TreeForest.new()
		forest.name = f[0]
		forest.position = f[1]
		var profs: Array[TreeProfile] = []
		for pn in f[2]:
			profs.append(load(DIR + "presets/%s.tres" % pn))
		forest.profiles = profs
		forest.profile_weights = f[3]
		forest.area = Vector2(440, 200)
		forest.spacing = 6.0
		forest.density = 0.8
		forest.random_seed = 3 if f[0] == "RealisticForest" else 5
		root.add_child(forest)

	var cam := Camera3D.new()
	cam.name = "Camera"
	cam.position = Vector3(0, 3.0, 42)
	cam.rotation = Vector3(-0.06, 0.0, 0.0)
	cam.fov = 70.0
	cam.far = 1000.0
	root.add_child(cam)

	var hud := CanvasLayer.new()
	hud.name = "HUD"
	root.add_child(hud)
	var stats := Label.new()
	stats.name = "Stats"
	stats.position = Vector2(12, 10)
	stats.add_theme_color_override("font_outline_color", Color.BLACK)
	stats.add_theme_constant_override("outline_size", 6)
	hud.add_child(stats)

	_own(root, root)
	var ps := PackedScene.new()
	assert(ps.pack(root) == OK)
	assert(ResourceSaver.save(ps, path) == OK)
	print("  create %s (%d ms)" % [path, Time.get_ticks_msec() - t0])


func _own(n: Node, root: Node) -> void:
	for c in n.get_children():
		c.owner = root
		_own(c, root)
