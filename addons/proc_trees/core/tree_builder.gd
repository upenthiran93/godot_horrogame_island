class_name TreeBuilder
extends RefCounted
## Grows a TreeProfile into meshes: build(profile, variant, lod) -> ArrayMesh with surface 0 = bark and
## surface 1 = foliage (if any). The skeleton (branch curves, leaf/puff/frond placements) is grown once per
## profile+variant and every LOD is emitted from it, so LODs share one silhouette. All results are cached:
## a thousand trees of the same profile/variant share one mesh per LOD.
##
## Budgets (LOD0 / LOD1 / LOD2 triangles, presets): realistic ~3-6k / 1-1.5k / 200-400,
## stylized ~1-2k / 600-900 / 150-300.

const LOD_COUNT := 3
## Per LOD: radial-segment scale, ring stride, deepest branch level drawn, thinnest branch drawn (m),
## keep 1-in-N leaf cards (survivors grow to keep coverage), puffs kept, puff icosphere detail, tier/frond detail.
const LOD := [
	{"radial": 1.0, "stride": 1, "max_level": 3, "min_r": 0.008, "keep": 1, "puffs": 1.0, "ico": 1, "detail": 1.0},
	{"radial": 0.6, "stride": 2, "max_level": 2, "min_r": 0.03, "keep": 2, "puffs": 0.6, "ico": 1, "detail": 0.6},
	{"radial": 0.4, "stride": 3, "max_level": 1, "min_r": 0.07, "keep": 5, "puffs": 0.35, "ico": 0, "detail": 0.35},
]
const BARK_TILE := 0.9  # metres of bark per texture repeat
const GOLDEN := 2.39996323

static var _meshes := {}
static var _skeletons := {}
static var _ico := {}
static var _noise: FastNoiseLite


class Branch:
	var level := 0
	var pts := PackedVector3Array()
	var radii := PackedFloat32Array()
	var flare := PackedFloat32Array()  # trunk only: root flare per point
	var lens := PackedFloat32Array()   # arc length at each point
	var length := 0.0
	var flex0 := 0.0
	var flex_rate := 0.0
	var phase := 0.0

	func finish() -> void:
		lens.resize(pts.size())
		lens[0] = 0.0
		for i in range(1, pts.size()):
			lens[i] = lens[i - 1] + pts[i].distance_to(pts[i - 1])
		length = lens[lens.size() - 1]

	## [position, direction, radius] at t (0..1 along the branch).
	func sample(t: float) -> Array:
		var target := clampf(t, 0.0, 1.0) * length
		for i in range(1, pts.size()):
			if lens[i] >= target or i == pts.size() - 1:
				var seg := lens[i] - lens[i - 1]
				var f := 0.0 if seg <= 0.0 else clampf((target - lens[i - 1]) / seg, 0.0, 1.0)
				return [pts[i - 1].lerp(pts[i], f), (pts[i] - pts[i - 1]).normalized(), lerpf(radii[i - 1], radii[i], f)]
		return [pts[0], Vector3.UP, radii[0]]

	func tangent(i: int) -> Vector3:
		return (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()

	func flex_at(t: float) -> float:
		return flex0 + t * flex_rate


class Card:
	var pos: Vector3
	var along: Vector3
	var side: Vector3
	var length := 1.0
	var width := 1.0
	var tile := 0
	var flex := 0.0
	var phase := 0.0
	var moss := false


class Skeleton:
	var height := 10.0
	var trunk_radius := 0.3
	var branches: Array = []  # Branch; [0] is the trunk
	var cards: Array = []     # Card
	var puffs: Array = []     # [centre, radius, flex, phase]
	var tiers: Array = []     # [centre, radius, height, rotation, flex, phase]
	var fronds: Array = []    # [spine PackedVector3Array, width, phase]
	var crown_center := Vector3.ZERO
	var crown_radii := Vector3.ONE

	## Outward normal of the crown ellipsoid (foliage normals bend towards it so the crown shades as one volume).
	func crown_normal(p: Vector3) -> Vector3:
		var g := (p - crown_center) / (crown_radii * crown_radii)
		return g.normalized() if g.length_squared() > 1e-8 else Vector3.UP

	## Cheap canopy self-occlusion: dark in the core and underneath, bright at the outer shell.
	func crown_ao(p: Vector3) -> float:
		var q := (p - crown_center) / crown_radii
		return clampf(0.3 + 0.7 * q.length(), 0.3, 1.0) * lerpf(0.75, 1.0, clampf(q.y * 0.5 + 0.5, 0.0, 1.0))

	## Trunk bend weight for the wind shader.
	func bend(y: float) -> float:
		return pow(clampf(y / height, 0.0, 1.3), 2.0) * height * 0.045


class Surf:
	var tangents := false
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var tan := PackedFloat32Array()
	var col := PackedColorArray()
	var uv := PackedVector2Array()
	var uv2 := PackedVector2Array()
	var idx := PackedInt32Array()

	func _init(with_tangents: bool) -> void:
		tangents = with_tangents

	func add(pos: Vector3, nrm: Vector3, t_uv: Vector2, t_uv2: Vector2, c: Color, t := Vector3.RIGHT) -> int:
		v.append(pos)
		n.append(nrm)
		uv.append(t_uv)
		uv2.append(t_uv2)
		col.append(c)
		if tangents:
			tan.append(t.x)
			tan.append(t.y)
			tan.append(t.z)
			tan.append(1.0)
		return v.size() - 1

	func tri(a: int, b: int, c: int) -> void:
		idx.append(a)
		idx.append(b)
		idx.append(c)

	func commit(mesh: ArrayMesh, mat: Material) -> void:
		if idx.is_empty():
			return
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = v
		arr[Mesh.ARRAY_NORMAL] = n
		if tangents:
			arr[Mesh.ARRAY_TANGENT] = tan
		arr[Mesh.ARRAY_COLOR] = col
		arr[Mesh.ARRAY_TEX_UV] = uv
		arr[Mesh.ARRAY_TEX_UV2] = uv2
		arr[Mesh.ARRAY_INDEX] = idx
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES)
		mesh.surface_set_material(mesh.get_surface_count() - 1, mat)


# --- public ------------------------------------------------------------------------------------------------

static func build(p: TreeProfile, variant := 0, lod := 0) -> ArrayMesh:
	lod = clampi(lod, 0, LOD_COUNT - 1)
	var key := hash([p.cache_key(), variant, lod])
	if not _meshes.has(key):
		if _meshes.size() > 512:  # editor tweaking leaves stale entries behind
			clear_cache()
		_meshes[key] = _emit(p, skeleton(p, variant), LOD[lod])
	return _meshes[key]


## Height and trunk radius of one variant (unscaled), for collision and culling.
static func info(p: TreeProfile, variant := 0) -> Dictionary:
	var sk := skeleton(p, variant)
	var r := sk.trunk_radius * (1.0 + p.root_flare * 0.35)
	return {"height": sk.height, "trunk_radius": r, "crown_radius": maxf(sk.crown_radii.x, sk.crown_radii.z),
		"collision_radius": r, "collision_height": minf(sk.height, 8.0)}


static func clear_cache() -> void:
	_meshes.clear()
	_skeletons.clear()


static func skeleton(p: TreeProfile, variant := 0) -> Skeleton:
	var key := hash([p.cache_key(), variant])
	if _skeletons.has(key):
		return _skeletons[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([p.shape_seed, variant])  # not the full key: editing colours or sizes keeps the shape
	var sk := Skeleton.new()
	sk.height = p.height * (1.0 + rng.randf_range(-p.height_jitter, p.height_jitter))
	sk.trunk_radius = p.trunk_radius * sqrt(sk.height / p.height)
	var trunk := _grow_trunk(p, sk, rng)
	sk.branches.append(trunk)
	if p.levels > 0 and p.archetype != TreeProfile.Archetype.PALM:
		_spawn_children(p, sk, rng, trunk)
	var stylized := p.style == TreeProfile.Style.STYLIZED
	match p.archetype:
		TreeProfile.Archetype.BROADLEAF:
			if stylized:
				_place_puffs(p, sk, rng)
			else:
				_place_leaves(p, sk, rng)
		TreeProfile.Archetype.CONIFER:
			if stylized:
				_place_tiers(p, sk, rng)
			else:
				_place_needles(p, sk, rng)
		TreeProfile.Archetype.PALM:
			_place_fronds(p, sk, rng)
	if p.hanging_moss > 0.0:
		_place_moss(p, sk, rng)
	_fit_crown(sk)
	_skeletons[key] = sk
	return sk


# --- skeleton ----------------------------------------------------------------------------------------------

static func _rand_dir(rng: RandomNumberGenerator) -> Vector3:
	return Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))


static func _perp(v: Vector3) -> Vector3:
	return v.cross(Vector3.UP if absf(v.y) < 0.95 else Vector3.RIGHT).normalized()


static func _branch_dir(axis: Vector3, azimuth: float, angle: float) -> Vector3:
	var u := _perp(axis)
	var w := axis.cross(u)
	return (axis * cos(angle) + (u * cos(azimuth) + w * sin(azimuth)) * sin(angle)).normalized()


static func _crown_shape(shape: int, t: float) -> float:
	match shape:
		TreeProfile.Crown.CONE:
			return 0.2 + 0.8 * (1.0 - t)
		TreeProfile.Crown.DOME:
			return 0.35 + 0.65 * sin(PI * 0.5 * (1.0 - t) + 0.3)
		TreeProfile.Crown.CYLINDER:
			return 1.0
		TreeProfile.Crown.FLAME:
			return t / 0.7 if t <= 0.7 else (1.0 - t) / 0.3
	return 0.25 + 0.75 * sin(PI * t)  # SPHERE


static func _grow_trunk(p: TreeProfile, sk: Skeleton, rng: RandomNumberGenerator) -> Branch:
	var b := Branch.new()
	var crowned := p.archetype == TreeProfile.Archetype.BROADLEAF or p.archetype == TreeProfile.Archetype.DEAD
	var length := sk.height * (p.trunk_length if crowned else 1.0)
	var segs := maxi(4, int(ceil(length * p.rings_per_meter)))
	var az := rng.randf() * TAU
	var dir := (Vector3.UP + Vector3(cos(az), 0.0, sin(az)) * p.lean).normalized()
	var pos := Vector3.ZERO
	var flare_h := 0.6 + sk.trunk_radius * 4.0
	for i in segs + 1:
		var t := float(i) / segs
		b.pts.append(pos)
		b.radii.append(sk.trunk_radius * lerpf(1.0, p.trunk_taper, pow(t, 0.85)))
		b.flare.append(p.root_flare * pow(clampf(1.0 - pos.y / flare_h, 0.0, 1.0), 2.5))
		dir += _rand_dir(rng) * p.gnarl * 0.25
		dir = dir.lerp(Vector3.UP, p.curve * 0.15)
		dir.y = maxf(dir.y, 0.25)
		dir = dir.normalized()
		pos += dir * (length / segs)
	b.phase = rng.randf()
	b.finish()
	return b


static func _grow_branch(p: TreeProfile, rng: RandomNumberGenerator, level: int, origin: Vector3, dir: Vector3,
		length: float, radius: float, flex0: float) -> Branch:
	var b := Branch.new()
	b.level = level
	var segs := clampi(int(ceil(length * p.rings_per_meter * (1.0 + 0.3 * level))), 2, 10)
	var pos := origin
	var d := dir
	for i in segs + 1:
		var t := float(i) / segs
		b.pts.append(pos)
		b.radii.append(radius * lerpf(1.0, 0.25, t))
		if i == segs:
			break
		d += _rand_dir(rng) * p.gnarl * 1.2 / segs
		d += Vector3.UP * p.branch_upturn / segs
		d += Vector3.DOWN * p.branch_droop * (0.4 + t) / segs
		d = d.normalized()
		pos += d * (length / segs)
	b.flex0 = flex0
	b.flex_rate = clampf(length * 0.12, 0.1, 0.6) + 0.1 * level
	b.phase = rng.randf()
	b.finish()
	return b


static func _spawn_children(p: TreeProfile, sk: Skeleton, rng: RandomNumberGenerator, parent: Branch) -> void:
	var L := parent.level + 1
	if L > p.levels or L > 3:
		return
	var count: int = [p.branch_count.x, p.branch_count.y, p.branch_count.z][L - 1]
	var angle_deg: float = [p.branch_angle.x, p.branch_angle.y, p.branch_angle.z][L - 1]
	var len_ratio: float = [p.branch_length.x, p.branch_length.y, p.branch_length.z][L - 1]
	if count <= 0 or len_ratio <= 0.0:
		return
	var whorls := p.archetype == TreeProfile.Archetype.CONIFER and L == 1
	var t0 := p.branch_start if L == 1 else 0.2
	var t1 := 0.97 if L == 1 else 0.95
	var n_whorls := ceili(float(count) / p.whorl_size)
	for k in count:
		var t: float
		var az: float
		if whorls:
			var w := k / p.whorl_size
			t = lerpf(t0, 0.94, clampf((w + rng.randf_range(-0.15, 0.15)) / maxf(n_whorls - 1, 1), 0.0, 1.0))
			az = TAU * (k % p.whorl_size) / p.whorl_size + w * 0.7 + rng.randf_range(-0.25, 0.25)
		else:
			t = lerpf(t0, t1, (k + rng.randf_range(0.0, 0.8)) / count)
			az = k * GOLDEN + rng.randf_range(-0.3, 0.3)
		var s := parent.sample(t)
		var tn := clampf((t - t0) / maxf(1.0 - t0, 0.01), 0.0, 1.0)
		var length: float = parent.length * len_ratio * (_crown_shape(p.crown, tn) if L == 1 else 1.0 - 0.6 * t)
		length *= rng.randf_range(0.8, 1.15)
		if length < 0.15:
			continue
		var ang := deg_to_rad(angle_deg * rng.randf_range(0.85, 1.15))
		if L == 1 and p.archetype != TreeProfile.Archetype.CONIFER:
			ang *= lerpf(1.0, 0.6, tn * tn)  # top branches reach up and close the crown
		var dir := _branch_dir(s[1], az, ang)
		if L > 1 and dir.y < -0.35:
			dir = _branch_dir(s[1], az + PI, ang)
		var prad: float = s[2]
		var radius := minf(prad * 0.85, prad * p.branch_radius * clampf(sqrt(length / maxf(parent.length, 0.01)) * 1.2, 0.3, 1.0))
		var child := _grow_branch(p, rng, L, s[0], dir, length, radius, parent.flex_at(t))
		sk.branches.append(child)
		_spawn_children(p, sk, rng, child)


static func _outward(p: Vector3) -> Vector3:
	var h := Vector3(p.x, 0.0, p.z)
	return h.normalized() if h.length_squared() > 1e-4 else Vector3.ZERO


static func _card_side(along: Vector3, rng: RandomNumberGenerator) -> Vector3:
	var s := along.cross(_rand_dir(rng))
	return s.normalized() if s.length_squared() > 1e-4 else _perp(along)


static func _place_leaves(p: TreeProfile, sk: Skeleton, rng: RandomNumberGenerator) -> void:
	var per_m := 3.6 * p.leaf_density / maxf(p.leaf_size, 0.05)
	var deepest := 0
	for b: Branch in sk.branches:
		deepest = maxi(deepest, b.level)
	for b: Branch in sk.branches:
		if b.level == 0 or b.level < deepest - 1:
			continue
		var t_from := 0.05 if b.level == deepest else 0.35
		var n := maxi(1, int(round(b.length * (1.0 - t_from) * per_m)))
		for i in n:
			var t := lerpf(t_from, 1.0, (i + rng.randf()) / n)
			var s := b.sample(t)
			var c := Card.new()
			c.pos = s[0]
			c.along = ((s[1] as Vector3) * 0.6 + _outward(s[0]) * 0.4 + _rand_dir(rng) * 0.7 + Vector3.UP * 0.1).normalized()
			c.side = _card_side(c.along, rng)
			c.length = p.leaf_size * rng.randf_range(0.8, 1.2)
			c.width = c.length
			c.tile = TreeMaterials.Tile.LEAVES
			c.flex = b.flex_at(t) + 0.15
			c.phase = rng.randf()
			sk.cards.append(c)


static func _place_needles(p: TreeProfile, sk: Skeleton, rng: RandomNumberGenerator) -> void:
	var per_m := 3.0 * p.leaf_density / maxf(p.leaf_size, 0.05)
	for b: Branch in sk.branches:
		var t_from := 0.85 if b.level == 0 else 0.1  # trunk: only the leader at the top
		var n := maxi(1, int(round(b.length * (1.0 - t_from) * per_m)))
		for i in n:
			var t := lerpf(t_from, 1.0, (i + rng.randf()) / n)
			var s := b.sample(t)
			var c := Card.new()
			c.pos = s[0]
			c.along = ((s[1] as Vector3) * 0.8 + _rand_dir(rng) * 0.3 + Vector3.DOWN * 0.1).normalized()
			var flat := c.along.cross(Vector3.UP)
			c.side = (flat.normalized() if flat.length_squared() > 1e-4 else _perp(c.along)).rotated(c.along, rng.randf_range(-1.1, 1.1))
			c.length = p.leaf_size * rng.randf_range(0.85, 1.15)
			c.width = c.length * 0.75
			c.tile = TreeMaterials.Tile.NEEDLES
			c.flex = b.flex_at(t) + 0.1
			c.phase = rng.randf()
			sk.cards.append(c)


static func _place_puffs(p: TreeProfile, sk: Skeleton, rng: RandomNumberGenerator) -> void:
	for b: Branch in sk.branches:
		if b.level == 0:
			continue
		var terminal := b.level >= p.levels
		var t := 1.0 if terminal else 0.8
		var s := b.sample(t)
		var r := p.blob_size * clampf(0.5 + b.length * 0.3, 0.6, 2.4) * rng.randf_range(0.85, 1.15)
		sk.puffs.append([s[0], r if terminal else r * 1.25, b.flex_at(t), rng.randf()])
	var trunk: Branch = sk.branches[0]
	sk.puffs.append([trunk.pts[trunk.pts.size() - 1] + Vector3.UP * p.blob_size * 0.6, p.blob_size * 1.6, 0.1, rng.randf()])


static func _place_tiers(p: TreeProfile, sk: Skeleton, rng: RandomNumberGenerator) -> void:
	var trunk: Branch = sk.branches[0]
	var n := clampi(int(round(sk.height / 2.4)), 3, 7)
	var base_r := sk.height * 0.2 * p.crown_width
	for k in n:
		var f := float(k) / (n - 1)
		var s := trunk.sample(lerpf(0.18, 0.78, f))
		sk.tiers.append([s[0], base_r * lerpf(1.0, 0.3, f) * rng.randf_range(0.92, 1.08), sk.height * lerpf(0.3, 0.24, f),
			rng.randf() * TAU, 0.2 + f * 0.6, rng.randf()])


static func _place_fronds(p: TreeProfile, sk: Skeleton, rng: RandomNumberGenerator) -> void:
	var trunk: Branch = sk.branches[0]
	var top := trunk.pts[trunk.pts.size() - 1]
	for k in p.frond_count:
		var az := k * GOLDEN + rng.randf_range(-0.2, 0.2)
		var pitch := rng.randf_range(-0.3, 0.85)
		var d := Vector3(cos(az) * cos(pitch), sin(pitch), sin(az) * cos(pitch))
		var length := p.frond_length * rng.randf_range(0.8, 1.15)
		var segs := 10
		var spine := PackedVector3Array()
		var pos := top + d * 0.1
		for i in segs + 1:
			spine.append(pos)
			d = (d + Vector3.DOWN * p.frond_droop * (0.3 + float(i) / segs * 1.4) * 2.0 / segs).normalized()
			pos += d * (length / segs)
		sk.fronds.append([spine, p.leaf_size * rng.randf_range(0.85, 1.1), rng.randf()])


static func _place_moss(p: TreeProfile, sk: Skeleton, rng: RandomNumberGenerator) -> void:
	for b: Branch in sk.branches:
		if b.level == 0 and p.archetype != TreeProfile.Archetype.DEAD:
			continue
		var n := int(round(b.length * p.hanging_moss * 3.0))
		for i in n:
			var t := rng.randf_range(0.15, 0.9)
			var s := b.sample(t)
			if absf((s[1] as Vector3).y) > 0.75:
				continue
			var c := Card.new()
			c.pos = (s[0] as Vector3) - Vector3.UP * (s[2] as float)
			c.along = (Vector3.DOWN + _rand_dir(rng) * 0.15).normalized()
			var yaw := rng.randf() * TAU
			c.side = Vector3(cos(yaw), 0.0, sin(yaw))
			c.length = rng.randf_range(0.5, 1.6) * (0.6 + p.hanging_moss * 0.6)
			c.width = rng.randf_range(0.3, 0.55)
			c.tile = TreeMaterials.Tile.MOSS
			c.moss = true
			c.flex = b.flex_at(t) + 0.3
			c.phase = rng.randf()
			sk.cards.append(c)


static func _fit_crown(sk: Skeleton) -> void:
	var pts := PackedVector3Array()
	for c: Card in sk.cards:
		if not c.moss:
			pts.append(c.pos)
	for f in sk.puffs:
		pts.append(f[0] + Vector3.ONE * f[1])
		pts.append(f[0] - Vector3.ONE * f[1])
	for t in sk.tiers:
		pts.append(t[0] + Vector3(t[1], t[2], t[1]))
		pts.append(t[0] - Vector3(t[1], 0.0, t[1]))
	for f in sk.fronds:
		pts.append_array(f[0])
	if pts.is_empty():
		for b: Branch in sk.branches:
			pts.append(b.pts[b.pts.size() - 1])
	var box := AABB(pts[0], Vector3.ZERO)
	for v in pts:
		box = box.expand(v)
	sk.crown_center = box.get_center()
	sk.crown_radii = (box.size * 0.5).max(Vector3(0.5, 0.5, 0.5))


# --- mesh emission -----------------------------------------------------------------------------------------

static func _emit(p: TreeProfile, sk: Skeleton, lod: Dictionary) -> ArrayMesh:
	var stylized := p.style == TreeProfile.Style.STYLIZED
	var bark := Surf.new(true)
	var fol := Surf.new(false)
	var radial0 := maxi(3, int(round(p.radial_segments * lod.radial)))
	for b: Branch in sk.branches:
		if b.level > lod.max_level or (b.level > 0 and b.radii[0] < lod.min_r):
			continue
		var radial := radial0 + (p.buttresses * 2 if b.level == 0 and lod.radial >= 1.0 else 0)
		if b.level > 0:
			radial = maxi(3, int(round(radial0 * pow(0.65, b.level))))
		_emit_tube(bark, sk, b, radial, lod.stride, p)
	var keep: int = lod.keep
	var grow := sqrt(float(keep)) * 0.9 if keep > 1 else 1.0
	for i in sk.cards.size():
		var c: Card = sk.cards[i]
		if i % keep != 0 and not (c.moss and keep < 5):
			continue
		if c.moss and stylized:
			_emit_tassel(fol, sk, c)
		else:
			_emit_card(fol, sk, c, 1.0 if c.moss else grow, grow)
	if not sk.puffs.is_empty():
		var puffs := sk.puffs.duplicate()
		puffs.sort_custom(func(a, b): return a[1] > b[1])
		var n: int = maxi(1, ceili(puffs.size() * lod.puffs))
		var inflate: float = 1.0 + (1.0 - lod.puffs) * 0.35
		for i in n:
			_emit_puff(fol, sk, puffs[i][0], puffs[i][1] * inflate, lod.ico, puffs[i][2], puffs[i][3])
	for t in sk.tiers:
		_emit_tier(fol, sk, t, maxi(5, int(round(12 * lod.detail))))
	for f in sk.fronds:
		_emit_frond(fol, sk, f, lod.stride, stylized)
	var mats := TreeMaterials.for_profile(p)
	var mesh := ArrayMesh.new()
	bark.commit(mesh, mats[0])
	fol.commit(mesh, mats[1])
	mesh.custom_aabb = mesh.get_aabb().grow(1.0)  # room for wind sway, so culling never clips a swaying crown
	return mesh


static func _emit_tube(S: Surf, sk: Skeleton, b: Branch, radial: int, stride: int, p: TreeProfile) -> void:
	var rows := []
	for i in range(0, b.pts.size(), stride):
		rows.append(i)
	if rows[rows.size() - 1] != b.pts.size() - 1:
		rows.append(b.pts.size() - 1)
	var u_span := maxf(1.0, roundf(TAU * b.radii[0] / BARK_TILE))
	var nrm := _perp(b.tangent(0))
	var prev_t := b.tangent(0)
	var base := S.v.size()
	var bt_phase := b.phase * TAU
	for i: int in rows:
		var t := b.tangent(i)
		var axis := prev_t.cross(t)
		if axis.length_squared() > 1e-10:
			nrm = nrm.rotated(axis.normalized(), prev_t.angle_to(t))  # parallel transport: no twisting
		nrm = (nrm - t * nrm.dot(t)).normalized()
		prev_t = t
		var bin := t.cross(nrm)
		var r := b.radii[i]
		var i0 := maxi(i - 1, 0)
		var i1 := mini(i + 1, b.pts.size() - 1)
		var slope := (b.radii[i1] - b.radii[i0]) / maxf(b.lens[i1] - b.lens[i0], 0.001)
		var pos := b.pts[i]
		var flex := b.flex_at(b.lens[i] / maxf(b.length, 0.001))
		var ao := 1.0 if b.level == 0 else clampf(0.5 + 0.5 * ((pos - sk.crown_center) / sk.crown_radii).length(), 0.5, 1.0)
		ao *= lerpf(0.6, 1.0, clampf(pos.y / 0.6, 0.0, 1.0))
		var col := Color(0.0, ao, b.phase, 1.0)
		var uv2 := Vector2(sk.bend(pos.y), flex)
		for j in radial + 1:
			var a := float(j) / radial * TAU
			var dir := nrm * cos(a) + bin * sin(a)
			var rr := r
			if b.level == 0 and b.flare[i] > 0.0:
				var lobe := 1.0
				if p.buttresses > 0:
					lobe = 0.3 + 2.2 * pow(0.5 + 0.5 * cos(a * p.buttresses + bt_phase), 8.0)
				rr *= 1.0 + b.flare[i] * lobe
			S.add(pos + dir * rr, (dir - t * slope).normalized(), Vector2(float(j) / radial * u_span, b.lens[i] / BARK_TILE),
				uv2, col, -nrm * sin(a) + bin * cos(a))
	for row in rows.size() - 1:
		for j in radial:
			var a0 := base + row * (radial + 1) + j
			var c0 := a0 + radial + 1
			S.tri(a0, c0, c0 + 1)
			S.tri(a0, c0 + 1, a0 + 1)
	# close the tip with a small cone
	var last: int = rows[rows.size() - 1]
	var tip_t := b.tangent(last)
	var tip := S.add(b.pts[last] + tip_t * b.radii[last] * 1.5, tip_t, Vector2(0.5 * u_span, b.length / BARK_TILE + 0.1),
		Vector2(sk.bend(b.pts[last].y), b.flex_at(1.0)), Color(0.0, 1.0, b.phase, 1.0))
	var ring := base + (rows.size() - 1) * (radial + 1)
	for j in radial:
		S.tri(ring + j, tip, ring + j + 1)


static func _emit_card(S: Surf, sk: Skeleton, c: Card, grow_l: float, grow_w: float) -> void:
	var base := c.pos - c.along * c.length * 0.06 * grow_l
	var tip := base + c.along * c.length * grow_l
	var hw := c.side * c.width * 0.5 * grow_w
	var cn := sk.crown_normal(c.pos)
	var face := c.along.cross(c.side).normalized()
	if face.dot(cn) < 0.0:
		face = -face
	var nrm := (face * (0.5 if c.moss else 0.35) + cn * (0.5 if c.moss else 0.65) + Vector3.UP * 0.1).normalized()
	var r := TreeMaterials.tile_rect(c.tile)
	var alpha := 0.0 if c.moss else 1.0
	var cb := Color(0.05, sk.crown_ao(base), c.phase, alpha)
	var ct := Color(1.0, sk.crown_ao(tip), c.phase, alpha)
	var u2b := Vector2(sk.bend(base.y), c.flex)
	var u2t := Vector2(sk.bend(tip.y), c.flex + (0.3 if c.moss else 0.1))
	var i0 := S.add(base - hw, nrm, Vector2(r.position.x, r.end.y), u2b, cb)
	var i1 := S.add(base + hw, nrm, Vector2(r.end.x, r.end.y), u2b, cb)
	var i2 := S.add(tip - hw, nrm, Vector2(r.position.x, r.position.y), u2t, ct)
	var i3 := S.add(tip + hw, nrm, Vector2(r.end.x, r.position.y), u2t, ct)
	S.tri(i0, i2, i3)
	S.tri(i0, i3, i1)


## Stylized hanging moss: two crossed solid wedges.
static func _emit_tassel(S: Surf, sk: Skeleton, c: Card) -> void:
	var tip := c.pos + c.along * c.length
	for side: Vector3 in [c.side, c.side.rotated(Vector3.UP, PI * 0.5)]:
		var hw := side * c.width * 0.35
		var nrm := (side.cross(c.along).normalized() * 0.5 + sk.crown_normal(c.pos) * 0.5).normalized()
		var a := S.add(c.pos - hw, nrm, Vector2.ZERO, Vector2(sk.bend(c.pos.y), c.flex), Color(0.05, 0.8, c.phase, 0.0))
		var b := S.add(c.pos + hw, nrm, Vector2.ZERO, Vector2(sk.bend(c.pos.y), c.flex), Color(0.05, 0.8, c.phase, 0.0))
		var t := S.add(tip, nrm, Vector2.ZERO, Vector2(sk.bend(tip.y), c.flex + 0.4), Color(1.0, 0.5, c.phase, 0.0))
		S.tri(a, t, b)


## Stylized canopy puff: noise-displaced icosphere with normals bent to the crown ellipsoid.
static func _emit_puff(S: Surf, sk: Skeleton, center: Vector3, r: float, sub: int, flex: float, phase: float) -> void:
	if _noise == null:
		_noise = FastNoiseLite.new()
		_noise.frequency = 1.0
	var ico := _icosphere(sub)
	var verts: PackedVector3Array = ico[0]
	var tris: PackedInt32Array = ico[1]
	var base := S.v.size()
	var ofs := Vector3(phase * 37.0, phase * 11.0, 0.0)
	for v in verts:
		var pos := center + v * r * (1.0 + 0.22 * _noise.get_noise_3dv(v * 1.7 + ofs)) * Vector3(1.0, 0.85, 1.0)
		S.add(pos, v.lerp(sk.crown_normal(pos), 0.55).normalized(), Vector2.ZERO, Vector2(sk.bend(pos.y), flex),
			Color(0.25, sk.crown_ao(pos), phase, 1.0))
	for i in range(0, tris.size(), 3):
		S.tri(base + tris[i], base + tris[i + 2], base + tris[i + 1])


## Stylized conifer tier: jagged cone skirt plus a darker underside.
static func _emit_tier(S: Surf, sk: Skeleton, tier: Array, segs: int) -> void:
	var c: Vector3 = tier[0]
	var r: float = tier[1]
	var th: float = tier[2]
	var rot: float = tier[3]
	var flex: float = tier[4]
	var ph: float = tier[5]
	var n := segs * 2
	var apex := S.add(c + Vector3.UP * th, Vector3.UP, Vector2.ZERO, Vector2(sk.bend(c.y + th), flex * 0.5), Color(0.0, 1.0, ph, 1.0))
	var under := S.add(c + Vector3.UP * th * 0.22, Vector3.DOWN, Vector2.ZERO, Vector2(sk.bend(c.y), flex * 0.5), Color(0.0, 0.2, ph, 1.0))
	var top0 := S.v.size()
	for pass_i in 2:
		for j in n:
			var a := rot + TAU * j / n
			var outer := j % 2 == 0
			var rr := r * (1.0 if outer else 0.72)
			var pos := c + Vector3(cos(a) * rr, -th * (0.12 if outer else 0.0), sin(a) * rr)
			var u2 := Vector2(sk.bend(pos.y), flex)
			if pass_i == 0:
				var cone := Vector3(cos(a) * th, r, sin(a) * th).normalized()
				S.add(pos, cone.lerp(sk.crown_normal(pos), 0.4).normalized(), Vector2.ZERO, u2,
					Color(0.3, 0.85 if outer else 0.6, ph, 1.0))
			else:
				S.add(pos, Vector3(cos(a) * 0.4, -1.0, sin(a) * 0.4).normalized(), Vector2.ZERO, u2, Color(0.3, 0.35, ph, 1.0))
	var bot0 := top0 + n
	for j in n:
		var j1 := (j + 1) % n
		S.tri(apex, top0 + j1, top0 + j)
		S.tri(under, bot0 + j, bot0 + j1)


## Palm frond: a V-folded strip along a drooping spine. Realistic = textured card strip;
## stylized = solid strip with notched (zig-zag) leaflet edges.
static func _emit_frond(S: Surf, sk: Skeleton, frond: Array, stride: int, stylized: bool) -> void:
	var spine: PackedVector3Array = frond[0]
	var width: float = frond[1]
	var ph: float = frond[2]
	var last := spine.size() - 1
	var rows := []  # [spine index (float), width scale]
	var step := stride if not stylized else maxi(1, stride)
	for i in range(0, last + 1, step):
		rows.append([float(i), 1.0])
		if stylized and i + step <= last:
			rows.append([i + step * 0.5, 0.55])
	if int(rows[rows.size() - 1][0]) != last:
		rows.append([float(last), 1.0])
	var r := TreeMaterials.tile_rect(TreeMaterials.Tile.FROND)
	var base := S.v.size()
	for row in rows:
		var fi: float = row[0]
		var i := int(fi)
		var pos := spine[i].lerp(spine[mini(i + 1, last)], fi - i)
		var t := fi / last
		var d := (spine[mini(i + 1, last)] - spine[maxi(i - 1, 0)]).normalized()
		var side := d.cross(Vector3.UP)
		side = side.normalized() if side.length_squared() > 1e-4 else Vector3.RIGHT
		var up := side.cross(d).normalized()
		var w := width * 0.5 * smoothstep(0.05, 0.3, t) * (1.0 - pow(t, 3.0) * 0.8) * (row[1] as float)
		var droop := up * w * 0.45
		var nrm := (up * 0.6 + sk.crown_normal(pos) * 0.4).normalized()
		var ao := sk.crown_ao(pos)
		var u2 := Vector2(sk.bend(pos.y), 0.3 + t)
		var v := lerpf(r.end.y, r.position.y, t)
		S.add(pos - side * w - droop, nrm, Vector2(r.position.x, v), u2, Color(t, ao, ph, 1.0))
		S.add(pos, nrm, Vector2(r.get_center().x, v), u2, Color(t * 0.3, ao, ph, 1.0))
		S.add(pos + side * w - droop, nrm, Vector2(r.end.x, v), u2, Color(t, ao, ph, 1.0))
	for k in rows.size() - 1:
		var a := base + k * 3
		var b := a + 3
		S.tri(a, b, b + 1)
		S.tri(a, b + 1, a + 1)
		S.tri(a + 1, b + 1, b + 2)
		S.tri(a + 1, b + 2, a + 2)


static func _icosphere(sub: int) -> Array:
	if _ico.has(sub):
		return _ico[sub]
	var t := (1.0 + sqrt(5.0)) / 2.0
	var verts: Array[Vector3] = [Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]
	var faces := [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4], [11, 10, 2],
		[10, 7, 6], [7, 1, 8], [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5], [2, 4, 11],
		[6, 2, 10], [8, 6, 7], [9, 8, 1]]
	for s in sub:
		var mids := {}
		var next := []
		for f in faces:
			var m := []
			for e in 3:
				var a: int = f[e]
				var b: int = f[(e + 1) % 3]
				var key := Vector2i(mini(a, b), maxi(a, b))
				if not mids.has(key):
					mids[key] = verts.size()
					verts.append((verts[a] + verts[b]) * 0.5)
				m.append(mids[key])
			next.append_array([[f[0], m[0], m[2]], [f[1], m[1], m[0]], [f[2], m[2], m[1]], [m[0], m[1], m[2]]])
		faces = next
	var pv := PackedVector3Array()
	for v in verts:
		pv.append(v.normalized())
	var pi := PackedInt32Array()
	for f in faces:
		pi.append_array(f)
	_ico[sub] = [pv, pi]
	return _ico[sub]
