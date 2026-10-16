extends RefCounted
## Shared helpers for the one-off previs generators (tools/build_*.gd):
## the island's height function (ported from the Three.js prototype's src/world/terrain.js),
## node/piece helpers, and the world coordinates every level and chapter agree on.

const PACK := "res://assets/packs/synty_prototype/FBX/"
const LEVELS_DIR := "res://game/levels/"

# One scene per playable area (loaded in / out as the player moves on). All areas share
# world coordinates, so neighbouring areas line up if both are loaded.
#   bounds = terrain chunk [x0, z0, x1, z1] (overlaps its neighbours a little)
#   core   = [z_min, z_max) that "belongs" to the area (vegetation is placed once, by core)
const AREAS := {
	"A01_Beach": {"folder": "a01_beach", "title": "AREA 01 · Beach", "bounds": [-90, 44, 110, 125], "core": [50, 999]},
	"A02_Trail": {"folder": "a02_trail", "title": "AREA 02 · Trail", "bounds": [-60, 6, 60, 62], "core": [12, 50]},
	"A03_Ravine": {"folder": "a03_ravine", "title": "AREA 03 · Ravine", "bounds": [-60, -16, 60, 20], "core": [-8, 12]},
	"A04_OldHarbor": {"folder": "a04_old_harbor", "title": "AREA 04 · Old Harbor", "bounds": [-90, -100, 110, -6], "core": [-80, -8]},
	"A05_BaseCamp": {"folder": "a05_base_camp", "title": "AREA 05 · Base Camp", "bounds": [-90, -200, 110, -74], "core": [-999, -80]},
	"A06_Ropeway": {"folder": "a06_ropeway", "title": "AREA 06 · Ropeway", "bounds": [-60, -330, 70, -160], "core": [-999, -999]},
	"A07_ServicePath": {"folder": "a07_service_path", "title": "AREA 07 · Service Path", "bounds": [-60, -420, 70, -290], "core": [-999, -999]},
	# The old village (Ch4, PROPOSED): a sunken hollow west of the service path, east → west.
	"A08_HollowEdge": {"folder": "a08_hollow_edge", "title": "AREA 08 · Hollow Edge", "bounds": [-152, -385, -90, -290], "core": [-999, -999]},
	"A09_VillageLanes": {"folder": "a09_village_lanes", "title": "AREA 09 · Village Lanes", "bounds": [-192, -385, -146, -290], "core": [-999, -999]},
	"A10_FestivalRing": {"folder": "a10_festival_ring", "title": "AREA 10 · Festival Ring", "bounds": [-232, -385, -186, -290], "core": [-999, -999]},
	"A11_BurnedQuarter": {"folder": "a11_burned_quarter", "title": "AREA 11 · Burned Quarter", "bounds": [-270, -385, -226, -290], "core": [-999, -999]},
}

# ---------------------------------------------------------------- old village hollow (Ch4)
# A flat-floored bowl cut into the slope west of the service path: a capsule around the segment A–B
# (the village lane runs along it), steep walls all round, a berm on the downhill side.
const VILLAGE_A := Vector2(-215, -335)
const VILLAGE_B := Vector2(-140, -335)
const VILLAGE_HW := 22.0        # flat floor half-width
const VILLAGE_RIM := 12.0       # width of the steep wall
const VILLAGE_BLEND := 16.0     # blend back into the mountain
const VILLAGE_RIM_H := 14.0     # wall height above the floor
const LANE_Z := -335.0          # the village lane (centre line)
const RING := Vector2(-205, -335)            # the festival ring
const LANDING := Vector2(-132, -321)         # where the player wakes
const STEPS_X := -127.0                      # the buried steps climb the north wall here, z -351 → -368
const LIFT_X := -212.0                       # the company cargo lift climbs the north wall here, z -356 → -371
const LIFT_Z0 := -356.0
const LIFT_Z1 := -371.0
const CODE_REAL := "2604"
const CODE_FALSE := "7392"
static var _village_floor := NAN

# ---------------------------------------------------------------- ropeway (Ch2 → Ch3)
const STATION_ROPE_Y := 10.5     # haul rope height inside the lower station (platform top + 7 m)
const HANGER := 6.9              # rope → cabin floor
const ROPE_X_UP := 4.5           # up track (car 2)
const ROPE_X_DOWN := 7.5
# [z, pylon height]; pylon 1 belongs to A05, the rest to A06
const PYLONS := [[-175.0, 16.0], [-235.0, 18.0], [-305.0, 20.0], [-390.0, 22.0]]
const CAR_STOP_Z := -303.4       # where car 2 breaks down, beside pylon 3 (Ch3)

# The pylon crews' service path up the mountain (switchbacks, fenced, lit). Carved into the terrain.
const SERVICE_PATH := [[8, -303], [30, -309], [32, -316], [-18, -325], [-20, -332], [30, -341], [32, -348], [-10, -357]]
# The old stream on the mountain (A07). Flows downhill from the top, crosses the service path once.
const STREAM := [[10.0, -332.0], [7.0, -326.0], [5.0, -321.0], [2.0, -316.0], [-2.0, -310.0], [-6.0, -302.0]]
const STREAM_HALF := 1.6     # water half-width
const STREAM_DEPTH := 1.0    # bed sits this far below the banks

static var _path_y := []


static func pylon_top(i: int) -> float:
	return G(6, PYLONS[i][0]) + float(PYLONS[i][1]) + 0.2


## Rope height on the up track at z (straight spans station → pylon 1 → 2 → 3 → 4).
static func rope_y(z: float) -> float:
	if z >= -141.0:
		return STATION_ROPE_Y
	var z0 := -141.0
	var y0 := STATION_ROPE_Y
	for i in PYLONS.size():
		var z1: float = PYLONS[i][0]
		var y1 := pylon_top(i)
		if z >= z1:
			return lerpf(y0, y1, (z0 - z) / (z0 - z1))
		z0 = z1
		y0 = y1
	return y0


## Cabin floor position of a car on the up track at z.
static func car_at_z(z: float) -> Vector3:
	return Vector3(ROPE_X_UP, rope_y(z) - HANGER, z)


static func area_blockout(id: String) -> String:
	var f: String = AREAS[id]["folder"]
	return LEVELS_DIR + f + "/" + f + "_blockout.tscn"

# ---------------------------------------------------------------- terrain tables
const PATH := [
	[0, 95], [0, 62], [-3, 44], [2, 28], [0, 14], [0, 7], [3, 0],
	[4, -12], [8, -30], [12, -46], [14, -60], [14, -135],
]
const PROFILE := [  # [z, height]
	[120, -8], [90, -5], [72, -0.8], [66, 0.4], [56, 1.6], [46, 2.2],
	[30, 3.0], [14, 3.8],
	[10.4, 4.0], [9.4, -4],
	[3.2, -4], [2.5, 11],
	[-8, 11], [-30, 7], [-48, 3], [-56, 2.5], [-300, 2.5],
]
const WIDTH := [  # [z, corridor half-width]
	[120, 34], [66, 30], [56, 10], [50, 4.5], [30, 4.5], [16, 5.5],
	[11, 9], [2, 9], [-4, 7], [-12, 5], [-40, 6], [-48, 14], [-58, 40], [-300, 40],
]

# ---------------------------------------------------------------- world anchors
const HARBOR_FZ := -80.0          # fence / gate line
const TOWER := Vector2(26, -66)   # watchtower (x, z)
const SHED := Vector2(-17, -65)   # maintenance shed centre
const HATCH := Vector2(6, -129)   # blast-site hatch
const SCAF_T0 := 4.05             # ravine bridge deck height
const SCAF_TB := 7.0              # scaffold platform height
const SCAF_TOP := 11.0            # cliff top
const SCAF_FLOOR := -4.5


static func ss(a: float, b: float, v: float) -> float:
	var t := clampf((v - a) / (b - a), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


static func hash2(x: float, z: float) -> float:
	var s := sin(x * 127.1 + z * 311.7) * 43758.5453123
	return s - floor(s)


static func vnoise(x: float, z: float) -> float:
	var xi := floorf(x)
	var zi := floorf(z)
	var xf := x - xi
	var zf := z - zi
	var u := xf * xf * (3.0 - 2.0 * xf)
	var v := zf * zf * (3.0 - 2.0 * zf)
	var a := hash2(xi, zi)
	var b := hash2(xi + 1, zi)
	var c := hash2(xi, zi + 1)
	var d := hash2(xi + 1, zi + 1)
	return lerpf(lerpf(a, b, u), lerpf(c, d, u), v)


static func fbm(x: float, z: float, octaves: int = 4) -> float:
	var sum := 0.0
	var amp := 0.5
	var freq := 1.0
	var norm := 0.0
	for i in octaves:
		sum += amp * vnoise(x * freq, z * freq)
		norm += amp
		amp *= 0.5
		freq *= 2.03
	return sum / norm


static func interp_table(table: Array, k: float) -> float:
	if k >= table[0][0]:
		return table[0][1]
	for i in table.size() - 1:
		var k0: float = table[i][0]
		var v0: float = table[i][1]
		var k1: float = table[i + 1][0]
		var v1: float = table[i + 1][1]
		if k >= k1:
			return lerpf(v0, v1, (k0 - k) / (k0 - k1))
	return table[table.size() - 1][1]


static func seg_dist(px: float, pz: float, ax: float, az: float, bx: float, bz: float) -> float:
	var dx := bx - ax
	var dz := bz - az
	var t := clampf(((px - ax) * dx + (pz - az) * dz) / (dx * dx + dz * dz), 0.0, 1.0)
	var x := ax + dx * t - px
	var z := az + dz * t - pz
	return sqrt(x * x + z * z)


static func path_distance(x: float, z: float) -> float:
	var m := INF
	for i in PATH.size() - 1:
		m = minf(m, seg_dist(x, z, PATH[i][0], PATH[i][1], PATH[i + 1][0], PATH[i + 1][1]))
	return m


static func path_x(z: float) -> float:
	for i in PATH.size() - 1:
		var ax: float = PATH[i][0]
		var az: float = PATH[i][1]
		var bx: float = PATH[i + 1][0]
		var bz: float = PATH[i + 1][1]
		if z <= az and z >= bz:
			return lerpf(ax, bx, (az - z) / (az - bz))
	return PATH[0][0] if z > PATH[0][1] else PATH[PATH.size() - 1][0]


static func corridor_width(z: float) -> float:
	return interp_table(WIDTH, z)


## Ground height at (x, z): the prototype's island formula + the mountain + the old stream
## (carved into the banks) + the service path (flattened; bridged over the stream).
static func G(x: float, z: float) -> float:
	var h := G_raw(x, z)
	var sn := stream_near(x, z)
	var sd: float = sn[0]
	if sd < 3.2:
		h = lerpf(h, sn[2], ss(3.2, 1.6, sd))
	if z > -298.0 or z < -362.0:
		return h
	var sp := service_path_near(x, z)
	return lerpf(h, sp[1], ss(3.4, 1.7, sp[0]) * ss(1.2, 2.4, sd))


## Nearest point on the service path: [distance, path height there].
static func service_path_near(x: float, z: float) -> Array:
	if _path_y.is_empty():
		for p in SERVICE_PATH:
			_path_y.append(G_raw(p[0], p[1]))
	var best := INF
	var py := 0.0
	for i in SERVICE_PATH.size() - 1:
		var ax: float = SERVICE_PATH[i][0]
		var az: float = SERVICE_PATH[i][1]
		var bx: float = SERVICE_PATH[i + 1][0]
		var bz: float = SERVICE_PATH[i + 1][1]
		var dx := bx - ax
		var dz := bz - az
		var t := clampf(((x - ax) * dx + (z - az) * dz) / (dx * dx + dz * dz), 0.0, 1.0)
		var d := Vector2(ax + dx * t - x, az + dz * t - z).length()
		if d < best:
			best = d
			py = lerpf(_path_y[i], _path_y[i + 1], t)
	return [best, py]


## Nearest point on the old stream: [distance, centreline point (Vector2), bed height].
static func stream_near(x: float, z: float) -> Array:
	if z > -296.0 or z < -345.0 or x < -16.0 or x > 16.0:
		return [INF, Vector2.ZERO, 0.0]
	var best := INF
	var q := Vector2.ZERO
	var pt := Vector2(x, z)
	for i in STREAM.size() - 1:
		var sa := Vector2(STREAM[i][0], STREAM[i][1])
		var sc := Vector2(STREAM[i + 1][0], STREAM[i + 1][1])
		var qq := Geometry2D.get_closest_point_to_segment(pt, sa, sc)
		var d := pt.distance_to(qq)
		if d < best:
			best = d
			q = qq
	# Where the stream meets the service path, the bed drops below the path so the bridge spans water.
	var raw_bed := G_raw(q.x, q.y) - STREAM_DEPTH
	var sp := service_path_near(q.x, q.y)
	var bed := lerpf(raw_bed, minf(raw_bed, sp[1] - 0.6), ss(6.0, 3.0, sp[0]))
	return [best, q, bed]


## Where the service path crosses the stream (the bridge deck, on the path's height).
static func stream_crossing() -> Vector3:
	var a := Vector2(SERVICE_PATH[2][0], SERVICE_PATH[2][1])
	var c := Vector2(SERVICE_PATH[3][0], SERVICE_PATH[3][1])
	var best := INF
	var at := a
	for i in 401:
		var q := a.lerp(c, i / 400.0)
		var d: float = stream_near(q.x, q.y)[0]
		if d < best:
			best = d
			at = q
	return Vector3(at.x, service_path_near(at.x, at.y)[1], at.y)


static func village_dist(x: float, z: float) -> float:
	return seg_dist(x, z, VILLAGE_A.x, VILLAGE_A.y, VILLAGE_B.x, VILLAGE_B.y)


## Height of the village floor: just below the lowest point of the slope round its outline.
static func village_floor() -> float:
	if is_nan(_village_floor):
		var m := INF
		var x := -250.0
		while x <= -105.0:
			var z := -372.0
			while z <= -298.0:
				var d := village_dist(x, z)
				if d >= 26.0 and d <= 30.0:
					m = minf(m, G_base(x, z))
				z += 2.0
			x += 2.0
		_village_floor = m - 1.0
	return _village_floor


static func village_carve(x: float, z: float, h: float) -> float:
	var d := village_dist(x, z)
	if d > VILLAGE_HW + VILLAGE_RIM + VILLAGE_BLEND:
		return h
	var wall_t := ss(VILLAGE_HW, VILLAGE_HW + VILLAGE_RIM, d)
	var bowl := village_floor() + VILLAGE_RIM_H * wall_t
	bowl += (fbm(x * 0.12, z * 0.12, 2) - 0.5) * 0.3 * (1.0 - ss(VILLAGE_HW - 2.0, VILLAGE_HW + 2.0, d))
	bowl += (fbm(x * 0.25 + 40.0, z * 0.25, 3) - 0.5) * 3.5 * wall_t
	return lerpf(h, bowl, 1.0 - ss(VILLAGE_HW + VILLAGE_RIM, VILLAGE_HW + VILLAGE_RIM + VILLAGE_BLEND, d))


## The company lift's rail: a polyline up the north wall, hugging the ground.
static func lift_path() -> Array:
	var pts := []
	var z := LIFT_Z0
	while z >= LIFT_Z1 - 0.01:
		pts.append(Vector3(LIFT_X, G(LIFT_X, z) + 0.9, z))
		z -= 1.0
	return pts


static func G_raw(x: float, z: float) -> float:
	return village_carve(x, z, G_base(x, z))


static func G_base(x: float, z: float) -> float:
	var d := path_distance(x, z)
	var w := interp_table(WIDTH, z)
	var base := interp_table(PROFILE, z)
	var harbor := ss(-50, -58, z)
	var n := (fbm(x * 0.18, z * 0.18, 3) - 0.5) * lerpf(0.35, 0.05, harbor)
	var wall_t := ss(0, 7, d - w)
	var wall := wall_t * (8 + 9 * fbm(x * 0.045 + 10, z * 0.045, 4)) + wall_t * (fbm(x * 0.3, z * 0.3, 2) - 0.5) * 1.6
	var h := base + n + wall
	var sea := ss(35.5, 37, x) * ss(-47, -53, z)
	return lerpf(h, -6.0, sea) + mountain(x, z)


## The mountain north of the base camp (research center on top, reached by cable car).
static func mountain(x: float, z: float) -> float:
	var d := maxf(0.0, -150.0 - z)
	if d <= 0.0:
		return 0.0
	return (d * 0.45 + d * d * 0.0012) * (0.85 + 0.3 * fbm(x * 0.02 + 3, z * 0.02, 3))


static func gv(x: float, z: float, lift: float = 0.0) -> Vector3:
	return Vector3(x, G(x, z) + lift, z)


# ---------------------------------------------------------------- node helpers
var root: Node
var _mats := {}


func _init(scene_root: Node) -> void:
	root = scene_root


func own(n: Node) -> Node:
	n.owner = root
	return n


func group(parent: Node, name: String, pos := Vector3.ZERO, rot := Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	n.name = name
	n.position = pos
	n.rotation = rot
	parent.add_child(n)
	own(n)
	return n


func mat(color: Color, extra := {}) -> StandardMaterial3D:
	var key := str(color) + str(extra)
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = extra.get("roughness", 0.9)
	m.metallic = extra.get("metallic", 0.0)
	if extra.has("emission"):
		m.emission_enabled = true
		m.emission = extra["emission"]
		m.emission_energy_multiplier = extra.get("emission_energy", 2.0)
	if extra.get("alpha", 1.0) < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color.a = extra["alpha"]
	if extra.get("unshaded", false):
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if extra.get("double", false):
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mats[key] = m
	return m


func _mesh_node(parent: Node, name: String, mesh: Mesh, pos: Vector3, rot: Vector3, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.position = pos
	mi.rotation = rot
	if material:
		mi.material_override = material
	parent.add_child(mi)
	own(mi)
	return mi


func box(parent: Node, name: String, size: Vector3, pos: Vector3, color: Color, rot := Vector3.ZERO, extra := {}) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	return _mesh_node(parent, name, m, pos, rot, mat(color, extra))


func cyl(parent: Node, name: String, r_top: float, r_bot: float, h: float, pos: Vector3, color: Color, rot := Vector3.ZERO, extra := {}) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = r_top
	m.bottom_radius = r_bot
	m.height = h
	m.radial_segments = extra.get("seg", 10)
	m.rings = 1
	return _mesh_node(parent, name, m, pos, rot, mat(color, extra))


func sphere(parent: Node, name: String, r: float, pos: Vector3, color: Color, extra := {}) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2
	m.radial_segments = 12
	m.rings = 6
	return _mesh_node(parent, name, m, pos, Vector3.ZERO, mat(color, extra))


## A thin cylinder from a to b (cables, struts, braces).
func beam(parent: Node, name: String, a: Vector3, b2: Vector3, r: float, color: Color, extra := {}) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = r
	m.bottom_radius = r
	m.height = a.distance_to(b2)
	m.radial_segments = extra.get("seg", 6)
	m.rings = 1
	var mi := _mesh_node(parent, name, m, (a + b2) / 2, Vector3.ZERO, mat(color, extra))
	var up := (b2 - a).normalized()
	var side := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	mi.basis = Basis(side, up, side.cross(up)).orthonormalized()
	return mi


## Stencil / sign text (Label3D).
func label(parent: Node, name: String, text: String, pos: Vector3, rot_y := 0.0, size := 0.4, color := Color(0.85, 0.82, 0.7)) -> Label3D:
	var l := Label3D.new()
	l.name = name
	l.text = text
	l.position = pos
	l.rotation.y = rot_y
	l.pixel_size = size / 32.0
	l.font_size = 32
	l.modulate = color
	l.outline_size = 0
	parent.add_child(l)
	own(l)
	return l


## Static collider box (rough level collision).
func collider(parent: Node, name: String, size: Vector3, pos: Vector3, rot := Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name
	body.position = pos
	body.rotation = rot
	parent.add_child(body)
	own(body)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	own(cs)
	return body


## Instance an unmodified Synty Prototype piece (e.g. "SM_Buildings_Wall_5x3_01").
func piece(parent: Node, name: String, fbx: String, pos: Vector3, rot_y := 0.0, scale := Vector3.ONE, rot := Vector3.ZERO) -> Node3D:
	var ps := load(PACK + fbx + ".fbx") as PackedScene
	assert(ps != null, "missing pack piece " + fbx)
	var inst := ps.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node3D
	inst.name = name
	inst.position = pos
	inst.rotation = Vector3(rot.x, rot_y if rot == Vector3.ZERO else rot.y, rot.z)
	inst.scale = scale
	parent.add_child(inst)
	own(inst)
	return inst


func marker(parent: Node, name: String, pos: Vector3, yaw := 0.0) -> Marker3D:
	var m := Marker3D.new()
	m.name = name
	m.position = pos
	m.rotation.y = yaw
	parent.add_child(m)
	own(m)
	return m


## Synty wall run along X at depth z, from xa to xb (xa < xb). doors = centre x of 2 m door pieces.
## Walls are 3 m tall; the last piece of a run is stretched to fit.
func wall_x(parent: Node, name: String, z: float, xa: float, xb: float, y: float, doors := [], windows := []) -> void:
	_wall_run(parent, name, xa, xb, doors, windows, func(x0: float, w: float, kind: String, sx: float, i: int):
		# Wall pieces span local x -w..0, so place the origin at the run's right end.
		piece(parent, "%s_%02d" % [name, i], kind, Vector3(x0 + w * sx, y, z - 0.05), 0.0, Vector3(sx, 1, 1)))
	collider(parent, name + "_Col", Vector3(xb - xa, 3, 0.25), Vector3((xa + xb) / 2, y + 1.5, z))


## Synty wall run along Z at x, from za to zb (za < zb).
func wall_z(parent: Node, name: String, x: float, za: float, zb: float, y: float, doors := [], windows := []) -> void:
	_wall_run(parent, name, za, zb, doors, windows, func(z0: float, w: float, kind: String, sx: float, i: int):
		# Rotated +90° the piece spans local -x → +z, starting at its origin.
		piece(parent, "%s_%02d" % [name, i], kind, Vector3(x - 0.05, y, z0), PI / 2, Vector3(sx, 1, 1)))
	collider(parent, name + "_Col", Vector3(0.25, 3, zb - za), Vector3(x, y + 1.5, (za + zb) / 2))


func _wall_run(_parent: Node, _name: String, a: float, b: float, doors: Array, windows: Array, place: Callable) -> void:
	# Split [a, b] into door / window slots (2 m each) and plain spans.
	var slots := []
	for d in doors:
		slots.append([d - 1.0, "SM_Buildings_WallDoor_2x3_01"])
	for w in windows:
		slots.append([w - 1.0, "SM_Buildings_WallWindow_2x3_01"])
	slots.sort_custom(func(p, q): return p[0] < q[0])
	var cur := a
	var i := 0
	for s in slots + [[b, ""]]:
		var span: float = s[0] - cur
		while span > 0.05:
			var w := 5.0 if span >= 5.0 else (2.0 if span >= 2.0 else 1.0)
			var kind := "SM_Buildings_Wall_%dx3_01" % int(w)
			var sx := 1.0
			if span < w or (span - w < 1.0 and span - w > 0.05):
				# stretch this piece over the remainder so we don't leave a sliver
				sx = span / w
			place.call(cur, w, kind, sx, i)
			i += 1
			cur += w * sx
			span = s[0] - cur
		if s[1] != "":
			place.call(cur, 2.0, s[1], 1.0, i)
			i += 1
			cur += 2.0


## Tile Synty 5x5 floor pieces over a rectangle (used as flat roofs / floors).
func floor_tiles(parent: Node, name: String, x0: float, z0: float, x1: float, z1: float, y: float) -> void:
	var g := group(parent, name)
	var nx := ceili((x1 - x0) / 5.0 - 0.01)
	var nz := ceili((z1 - z0) / 5.0 - 0.01)
	var sx := (x1 - x0) / (nx * 5.0)
	var sz := (z1 - z0) / (nz * 5.0)
	for i in nx:
		for j in nz:
			piece(g, "Tile_%d_%d" % [i, j], "SM_Buildings_Floor_5x5_01",
				Vector3(x0 + (i + 1) * 5.0 * sx, y, z0 + j * 5.0 * sz), 0.0, Vector3(sx, 1, sz))


static func save_scene(scene_root: Node, path: String, force: bool) -> bool:
	if FileAccess.file_exists(path) and not force:
		print("  keep   %s (exists; pass --force to rebuild)" % path)
		return false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var ps := PackedScene.new()
	var err := ps.pack(scene_root)
	assert(err == OK, "pack failed for " + path)
	err = ResourceSaver.save(ps, path)
	assert(err == OK, "save failed for " + path)
	print("  create %s" % path)
	return true
