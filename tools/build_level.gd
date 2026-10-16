extends SceneTree
## One-off generator for the area blockouts — one scene per playable area (see AREAS in build_common.gd):
##   res://game/levels/a0N_<area>/a0N_<area>_blockout.tscn  (+ terrain_mesh.res, terrain_shape.res)
##   res://game/levels/a0N_<area>/a0N_<area>.tscn            (inherited, for decoration)
## Layout, heights and anchor positions match the Three.js prototype (src/world/*.js).
## Run:  godot --headless --path . --script res://tools/build_level.gd [-- --only=A05] [--force]
## Never overwrites existing scenes unless --force is passed — edit the blockout in the editor after this.

const C := preload("res://tools/build_common.gd")
const V := preload("res://tools/village_builders.gd")

# palette (previs greys / muted colours, brighter than final so blocking reads at night)
const STONE := Color(0.42, 0.42, 0.4)
const MOSS := Color(0.3, 0.38, 0.24)
const WOOD := Color(0.42, 0.32, 0.22)
const WOOD_DARK := Color(0.26, 0.2, 0.15)
const ROTTEN := Color(0.3, 0.27, 0.2)
const METAL := Color(0.5, 0.52, 0.55)
const DARK_METAL := Color(0.22, 0.23, 0.25)
const RUST := Color(0.45, 0.25, 0.14)
const OLIVE := Color(0.3, 0.33, 0.2)
const CONCRETE := Color(0.5, 0.49, 0.46)
const CHARRED := Color(0.12, 0.11, 0.1)
const BASALT := Color(0.08, 0.08, 0.09)
const RED := Color(0.6, 0.1, 0.08)
const PAPER := Color(0.85, 0.82, 0.72)

var force := false
var b: C  # build_common instance


func _init() -> void:
	var only := ""
	for arg in OS.get_cmdline_user_args():
		if arg == "--force":
			force = true
		elif arg.begins_with("--only="):
			only = arg.get_slice("=", 1)
	b = C.new(Node3D.new())
	build_cable_car_scene()
	for id in C.AREAS:
		if only.is_empty() or id.begins_with(only):
			build_area(id)
	quit()


func area_dir(id: String) -> String:
	return C.LEVELS_DIR + C.AREAS[id]["folder"] + "/"


func build_area(id: String) -> void:
	var path := C.area_blockout(id)
	if FileAccess.file_exists(path) and not force:
		print("  keep   %s (exists; pass --force to rebuild)" % path)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(area_dir(id)))
	build_terrain(id)
	var root := Node3D.new()
	root.name = id
	b = C.new(root)

	var terrain := StaticBody3D.new()
	terrain.name = "Terrain"
	root.add_child(terrain)
	b.own(terrain)
	var tm := MeshInstance3D.new()
	tm.name = "TerrainMesh"
	tm.mesh = load(area_dir(id) + "terrain_mesh.res")
	terrain.add_child(tm)
	b.own(tm)
	var bd: Array = C.AREAS[id]["bounds"]
	var tc := CollisionShape3D.new()
	tc.name = "TerrainShape"
	tc.shape = load(area_dir(id) + "terrain_shape.res")
	tc.position = Vector3((bd[0] + bd[2]) / 2.0, 0, (bd[1] + bd[3]) / 2.0)
	terrain.add_child(tc)
	b.own(tc)
	var ocean := MeshInstance3D.new()
	ocean.name = "Ocean"
	var pm := PlaneMesh.new()
	pm.size = Vector2(900, 900)
	ocean.mesh = pm
	ocean.position = Vector3(10, -0.15, (bd[1] + bd[3]) / 2.0)
	ocean.material_override = b.mat(Color(0.05, 0.09, 0.11), {"roughness": 0.15, "metallic": 0.4})
	root.add_child(ocean)
	b.own(ocean)

	var geo := b.group(root, "Geometry")
	var dyn := b.group(root, "Dynamic")
	var markers := b.group(root, "Markers")
	match id:
		"A01_Beach":
			build_beach(b.group(geo, "Beach"), dyn, markers)
		"A02_Trail":
			build_trail(b.group(geo, "Trail"), markers)
		"A03_Ravine":
			build_ravine(b.group(geo, "Ravine"), dyn, markers)
		"A04_OldHarbor":
			build_harbor(b.group(geo, "Harbor"), dyn, markers)
			build_shed(b.group(geo, "Shed"), dyn, markers)
			build_tower(b.group(geo, "Watchtower"), dyn, markers)
		"A05_BaseCamp":
			build_closed_area(b.group(geo, "BaseCamp"), dyn, markers)
		"A06_Ropeway":
			build_ropeway(b.group(geo, "Ropeway"), dyn, markers)
		"A07_ServicePath":
			build_service_path(b.group(geo, "ServicePath"), dyn, markers)
		"A08_HollowEdge":
			V.new(b).build_hollow_edge(b.group(geo, "HollowEdge"), dyn, markers)
		"A09_VillageLanes":
			V.new(b).build_village_lanes(b.group(geo, "VillageLanes"), dyn, markers)
		"A10_FestivalRing":
			V.new(b).build_festival_ring(b.group(geo, "FestivalRing"), dyn, markers)
		"A11_BurnedQuarter":
			V.new(b).build_burned_quarter(b.group(geo, "BurnedQuarter"), dyn, markers)
	build_vegetation(b.group(root, "Vegetation"), C.AREAS[id]["core"])
	C.save_scene(root, path, true)
	root.free()
	write_decorated(id)


# =============================================================================
#  Terrain chunk for one area, from the shared height function, plus a heightmap collider.
#  Grids sit on a global lattice so overlapping chunks match exactly.
# =============================================================================
func build_terrain(id: String) -> void:
	var bd: Array = C.AREAS[id]["bounds"]
	var res := 0.75
	var x0 := snappedf(bd[0], res)
	var z0 := snappedf(bd[1], res)
	var nx := int(round((snappedf(bd[2], res) - x0) / res)) + 1
	var nz := int(round((snappedf(bd[3], res) - z0) / res)) + 1
	var h := PackedFloat32Array()
	h.resize(nx * nz)
	for j in nz:
		for i in nx:
			h[j * nx + i] = C.G(x0 + i * res, z0 + j * res)
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	verts.resize(nx * nz)
	normals.resize(nx * nz)
	colors.resize(nx * nz)
	var sand := Color("857a60")
	var wet := Color("4a443a")
	var dirt := Color("4f4030")
	var grass := Color("33402a")
	var moss := Color("3a4a2a")
	var rock := Color("575650")
	var concrete := Color("66645e")
	var seabed := Color("1d2224")
	for j in nz:
		for i in nx:
			var k := j * nx + i
			var x := x0 + i * res
			var z := z0 + j * res
			var y := h[k]
			verts[k] = Vector3(x, y, z)
			var hx := h[j * nx + mini(i + 1, nx - 1)] - h[j * nx + maxi(i - 1, 0)]
			var hz := h[mini(j + 1, nz - 1) * nx + i] - h[maxi(j - 1, 0) * nx + i]
			normals[k] = Vector3(-hx / (2 * res), 1.0, -hz / (2 * res)).normalized()
			var slope := Vector2(hx, hz).length() / (2 * res)
			var d := C.path_distance(x, z)
			var w := C.corridor_width(z)
			var c := dirt.lerp(grass, C.ss(w * 0.25, w * 0.9, d))
			var beach := C.ss(52, 58, z)
			var s := sand.lerp(wet, C.ss(1.0, 0.0, y))
			c = c.lerp(s, beach * (1.0 - C.ss(w, w + 4, d) * 0.6))
			var yard := C.ss(-49, -55, z) * (1.0 - C.ss(w - 2, w + 1, d)) * (1.0 - C.ss(-140, -150, z))
			c = c.lerp(concrete, yard * 0.85)
			c = c.lerp(moss, C.ss(w + 1, w + 4, d) * 0.5)
			# the old village hollow: packed earth on the floor, grass up the walls
			var vd := C.village_dist(x, z)
			if vd < C.VILLAGE_HW + C.VILLAGE_RIM + C.VILLAGE_BLEND:
				c = c.lerp(Color("4d4436"), (1.0 - C.ss(C.VILLAGE_HW, C.VILLAGE_HW + 6.0, vd)) * 0.9)
				c = c.lerp(grass, C.ss(C.VILLAGE_HW + 4.0, C.VILLAGE_HW + C.VILLAGE_RIM + 4.0, vd) * 0.8)
			c = c.lerp(rock, C.ss(0.9, 1.8, slope))
			c = c.lerp(seabed, C.ss(-0.2, -2.5, y))
			var v := 0.8 + 0.4 * C.fbm(x * 0.35, z * 0.35, 3)
			colors[k] = Color(c.r * v, c.g * v, c.b * v)
	var idx := PackedInt32Array()
	idx.resize((nx - 1) * (nz - 1) * 6)
	var p := 0
	for j in nz - 1:
		for i in nx - 1:
			var a := j * nx + i
			var bb := a + 1
			var cc := a + nx
			var d := cc + 1
			idx[p] = a; idx[p + 1] = bb; idx[p + 2] = cc
			idx[p + 3] = bb; idx[p + 4] = d; idx[p + 5] = cc
			p += 6
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.roughness = 1.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0, m)
	mesh.resource_name = id + "_Terrain"
	ResourceSaver.save(mesh, area_dir(id) + "terrain_mesh.res")
	# 1 m heightmap collider (HeightMapShape3D is centred on its node)
	var sw := int(bd[2] - bd[0]) + 1
	var sd := int(bd[3] - bd[1]) + 1
	var data := PackedFloat32Array()
	data.resize(sw * sd)
	for j in sd:
		for i in sw:
			data[j * sw + i] = C.G(bd[0] + i, bd[1] + j)
	var shape := HeightMapShape3D.new()
	shape.map_width = sw
	shape.map_depth = sd
	shape.map_data = data
	ResourceSaver.save(shape, area_dir(id) + "terrain_shape.res")
	print("  create %sterrain_mesh.res (%d verts)" % [area_dir(id), verts.size()])


## <area>.tscn inherits the blockout and adds Decoration / Lighting (the art pass).
func write_decorated(id: String) -> void:
	var f_name: String = C.AREAS[id]["folder"]
	var path := area_dir(id) + f_name + ".tscn"
	if FileAccess.file_exists(path):
		print("  keep   %s" % path)
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("""[gd_scene load_steps=2 format=3]

[ext_resource type="PackedScene" path="%s" id="1_blockout"]

[node name="%s" instance=ExtResource("1_blockout")]

[node name="Decoration" type="Node3D" parent="."]

[node name="Lighting" type="Node3D" parent="."]
""" % [C.area_blockout(id), id])
	f.close()
	print("  create %s" % path)


# ---------------------------------------------------------------- beach (ch1 opening)
func build_beach(g: Node3D, dyn: Node3D, mk: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 14:
		var x := rng.randf_range(-24, 24)
		var z := rng.randf_range(56, 74)
		if absf(x) < 4:
			continue
		b.piece(g, "Rocks_%02d" % i, "SM_Generic_Small_Rocks_0%d" % (1 + i % 2), C.gv(x, z), rng.randf() * TAU, Vector3.ONE * rng.randf_range(1.5, 3.0))
	# The black stone (the shifting rock) out past the point — submerged until the end of ch1.
	var rock := b.group(dyn, "ShiftingRock", Vector3(22, -12.5, 114))
	for c in [[6, 11, 0, 0], [3, 9.5, 5, 3], [4, 10, -4, -2], [2, 8.5, 2, -5], [2.5, 8, -6, 4]]:
		b.cyl(rock, "Spire_%d" % rock.get_child_count(), 0.0, c[0], c[1], Vector3(c[2], c[1] / 2.0, c[3]), BASALT, Vector3.ZERO, {"seg": 6})
	b.cyl(rock, "Base", 14, 16, 2, Vector3(0, 6.5, 0), BASALT, Vector3.ZERO, {"seg": 16})
	b.marker(mk, "Mk_Ch01_BoatAnchor", Vector3(0, 0.1, 78), PI)
	b.marker(mk, "Mk_Ch01_Landing", C.gv(0, 66), PI)
	b.marker(mk, "Mk_Ch01_BlackStone", Vector3(22, 0, 114))


# ---------------------------------------------------------------- trail: fallen tree, wall, shrine
func build_trail(g: Node3D, mk: Node3D) -> void:
	var tz := 36.0
	var tx := C.path_x(tz)
	var gy := C.G(tx, tz)
	var tree := b.group(g, "FallenTree", Vector3(tx, gy + 1.68, tz))
	b.cyl(tree, "Trunk", 0.38, 0.47, 13, Vector3.ZERO, WOOD_DARK, Vector3(0, 0.02, PI / 2 + 0.03))
	b.piece(tree, "Roots", "SM_Generic_TreeStump_01", Vector3(-6.6, -1.6, 0), 0.0, Vector3.ONE * 1.6)
	b.collider(tree, "Col", Vector3(14, 0.88, 0.84), Vector3.ZERO)
	b.marker(mk, "Mk_Ch01_FallenTree", Vector3(tx, gy, tz))

	var wz := 25.0
	var wx := C.path_x(wz)
	var gmin := INF
	var x := wx - 6
	while x <= wx + 6:
		gmin = minf(gmin, C.G(x, wz))
		x += 0.5
	var top := C.G(wx, wz) + 1.15
	var bottom := gmin - 0.6
	b.box(g, "RuinedWall", Vector3(12, top - bottom, 1.0), Vector3(wx, (top + bottom) / 2, wz), STONE.lerp(MOSS, 0.4))
	b.collider(g, "RuinedWall_Col", Vector3(12, top - bottom, 1.0), Vector3(wx, (top + bottom) / 2, wz))
	b.marker(mk, "Mk_Ch01_RuinedWall", Vector3(wx, top, wz))

	var sz := 15.0
	var sx := C.path_x(sz) + 3.4
	var sg := C.G(sx, sz)
	var shrine := b.group(g, "Shrine", Vector3(sx, sg, sz))
	b.box(shrine, "Plinth", Vector3(1.3, 0.5, 1.3), Vector3(0, 0.2, 0), MOSS)
	b.box(shrine, "Idol", Vector3(0.6, 0.8, 0.5), Vector3(0, 0.85, 0), STONE.lerp(MOSS, 0.5))
	b.box(shrine, "PillarL", Vector3(0.22, 2.4, 0.22), Vector3(-0.15, 1.2, -1.0), MOSS)
	b.box(shrine, "PillarR", Vector3(0.22, 2.4, 0.22), Vector3(-0.15, 1.2, 1.0), MOSS)
	b.box(shrine, "Lintel", Vector3(0.3, 0.25, 2.7), Vector3(-0.15, 2.45, 0), MOSS, Vector3(0.05, 0, 0))
	b.box(shrine, "Bracelet", Vector3(0.12, 0.03, 0.12), Vector3(-0.5, 0.46, -0.05), RED, Vector3.ZERO, {"emission": RED, "emission_energy": 0.4})
	b.marker(mk, "Mk_Ch01_Shrine", Vector3(sx, sg + 1.2, sz))


# ---------------------------------------------------------------- ravine scaffold (collapses in ch1)
func build_ravine(g: Node3D, dyn: Node3D, mk: Node3D) -> void:
	var T0 := C.SCAF_T0
	var TB := C.SCAF_TB
	var TOP := C.SCAF_TOP
	var FL := C.SCAF_FLOOR
	# Pivot at the foot of the scaffold so the collapse can tip it into the ravine.
	var scaf := b.group(dyn, "Scaffold", Vector3(2.5, FL, 6.5))
	var off := -scaf.position
	var post := func(px: float, pz: float, ptop: float, i: int):
		b.box(scaf, "Post_%02d" % i, Vector3(0.16, ptop - FL, 0.16), Vector3(px, (ptop + FL) / 2, pz) + off, WOOD_DARK)
	var n := 0
	for z in [3.6, 6.2, 8.8, 10.8]:
		post.call(-0.75, z, T0, n); n += 1
		post.call(0.75, z, T0, n); n += 1
	for p in [[4.9, 3.0], [6.5, 3.0], [4.9, 5.5], [6.5, 5.5]]:
		post.call(p[0], p[1], TB, n); n += 1
	# bridge deck across the ravine (x = 0, z 11.5 → 3.4)
	b.box(scaf, "Deck", Vector3(1.6, 0.08, 8.2), Vector3(0, T0 - 0.04, 7.4) + off, WOOD)
	b.box(scaf, "RailL", Vector3(0.05, 0.06, 7.3), Vector3(-0.82, T0 + 1.0, 7.1) + off, WOOD)
	b.box(scaf, "RailR", Vector3(0.05, 0.06, 5.2), Vector3(0.82, T0 + 1.0, 8.15) + off, WOOD)
	# stairs up along +x to the platform (y T0 → TB)
	var steps := 10
	for s in steps:
		var t := float(s) / steps
		b.box(scaf, "Step_%02d" % s, Vector3(0.42, 0.07, 1.8), Vector3(0.9 + t * 3.9, lerpf(T0, TB, t + 1.0 / steps) - 0.04, 4.5) + off, WOOD)
	b.box(scaf, "Platform", Vector3(1.8, 0.08, 2.7), Vector3(5.7, TB - 0.04, 4.25) + off, WOOD)
	b.piece(scaf, "PlatformRail", "SM_Buildings_Rail_1x1_01", Vector3(6.62, TB, 3.0) + off, 0.0, Vector3(1, 1, 2.6))
	# ladder up the cliff face to the top (stays standing after the collapse)
	b.piece(g, "CliffLadder", "SM_Prop_Ladder_1x4_01", Vector3(6.0, TB, 3.0), PI)
	# cliff dressing
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for x in [-9, -6.5, -3.5, -1, 2.5, 9, 11.5]:
		b.box(g, "CliffRock_%d" % int(x * 10), Vector3(2.4, 3.6, 1.4), Vector3(x, lerpf(-2, 9, rng.randf()), 1.7), BASALT.lerp(STONE, 0.5), Vector3(0, rng.randf() * TAU, 0))
	b.marker(mk, "Mk_Ch01_ScaffoldBase", Vector3(0, T0, 10.5))
	b.marker(mk, "Mk_Ch01_ScaffoldPlatform", Vector3(5.7, TB, 4.2))
	b.marker(mk, "Mk_Ch01_CliffTop", Vector3(5.7, TOP, 1.8))


# ---------------------------------------------------------------- old harbor + gate
func build_harbor(g: Node3D, dyn: Node3D, mk: Node3D) -> void:
	var FZ := C.HARBOR_FZ
	var HG := C.G(10, FZ)
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	# quay edge + old pier
	b.box(g, "Quay", Vector3(1.4, 6, 64), Vector3(36.6, -0.4, -82), CONCRETE)
	b.collider(g, "Quay_Col", Vector3(1.4, 6, 64), Vector3(36.6, -0.4, -82))
	var pier := b.group(g, "Pier")
	b.box(pier, "Deck", Vector3(18.6, 0.07, 3.8), Vector3(46.7, 2.72, -64), WOOD.lerp(ROTTEN, 0.4))
	var px := 38.0
	while px < 56:
		b.cyl(pier, "Pylon_%d" % int(px), 0.14, 0.16, 5.5, Vector3(px, 0.0, -65.8), WOOD_DARK)
		b.cyl(pier, "PylonB_%d" % int(px), 0.14, 0.16, 5.5, Vector3(px, 0.0, -62.2), WOOD_DARK)
		px += 3.0
	for z in [-56, -71, -88, -96, -104]:
		b.cyl(g, "Bollard_%d" % -z, 0.18, 0.24, 0.55, Vector3(36.1, 2.85, z), DARK_METAL)
	# wrecked boat on the yard, crates, barrels, lamps
	var wreck := b.group(g, "WreckedBoat", C.gv(24, -55, 0.4), Vector3(0.15, 0.6, 0.35))
	b.box(wreck, "Hull", Vector3(2.2, 1.0, 5.5), Vector3.ZERO, WOOD.lerp(Color.SLATE_GRAY, 0.4))
	b.box(wreck, "Cabin", Vector3(1.4, 1.0, 1.4), Vector3(0, 0.9, 1.2), ROTTEN)
	var i := 0
	for c in [[-2, -77.5], [-1, -76.5], [28, -60], [29, -61.2], [16, -74]]:
		b.piece(g, "Crate_%d" % i, "SM_Prop_Crate_0%d" % (1 + i % 3), C.gv(c[0], c[1], 0.5), rng.randf() * 0.4)
		i += 1
	i = 0
	for c in [[-4, -74], [-3.3, -74.6], [18, -62], [30, -66], [30.7, -66.6], [14, -76]]:
		b.piece(g, "Barrel_%d" % i, "SM_Prop_Barrel_01", C.gv(c[0], c[1], 0.47), rng.randf() * TAU)
		i += 1
	i = 0
	for c in [[0, -56], [20, -60], [-12, -73], [31, -74], [6, -78]]:
		var lg := C.G(c[0], c[1])
		b.cyl(g, "LampPost_%d" % i, 0.07, 0.09, 4.5, Vector3(c[0], lg + 2.25, c[1]), DARK_METAL)
		b.box(g, "LampHead_%d" % i, Vector3(0.8, 0.08, 0.3), Vector3(c[0] + 0.4, lg + 4.4, c[1]), DARK_METAL)
		i += 1
	# ruined cottage from the old fishing settlement
	var cg := C.G(-9.5, -57.5)
	var cot := b.group(g, "CottageRuin", Vector3(-9.5, cg, -57.5))
	b.piece(cot, "WallBack", "SM_Buildings_WallWindow_5x3_01", Vector3(2.5, 0, -2.35), 0.0, Vector3(1, 0.8, 1))
	b.piece(cot, "WallSide", "SM_Buildings_Wall_5x3_01", Vector3(-2.35, 0, -2.5), PI / 2, Vector3(0.92, 0.55, 1))
	b.piece(cot, "WallStub", "SM_Buildings_Wall_2x3_01", Vector3(2.35, 0, -2.2), PI / 2, Vector3(1.1, 0.3, 1))
	# locals' carved warning board at the yard entrance
	var wg := C.G(9.5, -51.5)
	var board := b.group(g, "WarningBoard", Vector3(9.5, wg, -51.5))
	b.cyl(board, "PostL", 0.07, 0.08, 1.8, Vector3(-0.9, 0.9, 0), ROTTEN)
	b.cyl(board, "PostR", 0.07, 0.08, 1.8, Vector3(0.9, 0.9, 0), ROTTEN)
	b.box(board, "Board", Vector3(2.0, 1.0, 0.06), Vector3(0, 1.3, 0), ROTTEN.lerp(PAPER, 0.25))
	b.marker(mk, "Mk_Ch01_WarningBoard", Vector3(9.5, wg + 1.3, -51.4))
	# perimeter fence with the gate gap x 8..12
	var fence := b.group(g, "Fence")
	for seg in [[-31.0, 8.0], [12.0, 39.5]]:
		var xa: float = seg[0]
		var xb: float = seg[1]
		var fx := xa
		while fx <= xb + 0.01:
			b.cyl(fence, "Post_%d" % int(fx * 10), 0.05, 0.05, 3.3, Vector3(fx, HG + 1.55, FZ), METAL, Vector3.ZERO, {"seg": 6})
			fx += 3.0
		b.box(fence, "Mesh_%d" % int(xa), Vector3(xb - xa, 2.6, 0.02), Vector3((xa + xb) / 2, HG + 1.4, FZ), METAL, Vector3.ZERO, {"alpha": 0.35, "double": true})
		b.box(fence, "Wire_%d" % int(xa), Vector3(xb - xa, 0.05, 0.05), Vector3((xa + xb) / 2, HG + 2.95, FZ + 0.1), DARK_METAL)
		b.collider(fence, "Col_%d" % int(xa), Vector3(xb - xa, 4.5, 0.2), Vector3((xa + xb) / 2, HG + 1.25, FZ))
	b.box(fence, "GatePostL", Vector3(0.18, 3.4, 0.18), Vector3(7.9, HG + 1.7, FZ), DARK_METAL)
	b.box(fence, "GatePostR", Vector3(0.18, 3.4, 0.18), Vector3(12.1, HG + 1.7, FZ), DARK_METAL)
	b.box(fence, "Terminal", Vector3(0.48, 0.62, 0.26), Vector3(13.1, HG + 1.35, FZ + 0.3), OLIVE)
	b.box(fence, "KeepOutSign", Vector3(1.04, 0.79, 0.02), Vector3(5, HG + 1.7, FZ + 0.06), OLIVE.lerp(PAPER, 0.3))
	b.box(fence, "Barrier", Vector3(4.4, 0.12, 0.12), Vector3(11.2, HG + 0.62, -71.5), Color(0.75, 0.6, 0.1), Vector3(0.1, 0.12, 0.24))
	# gate leaves: pivots at the hinges (animated by ch01)
	for side in [[8.0, 1.0, "GateLeft"], [12.0, -1.0, "GateRight"]]:
		var hx: float = side[0]
		var dir: float = side[1]
		var leaf := b.group(dyn, side[2], Vector3(hx, HG, FZ))
		b.box(leaf, "Frame", Vector3(1.9, 2.6, 0.06), Vector3(dir * 1.0, 1.35, 0), METAL, Vector3.ZERO, {"alpha": 0.5, "double": true})
		b.box(leaf, "Top", Vector3(1.9, 0.06, 0.06), Vector3(dir * 1.0, 2.62, 0), METAL)
		b.box(leaf, "Bottom", Vector3(1.9, 0.06, 0.06), Vector3(dir * 1.0, 0.08, 0), METAL)
		if dir > 0:
			b.box(leaf, "Insignia", Vector3(1.04, 0.79, 0.02), Vector3(1.0, 1.55, 0.04), OLIVE)
	var chain := b.group(dyn, "GateChain", Vector3(10, HG + 1.2, FZ + 0.1))
	b.box(chain, "Chain", Vector3(0.3, 0.25, 0.08), Vector3.ZERO, RUST)
	b.box(chain, "Padlock", Vector3(0.1, 0.12, 0.05), Vector3(0, -0.2, 0.06), RUST)
	b.marker(mk, "Mk_Ch01_HarborEntry", C.gv(12, -46))
	b.marker(mk, "Mk_Ch01_Gate", Vector3(10, HG, FZ + 0.5))
	b.marker(mk, "Mk_Ch01_Insignia", Vector3(9, HG + 1.55, FZ + 0.1))
	b.marker(mk, "Mk_Ch01_Pier", Vector3(46, 2.72, -64))


# ---------------------------------------------------------------- maintenance shed
func build_shed(g: Node3D, dyn: Node3D, mk: Node3D) -> void:
	var cx := C.SHED.x
	var cz := C.SHED.y
	var gy := C.G(cx, cz)
	var fy := gy + 0.12
	var x0 := cx - 3.2
	var x1 := cx + 3.2
	var z0 := cz - 3.2
	var z1 := cz + 3.2
	b.box(g, "Slab", Vector3(6.6, 0.62, 6.6), Vector3(cx, gy - 0.19, cz), CONCRETE)
	b.wall_z(g, "WallWest", x0, z0, z1, fy)
	b.wall_x(g, "WallNorth", z0, x0, x1, fy)
	b.wall_x(g, "WallSouth", z1, x0, x1, fy)
	b.wall_z(g, "WallEast", x1, z0, z1, fy, [cz])
	b.floor_tiles(g, "Roof", x0 - 0.2, z0 - 0.2, x1 + 0.2, z1 + 0.2, fy + 3.1)
	b.box(g, "Workbench", Vector3(0.9, 0.08, 3), Vector3(x0 + 0.65, fy + 0.9, cz - 0.5), WOOD)
	b.box(g, "ToolBoard", Vector3(0.04, 1.2, 2.2), Vector3(x0 + 0.15, fy + 1.65, cz - 0.3), WOOD_DARK)
	b.box(g, "ToolOutline", Vector3(0.02, 0.6, 0.15), Vector3(x0 + 0.18, fy + 1.65, cz - 0.3), PAPER)
	b.box(g, "SignOutSheet", Vector3(0.26, 0.36, 0.02), Vector3(cx + 1.4, fy + 1.45, z1 - 0.17), PAPER)
	b.box(g, "Memo", Vector3(0.3, 0.02, 0.22), Vector3(x0 + 0.55, fy + 0.95, cz - 1.4), PAPER)
	b.box(g, "TapeRecorder", Vector3(0.32, 0.09, 0.22), Vector3(x1 - 0.7, fy + 0.745, z1 - 0.7), CHARRED)
	b.piece(g, "TapeCrate", "SM_Prop_Crate_01", Vector3(x1 - 0.7, fy + 0.35, z1 - 0.7), 0.0, Vector3.ONE * 0.7)
	b.piece(g, "OilDrum", "SM_Prop_Barrel_01", Vector3(cx + 1.8, fy + 0.47, z0 + 0.6))
	# door: hinge on the north side of the doorway, opens outward (animated by ch01)
	var door := b.group(dyn, "ShedDoor", Vector3(x1 + 0.05, fy, cz - 0.5), Vector3(0, -1.9, 0))
	b.piece(door, "Door", "SM_Buildings_Door_01", Vector3.ZERO, -PI / 2)
	b.marker(mk, "Mk_Ch01_ShedDoor", Vector3(x1 + 1.5, gy, cz), PI / 2)
	b.marker(mk, "Mk_Ch01_SignOut", Vector3(cx + 1.4, fy + 1.45, z1 - 0.2))
	b.marker(mk, "Mk_Ch01_ToolBoard", Vector3(x0 + 0.2, fy + 1.65, cz - 0.3))


# ---------------------------------------------------------------- watchtower
func build_tower(g: Node3D, dyn: Node3D, mk: Node3D) -> void:
	var TX := C.TOWER.x
	var TZ := C.TOWER.y
	var G0 := C.G(TX, TZ)
	var MID := G0 + 5.5
	var TOP := G0 + 10.5
	var P := 1.6
	var t := b.group(g, "Tower", Vector3(TX, G0, TZ))
	for c in [[-1, -1], [1, -1], [-1, 1], [1, 1]]:
		for k in 5:
			b.piece(t, "Leg_%d%d_%d" % [c[0] + 1, c[1] + 1, k], "SM_Buildings_Column_1x3_01", Vector3(c[0] * 1.6 + 0.1, k * 3.0, c[1] * 1.6 - 0.1))
	b.box(t, "MidPlatform", Vector3(P * 2, 0.14, P * 2), Vector3(0, MID - G0 - 0.07, 0), WOOD)
	b.box(t, "TopPlatform", Vector3(P * 2, 0.14, P * 2), Vector3(0, TOP - G0 - 0.07, 0), WOOD)
	b.box(t, "Roof", Vector3(4.0, 0.12, 4.0), Vector3(0, TOP - G0 + 2.55, 0), RUST, Vector3(0.05, 0, 0.04))
	for side in [[0, -P, 0.0], [0, P, 0.0], [-P, 0, PI / 2], [P, 0, PI / 2]]:
		b.box(t, "TopRail_%d" % t.get_child_count(), Vector3(P * 2, 0.06, 0.06), Vector3(side[0], TOP - G0 + 1.0, side[1]), WOOD, Vector3(0, side[2], 0))
	# ladder 1 outside the south face → mid; ladder 2 inside → top
	b.piece(t, "Ladder1a", "SM_Prop_Ladder_1x4_01", Vector3(0.3, 0, P + 0.1))
	b.piece(t, "Ladder1b", "SM_Prop_Ladder_1x2_01", Vector3(0.3, 4.0, P + 0.1))
	b.piece(t, "Ladder2a", "SM_Prop_Ladder_1x4_01", Vector3(0.3, MID - G0, -0.95))
	b.piece(t, "Ladder2b", "SM_Prop_Ladder_1x1_01", Vector3(0.3, MID - G0 + 4.0, -0.95))
	b.collider(t, "Col", Vector3(3.6, 13, 3.6), Vector3(0, 6.5, 0))
	# Cpl. Reyes' body on the top platform
	b.piece(g, "ReyesBody", "SM_Pawn_Dead_Male_01", Vector3(TX + 0.9, TOP, TZ + 0.6), PI * 0.8)
	# bolt cutters (picked up in ch01)
	var cut := b.group(dyn, "BoltCutters", Vector3(TX + 1.0, TOP + 0.05, TZ - 0.7))
	b.box(cut, "Jaws", Vector3(0.08, 0.05, 0.5), Vector3.ZERO, METAL)
	b.box(cut, "Grips", Vector3(0.14, 0.05, 0.22), Vector3(0, 0, 0.32), RED)
	# searchlight + beam to the stalker spot (animated by ch01)
	var lp := Vector3(TX - 1.3, TOP + 1.25, TZ + 1.3)
	var spot := C.gv(TX - 14.5, TZ)
	b.cyl(g, "SearchlightHousing", 0.3, 0.35, 0.5, lp, DARK_METAL, Vector3(PI / 2.4, 0, 0))
	var sl := b.group(dyn, "Searchlight", lp)
	sl.transform = Transform3D(Basis.looking_at(spot - lp, Vector3.UP), lp)
	var light := SpotLight3D.new()
	light.name = "Light"
	light.light_color = Color(1.0, 0.95, 0.8)
	light.light_energy = 0.0
	light.spot_range = 30.0
	light.spot_angle = 9.0
	light.shadow_enabled = true
	sl.add_child(light)
	b.own(light)
	var beam_len := lp.distance_to(spot)
	var beam := b.cyl(sl, "Beam", 0.15, 1.4, beam_len, Vector3(0, 0, -beam_len / 2), Color(1, 0.95, 0.8), Vector3(PI / 2, 0, 0), {"alpha": 0.12, "unshaded": true, "double": true, "seg": 16})
	beam.visible = false
	b.marker(mk, "Mk_Ch01_TowerBase", Vector3(TX, G0, TZ + P + 2.5))
	b.marker(mk, "Mk_Ch01_TowerTop", Vector3(TX, TOP, TZ - 1.2))
	b.marker(mk, "Mk_Ch01_ReyesBody", Vector3(TX + 1.1, TOP + 0.6, TZ + 0.7))
	b.marker(mk, "Mk_Ch01_StalkerSpot", spot)


# ---------------------------------------------------------------- base camp (ch02)
func build_closed_area(g: Node3D, dyn: Node3D, mk: Node3D) -> void:
	var G0 := C.G(8, -100)
	var rng := RandomNumberGenerator.new()
	rng.seed = 202
	var power := b.group(dyn, "BasePower")  # lights that come on with the breakers (hidden = off)
	power.visible = false
	var powered := func(name: String, pos: Vector3, energy: float, rng_m: float):
		var l := OmniLight3D.new()
		l.name = name
		l.position = pos
		l.light_color = Color(1.0, 0.92, 0.78)
		l.light_energy = energy
		l.omni_range = rng_m
		power.add_child(l)
		b.own(l)

	# courtyard: searchlight tower, floodlights, sandbags, burnt jeep, crates
	var yard := b.group(g, "Courtyard")
	for c in [[-1, -1], [1, -1], [-1, 1], [1, 1]]:
		b.cyl(yard, "TowerLeg_%d%d" % [c[0] + 1, c[1] + 1], 0.08, 0.1, 7, Vector3(2 + c[0], G0 + 3.5, -88 + c[1]), DARK_METAL)
	b.box(yard, "TowerDeck", Vector3(2.6, 0.2, 2.6), Vector3(2, G0 + 7, -88), DARK_METAL)
	for c in [[7, -92], [-4, -95], [17, -97]]:
		b.cyl(yard, "Flood_%d" % c[0], 0.1, 0.13, 6.5, Vector3(c[0], G0 + 3.25, c[1]), DARK_METAL)
		b.box(yard, "FloodHead_%d" % c[0], Vector3(0.6, 0.35, 0.4), Vector3(c[0], G0 + 6.5, c[1]), DARK_METAL)
		powered.call("Flood_%d" % c[0], Vector3(c[0], G0 + 6.2, c[1] + 0.6), 3.0, 26.0)
	for k in 8:
		b.box(yard, "Sandbag_%d" % k, Vector3(0.7, 0.3, 0.4), Vector3(-1 + (k % 4) * 0.72, G0 + 0.15 + (k / 4) * 0.3, -84), OLIVE)
	var jeep := b.group(yard, "BurntJeep", Vector3(12, G0, -104), Vector3(0, 0.4, 0))
	b.box(jeep, "Body", Vector3(1.8, 0.8, 3.6), Vector3(0, 0.75, 0), CHARRED)
	b.box(jeep, "Cab", Vector3(1.6, 0.6, 1.4), Vector3(0, 1.45, 0.4), CHARRED)
	var k2 := 0
	for c in [[-1, -92], [0.2, -92.3], [15, -87], [-15, -90], [-14, -91.2]]:
		b.piece(yard, "Crate_%d" % k2, "SM_Prop_Crate_01", C.gv(c[0], c[1], 0.55), rng.randf() * 0.3, Vector3.ONE * 1.1)
		k2 += 1

	# substation B (x 16..28, z -94..-84) — fenced, generator + breaker panel
	var sub := b.group(g, "SubstationB")
	for f in [[22.0, -84.0, 12.0, 0.0], [22.0, -94.0, 12.0, 0.0], [28.0, -89.0, 10.0, PI / 2], [16.0, -92.0, 4.0, PI / 2], [16.0, -86.0, 4.0, PI / 2]]:
		b.box(sub, "Fence_%d" % sub.get_child_count(), Vector3(f[2], 2.4, 0.02), Vector3(f[0], G0 + 1.2, f[1]), METAL, Vector3(0, f[3], 0), {"alpha": 0.35, "double": true})
	b.box(sub, "TransformerA", Vector3(1.6, 2.2, 1.4), Vector3(26.4, G0 + 1.1, -86.2), OLIVE)
	b.box(sub, "TransformerB", Vector3(1.6, 2.2, 1.4), Vector3(26.4, G0 + 1.1, -92.4), OLIVE)
	var gen := b.group(sub, "Generator", Vector3(22.5, G0, -89.5))
	b.box(gen, "Body", Vector3(2.4, 1.3, 1.2), Vector3(0, 0.75, 0), OLIVE)
	b.box(gen, "Skid", Vector3(2.5, 0.1, 1.3), Vector3(0, 0.05, 0), DARK_METAL)
	b.cyl(gen, "FuelCap", 0.09, 0.09, 0.08, Vector3(-0.8, 1.44, 0.2), RUST)
	b.box(gen, "StarterHandle", Vector3(0.08, 0.08, 0.2), Vector3(-1.22, 0.9, 0.2), RED)
	b.box(sub, "BreakerStand", Vector3(1.8, 2.2, 0.4), Vector3(19.5, G0 + 1.1, -93.5), CONCRETE)
	b.box(sub, "BreakerPanel", Vector3(1.3, 0.9, 0.12), Vector3(19.5, G0 + 1.5, -93.24), DARK_METAL)
	b.box(sub, "ProcedureNote", Vector3(0.22, 0.3, 0.01), Vector3(18.75, G0 + 1.45, -93.17), PAPER)
	var lever_x := {"Lever_Lighting": 19.0, "Lever_Comms": 19.5, "Lever_Main": 20.0}
	for ln in lever_x:
		var pivot := b.group(dyn, ln, Vector3(lever_x[ln], G0 + 1.4, -93.15), Vector3(0.6, 0, 0))
		b.box(pivot, "Handle", Vector3(0.06, 0.28, 0.06), Vector3(0, 0.12, 0.04), RED)
	powered.call("SubstationLamp", Vector3(19.5, G0 + 3.0, -92.0), 1.5, 8.0)
	b.marker(mk, "Mk_Ch02_GateInside", C.gv(10, -86))
	b.marker(mk, "Mk_Ch02_Generator", Vector3(21.2, G0, -88.4))
	b.marker(mk, "Mk_Ch02_BreakerPanel", Vector3(19.5, G0, -91.6))

	# barracks (x 20..34, z -114..-100), door at x 26.5 on the yard side
	var bar := b.group(g, "Barracks")
	var bfy := G0 + 0.15
	b.box(bar, "Slab", Vector3(14.4, 0.5, 14.4), Vector3(27, G0 - 0.1, -107), CONCRETE)
	b.wall_x(bar, "WallFront", -100, 20, 34, bfy, [26.5], [22.5, 31.5])
	b.wall_x(bar, "WallBack", -114, 20, 34, bfy)
	b.wall_z(bar, "WallWest", 20, -114, -100, bfy)
	b.wall_z(bar, "WallEast", 34, -114, -100, bfy, [], [-107])
	b.floor_tiles(bar, "Roof", 19.8, -114.2, 34.2, -99.8, bfy + 3.1)
	for row in [[22.0, -103.5], [22.0, -109.0], [32.0, -103.5], [32.0, -109.0]]:
		var bunk := b.group(bar, "Bunk_%d" % bar.get_child_count(), Vector3(row[0], bfy, row[1]))
		for y in [0.45, 1.45]:
			b.box(bunk, "Bed_%d" % int(y * 10), Vector3(0.9, 0.2, 2.0), Vector3(0, y, 0), DARK_METAL.lerp(OLIVE, 0.5))
		b.box(bunk, "Frame", Vector3(0.9, 1.9, 0.05), Vector3(0, 0.95, -0.97), DARK_METAL)
	b.box(bar, "Table", Vector3(1.0, 0.08, 2.2), Vector3(27, bfy + 0.8, -106), WOOD)
	for lx in [22.2, 23.0, 24.6, 28.2, 29.0, 31.0, 31.8]:
		var lk := b.box(bar, "Locker_%d" % int(lx * 10), Vector3(0.6, 2.0, 0.55), Vector3(lx, bfy + 1.0, -113.585), METAL.lerp(OLIVE, 0.3))
		if lx == 28.2:
			lk.name = "Locker_Elias"
	b.box(bar, "Roster", Vector3(0.3, 0.4, 0.02), Vector3(23.2, bfy + 1.55, -100.15), PAPER)
	b.box(bar, "ShelfLow", Vector3(0.5, 0.05, 2.0), Vector3(33.5, bfy + 0.9, -110.5), WOOD)
	b.box(bar, "ShelfHigh", Vector3(0.5, 0.05, 2.0), Vector3(33.5, bfy + 1.6, -110.5), WOOD)
	var fuel := b.group(dyn, "FuelCan", Vector3(33.2, bfy + 0.93, -110.2))
	b.box(fuel, "Can", Vector3(0.3, 0.38, 0.16), Vector3(0, 0.19, 0), RED)
	var bdoor := b.group(dyn, "BarracksDoor", Vector3(26.0, bfy, -99.95), Vector3(0, 1.6, 0))
	b.piece(bdoor, "Door", "SM_Buildings_Door_01", Vector3(1.0, 0, 0))
	powered.call("BarracksLight", Vector3(27, bfy + 2.8, -107), 1.2, 10.0)
	b.marker(mk, "Mk_Ch02_BarracksDoor", Vector3(26.5, G0, -99.5))
	b.marker(mk, "Mk_Ch02_Roster", Vector3(23.2, bfy + 1.55, -100.3))
	b.marker(mk, "Mk_Ch02_EliasLocker", Vector3(28.2, bfy, -113.0))
	b.marker(mk, "Mk_Ch02_HideLocker", Vector3(31.0, bfy, -113.6))
	b.marker(mk, "Mk_Ch02_FuelCan", Vector3(33.2, bfy + 1.1, -110.2))

	# supply yard (x -18..-2, z -112..-96): everything here is stamped for the upper station
	var sup := b.group(g, "SupplyYard")
	b.box(sup, "Apron", Vector3(18, 0.2, 18), Vector3(-10, G0 + 0.05, -104), CONCRETE)
	var stacks := [[-16, -100, 3], [-13.5, -100, 2], [-16, -103, 2], [-12, -106, 3], [-15, -108.5, 1], [-6, -101, 2], [-4, -106, 3], [-7, -109, 1]]
	var n := 0
	for st in stacks:
		for h in st[2]:
			b.piece(sup, "Crate_%02d" % n, "SM_Prop_Crate_0%d" % (1 + n % 3), Vector3(st[0], G0 + 0.65 + h * 1.0, st[1]), rng.randf() * 0.15)
			n += 1
		b.label(sup, "Stencil_%02d" % n, "UPPER STATION", Vector3(st[0], G0 + 0.7, st[1] + 0.51), 0.0, 0.18, Color(0.9, 0.85, 0.7))
	for d in [[-9, -112], [-8.2, -112.1], [-7.4, -111.9], [-9.4, -111.2]]:
		b.piece(sup, "Drum_%d" % sup.get_child_count(), "SM_Prop_Barrel_01", C.gv(d[0], d[1], 0.57), rng.randf() * TAU)
	b.box(sup, "Pallet", Vector3(1.2, 0.15, 1.0), Vector3(-9, G0 + 0.22, -100.2), WOOD)
	b.piece(sup, "ManifestCrate", "SM_Prop_Crate_01", Vector3(-9, G0 + 0.8, -100.2), 0.1)
	b.box(sup, "Manifest", Vector3(0.24, 0.02, 0.32), Vector3(-9, G0 + 1.32, -100.2), PAPER)
	b.label(sup, "Sign", "SUPPLY DEPOT — ALL CARGO VIA ROPEWAY TO RESEARCH CENTER", Vector3(-10, G0 + 2.6, -95.9), 0.0, 0.32)
	b.cyl(sup, "SignPostL", 0.06, 0.06, 2.8, Vector3(-15, G0 + 1.4, -96), DARK_METAL)
	b.cyl(sup, "SignPostR", 0.06, 0.06, 2.8, Vector3(-5, G0 + 1.4, -96), DARK_METAL)
	b.box(sup, "SignBoard", Vector3(10.2, 0.5, 0.05), Vector3(-10, G0 + 2.6, -96.03), OLIVE.darkened(0.3))
	b.marker(mk, "Mk_Ch02_SupplyYard", C.gv(-9, -99))
	b.marker(mk, "Mk_Ch02_Manifest", Vector3(-9, G0 + 1.33, -100.2))

	# cable car lower station (platform x 0..12, z -142..-130) + the line up the mountain
	var sta := b.group(g, "CableCarStation")
	var PY := G0 + 1.0           # platform top
	var ROPE_Y := PY + 7.0       # haul rope height in the station
	b.box(sta, "Platform", Vector3(12, PY - G0 + 0.3, 12), Vector3(6, (PY + G0 - 0.3) / 2, -136), CONCRETE)
	b.collider(sta, "Platform_Col", Vector3(12, PY - G0 + 0.3, 12), Vector3(6, (PY + G0 - 0.3) / 2, -136))
	for i in 4:
		b.box(sta, "Step_%d" % i, Vector3(3, 0.25, 0.4), Vector3(5, G0 + 0.125 + i * 0.25, -129.0 - i * 0.4), CONCRETE)
	for c in [[0.2, -130.2], [11.8, -130.2], [0.2, -141.8], [11.8, -141.8]]:
		for k in 3:
			b.piece(sta, "Column_%d_%d_%d" % [int(c[0]), int(-c[1]), k], "SM_Buildings_Column_1x3_01", Vector3(c[0] + 0.1, PY + k * 3.0, c[1] - 0.1), 0.0, Vector3(2, 1, 2))
	b.floor_tiles(sta, "Roof", 0, -142, 12, -130, PY + 9.1)
	var bull := MeshInstance3D.new()
	bull.name = "Bullwheel"
	var tor := TorusMesh.new()
	tor.inner_radius = 1.35
	tor.outer_radius = 1.55
	bull.mesh = tor
	bull.position = Vector3(6, ROPE_Y, -141)
	bull.material_override = b.mat(DARK_METAL)
	sta.add_child(bull)
	b.own(bull)
	b.box(sta, "DriveHouse", Vector3(4, 2.4, 2.4), Vector3(6, PY + 8.1 - 1.2, -141), OLIVE)
	b.label(sta, "StationSign", "LOWER STATION — CARGO ROPEWAY — RESEARCH CENTER", Vector3(6, PY + 8.2, -129.85), 0.0, 0.34)
	# operator booth (east side, open toward the cars)
	b.wall_z(sta, "BoothEast", 12.5, -133.5, -130.5, PY)
	b.wall_x(sta, "BoothNorth", -133.5, 9.5, 12.5, PY, [], [11.0])
	b.box(sta, "BoothRoof", Vector3(3.2, 0.1, 3.2), Vector3(11, PY + 3.05, -132), DARK_METAL)
	b.box(sta, "ControlDesk", Vector3(0.7, 1.0, 2.2), Vector3(12.0, PY + 0.5, -132), OLIVE)
	b.box(sta, "Intercom", Vector3(0.12, 0.35, 0.3), Vector3(12.3, PY + 1.55, -131.4), DARK_METAL)
	b.label(sta, "IntercomLabel", "INTERCOM — UPPER STATION", Vector3(12.22, PY + 1.85, -131.4), -PI / 2, 0.1)
	b.box(sta, "DriveSwitch", Vector3(0.1, 0.3, 0.2), Vector3(12.3, PY + 1.3, -132.6), RED)
	# ropes: two tracks (up x 4.5 / down x 7.5) from the station to pylon 1; the rest of the line is A06
	var line := b.group(g, "RopewayLine")
	b.beam(sta, "RopeStation_L", Vector3(C.ROPE_X_UP, ROPE_Y, -128), Vector3(C.ROPE_X_UP, ROPE_Y, -141), 0.03, DARK_METAL)
	b.beam(sta, "RopeStation_R", Vector3(C.ROPE_X_DOWN, ROPE_Y, -128), Vector3(C.ROPE_X_DOWN, ROPE_Y, -141), 0.03, DARK_METAL)
	build_pylon(line, mk, 0)
	build_ropes(line, Vector3(0, ROPE_Y, -141), 0)
	# car 2, parked on the up track (animated by ch02). Origin = cabin floor centre.
	add_cable_car(dyn, Vector3(C.ROPE_X_UP, PY + 0.1, -136))
	powered.call("StationLight_A", Vector3(3, PY + 6.5, -134), 2.0, 12.0)
	powered.call("StationLight_B", Vector3(9, PY + 6.5, -138), 2.0, 12.0)
	powered.call("BoothLight", Vector3(11, PY + 2.6, -132), 1.0, 5.0)
	b.marker(mk, "Mk_Ch02_Station", Vector3(6, PY, -133.5))
	b.marker(mk, "Mk_Ch02_Booth", Vector3(10.8, PY, -131.5), PI / 2)
	b.marker(mk, "Mk_Ch02_CableCar", Vector3(C.ROPE_X_UP, PY + 0.1, -136))
	mountain_pines(b.group(g, "MountainPines"), -200, -152, 60, 7)


# ---------------------------------------------------------------- cable car (prop scene, used by A05 and A06)
const CABLE_CAR := "res://game/props/cable_car/cable_car.tscn"


func build_cable_car_scene() -> void:
	if FileAccess.file_exists(CABLE_CAR) and not force:
		return
	var car := Node3D.new()
	car.name = "CableCar"
	var keep := b
	b = C.new(car)
	var hull := Color(0.62, 0.5, 0.18)
	b.box(car, "Floor", Vector3(2.2, 0.12, 3.0), Vector3(0, 0.06, 0), DARK_METAL)
	b.box(car, "Roof", Vector3(2.3, 0.12, 3.1), Vector3(0, 2.5, 0), hull)
	b.box(car, "Side_W_Low", Vector3(0.06, 1.0, 3.0), Vector3(-1.1, 0.6, 0), hull)
	b.box(car, "Side_E_LowA", Vector3(0.06, 1.0, 1.3), Vector3(1.1, 0.6, -0.85), hull)  # door gap z -0.2..0.8
	b.box(car, "Side_E_LowB", Vector3(0.06, 1.0, 0.7), Vector3(1.1, 0.6, 1.15), hull)
	for side in [-1.1, 1.1]:
		b.box(car, "Side_%d_Top" % int(side * 10), Vector3(0.06, 0.25, 3.0), Vector3(side, 2.32, 0), hull)
	for end in [-1.5, 1.5]:
		b.box(car, "End_%d_Low" % int(end * 10), Vector3(2.2, 1.0, 0.06), Vector3(0, 0.6, end), hull)
		b.box(car, "End_%d_Top" % int(end * 10), Vector3(2.2, 0.25, 0.06), Vector3(0, 2.32, end), hull)
	for c in [[-1.1, -1.5], [1.1, -1.5], [-1.1, 1.5], [1.1, 1.5]]:
		b.box(car, "Post_%d_%d" % [int(c[0] * 10), int(c[1] * 10)], Vector3(0.1, 2.4, 0.1), Vector3(c[0], 1.25, c[1]), hull.darkened(0.3))
	b.box(car, "Glass", Vector3(2.16, 1.1, 2.96), Vector3(0, 1.65, 0), Color(0.5, 0.6, 0.65), Vector3.ZERO, {"alpha": 0.12, "double": true})
	var hang := C.HANGER - 2.6
	b.box(car, "Hanger", Vector3(0.14, hang, 0.14), Vector3(0, 2.5 + hang / 2, 0), DARK_METAL)
	b.box(car, "Grip", Vector3(0.3, 0.4, 0.8), Vector3(0, C.HANGER - 0.1, 0), DARK_METAL)
	b.label(car, "Number", "2", Vector3(1.14, 1.9, 0), PI / 2, 0.5, Color(0.1, 0.1, 0.1))
	var run := b.group(car, "RunLever", Vector3(-0.85, 1.0, -1.25), Vector3(0.6, 0, 0))
	b.box(run, "Handle", Vector3(0.06, 0.32, 0.06), Vector3(0, 0.14, 0), RED)
	var cab_light := OmniLight3D.new()
	cab_light.name = "CabinLight"
	cab_light.position = Vector3(0, 2.2, 0)
	cab_light.light_color = Color(1.0, 0.85, 0.6)
	cab_light.light_energy = 0.0
	cab_light.omni_range = 4.0
	car.add_child(cab_light)
	b.own(cab_light)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CABLE_CAR.get_base_dir()))
	C.save_scene(car, CABLE_CAR, true)
	car.free()
	b = keep


func add_cable_car(parent: Node, pos: Vector3) -> Node3D:
	var car := (load(CABLE_CAR) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node3D
	car.name = "CableCar"
	car.position = pos
	parent.add_child(car)
	b.own(car)
	return car


## Lattice pylon i (C.PYLONS) with crossarm and a full-height maintenance ladder.
func build_pylon(parent: Node, mk: Node, i: int) -> void:
	var pz: float = C.PYLONS[i][0]
	var pg := C.G(6, pz)
	var top := pg + float(C.PYLONS[i][1])
	var pylon := b.group(parent, "Pylon_%d" % (i + 1), Vector3(6, pg, pz))
	var h := top - pg
	for c in [[-1, -1], [1, -1], [-1, 1], [1, 1]]:
		b.beam(pylon, "Leg_%d%d" % [c[0] + 1, c[1] + 1], Vector3(c[0] * 1.6, -1, c[1] * 1.6), Vector3(c[0] * 0.5, h, c[1] * 0.5), 0.1, DARK_METAL)
	for k in 4:
		var y0 := h * k / 4.0
		var y1 := h * (k + 1) / 4.0
		var w0 := lerpf(1.6, 0.5, float(k) / 4.0)
		var w1 := lerpf(1.6, 0.5, float(k + 1) / 4.0)
		b.beam(pylon, "Brace_%d_a" % k, Vector3(-w0, y0, w0), Vector3(w1, y1, w1), 0.04, DARK_METAL)
		b.beam(pylon, "Brace_%d_b" % k, Vector3(w0, y0, -w0), Vector3(-w1, y1, -w1), 0.04, DARK_METAL)
	b.box(pylon, "CrossArm", Vector3(4.2, 0.3, 0.5), Vector3(0, h, 0), DARK_METAL)
	for k in ceili(h / 4.0):
		b.piece(pylon, "MaintLadder_%d" % k, "SM_Prop_Ladder_1x4_01", Vector3(0.3, k * 4.0, 1.7))
	b.marker(mk, "Mk_Ch03_Pylon_%d" % (i + 1), Vector3(6, top, pz))
	b.marker(mk, "Mk_Ch03_Pylon_%d_Base" % (i + 1), Vector3(6, pg, pz + 1.9))


## Both rope tracks from `from` (x ignored) to pylon `to_i`.
func build_ropes(parent: Node, from: Vector3, to_i: int) -> void:
	var z1: float = C.PYLONS[to_i][0]
	var y1 := C.pylon_top(to_i)
	for x in [C.ROPE_X_UP, C.ROPE_X_DOWN]:
		b.beam(parent, "Rope_%d_%d" % [int(x * 10), to_i + 1], Vector3(x, from.y, from.z), Vector3(x, y1, z1), 0.03, DARK_METAL)


func mountain_pines(g: Node3D, z0: float, z1: float, count: int, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var m := 0
	var tries := 0
	while m < count and tries < 6000:
		tries += 1
		var x := rng.randf_range(-58, 68)
		var z := rng.randf_range(z0, z1)
		if absf(x - 6) < 7 or near_service_path(x, z, 5.0):
			continue
		var s := rng.randf_range(3.2, 5.8)
		b.piece(g, "Pine_%03d" % m, "SM_Prop_Tree_Pine_0%d" % (1 + m % 2), Vector3(x, C.G(x, z) - 0.3, z), rng.randf() * TAU, Vector3(s, s * rng.randf_range(0.9, 1.2), s))
		m += 1


func near_service_path(x: float, z: float, r: float) -> bool:
	var P := C.SERVICE_PATH
	for i in P.size() - 1:
		var a := Vector2(P[i][0], P[i][1])
		var c := Vector2(P[i + 1][0], P[i + 1][1])
		var q := Geometry2D.get_closest_point_to_segment(Vector2(x, z), a, c)
		if q.distance_to(Vector2(x, z)) < r:
			return true
	return false


# ---------------------------------------------------------------- A06 ropeway (ch03: the ride, the breakdown)
func build_ropeway(g: Node3D, dyn: Node3D, mk: Node3D) -> void:
	var line := b.group(g, "RopewayLine")
	for i in range(1, C.PYLONS.size()):
		build_pylon(line, mk, i)
		build_ropes(line, Vector3(0, C.pylon_top(i - 1), C.PYLONS[i - 1][0]), i)
	# car 2 as it ends up in ch03: broken down beside pylon 3
	add_cable_car(dyn, C.car_at_z(C.CAR_STOP_Z))
	b.marker(mk, "Mk_Ch03_CarStop", C.car_at_z(C.CAR_STOP_Z))
	mountain_pines(b.group(g, "MountainPines"), -300, -165, 160, 11)


# ---------------------------------------------------------------- A07 service path: lit fenced path, old stream + bridge, scree, forest
const GRAVEL := Color(0.36, 0.34, 0.3)
const WATER := Color(0.12, 0.2, 0.22)


func wet(p: Vector3) -> bool:
	return C.stream_near(p.x, p.z)[0] < 3.4


func build_service_path(g: Node3D, dyn: Node3D, mk: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	var path := b.group(g, "ServicePath")
	var P := C.SERVICE_PATH
	var lamp_n := 0
	for i in P.size() - 1:
		var a := C.gv(P[i][0], P[i][1])
		var c := C.gv(P[i + 1][0], P[i + 1][1])
		var dir := c - a
		var flat := Vector3(dir.x, 0, dir.z).normalized()
		var side := Vector3(-flat.z, 0, flat.x)
		var leg := b.group(path, "Leg_%d" % (i + 1))
		var length := Vector2(dir.x, dir.z).length()
		var steps := maxi(int(length / 1.5), 1)
		var yaw := atan2(dir.x, dir.z)
		# gravel, fence rails: in short pieces, so nothing is laid across the stream
		for k in steps:
			var p0: Vector3 = a.lerp(c, float(k) / steps)
			var p1: Vector3 = a.lerp(c, float(k + 1) / steps)
			var mid: Vector3 = (p0 + p1) / 2.0
			if wet(mid):
				continue
			b.box(leg, "Gravel_%02d" % k, Vector3(2.4, 0.06, p0.distance_to(p1) + 0.02), Vector3(mid.x, C.G(mid.x, mid.z) + 0.03, mid.z), GRAVEL, Vector3(0, yaw, 0))
		for sgn in [-1.0, 1.0]:
			var off: Vector3 = side * 1.4 * sgn
			var tag := "L" if sgn < 0 else "R"
			var posts := maxi(int(length / 3.0), 1)
			for k in posts + 1:
				var p: Vector3 = a.lerp(c, float(k) / posts) + off
				if wet(p):
					continue
				p.y = C.G(p.x, p.z)
				b.cyl(leg, "Post_%s_%02d" % [tag, k], 0.05, 0.06, 1.25, p + Vector3(0, 0.62, 0), WOOD_DARK, Vector3.ZERO, {"seg": 5})
			for hgt in [0.55, 1.1]:
				for k in steps:
					var q0: Vector3 = a.lerp(c, float(k) / steps) + off
					var q1: Vector3 = a.lerp(c, float(k + 1) / steps) + off
					if wet(q0) or wet(q1):
						continue
					q0.y = C.G(q0.x, q0.z) + hgt
					q1.y = C.G(q1.x, q1.z) + hgt
					b.beam(leg, "Rail_%s_%d_%02d" % [tag, int(hgt * 100), k], q0, q1, 0.03, WOOD)
		# lamps along the outer side, every ~12 m
		var lamps := maxi(int(length / 12.0), 1)
		for k in lamps:
			var p: Vector3 = a.lerp(c, (k + 0.5) / lamps) + side * 1.8
			if wet(p):
				continue
			p.y = C.G(p.x, p.z)
			lamp_n += 1
			b.cyl(leg, "LampPost_%d" % lamp_n, 0.05, 0.07, 3.2, p + Vector3(0, 1.6, 0), DARK_METAL)
			b.box(leg, "LampHead_%d" % lamp_n, Vector3(0.3, 0.18, 0.3), p + Vector3(0, 3.25, 0), Color(1.0, 0.85, 0.55), Vector3.ZERO, {"emission": Color(1.0, 0.8, 0.5), "emission_energy": 3.0})
			var l := OmniLight3D.new()
			l.name = "Lamp_%d" % lamp_n
			l.position = p + Vector3(0, 3.0, 0)
			l.light_color = Color(1.0, 0.82, 0.55)
			l.light_energy = 1.4
			l.omni_range = 11.0
			path.add_child(l)
			b.own(l)
		b.marker(mk, "Mk_Ch03_PathTurn_%d" % (i + 1), c)
	b.marker(mk, "Mk_Ch03_PathStart", C.gv(P[0][0], P[0][1]))
	b.label(path, "PathSign", "SERVICE PATH — PYLONS 3–6 — UPPER STATION ↑", C.gv(P[0][0] + 1.5, P[0][1] + 1.6, 1.6), PI, 0.22)

	build_stream(b.group(g, "Stream"))
	build_bridge(b.group(g, "OldBridge"), mk)
	scatter_scree(b.group(g, "Scree"), rng)
	var forest := b.group(g, "Forest")
	scatter_along_path(forest, rng, 300, 2.6, 26.0, ["SM_Prop_Tree_Pine_01", "SM_Prop_Tree_Pine_02"], 3.0, 6.0, "Pine", 2.6)
	scatter_along_path(forest, rng, 120, 2.6, 26.0, ["SM_Generic_Tree_01", "SM_Generic_Tree_02", "SM_Generic_Tree_03", "SM_Generic_Tree_04"], 1.6, 2.6, "Tree", 2.6)
	scatter_along_path(forest, rng, 22, 3.0, 14.0, ["SM_Generic_TreeDead_01"], 0.9, 1.4, "Dead", 2.6)
	scatter_along_path(forest, rng, 180, 1.8, 7.0, ["SM_Prop_Tree_Bush_01"], 0.8, 1.6, "Bush", 1.6)


## The old stream: one water ribbon per stream segment, lying in the carved bed.
func build_stream(g: Node3D) -> void:
	var S := C.STREAM
	for i in S.size() - 1:
		var a := Vector2(S[i][0], S[i][1])
		var c := Vector2(S[i + 1][0], S[i + 1][1])
		var mid := (a + c) / 2.0
		var dir := c - a
		var bed: float = C.stream_near(mid.x, mid.y)[2]
		b.box(g, "Water_%d" % i, Vector3(C.STREAM_HALF * 2.0, 0.06, dir.length() + 0.5), Vector3(mid.x, bed + 0.35, mid.y), WATER, Vector3(0, atan2(dir.x, dir.y), 0), {"alpha": 0.7, "roughness": 0.08, "metallic": 0.3})
	# a few boulders in the bed, either side of the water
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	for k in 14:
		var t := rng.randf()
		var i := rng.randi() % (S.size() - 1)
		var base := Vector2(S[i][0], S[i][1]).lerp(Vector2(S[i + 1][0], S[i + 1][1]), t)
		var bed2: float = C.stream_near(base.x, base.y)[2]
		var sz := rng.randf_range(0.6, 1.2)
		b.box(g, "Boulder_%02d" % k, Vector3(sz, sz * 0.7, sz * 0.9), Vector3(base.x + rng.randf_range(-1.6, 1.6), bed2 + sz * 0.2, base.y + rng.randf_range(-1.2, 1.2)), BASALT.lerp(STONE, 0.3), Vector3(rng.randf() * 0.3, rng.randf() * TAU, rng.randf() * 0.3))


## The planked footbridge over the stream, on the path's height. Piers stand in the banks.
func build_bridge(g: Node3D, mk: Node3D) -> void:
	var X: Vector3 = C.stream_crossing()
	var P := C.SERVICE_PATH
	var dir := Vector2(P[3][0] - P[2][0], P[3][1] - P[2][1]).normalized()
	var th := atan2(dir.x, dir.y)
	var br := b.group(g, "Bridge", X, Vector3(0, th, 0))
	b.box(br, "Deck", Vector3(2.6, 0.12, 6.4), Vector3(0, -0.06, 0), WOOD_DARK)
	for k in 13:
		var z := -3.0 + k * 0.5
		b.box(br, "Plank_%02d" % k, Vector3(2.6, 0.03, 0.22), Vector3(0, 0.005, z), WOOD if k % 2 == 0 else ROTTEN)
	b.beam(br, "RailL", Vector3(-1.2, 0.9, -3.2), Vector3(-1.2, 0.9, 3.2), 0.04, WOOD)
	b.beam(br, "RailR", Vector3(1.2, 0.9, -3.2), Vector3(1.2, 0.9, 3.2), 0.04, WOOD)
	for lx in [-1.2, 1.2]:
		for lz in [-3.2, 3.2]:
			b.cyl(br, "Post_%d_%d" % [int(lx * 10), int(lz * 10)], 0.07, 0.07, 0.9, Vector3(lx, 0.45, lz), WOOD_DARK, Vector3.ZERO, {"seg": 5})
	for lx in [-1.1, 1.1]:
		for lz in [-2.2, 2.2]:
			var wx: float = X.x + lx * cos(th) + lz * sin(th)
			var wz: float = X.z - lx * sin(th) + lz * cos(th)
			var bed: float = C.stream_near(wx, wz)[2]
			var top := X.y - 0.1
			var h := maxf(top - bed, 0.2)
			b.cyl(br, "Pier_%d_%d" % [int(lx * 10), int(lz * 10)], 0.09, 0.09, h, Vector3(lx, top - h / 2.0 - X.y, lz), WOOD_DARK, Vector3.ZERO, {"seg": 5})
	b.marker(mk, "Mk_Ch03_Bridge", X)


## Loose scree on the slopes beside the path, mostly on the uphill side.
func scatter_scree(g: Node3D, rng: RandomNumberGenerator) -> void:
	var P := C.SERVICE_PATH
	var palette := [STONE, Color(0.3, 0.3, 0.29), Color(0.22, 0.22, 0.23), Color(0.4, 0.37, 0.32)]
	var n := 0
	for i in P.size() - 1:
		var a := Vector2(P[i][0], P[i][1])
		var c := Vector2(P[i + 1][0], P[i + 1][1])
		var dir := (c - a).normalized()
		var nrm := Vector2(-dir.y, dir.x)
		for k in 52:
			var base: Vector2 = a.lerp(c, rng.randf())
			var up := nrm
			if C.G(base.x + nrm.x * 4.0, base.y + nrm.y * 4.0) < C.G(base.x - nrm.x * 4.0, base.y - nrm.y * 4.0):
				up = -nrm
			var side: Vector2 = up if rng.randf() < 0.75 else -up
			var p2: Vector2 = base + side * rng.randf_range(3.4, 13.0)
			if C.stream_near(p2.x, p2.y)[0] < 3.6:
				continue
			var sz := Vector3(rng.randf_range(0.3, 1.1), rng.randf_range(0.2, 0.6), rng.randf_range(0.3, 1.0))
			var pos := C.gv(p2.x, p2.y, sz.y * 0.35)
			b.box(g, "Scree_%03d" % n, sz, pos, palette[n % palette.size()], Vector3(rng.randf() * 0.4, rng.randf() * TAU, rng.randf() * 0.4))
			n += 1


## Trees / bushes scattered in a band off the path, kept clear of the path, stream and pylon.
func scatter_along_path(g: Node3D, rng: RandomNumberGenerator, count: int, off_min: float, off_max: float, kinds: Array, s_min: float, s_max: float, prefix: String, clear: float) -> void:
	var P := C.SERVICE_PATH
	var n := 0
	var tries := 0
	while n < count and tries < count * 25:
		tries += 1
		var i := rng.randi() % (P.size() - 1)
		var a := Vector2(P[i][0], P[i][1])
		var c := Vector2(P[i + 1][0], P[i + 1][1])
		var dir := (c - a).normalized()
		var nrm := Vector2(-dir.y, dir.x) * (1.0 if rng.randf() < 0.5 else -1.0)
		var p2: Vector2 = a.lerp(c, rng.randf()) + nrm * rng.randf_range(off_min, off_max)
		if p2.y > -292.0 or p2.y < -420.0 or p2.x < -62.0 or p2.x > 68.0:
			continue
		if C.stream_near(p2.x, p2.y)[0] < 4.0 or near_service_path(p2.x, p2.y, clear) or p2.distance_to(Vector2(6, -305)) < 4.5:
			continue
		var kind: String = kinds[rng.randi() % kinds.size()]
		var s := rng.randf_range(s_min, s_max)
		var pos := C.gv(p2.x, p2.y)
		b.piece(g, "%s_%03d" % [prefix, n], kind, pos, rng.randf() * TAU, Vector3(s, s * rng.randf_range(0.9, 1.15), s))
		n += 1




# ---------------------------------------------------------------- vegetation (Synty pines / dead trees / bushes)
func build_vegetation(g: Node3D, core: Array) -> void:
	var mine := func(z: float) -> bool: return z >= core[0] and z < core[1]
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var pines := b.group(g, "Pines")
	var n := 0
	var tries := 0
	while n < 420 and tries < 20000:
		tries += 1
		var x := rng.randf_range(-70, 90)
		var z := rng.randf_range(-160, 100)
		var d := C.path_distance(x, z)
		var w := C.corridor_width(z)
		if d < w + 1.5 or d > w + 26:
			continue
		if (z < -48 or z > 60) and d < w + 5:
			continue
		var h := C.G(x, z)
		if h < 0.8:
			continue
		var s := rng.randf_range(3.2, 5.6)
		if mine.call(z):
			b.piece(pines, "Pine_%03d" % n, "SM_Prop_Tree_Pine_0%d" % (1 + n % 2), Vector3(x, h - 0.3, z), rng.randf() * TAU, Vector3(s, s * rng.randf_range(0.9, 1.2), s))
		n += 1
	var dead := b.group(g, "DeadTrees")
	n = 0
	tries = 0
	while n < 40 and tries < 4000:
		tries += 1
		var z := rng.randf_range(-48, 56)
		if z < 11 and z > 1:
			continue
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var x := C.path_x(z) + side * (C.corridor_width(z) + 0.3 + rng.randf() * 2.5)
		if mine.call(z):
			b.piece(dead, "DeadTree_%02d" % n, "SM_Generic_TreeDead_01", C.gv(x, z, -0.2), rng.randf() * TAU, Vector3.ONE * rng.randf_range(0.9, 1.5), Vector3(0, rng.randf() * TAU, side * rng.randf_range(0.05, 0.25)))
		n += 1
	var bushes := b.group(g, "Bushes")
	n = 0
	tries = 0
	while n < 140 and tries < 6000:
		tries += 1
		var z := rng.randf_range(-50, 60)
		if z < 11 and z > 1:
			continue
		var w := C.corridor_width(z)
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var x := C.path_x(z) + side * (w * 0.5 + rng.randf() * (w * 0.6 + 2))
		if C.path_distance(x, z) < 1.6:
			continue
		if mine.call(z):
			b.piece(bushes, "Bush_%03d" % n, "SM_Prop_Tree_Bush_01", C.gv(x, z, -0.1), rng.randf() * TAU, Vector3.ONE * rng.randf_range(0.8, 1.6))
		n += 1
