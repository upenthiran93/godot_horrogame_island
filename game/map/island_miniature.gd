extends Node3D
## Story-map miniature: the whole island as one simplified 3D model, with the player's route drawn over and
## under it. Everything comes from res://story/map.json (route, structures) and island_height.gd (terrain), so
## edit those and run again. 1 unit = 1 metre; the grid is 100 m. Underground parts show through the ground in X-ray.
##
## Mouse: left-drag orbit · right/middle-drag pan · wheel zoom.  Keys: WASD pan · Q/E down/up
##   Space play/pause the walk · , . previous/next stage · [ ] speed · F follow · X x-ray ground · L labels
##   G grid · A built-area outlines · 1 top  2 iso  3 south  4 west · H hide panels · Esc quit
## Screenshots: godot --path . res://game/map/island_miniature.tscn --write-movie out.png --fixed-fps 1 --quit-after 3 -- --view=iso --xray=1

const C := preload("res://tools/build_common.gd")
const IH := preload("res://game/map/island_height.gd")
const MAP_PATH := "res://story/map.json"
const X0 := -420.0
const X1 := 180.0
const Z0 := -720.0
const Z1 := 160.0
const RES := 4.0
const CENTRE := Vector3(-120.0, 120.0, -280.0)

var map := {}
var stages: Array = []      # {id, name, act, status, mode, pts: Array[Vector3], start_d, len, color}
var full: Array = []        # every route point in play order
var cum: Array = []         # distance along the whole route at each point
var total := 0.0

var rig: Node3D
var cam: Camera3D
var yaw := -0.6
var pitch := -0.62
var dist := 1100.0
var target := CENTRE

var terrain_mat: StandardMaterial3D
var labels: Node3D
var grid: Node3D
var areas_node: Node3D
var token: Node3D
var playing := false
var at_d := 0.0
var speed := 45.0
var follow := false
var xray := true
var cur_stage := 0
var hud_root: Control
var hud_keys: Label
var hud_stages: Label
var hud_now: Label
var _drag := 0


func _ready() -> void:
	var f := FileAccess.open(MAP_PATH, FileAccess.READ)
	map = JSON.parse_string(f.get_as_text())
	var args := OS.get_cmdline_user_args()
	build_environment()
	build_terrain()
	build_plinth()
	labels = Node3D.new()
	labels.name = "Labels"
	add_child(labels)
	build_routes()
	build_structures()
	grid = build_grid()
	areas_node = build_areas()
	build_token()
	build_hud()
	cam = Camera3D.new()
	cam.fov = 50.0
	cam.near = 2.0
	cam.far = 9000.0
	rig = Node3D.new()
	rig.add_child(cam)
	add_child(rig)
	set_view("iso")
	for a in args:
		if a.begins_with("--view="):
			set_view(a.get_slice("=", 1))
		elif a.begins_with("--xray="):
			xray = a.get_slice("=", 1) == "1"
			apply_xray()
		elif a.begins_with("--stage="):
			goto_stage(a.get_slice("=", 1).to_int())
		elif a == "--no-hud":
			hud_root.visible = false
		elif a == "--no-areas":
			areas_node.visible = false
		elif a.begins_with("--dist="):
			dist = a.get_slice("=", 1).to_float()
	apply_xray()
	update_hud()
	if "--report" in args:
		print("STAGE REPORT (metres)")
		var cum_len := 0.0
		for st in stages:
			print("%s | %-26s | %-8s | len %5d | start %5d | y %4d -> %4d | min %4d max %4d" % [st["id"], st["name"], st["status"], int(st["len"]), int(cum_len), int(st["y0"]), int(st["y1"]), int(st["ymin"]), int(st["ymax"])])
			cum_len += st["len"]
		print("TOTAL %d m" % int(total))
		get_tree().quit()


# ============================================================ scene furniture
func build_environment() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.06, 0.07, 0.1)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.78, 0.85)
	e.ambient_light_energy = 0.7
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.9, -0.5, 0)
	sun.light_energy = 1.1
	add_child(sun)


func build_plinth() -> void:
	var cx := (X0 + X1) / 2.0
	var cz := (Z0 + Z1) / 2.0
	var plinth := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(X1 - X0, 50.0, Z1 - Z0)
	plinth.mesh = bm
	plinth.position = Vector3(cx, -36.0, cz)
	plinth.material_override = flat(Color(0.12, 0.1, 0.09))
	add_child(plinth)
	var sea := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(X1 - X0, Z1 - Z0)
	sea.mesh = pm
	sea.position = Vector3(cx, -3.0, cz)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.12, 0.3, 0.42, 0.55)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.render_priority = -2
	sea.material_override = m
	add_child(sea)


func flat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	return m


func glow(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func hex(s: String) -> Color:
	return Color.html(s)


# ============================================================ terrain
func terrain_colour(x: float, z: float, y: float, slope: float) -> Color:
	var seabed := Color(0.1, 0.17, 0.2)
	var sand := Color(0.64, 0.58, 0.42)
	var grass := Color(0.2, 0.33, 0.19)
	var forest := Color(0.14, 0.24, 0.16)
	var rock := Color(0.42, 0.41, 0.4)
	var high := Color(0.62, 0.62, 0.64)
	var earth := Color(0.4, 0.33, 0.25)
	var c := grass
	c = c.lerp(forest, C.ss(60.0, 160.0, y))
	c = c.lerp(rock, C.ss(180.0, 280.0, y))
	c = c.lerp(high, C.ss(330.0, 420.0, y))
	c = c.lerp(sand, 1.0 - C.ss(1.5, 5.0, y))
	c = c.lerp(rock, C.ss(0.9, 1.7, slope))
	c = c.lerp(seabed, C.ss(-0.5, -4.0, y))
	var vd := C.village_dist(x, z)
	if vd < C.VILLAGE_HW + 2.0:
		c = c.lerp(earth, 1.0 - C.ss(C.VILLAGE_HW - 2.0, C.VILLAGE_HW + 2.0, vd))
	var v := 0.9 + 0.2 * C.fbm(x * 0.2, z * 0.2, 2)
	return Color(c.r * v, c.g * v, c.b * v)


func build_terrain() -> void:
	var nx := int((X1 - X0) / RES) + 1
	var nz := int((Z1 - Z0) / RES) + 1
	var h := PackedFloat32Array()
	h.resize(nx * nz)
	for j in nz:
		for i in nx:
			h[j * nx + i] = IH.H(X0 + i * RES, Z0 + j * RES)
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	verts.resize(nx * nz)
	normals.resize(nx * nz)
	colors.resize(nx * nz)
	for j in nz:
		for i in nx:
			var k := j * nx + i
			var x := X0 + i * RES
			var z := Z0 + j * RES
			verts[k] = Vector3(x, h[k], z)
			var hx := h[j * nx + mini(i + 1, nx - 1)] - h[j * nx + maxi(i - 1, 0)]
			var hz := h[mini(j + 1, nz - 1) * nx + i] - h[maxi(j - 1, 0) * nx + i]
			normals[k] = Vector3(-hx / (2.0 * RES), 1.0, -hz / (2.0 * RES)).normalized()
			colors[k] = terrain_colour(x, z, h[k], Vector2(hx, hz).length() / (2.0 * RES))
	var idx := PackedInt32Array()
	idx.resize((nx - 1) * (nz - 1) * 6)
	var p := 0
	for j in nz - 1:
		for i in nx - 1:
			var a := j * nx + i
			var b := a + 1
			var c := a + nx
			var d := c + 1
			idx[p] = a
			idx[p + 1] = b
			idx[p + 2] = c
			idx[p + 3] = b
			idx[p + 4] = d
			idx[p + 5] = c
			p += 6
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	terrain_mat = StandardMaterial3D.new()
	terrain_mat.vertex_color_use_as_albedo = true
	terrain_mat.vertex_color_is_srgb = true
	terrain_mat.roughness = 1.0
	terrain_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0, terrain_mat)
	var mi := MeshInstance3D.new()
	mi.name = "Terrain"
	mi.mesh = mesh
	add_child(mi)


func apply_xray() -> void:
	if xray:
		terrain_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		terrain_mat.albedo_color = Color(1, 1, 1, 0.55)
	else:
		terrain_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		terrain_mat.albedo_color = Color(1, 1, 1, 1)


# ============================================================ routes
func ground_y(x: float, z: float) -> float:
	return IH.H(x, z)


## The 3D points of one route: [x, z] follows the ground, [x, z, y] is at that height.
func route_points(raw: Array, mode: String, lift: float) -> Array:
	var pts: Array = []
	for i in raw.size():
		var p: Array = raw[i]
		var q: Array = raw[maxi(i - 1, 0)]
		var steps := 1
		if p.size() == 2 and q.size() == 2 and i > 0:
			steps = maxi(int(Vector2(p[0] - q[0], p[1] - q[1]).length() / 5.0), 1)
		elif i > 0:
			steps = maxi(int(Vector2(p[0] - q[0], p[1] - q[1]).length() / 12.0), 1)
		for s in range(1 if i > 0 else 0, (steps if i > 0 else 0) + 1):
			var t := float(s) / float(steps) if i > 0 else 1.0
			var x: float = lerpf(q[0], p[0], t) if i > 0 else p[0]
			var z: float = lerpf(q[1], p[1], t) if i > 0 else p[1]
			var y: float
			if mode == "ropeway":
				y = C.car_at_z(z).y + lift + 3.0
			elif p.size() == 3:
				var qy: float = q[2] if q.size() == 3 else ground_y(q[0], q[1]) + lift
				y = lerpf(qy, p[2], t) if i > 0 else p[2]
			else:
				y = ground_y(x, z) + lift
			pts.append(Vector3(x, y, z))
	return pts


func stage_colour(s: Dictionary) -> Color:
	if s.get("mode", "ground") == "ropeway":
		return Color(0.4, 0.8, 1.0)
	if s["mode"] == "underground":
		return Color(0.82, 0.48, 1.0)
	if s["status"] == "built":
		return Color(0.35, 0.92, 0.5)
	return Color(1.0, 0.72, 0.2)


func tube(parent: Node3D, a: Vector3, b: Vector3, r: float, m: Material) -> void:
	var len := a.distance_to(b)
	if len < 0.01:
		return
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = len
	cm.radial_segments = 6
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = m
	mi.position = (a + b) / 2.0
	var up := (b - a) / len
	var side := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	mi.basis = Basis(side, up, side.cross(up)).orthonormalized()
	parent.add_child(mi)


func make_label(text: String, pos: Vector3, size: int, color: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = size
	l.pixel_size = 0.00036
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.fixed_size = true
	l.no_depth_test = true
	l.modulate = color
	l.outline_size = 10
	l.outline_modulate = Color(0, 0, 0, 0.9)
	l.render_priority = 5
	labels.add_child(l)
	return l


func build_routes() -> void:
	var routes := Node3D.new()
	routes.name = "Routes"
	add_child(routes)
	var d := 0.0
	for raw_stage in map["stages"]:
		var s: Dictionary = raw_stage
		var mode: String = s.get("mode", "ground")
		var col := stage_colour(s)
		var m := glow(col)
		var r: float = s.get("radius", 1.5 if mode != "underground" else 2.4)
		var lift := 1.6 if mode == "ground" else 0.0
		var pts := route_points(s["route"], mode, lift)
		var node := Node3D.new()
		node.name = s["id"]
		routes.add_child(node)
		for i in pts.size() - 1:
			tube(node, pts[i], pts[i + 1], r, m)
		# route length and elevation range
		var len := 0.0
		var ymin := INF
		var ymax := -INF
		for i in pts.size():
			ymin = minf(ymin, pts[i].y)
			ymax = maxf(ymax, pts[i].y)
			if i > 0:
				len += pts[i].distance_to(pts[i - 1])
		s["pts"] = pts
		s["start_d"] = d
		s["len"] = len
		s["y0"] = pts[0].y
		s["ymin"] = ymin
		s["ymax"] = ymax
		s["y1"] = pts[pts.size() - 1].y
		s["col"] = col
		d += len
		stages.append(s)
		# chambers (caves, rooms)
		for ch in s.get("chambers", []):
			var sm := MeshInstance3D.new()
			var sp := SphereMesh.new()
			sp.radius = 1.0
			sp.height = 2.0
			sp.radial_segments = 16
			sp.rings = 8
			sm.mesh = sp
			sm.position = Vector3(ch[0], ch[2], ch[1])
			sm.scale = Vector3(ch[3], ch[4], ch[5])
			var cm := StandardMaterial3D.new()
			cm.albedo_color = Color(col.r, col.g, col.b, 0.35)
			cm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			cm.render_priority = 1
			sm.material_override = cm
			node.add_child(sm)
		# the stage label sits at the middle of the route
		var mid: Vector3 = pts[pts.size() / 2]
		make_label("%s %s" % [s["id"], s["name"]], mid + Vector3(0, 14, 0), 36, col.lightened(0.25))
	# the player's walk: all stage points joined, no duplicate join points
	for st in stages:
		for i in st["pts"].size():
			var p: Vector3 = st["pts"][i]
			if full.is_empty() or p.distance_to(full[full.size() - 1]) > 0.05:
				full.append(p)
	cum.append(0.0)
	for i in range(1, full.size()):
		cum.append(cum[i - 1] + full[i].distance_to(full[i - 1]))
	total = cum[cum.size() - 1]
	# side routes (cable line, bypassed service path, the Ch4 lift)
	for sr in map.get("side_routes", []):
		var style: String = sr.get("style", "surface")
		var col2 := Color(0.55, 0.78, 0.95) if style == "air" else Color(0.85, 0.85, 0.88)
		var pts2 := route_points(sr["route"], "air" if style == "air" else "ground", 1.4)
		var side := Node3D.new()
		side.name = "Side_" + sr["name"]
		routes.add_child(side)
		for i in pts2.size() - 1:
			tube(side, pts2[i], pts2[i + 1], 0.55, glow(col2))
		make_label(sr["name"], pts2[pts2.size() / 2] + Vector3(0, 8, 0), 26, col2)


func build_structures() -> void:
	var holder := Node3D.new()
	holder.name = "Structures"
	add_child(holder)
	for raw in map.get("structures", []):
		var s: Dictionary = raw
		var pos: Array = s["pos"]
		var y: float = pos[2] if pos.size() == 3 else ground_y(pos[0], pos[1])
		var sz: Array = s["size"]
		var col := hex(s.get("color", "#cccccc"))
		var node := Node3D.new()
		node.name = s["name"]
		node.position = Vector3(pos[0], y, pos[1])
		node.rotation.y = deg_to_rad(s.get("yaw", 0.0))
		holder.add_child(node)
		var mi := MeshInstance3D.new()
		match s["kind"]:
			"ring":
				var tm := TorusMesh.new()
				tm.inner_radius = sz[0] * 0.42
				tm.outer_radius = sz[0] * 0.5
				mi.mesh = tm
				mi.position.y = 1.0
			"ship":
				var bm := BoxMesh.new()
				bm.size = Vector3(sz[0], sz[1], sz[2])
				mi.mesh = bm
				mi.position.y = sz[1] * 0.5
				mi.rotation.z = 0.12
				var prow := MeshInstance3D.new()
				var pm := PrismMesh.new()
				pm.size = Vector3(sz[2], sz[1], sz[2])
				prow.mesh = pm
				prow.position = Vector3(sz[0] * 0.5 + sz[2] * 0.2, sz[1] * 0.5, 0)
				prow.rotation = Vector3(0, PI / 2.0, 0.12)
				prow.material_override = flat(col)
				node.add_child(prow)
			_:
				var bm2 := BoxMesh.new()
				bm2.size = Vector3(sz[0], sz[1], sz[2])
				mi.mesh = bm2
				mi.position.y = sz[1] * 0.5
		mi.material_override = flat(col)
		node.add_child(mi)
		make_label(s["name"], node.position + Vector3(0, float(sz[1]) + 14.0, 0), 28, Color(0.95, 0.95, 0.95))
	for raw in map.get("landmarks", []):
		var lm: Dictionary = raw
		var lp: Array = lm["pos"]
		var ly := ground_y(lp[0], lp[1])
		var post := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.6
		cm.bottom_radius = 0.6
		cm.height = 16.0
		post.mesh = cm
		post.position = Vector3(lp[0], ly + 8.0, lp[1])
		post.material_override = glow(Color(1, 1, 1))
		holder.add_child(post)
		make_label(lm["name"], Vector3(lp[0], ly + 22.0, lp[1]), 22, Color(0.85, 0.85, 0.85))


func build_grid() -> Node3D:
	var g := Node3D.new()
	g.name = "Grid"
	add_child(g)
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	var x := -400.0
	while x <= X1:
		im.surface_add_vertex(Vector3(x, -9.0, Z0))
		im.surface_add_vertex(Vector3(x, -9.0, Z1))
		x += 100.0
	var z := -700.0
	while z <= Z1:
		im.surface_add_vertex(Vector3(X0, -9.0, z))
		im.surface_add_vertex(Vector3(X1, -9.0, z))
		z += 100.0
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	var m := glow(Color(0.5, 0.6, 0.7, 0.5))
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = m
	g.add_child(mi)
	return g


## Outlines of the built level areas (A01 to A11), draped over the ground.
func build_areas() -> Node3D:
	var n := Node3D.new()
	n.name = "Areas"
	add_child(n)
	var im := ImmediateMesh.new()
	for id in C.AREAS:
		var bd: Array = C.AREAS[id]["bounds"]
		im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		var ring := [[bd[0], bd[1], bd[2], bd[1]], [bd[2], bd[1], bd[2], bd[3]], [bd[2], bd[3], bd[0], bd[3]], [bd[0], bd[3], bd[0], bd[1]]]
		for e in ring:
			var len := Vector2(e[2] - e[0], e[3] - e[1]).length()
			var steps := maxi(int(len / 8.0), 1)
			for k in steps + 1:
				var t := float(k) / steps
				var px: float = lerpf(e[0], e[2], t)
				var pz: float = lerpf(e[1], e[3], t)
				im.surface_add_vertex(Vector3(px, ground_y(px, pz) + 2.5, pz))
		im.surface_end()
		var cx: float = (bd[0] + bd[2]) / 2.0
		var cz: float = (bd[1] + bd[3]) / 2.0
		var l := Label3D.new()
		l.text = String(id).get_slice("_", 0)
		l.position = Vector3(cx, ground_y(cx, cz) + 6.0, cz)
		l.font_size = 24
		l.pixel_size = 0.00036
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.fixed_size = true
		l.no_depth_test = true
		l.modulate = Color(1, 1, 1, 0.65)
		l.outline_size = 8
		n.add_child(l)
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.material_override = glow(Color(1, 1, 1, 0.7))
	n.add_child(mi)
	return n


func build_token() -> void:
	token = Node3D.new()
	token.name = "Player"
	add_child(token)
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 3.0
	cm.height = 10.0
	mi.mesh = cm
	mi.position.y = 5.0
	mi.material_override = glow(Color(1, 1, 1))
	token.add_child(mi)
	var beam := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.5
	bm.bottom_radius = 0.5
	bm.height = 120.0
	beam.mesh = bm
	beam.position.y = 60.0
	var m := glow(Color(1, 1, 1, 0.35))
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam.material_override = m
	token.add_child(beam)
	place_token()


func place_token() -> void:
	var p := point_at(at_d)
	token.position = p


func point_at(d: float) -> Vector3:
	d = clampf(d, 0.0, total)
	var i := 1
	while i < full.size() - 1 and cum[i] < d:
		i += 1
	var seg: float = cum[i] - cum[i - 1]
	var t := clampf((d - cum[i - 1]) / (seg if seg > 0.0 else 1.0), 0.0, 1.0)
	return (full[i - 1] as Vector3).lerp(full[i], t)


func stage_at(d: float) -> int:
	var k := 0
	for i in stages.size():
		if d >= float(stages[i]["start_d"]) - 0.01:
			k = i
	return k


# ============================================================ HUD
func build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud_root = Control.new()
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud_root)
	hud_keys = hud_label(Control.PRESET_TOP_LEFT, 13)
	hud_keys.text = "Tidewater: story map (1 unit = 1 m, grid 100 m)\ngreen = built · amber = proposed (ground) · purple = underground · blue = cable car\ndrag orbit · right-drag pan · wheel zoom · WASD pan\nSpace walk the route · , . stage · [ ] speed · F follow\nX x-ray ground · L labels · G grid · A areas · 1-4 views · H hide"
	hud_now = hud_label(Control.PRESET_BOTTOM_LEFT, 18)
	hud_stages = hud_label(Control.PRESET_TOP_RIGHT, 13)
	hud_stages.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


func hud_label(preset: int, size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(l)
	l.set_anchors_preset(preset)
	l.offset_left = 12 if preset in [Control.PRESET_TOP_LEFT, Control.PRESET_BOTTOM_LEFT] else -420
	l.offset_right = 12 if preset in [Control.PRESET_TOP_LEFT, Control.PRESET_BOTTOM_LEFT] else -12
	l.offset_top = 10 if preset in [Control.PRESET_TOP_LEFT, Control.PRESET_TOP_RIGHT] else -80
	return l


func update_hud() -> void:
	cur_stage = stage_at(at_d)
	var s: Dictionary = stages[cur_stage]
	var p := point_at(at_d)
	hud_now.text = "%s  %s   [%s]   elevation %d m   route %d / %d m\n%s" % [s["id"], s["name"], s["status"], int(p.y), int(at_d), int(total), s.get("note", "")]
	var lines := PackedStringArray()
	var gain := 0.0
	for i in stages.size():
		var st: Dictionary = stages[i]
		var mark := "▶ " if i == cur_stage else "   "
		var flag := "" if st["status"] == "built" else "*"
		lines.append("%s%s %s%s   %d→%d m" % [mark, st["id"], st["name"], flag, int(st["y0"]), int(st["y1"])])
	lines.append("")
	lines.append("* proposed. Route %d m, start 0 m, summit %d m." % [int(total), int((full[full.size() - 1] as Vector3).y)])
	hud_stages.text = "\n".join(lines)


# ============================================================ camera and input
func set_view(name: String) -> void:
	target = CENTRE
	match name:
		"top":
			yaw = 0.0
			pitch = -PI / 2.0 + 0.001
			dist = 1150.0
		"south":
			yaw = 0.0
			pitch = -0.12
			dist = 1300.0
		"west":
			yaw = -PI / 2.0
			pitch = -0.12
			dist = 1300.0
		_:
			yaw = -0.6
			pitch = -0.62
			dist = 1100.0


func goto_stage(i: int) -> void:
	i = clampi(i, 0, stages.size() - 1)
	at_d = stages[i]["start_d"]
	place_token()
	var pts: Array = stages[i]["pts"]
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	for p in pts:
		lo = lo.min(p)
		hi = hi.max(p)
	target = (lo + hi) / 2.0
	dist = clampf((hi - lo).length() * 1.3 + 140.0, 160.0, 1400.0)
	update_hud()


func _process(delta: float) -> void:
	if playing:
		at_d += speed * delta
		if at_d >= total:
			at_d = total
			playing = false
		place_token()
		update_hud()
		if follow:
			target = target.lerp(token.position, minf(delta * 3.0, 1.0))
	var mv := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		mv.z -= 1
	if Input.is_key_pressed(KEY_S):
		mv.z += 1
	if Input.is_key_pressed(KEY_A):
		mv.x -= 1
	if Input.is_key_pressed(KEY_D):
		mv.x += 1
	if Input.is_key_pressed(KEY_Q):
		mv.y -= 1
	if Input.is_key_pressed(KEY_E):
		mv.y += 1
	if mv != Vector3.ZERO:
		var fwd := Basis(Vector3.UP, yaw)
		target += (fwd * Vector3(mv.x, 0, mv.z) + Vector3(0, mv.y, 0)) * dist * 0.6 * delta
	rig.position = target
	rig.rotation = Vector3(pitch, yaw, 0)
	cam.position = Vector3(0, 0, dist)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			dist = maxf(dist * 0.9, 40.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			dist = minf(dist * 1.1, 4000.0)
		elif mb.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			_drag = mb.button_index if mb.pressed else 0
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _drag == MOUSE_BUTTON_LEFT:
			yaw -= mm.relative.x * 0.005
			pitch = clampf(pitch - mm.relative.y * 0.005, -PI / 2.0 + 0.001, 0.2)
		elif _drag == MOUSE_BUTTON_RIGHT or _drag == MOUSE_BUTTON_MIDDLE:
			var fwd := Basis(Vector3.UP, yaw)
			target -= fwd * Vector3(mm.relative.x, 0, mm.relative.y) * dist * 0.0017
	elif event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		match (event as InputEventKey).keycode:
			KEY_SPACE:
				if at_d >= total:
					at_d = 0.0
				playing = not playing
			KEY_R:
				at_d = 0.0
				place_token()
				update_hud()
			KEY_COMMA:
				goto_stage(cur_stage - 1)
			KEY_PERIOD:
				goto_stage(cur_stage + 1)
			KEY_BRACKETLEFT:
				speed = maxf(speed * 0.7, 5.0)
			KEY_BRACKETRIGHT:
				speed = minf(speed * 1.4, 600.0)
			KEY_F:
				follow = not follow
			KEY_X:
				xray = not xray
				apply_xray()
			KEY_L:
				labels.visible = not labels.visible
			KEY_G:
				grid.visible = not grid.visible
			KEY_A:
				areas_node.visible = not areas_node.visible
			KEY_H:
				hud_root.visible = not hud_root.visible
			KEY_1:
				set_view("top")
			KEY_2:
				set_view("iso")
			KEY_3:
				set_view("south")
			KEY_4:
				set_view("west")
			KEY_ESCAPE:
				get_tree().quit()
