extends RefCounted
## Blockout builders for the old-village areas (Ch4, PROPOSED), called from build_level.gd:
##   A08 Hollow Edge · A09 Village Lanes · A10 Festival Ring · A11 Burned Quarter
## Primitives only: stone-coloured boxes for the ruins, stick-figure "carvings", pack pieces as-is for trees.
## Story: story/chapters/ch04_the_old_village.md. All positions are world coordinates (see C.VILLAGE_*).

const C := preload("res://tools/build_common.gd")

const STONE := Color(0.42, 0.42, 0.4)
const MOSS := Color(0.3, 0.38, 0.24)
const WOOD := Color(0.42, 0.32, 0.22)
const WOOD_DARK := Color(0.26, 0.2, 0.15)
const ROTTEN := Color(0.3, 0.27, 0.2)
const METAL := Color(0.5, 0.52, 0.55)
const DARK_METAL := Color(0.22, 0.23, 0.25)
const RUST := Color(0.45, 0.25, 0.14)
const OLIVE := Color(0.3, 0.33, 0.2)
const CHARRED := Color(0.12, 0.11, 0.1)
const BASALT := Color(0.08, 0.08, 0.09)
const RED := Color(0.6, 0.1, 0.08)
const PAPER := Color(0.85, 0.82, 0.72)
const BONE := Color(0.78, 0.74, 0.62)
const CRYSTAL := Color(0.35, 0.65, 0.95)
const TARP := Color(0.2, 0.3, 0.38)
const ORANGE := Color(0.85, 0.45, 0.1)
const DUST := Color(0.5, 0.46, 0.38)

var b: C


func _init(builder: C) -> void:
	b = builder


# =============================================================================
#  Shared pieces
# =============================================================================

## A roofless stone house: wall blocks of random height, a gap for the door, rubble inside.
func ruin_house(g: Node3D, name: String, cx: float, cz: float, w: float, d: float, door_wall: String, rng: RandomNumberGenerator, hmin: float, hmax: float, color: Color) -> Node3D:
	var hg := b.group(g, name, Vector3(cx, C.G(cx, cz), cz))
	b.box(hg, "Floor", Vector3(w, 0.1, d), Vector3(0, 0.04, 0), color.darkened(0.45))
	for wall in ["N", "S", "W", "E"]:
		var along_x: bool = wall == "N" or wall == "S"
		var length := w if along_x else d
		var fixed: float = (d if wall == "S" else -d) / 2.0 if along_x else (w if wall == "E" else -w) / 2.0
		var n := maxi(int(round(length / 1.5)), 2)
		var seg := length / n
		for k in n:
			var t := -length / 2.0 + (k + 0.5) * seg
			if wall == door_wall and absf(t) < 1.0:
				continue
			if k > 0 and k < n - 1 and rng.randf() < 0.1:
				continue
			var h := rng.randf_range(hmin, hmax)
			if wall == door_wall and absf(t) < 2.7:
				h = maxf(h, 1.9)   # the doorposts still stand
			var size := Vector3(seg + 0.02, h, 0.5) if along_x else Vector3(0.5, h, seg + 0.02)
			var pos := Vector3(t, h / 2.0, fixed) if along_x else Vector3(fixed, h / 2.0, t)
			b.box(hg, "Wall%s_%02d" % [wall, k], size, pos, color.lerp(MOSS, rng.randf() * 0.25))
		if wall != door_wall:
			var csize := Vector3(length, 2.0, 0.5) if along_x else Vector3(0.5, 2.0, length)
			var cpos := Vector3(0, 1.0, fixed) if along_x else Vector3(fixed, 1.0, 0)
			b.collider(hg, "Col" + wall, csize, cpos)
	for i in 3:
		var rs := rng.randf_range(0.3, 0.7)
		b.box(hg, "Rubble_%d" % i, Vector3(rs, rs * 0.6, rs), Vector3(rng.randf_range(-w, w) * 0.35, rs * 0.3, rng.randf_range(-d, d) * 0.35), color.darkened(0.2), Vector3(rng.randf(), rng.randf() * TAU, rng.randf()))
	return hg


## A plank by a doorway with tally strokes cut in it, one per year. The last group is unfinished.
func tally_board(g: Node3D, name: String, pos: Vector3, yaw: float) -> void:
	var tb := b.group(g, name, pos, Vector3(0, yaw, 0))
	b.box(tb, "Plank", Vector3(1.5, 0.55, 0.05), Vector3.ZERO, WOOD_DARK)
	for gi in 6:
		var x := -0.6 + gi * 0.23
		var strokes := 4 if gi < 5 else 2
		for s in strokes:
			b.box(tb, "T%d_%d" % [gi, s], Vector3(0.018, 0.34, 0.02), Vector3(x + s * 0.035 - 0.05, 0, 0.04), PAPER.darkened(0.1))
		if gi < 5:
			b.box(tb, "T%d_X" % gi, Vector3(0.16, 0.018, 0.02), Vector3(x, 0, 0.05), PAPER.darkened(0.1), Vector3(0, 0, 0.5))


## A stick-figure carving (+Z is the face). pose: stand | lie | open (arms raised) | tall | coat.
func figure(g: Node3D, name: String, pos: Vector3, yaw: float, pose: String, color: Color, crystal := false, s := 1.0) -> Node3D:
	var f := b.group(g, name, pos, Vector3(0, yaw, 0))
	f.scale = Vector3.ONE * s
	match pose:
		"stand", "open":
			b.sphere(f, "Head", 0.09, Vector3(0, 0.78, 0), color)
			b.box(f, "Body", Vector3(0.1, 0.5, 0.05), Vector3(0, 0.45, 0), color)
			b.box(f, "Legs", Vector3(0.12, 0.35, 0.04), Vector3(0, 0.1, 0), color)
			if pose == "open":
				b.box(f, "ArmL", Vector3(0.04, 0.34, 0.04), Vector3(-0.15, 0.7, 0), color, Vector3(0, 0, -0.7))
				b.box(f, "ArmR", Vector3(0.04, 0.34, 0.04), Vector3(0.15, 0.7, 0), color, Vector3(0, 0, 0.7))
			else:
				b.box(f, "Arms", Vector3(0.36, 0.04, 0.04), Vector3(0, 0.58, 0), color)
		"lie":
			b.sphere(f, "Head", 0.09, Vector3(-0.5, 0.0, 0), color)
			b.box(f, "Body", Vector3(0.5, 0.1, 0.05), Vector3(-0.1, 0.0, 0), color)
			b.box(f, "Legs", Vector3(0.35, 0.12, 0.04), Vector3(0.38, 0.0, 0), color)
		"tall":
			b.sphere(f, "Head", 0.1, Vector3(0, 1.75, 0), color)
			b.box(f, "Body", Vector3(0.12, 1.2, 0.06), Vector3(0, 1.05, 0), color)
			b.box(f, "Legs", Vector3(0.14, 0.7, 0.05), Vector3(0, 0.35, 0), color)
			b.box(f, "ArmL", Vector3(0.04, 0.9, 0.04), Vector3(-0.17, 1.15, 0), color, Vector3(0, 0, -0.1))
			b.box(f, "ArmR", Vector3(0.04, 0.9, 0.04), Vector3(0.17, 1.15, 0), color, Vector3(0, 0, 0.1))
		"coat":
			b.sphere(f, "Head", 0.09, Vector3(0, 0.78, 0), color)
			b.box(f, "Coat", Vector3(0.26, 0.62, 0.06), Vector3(0, 0.38, 0), color)
			b.box(f, "Legs", Vector3(0.12, 0.2, 0.04), Vector3(0, 0.0, 0), color)
	if crystal:
		b.box(f, "Crystal", Vector3(0.07, 0.1, 0.07), Vector3(0.2, 0.55, 0.05), CRYSTAL, Vector3(0, 0.4, 0.3), {"emission": CRYSTAL, "emission_energy": 1.5})
	return f


## The lit path above: a line of lamp posts along the north rim (the service path, seen from the hollow).
func rim_lamps(g: Node3D, x0: float, x1: float) -> void:
	var lamps := b.group(g, "RimLamps")
	var n := 0
	var x := ceilf(x0 / 9.0) * 9.0
	while x <= x1:
		var dz := 40.0
		if x > C.VILLAGE_B.x:
			dz = sqrt(maxf(0.0, 1600.0 - (x - C.VILLAGE_B.x) * (x - C.VILLAGE_B.x)))
		elif x < C.VILLAGE_A.x:
			dz = sqrt(maxf(0.0, 1600.0 - (C.VILLAGE_A.x - x) * (C.VILLAGE_A.x - x)))
		var z := C.LANE_Z - dz
		var p := Vector3(x, C.G(x, z), z)
		n += 1
		b.cyl(lamps, "Post_%d" % n, 0.05, 0.07, 3.2, p + Vector3(0, 1.6, 0), DARK_METAL)
		b.box(lamps, "Head_%d" % n, Vector3(0.3, 0.18, 0.3), p + Vector3(0, 3.25, 0), Color(1.0, 0.85, 0.55), Vector3.ZERO, {"emission": Color(1.0, 0.8, 0.5), "emission_energy": 3.0})
		var l := OmniLight3D.new()
		l.name = "Lamp_%d" % n
		l.position = p + Vector3(0, 3.0, 0)
		l.light_color = Color(1.0, 0.82, 0.55)
		l.light_energy = 1.4
		l.omni_range = 11.0
		lamps.add_child(l)
		b.own(l)
		x += 9.0


## Trees on the slope beyond the rim.
func rim_trees(g: Node3D, rng: RandomNumberGenerator, x0: float, x1: float, count: int) -> void:
	var trees := b.group(g, "RimTrees")
	var n := 0
	var tries := 0
	while n < count and tries < count * 40:
		tries += 1
		var x := rng.randf_range(x0, x1)
		var z := rng.randf_range(-392.0, -286.0)
		var d := C.village_dist(x, z)
		if d < 33.0 or d > 50.0:
			continue
		if Vector2(x, z).distance_to(Vector2(C.LIFT_X, C.LIFT_Z1)) < 10.0 or Vector2(x, z).distance_to(Vector2(C.STEPS_X, -368.0)) < 8.0:
			continue   # keep the lift top and the buried steps clear
		var s := rng.randf_range(3.0, 5.0)
		if n % 5 == 4:
			b.piece(trees, "Dead_%02d" % n, "SM_Generic_TreeDead_01", C.gv(x, z, -0.2), rng.randf() * TAU, Vector3.ONE * rng.randf_range(0.9, 1.4))
		else:
			b.piece(trees, "Pine_%02d" % n, "SM_Prop_Tree_Pine_0%d" % (1 + n % 2), C.gv(x, z, -0.3), rng.randf() * TAU, Vector3(s, s * rng.randf_range(0.9, 1.2), s))
		n += 1


func floor_boulders(g: Node3D, rng: RandomNumberGenerator, x0: float, x1: float, count: int) -> void:
	var rocks := b.group(g, "Boulders")
	for i in count:
		var x := rng.randf_range(x0, x1)
		var z := C.LANE_Z + rng.randf_range(-20.0, 20.0)
		if C.village_dist(x, z) > 20.0 or absf(z - C.LANE_Z) < 4.0:
			continue
		var s := rng.randf_range(0.5, 1.4)
		b.box(rocks, "Boulder_%02d" % i, Vector3(s, s * 0.7, s * 0.9), C.gv(x, z, s * 0.25), BASALT.lerp(STONE, 0.4), Vector3(rng.randf() * 0.3, rng.randf() * TAU, rng.randf() * 0.3))


# =============================================================================
#  A08 — Hollow Edge: where the player wakes; the buried steps; the first ruins
# =============================================================================
func build_hollow_edge(g: Node3D, dyn: Node3D, mk: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 801
	var L := C.LANDING
	# drag marks from the foot of the steps to where the player lies
	var drag := b.group(g, "DragMarks")
	var from := Vector2(C.STEPS_X + 0.4, -350.0)
	for i in 14:
		var t := float(i) / 13.0
		var p := from.lerp(L, t) + Vector2(sin(t * 5.0) * 0.8, 0)
		for side in [-0.22, 0.22]:
			b.box(drag, "Mark_%02d_%s" % [i, "L" if side < 0 else "R"], Vector3(0.14, 0.03, 2.3), C.gv(p.x + side, p.y, 0.02), Color(0.07, 0.06, 0.05), Vector3(0, -0.1 * sin(t * 5.0), 0))
	# buried steps up the north wall, choked with a rockfall
	var steps := b.group(g, "BuriedSteps")
	var z := -352.0
	var si := 0
	while z >= -368.0:
		var y := C.G(C.STEPS_X, z)
		b.box(steps, "Tread_%02d" % si, Vector3(3.0, 0.3, 1.1), Vector3(C.STEPS_X, y + 0.05, z), STONE.lerp(MOSS, 0.3))
		if si % 4 == 0:
			b.box(steps, "WallL_%02d" % si, Vector3(0.3, 0.9, 4.0), Vector3(C.STEPS_X - 1.65, y + 0.45, z - 1.5), STONE.lerp(MOSS, 0.4))
			b.box(steps, "WallR_%02d" % si, Vector3(0.3, 0.9, 4.0), Vector3(C.STEPS_X + 1.65, y + 0.45, z - 1.5), STONE.lerp(MOSS, 0.4))
		z -= 1.0
		si += 1
	var fall := b.group(g, "Rockfall")
	for i in 22:
		var rz := rng.randf_range(-362.0, -355.0)
		var rx := C.STEPS_X + rng.randf_range(-2.4, 2.4)
		var s := rng.randf_range(0.7, 2.2)
		b.box(fall, "Rock_%02d" % i, Vector3(s, s * 0.8, s * 0.9), C.gv(rx, rz, s * 0.3), BASALT.lerp(STONE, rng.randf() * 0.5), Vector3(rng.randf() * 0.5, rng.randf() * TAU, rng.randf() * 0.5))
	b.box(fall, "BrokenBeam", Vector3(0.2, 0.2, 3.6), C.gv(C.STEPS_X + 0.8, -358.5, 1.6), WOOD_DARK, Vector3(0.5, 0.4, 0.2))
	# the outskirts: one badly ruined house, a well
	ruin_house(g, "Outskirts", -143.0, -347.0, 4.5, 4.0, "S", rng, 0.3, 1.3, STONE)
	var well := b.group(g, "Well", C.gv(-139.0, -329.0))
	b.cyl(well, "Ring", 0.95, 1.05, 0.9, Vector3(0, 0.45, 0), STONE.lerp(MOSS, 0.3), Vector3.ZERO, {"seg": 12})
	b.cyl(well, "Water", 0.8, 0.8, 0.02, Vector3(0, 0.8, 0), BASALT, Vector3.ZERO, {"seg": 12})
	floor_boulders(g, rng, -150.0, -120.0, 9)
	rim_lamps(g, -150.0, -92.0)
	rim_trees(g, rng, -152.0, -90.0, 36)
	b.marker(mk, "Mk_Ch04_Landing", C.gv(L.x, L.y), PI)
	b.marker(mk, "Mk_Ch04_BuriedSteps", C.gv(C.STEPS_X, -353.0))


# =============================================================================
#  A09 — Village Lanes: houses, year marks, the healing wall, the guest house
# =============================================================================
func build_village_lanes(g: Node3D, dyn: Node3D, mk: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 901
	var LZ := C.LANE_Z
	# north row faces the lane (door in the south wall); south row faces it (door in the north wall)
	var north := [[-155.0, 6.0], [-165.0, 5.0], [-180.0, 6.0]]
	var south := [[-153.0, 5.0], [-182.0, 5.0]]
	var i := 0
	for h in north:
		ruin_house(g, "HouseN%d" % (i + 1), h[0], LZ - 8.5, h[1], 5.0, "S", rng, 1.2, 2.6, STONE)
		tally_board(g, "YearMarks_N%d" % (i + 1), C.gv(h[0] + 1.9, LZ - 5.68, 1.4), 0.0)
		i += 1
	i = 0
	for h in south:
		ruin_house(g, "HouseS%d" % (i + 1), h[0], LZ + 8.5, h[1], 5.0, "N", rng, 0.8, 2.4, STONE)
		tally_board(g, "YearMarks_S%d" % (i + 1), C.gv(h[0] - 1.9, LZ + 5.68, 1.4), PI)
		i += 1
	# the guest house: bigger, taller, beds laid out for strangers
	var gh := ruin_house(g, "GuestHouse", -168.0, LZ + 9.5, 9.0, 6.0, "N", rng, 2.1, 2.8, STONE.lerp(WOOD, 0.15))
	for k in 5:
		var bed := b.group(gh, "Bed_%d" % k, Vector3(-3.6 + k * 1.8, 0.2, 2.0))
		b.box(bed, "Frame", Vector3(0.9, 0.3, 1.9), Vector3.ZERO, WOOD_DARK)
		b.box(bed, "Blanket", Vector3(0.8, 0.1, 1.3), Vector3(0, 0.2, 0.2), PAPER.darkened(0.45))
	var table := b.group(gh, "LogTable", Vector3(3.0, 0.0, -0.3))
	b.box(table, "Top", Vector3(1.4, 0.06, 0.9), Vector3(0, 0.78, 0), WOOD)
	for lx in [-0.6, 0.6]:
		for lz in [-0.35, 0.35]:
			b.box(table, "Leg_%d_%d" % [int(lx * 10), int(lz * 10)], Vector3(0.06, 0.78, 0.06), Vector3(lx, 0.39, lz), WOOD_DARK)
	for k in 3:
		b.box(table, "LogPage_%d" % k, Vector3(0.28, 0.01, 0.2), Vector3(-0.3 + k * 0.3, 0.82, 0.05 * k), PAPER, Vector3(0, 0.3 * k - 0.2, 0))
	b.cyl(table, "Lantern", 0.1, 0.12, 0.28, Vector3(0.5, 0.95, 0.15), RUST)
	b.piece(table, "Chair", "SM_Prop_Crate_01", Vector3(-0.2, 0.25, 0.9), 0.0, Vector3.ONE * 0.5)
	# the healing wall: sick figures lying down above, the same figures standing and holding stones below
	var hw := b.group(g, "HealingWall", C.gv(-173.0, LZ - 4.0))
	b.box(hw, "Wall", Vector3(6.4, 2.6, 0.5), Vector3(0, 1.3, 0), STONE.lerp(MOSS, 0.2))
	b.collider(hw, "Col", Vector3(6.4, 2.6, 0.5), Vector3(0, 1.3, 0))
	var carve := Color(0.18, 0.17, 0.16)
	for k in 5:
		var fx := -2.4 + k * 1.2
		figure(hw, "Sick_%d" % k, Vector3(fx, 1.95, 0.27), 0.0, "lie", carve, false, 0.9)
		figure(hw, "Healed_%d" % k, Vector3(fx, 0.45, 0.27), 0.0, "stand", carve, true, 0.95)
	figure(hw, "Giver", Vector3(0, 1.2, 0.27), 0.0, "tall", Color(0.3, 0.28, 0.24), false, 0.55)
	rim_lamps(g, -192.0, -146.0)
	rim_trees(g, rng, -192.0, -146.0, 30)
	floor_boulders(g, rng, -190.0, -148.0, 8)
	b.marker(mk, "Mk_Ch04_YearMarks", C.gv(-153.1, LZ - 5.68, 1.4), 0.0)
	b.marker(mk, "Mk_Ch04_HealingWall", C.gv(-173.0, LZ - 3.7, 1.2), 0.0)
	b.marker(mk, "Mk_Ch04_GuestHouse", C.gv(-168.0, LZ + 6.5), PI)
	b.marker(mk, "Mk_Ch04_LogTable", C.gv(-165.0, LZ + 9.2, 0.8))


# =============================================================================
#  A10 — Festival Ring: the stone ring, the company dig site, the generator, the lift
# =============================================================================
func build_festival_ring(g: Node3D, dyn: Node3D, mk: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1001
	var R := C.RING
	var carve := Color(0.2, 0.19, 0.17)
	# the ring
	b.cyl(g, "RingGround", 9.4, 9.6, 0.05, C.gv(R.x, R.y, 0.03), DUST, Vector3.ZERO, {"seg": 24})
	for i in 9:
		var a := i * TAU / 9.0
		var p := Vector2(R.x + cos(a) * 8.0, R.y + sin(a) * 8.0)
		var h := rng.randf_range(2.6, 3.5)
		var stone := b.group(g, "Stone_%d" % i, C.gv(p.x, p.y), Vector3(0, -a, 0))
		b.box(stone, "Block", Vector3(0.7, h, 1.1), Vector3(0, h / 2.0 - 0.1, 0), STONE.lerp(MOSS, 0.3), Vector3(0, 0, rng.randf_range(-0.05, 0.05)))
		b.collider(stone, "Col", Vector3(0.7, h, 1.1), Vector3(0, h / 2.0, 0))
		# carvings on the inward face (stone's local +x faces the centre because the group is rotated by -a)
		if i < 4:
			var f := figure(stone, "OpenHands", Vector3(-0.4, 0.8, 0), -PI / 2, "open", carve, false, 1.3)
			f.rotation = Vector3(0, -PI / 2, 0)
			f.position = Vector3(-0.38, 0.8, 0)
		elif i == 4:
			var t := figure(stone, "TheVisitor", Vector3(-0.38, 0.6, 0), -PI / 2, "tall", Color(0.3, 0.28, 0.24), false, 1.0)
			t.rotation = Vector3(0, -PI / 2, 0)
	# the three socket pedestals
	for i in 3:
		var a := PI / 2 + i * TAU / 3.0
		var p := Vector2(R.x + cos(a) * 2.4, R.y + sin(a) * 2.4)
		var ped := b.group(g, "Socket_%d" % (i + 1), C.gv(p.x, p.y))
		b.box(ped, "Pillar", Vector3(0.75, 1.0, 0.75), Vector3(0, 0.45, 0), STONE.lerp(MOSS, 0.2))
		b.box(ped, "Hole", Vector3(0.34, 0.06, 0.34), Vector3(0, 0.97, 0), Color(0.01, 0.01, 0.01))
		for k in 4:
			var ka := k * PI / 2.0 + 0.4
			b.box(ped, "Pry_%d" % k, Vector3(0.05, 0.03, 0.14), Vector3(cos(ka) * 0.3, 0.97, sin(ka) * 0.3), Color(0.6, 0.55, 0.45), Vector3(0, ka, 0))
		var stake := b.group(g, "TagStake_%d" % (i + 1), C.gv(p.x + 0.9, p.y + 0.5))
		b.cyl(stake, "Stake", 0.02, 0.025, 0.9, Vector3(0, 0.45, 0), WOOD)
		b.box(stake, "Tag", Vector3(0.28, 0.2, 0.01), Vector3(0, 0.9, 0), ORANGE)
		b.label(stake, "Text", "SOCKET %d/3\nRECOVERED" % (i + 1), Vector3(0, 0.9, 0.012), 0.0, 0.05, Color(0.1, 0.05, 0.0))
	# the dig site: trenches, spoil heaps, tape, tarps
	var dig := b.group(g, "DigSite")
	b.box(dig, "Trench_A", Vector3(10.0, 0.14, 1.5), C.gv(-201.0, -346.5, 0.06), CHARRED)
	b.box(dig, "Trench_B", Vector3(1.5, 0.14, 8.0), C.gv(-213.0, -343.0, 0.06), CHARRED)
	b.box(dig, "Spoil_A", Vector3(4.0, 0.8, 1.6), C.gv(-201.0, -348.6, 0.35), Color(0.3, 0.24, 0.17))
	b.box(dig, "Spoil_B", Vector3(1.6, 0.8, 4.0), C.gv(-215.0, -343.0, 0.35), Color(0.3, 0.24, 0.17))
	for p in [[-206.0, -349.0], [-196.0, -349.0], [-206.0, -344.0], [-196.0, -344.0]]:
		b.cyl(dig, "TapePost_%d_%d" % [int(-p[0]), int(-p[1])], 0.03, 0.03, 1.1, C.gv(p[0], p[1], 0.55), ORANGE)
	b.beam(dig, "Tape_1", C.gv(-206.0, -349.0, 1.0), C.gv(-196.0, -349.0, 1.0), 0.012, ORANGE)
	b.beam(dig, "Tape_2", C.gv(-206.0, -349.0, 1.0), C.gv(-206.0, -344.0, 1.0), 0.012, ORANGE)
	b.box(dig, "Tarp_1", Vector3(3.6, 0.08, 2.6), C.gv(-218.0, -331.0, 0.4), TARP, Vector3(0.05, 0.3, 0.04))
	b.box(dig, "Tarp_2", Vector3(2.4, 0.08, 3.0), C.gv(-192.0, -336.0, 0.35), TARP, Vector3(-0.04, -0.2, 0.03))
	for i in 3:
		b.piece(dig, "Crate_%d" % i, "SM_Prop_Crate_0%d" % (1 + i), C.gv(-190.0 + i * 0.4, -346.0 + i * 0.7, 0.5), rng.randf() * 0.5)
	# the dig tent with the table: radio, the dig log, a lamp
	var tent := b.group(g, "DigTent", C.gv(-196.0, -352.0))
	b.box(tent, "Back", Vector3(4.2, 2.0, 0.08), Vector3(0, 1.0, -1.6), TARP.lerp(PAPER, 0.3))
	b.box(tent, "SideL", Vector3(0.08, 2.0, 3.2), Vector3(-2.1, 1.0, 0), TARP.lerp(PAPER, 0.3))
	b.box(tent, "SideR", Vector3(0.08, 2.0, 3.2), Vector3(2.1, 1.0, 0), TARP.lerp(PAPER, 0.3))
	b.box(tent, "RoofL", Vector3(2.4, 0.06, 3.4), Vector3(-1.0, 2.2, 0), TARP, Vector3(0, 0, 0.3))
	b.box(tent, "RoofR", Vector3(2.4, 0.06, 3.4), Vector3(1.0, 2.2, 0), TARP, Vector3(0, 0, -0.3))
	var tbl := b.group(tent, "DigTable", Vector3(0, 0, -0.8))
	b.box(tbl, "Top", Vector3(2.2, 0.06, 0.9), Vector3(0, 0.8, 0), WOOD)
	for lx in [-1.0, 1.0]:
		b.box(tbl, "Leg_%d" % int(lx), Vector3(0.06, 0.8, 0.8), Vector3(lx, 0.4, 0), WOOD_DARK)
	b.box(tbl, "DigLog", Vector3(0.3, 0.04, 0.4), Vector3(-0.6, 0.85, 0.05), Color(0.2, 0.25, 0.3), Vector3(0, 0.2, 0))
	b.box(tbl, "LastPage", Vector3(0.28, 0.01, 0.2), Vector3(-0.3, 0.875, 0.1), PAPER, Vector3(0, -0.3, 0))
	b.box(tbl, "Lamp", Vector3(0.14, 0.2, 0.14), Vector3(0.8, 0.9, 0.0), RUST)
	b.piece(g, "FuelDrums", "SM_Prop_Barrel_01", C.gv(-199.5, -352.0, 0.47))
	# the generator (starts in the chapter)
	var gen := b.group(dyn, "Generator", C.gv(-192.0, -326.0))
	b.box(gen, "Slab", Vector3(2.0, 0.12, 1.4), Vector3(0, 0.06, 0), CHARRED)
	b.box(gen, "Body", Vector3(1.2, 0.8, 0.7), Vector3(0, 0.55, 0), OLIVE)
	b.box(gen, "Frame", Vector3(1.4, 0.06, 0.9), Vector3(0, 0.97, 0), DARK_METAL)
	b.cyl(gen, "Exhaust", 0.07, 0.07, 0.6, Vector3(0.45, 1.25, -0.2), DARK_METAL)
	b.cyl(gen, "FuelCap", 0.1, 0.1, 0.06, Vector3(-0.4, 1.0, 0.0), RED)
	b.box(gen, "PullCord", Vector3(0.04, 0.3, 0.04), Vector3(0.65, 0.6, 0.4), RED)
	var can := b.group(dyn, "FuelCan", C.gv(-198.0, -347.0))
	b.box(can, "Can", Vector3(0.4, 0.55, 0.2), Vector3(0, 0.3, 0), RED)
	b.box(can, "Spout", Vector3(0.08, 0.1, 0.08), Vector3(0.12, 0.62, 0), DARK_METAL)
	# floodlights: poles in the geometry, the lamps (off until the generator runs) in Dynamic
	var flood := b.group(dyn, "FloodLights")
	var poles := [[-190.0, -343.0, R.x, R.y], [-220.0, -343.0, R.x, R.y], [-190.0, -327.0, R.x, R.y], [-220.0, -327.0, R.x, R.y], [-208.0, -350.0, C.LIFT_X, -356.0]]
	for i in poles.size():
		var p: Array = poles[i]
		var base := C.gv(p[0], p[1])
		b.cyl(g, "FloodPole_%d" % i, 0.06, 0.09, 6.0, base + Vector3(0, 3.0, 0), DARK_METAL)
		b.box(g, "FloodHead_%d" % i, Vector3(0.6, 0.35, 0.3), base + Vector3(0, 6.1, 0), DARK_METAL)
		var sp := SpotLight3D.new()
		sp.name = "Flood_%d" % i
		flood.add_child(sp)
		b.own(sp)
		var from := base + Vector3(0, 6.0, 0)
		var to := C.gv(p[2], p[3], 0.0)
		sp.transform = Transform3D(Basis.looking_at(to - from, Vector3.UP), from)
		sp.light_color = Color(1.0, 0.95, 0.85)
		sp.light_energy = 0.0
		sp.spot_range = 36.0
		sp.spot_angle = 42.0
		sp.spot_attenuation = 0.6
	# the dig radio (blinks when the owner talks)
	var radio := b.group(dyn, "DigRadio", C.gv(-196.8, -352.9, 0.9))
	b.box(radio, "Body", Vector3(0.3, 0.2, 0.15), Vector3(0, 0.1, 0), OLIVE)
	b.box(radio, "Dial", Vector3(0.06, 0.06, 0.02), Vector3(0.08, 0.13, 0.08), RED, Vector3.ZERO, {"emission": RED, "emission_energy": 0.6})
	var rl := OmniLight3D.new()
	rl.name = "Light"
	rl.position = Vector3(0, 0.3, 0.1)
	rl.light_color = Color(1.0, 0.2, 0.15)
	rl.light_energy = 0.0
	rl.omni_range = 3.0
	radio.add_child(rl)
	b.own(rl)
	build_lift(g, dyn, mk)
	rim_lamps(g, -232.0, -186.0)
	rim_trees(g, rng, -232.0, -186.0, 30)
	b.marker(mk, "Mk_Ch04_Ring", C.gv(R.x, R.y))
	b.marker(mk, "Mk_Ch04_DigSite", C.gv(-201.0, -346.5))
	b.marker(mk, "Mk_Ch04_Generator", C.gv(-192.0, -326.0))
	b.marker(mk, "Mk_Ch04_FuelCan", C.gv(-198.0, -347.0))
	b.marker(mk, "Mk_Ch04_DigTable", C.gv(-196.0, -352.8, 0.8))


## The company cargo lift: rails up the north wall, a platform, a keypad console at the foot, the top landing.
func build_lift(g: Node3D, dyn: Node3D, mk: Node3D) -> void:
	var path := C.lift_path()
	var lift := b.group(g, "LiftTrack")
	for rx in [-1.2, 1.2]:
		for i in path.size() - 1:
			var a: Vector3 = path[i] + Vector3(rx, 0.15, 0)
			var c: Vector3 = path[i + 1] + Vector3(rx, 0.15, 0)
			b.beam(lift, "Rail_%s_%02d" % ["L" if rx < 0 else "R", i], a, c, 0.06, DARK_METAL)
	for i in range(0, path.size(), 3):
		var p: Vector3 = path[i]
		var gy := C.G(p.x, p.z)
		for rx in [-1.2, 1.2]:
			b.cyl(lift, "Post_%d_%d" % [i, int(rx * 10)], 0.07, 0.09, maxf(p.y - gy + 0.2, 0.3), Vector3(p.x + rx, (p.y + gy) / 2.0, p.z), DARK_METAL)
	# the platform (rides the track in ch04)
	var plat := b.group(dyn, "Lift", path[0] - Vector3(0, 0.8, 0))
	b.box(plat, "Deck", Vector3(2.6, 0.12, 1.9), Vector3(0, 0.0, 0), METAL)
	for k in 4:
		b.box(plat, "Slat_%d" % k, Vector3(2.5, 0.02, 0.1), Vector3(0, 0.07, -0.7 + k * 0.45), DARK_METAL)
	b.box(plat, "RailBack", Vector3(2.6, 0.06, 0.06), Vector3(0, 1.0, -0.9), METAL)
	b.box(plat, "RailL", Vector3(0.06, 0.06, 1.9), Vector3(-1.25, 1.0, 0), METAL)
	b.box(plat, "RailR", Vector3(0.06, 0.06, 1.9), Vector3(1.25, 1.0, 0), METAL)
	for px in [-1.25, 1.25]:
		for pz in [-0.9, 0.9]:
			b.cyl(plat, "Post_%d_%d" % [int(px * 10), int(pz * 10)], 0.04, 0.04, 1.0, Vector3(px, 0.5, pz), METAL)
	b.box(plat, "Gate", Vector3(2.0, 0.9, 0.04), Vector3(0, 0.55, 0.92), Color(0.9, 0.7, 0.1), Vector3.ZERO, {"alpha": 0.6})
	b.box(plat, "Panel", Vector3(0.3, 0.4, 0.15), Vector3(-1.05, 0.85, -0.6), OLIVE)
	var plight := OmniLight3D.new()
	plight.name = "LiftLamp"
	plight.position = Vector3(0, 1.8, 0)
	plight.light_color = Color(1.0, 0.8, 0.5)
	plight.light_energy = 0.8
	plight.omni_range = 5.0
	plat.add_child(plight)
	b.own(plight)
	# console at the foot: keypad + keycard reader, a red or green screen
	var cons := b.group(dyn, "LiftConsole", C.gv(-208.8, -353.4))
	b.cyl(cons, "Post", 0.08, 0.1, 1.1, Vector3(0, 0.55, 0), DARK_METAL)
	b.box(cons, "Box", Vector3(0.5, 0.55, 0.3), Vector3(0, 1.3, 0), OLIVE)
	b.box(cons, "Keypad", Vector3(0.22, 0.26, 0.02), Vector3(-0.1, 1.25, 0.16), DARK_METAL)
	b.box(cons, "CardSlot", Vector3(0.1, 0.04, 0.02), Vector3(0.12, 1.2, 0.16), BASALT)
	var sr := b.box(cons, "ScreenRed", Vector3(0.36, 0.12, 0.02), Vector3(0, 1.48, 0.16), RED, Vector3.ZERO, {"emission": RED, "emission_energy": 1.5})
	var sg := b.box(cons, "ScreenGreen", Vector3(0.36, 0.12, 0.02), Vector3(0, 1.48, 0.16), Color(0.1, 0.7, 0.2), Vector3.ZERO, {"emission": Color(0.1, 0.8, 0.2), "emission_energy": 1.5})
	sr.visible = true
	sg.visible = false
	b.label(cons, "Sign", "CARGO LIFT 2\nCODE + KEYCARD", Vector3(0, 1.62, 0.17), 0.0, 0.06, Color(0.9, 0.9, 0.8))
	# the top landing: the start of the lit path
	var top: Vector3 = path.back()
	var land := b.group(g, "TopLanding", top - Vector3(0, 0.75, 1.8))
	b.box(land, "Deck", Vector3(3.2, 0.14, 3.6), Vector3.ZERO, METAL)
	b.box(land, "Fence", Vector3(3.2, 1.0, 0.05), Vector3(0, 0.55, -1.8), METAL, Vector3.ZERO, {"alpha": 0.4, "double": true})
	b.label(land, "Sign", "SERVICE PATH ↑ UPPER STATION", Vector3(0, 1.4, -1.7), 0.0, 0.18, Color(0.9, 0.9, 0.8))
	b.marker(mk, "Mk_Ch04_Lift", path[0] - Vector3(0, 0.8, 0), PI)
	b.marker(mk, "Mk_Ch04_LiftConsole", C.gv(-208.8, -353.0, 1.2), PI)
	b.marker(mk, "Mk_Ch04_LiftTop", top)


# =============================================================================
#  A11 — Burned Quarter: the massacre, the guard's keycard, the creature, the last carving
# =============================================================================
func build_burned_quarter(g: Node3D, dyn: Node3D, mk: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1101
	var LZ := C.LANE_Z
	for h in [["B1", -224.0, LZ - 8.0, 6.0, "S"], ["B2", -231.0, LZ + 8.0, 6.0, "N"], ["B3", -233.0, LZ - 6.5, 5.0, "S"], ["B4", -221.0, LZ + 9.0, 5.0, "N"]]:
		ruin_house(g, "Burned_" + h[0], h[1], h[2], h[3], 5.0, h[4], rng, 0.4, 1.7, CHARRED.lerp(STONE, 0.15))
	for i in 8:
		var p := Vector2(rng.randf_range(-236.0, -222.0), LZ + rng.randf_range(-12.0, 12.0))
		b.cyl(g, "Scorch_%d" % i, rng.randf_range(1.5, 3.5), rng.randf_range(1.5, 3.5), 0.03, C.gv(p.x, p.y, 0.025), Color(0.04, 0.035, 0.03), Vector3.ZERO, {"seg": 12})
	# the pile of bones, one still gripping a healing crystal
	var bones := b.group(g, "BonePile", C.gv(-228.0, LZ))
	for i in 26:
		var a := rng.randf() * TAU
		var r := rng.randf() * 1.6
		var s := rng.randf_range(0.15, 0.5)
		b.box(bones, "Bone_%02d" % i, Vector3(0.06, 0.06, s), Vector3(cos(a) * r, rng.randf() * 0.35 + 0.05, sin(a) * r), BONE, Vector3(rng.randf() * 3.0, rng.randf() * TAU, rng.randf() * 3.0))
	b.sphere(bones, "Skull", 0.14, Vector3(0.4, 0.45, 0.2), BONE)
	b.box(bones, "Ribs", Vector3(0.4, 0.2, 0.3), Vector3(0.0, 0.3, -0.2), BONE.darkened(0.1), Vector3(0.2, 0.4, 0.1))
	b.box(bones, "HeldCrystal", Vector3(0.08, 0.14, 0.08), Vector3(0.1, 0.5, 0.4), CRYSTAL, Vector3(0.3, 0.3, 0.2), {"emission": CRYSTAL, "emission_energy": 2.0})
	var cl := OmniLight3D.new()
	cl.name = "CrystalGlow"
	cl.position = Vector3(0.1, 0.6, 0.4)
	cl.light_color = CRYSTAL
	cl.light_energy = 0.5
	cl.omni_range = 3.5
	bones.add_child(cl)
	b.own(cl)
	# carvings slashed with iron
	var slash := b.group(g, "SlashedStone", C.gv(-225.0, LZ - 4.6))
	b.box(slash, "Slab", Vector3(2.4, 2.3, 0.4), Vector3(0, 1.15, 0), STONE.lerp(MOSS, 0.2))
	figure(slash, "Carving", Vector3(0, 0.6, 0.22), 0.0, "open", Color(0.18, 0.17, 0.16), false, 1.4)
	for i in 6:
		b.box(slash, "Slash_%d" % i, Vector3(0.05, 1.4, 0.03), Vector3(-0.8 + i * 0.32, 1.1, 0.23), Color(0.3, 0.1, 0.07), Vector3(0, 0, 0.9 if i % 2 == 0 else -0.9))
	# the dead company guard, with the keycard, a radio and a road flare
	b.piece(g, "GuardBody", "SM_Pawn_Dead_Male_01", C.gv(-226.5, LZ + 5.4), PI * 0.4)
	var kc := b.group(dyn, "Keycard", C.gv(-226.0, LZ + 5.0))
	b.box(kc, "Card", Vector3(0.09, 0.012, 0.06), Vector3(0, 0.03, 0), Color(0.1, 0.8, 0.25), Vector3(0, 0.4, 0), {"emission": Color(0.1, 0.8, 0.25), "emission_energy": 1.2})
	b.box(g, "GuardRadio", Vector3(0.14, 0.05, 0.08), C.gv(-227.4, LZ + 5.0, 0.04), OLIVE)
	var flare := b.group(dyn, "Flare", C.gv(-227.0, LZ + 4.3))
	b.cyl(flare, "Stick", 0.025, 0.025, 0.3, Vector3(0, 0.03, 0), RED, Vector3(0, 0, PI / 2), {"emission": RED, "emission_energy": 2.0})
	var fl := OmniLight3D.new()
	fl.name = "Light"
	fl.position = Vector3(0, 0.4, 0)
	fl.light_color = Color(1.0, 0.25, 0.12)
	fl.light_energy = 0.0
	fl.omni_range = 16.0
	flare.add_child(fl)
	b.own(fl)
	# the last carving: the tall figure turned black, leading a man in a coat; the black stone rising from the sea
	var slab := b.group(g, "LastCarving", C.gv(-236.8, LZ))
	b.box(slab, "Slab", Vector3(0.6, 4.2, 8.0), Vector3(0, 2.1, 0), STONE.lerp(MOSS, 0.15))
	b.collider(slab, "Col", Vector3(0.6, 4.2, 8.0), Vector3(0, 2.1, 0))
	var face := b.group(slab, "Face", Vector3(0.33, 0, 0), Vector3(0, PI / 2, 0))
	figure(face, "God", Vector3(-1.4, 1.1, 0), 0.0, "tall", BASALT, false, 1.2)
	b.beam(face, "Cord", Vector3(-1.2, 1.4, 0.0), Vector3(0.4, 0.9, 0.0), 0.012, Color(0.25, 0.22, 0.18))
	figure(face, "Captain", Vector3(0.7, 0.9, 0), 0.0, "coat", Color(0.22, 0.2, 0.18), false, 1.3)
	b.box(face, "Sea", Vector3(5.0, 0.05, 0.03), Vector3(2.4, 2.8, 0), Color(0.15, 0.25, 0.3))
	b.box(face, "Sea2", Vector3(5.0, 0.05, 0.03), Vector3(2.4, 2.65, 0), Color(0.15, 0.25, 0.3))
	b.cyl(face, "BlackStone", 0.0, 0.55, 1.2, Vector3(2.4, 3.4, 0.02), BASALT, Vector3(PI / 2, 0, 0), {"seg": 5})
	b.marker(mk, "Mk_Ch04_BurnedQuarter", C.gv(-228.0, LZ))
	b.marker(mk, "Mk_Ch04_Bones", C.gv(-228.0, LZ, 0.6))
	b.marker(mk, "Mk_Ch04_Guard", C.gv(-226.5, LZ + 5.4, 0.3))
	b.marker(mk, "Mk_Ch04_LastCarving", C.gv(-236.4, LZ, 1.6), PI / 2)
	b.marker(mk, "Mk_Ch04_StalkerSpot", C.gv(-232.0, LZ + 3.0), PI / 2)
	rim_lamps(g, -270.0, -226.0)
	rim_trees(g, rng, -270.0, -226.0, 30)
