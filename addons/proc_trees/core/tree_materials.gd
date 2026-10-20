class_name TreeMaterials
extends RefCounted
## Shader materials for tree profiles (shared by every tree with the same look) and the textures they use:
## a 2x2 leaf atlas (broad leaves, needles, palm frond, hanging moss) and tiling bark noise.
## The atlas is painted procedurally; addons/proc_trees/tools/build_assets.gd bakes it to textures/leaf_atlas.png
## (imported with mipmaps + VRAM compression). If that file is missing, a smaller copy is painted at runtime.

const SHADER_DIR := "res://addons/proc_trees/shaders/"
const ATLAS_PATH := "res://addons/proc_trees/textures/leaf_atlas.png"
## Shader globals every tree shader reads. The editor plugin adds them to Project Settings; ensure_globals()
## also registers them at runtime, so trees work in projects/exports where that never happened.
const GLOBALS := {
	"tree_wind": [RenderingServer.GLOBAL_VAR_TYPE_VEC4, "vec4", Vector4(0.77, 0.64, 0.5, 0.6)],
	"tree_view_pos": [RenderingServer.GLOBAL_VAR_TYPE_VEC3, "vec3", Vector3.ZERO],
}

enum Tile { LEAVES, NEEDLES, FROND, MOSS }

static var _materials := {}
static var _globals_ok := false
static var _atlas: Texture2D
static var _bark_noise: Texture2D
static var _bark_normal: Texture2D


## [bark material, foliage material] for a profile.
static func for_profile(p: TreeProfile) -> Array:
	var key := hash([p.style, p.archetype, p.leaf_color, p.leaf_color_2, p.moss_color, p.bark_color, p.bark_color_2,
		p.bark_moss, p.bark_normal, p.translucency, p.wind_bend, p.wind_branch, p.wind_flutter])
	if _materials.has(key):
		return _materials[key]
	ensure_globals()
	var stylized := p.style == TreeProfile.Style.STYLIZED
	var bark := ShaderMaterial.new()
	var fol := ShaderMaterial.new()
	bark.shader = load(SHADER_DIR + ("tree_bark_toon.gdshader" if stylized else "tree_bark.gdshader"))
	fol.shader = load(SHADER_DIR + ("tree_canopy_toon.gdshader" if stylized else "tree_leaves.gdshader"))
	for m: ShaderMaterial in [bark, fol]:
		m.set_shader_parameter("wind_bend", p.wind_bend)
		m.set_shader_parameter("wind_branch", p.wind_branch)
		m.set_shader_parameter("wind_flutter", p.wind_flutter)
	bark.set_shader_parameter("bark_color", p.bark_color)
	bark.set_shader_parameter("bark_color_2", p.bark_color_2)
	bark.set_shader_parameter("palm_rings", 1.0 if p.archetype == TreeProfile.Archetype.PALM else 0.0)
	fol.set_shader_parameter("leaf_color", p.leaf_color)
	fol.set_shader_parameter("leaf_color_2", p.leaf_color_2)
	fol.set_shader_parameter("moss_color", p.moss_color)
	if not stylized:
		bark.set_shader_parameter("bark_noise", bark_texture(false))
		bark.set_shader_parameter("bark_normal", bark_texture(true))
		bark.set_shader_parameter("normal_strength", p.bark_normal)
		bark.set_shader_parameter("moss", p.bark_moss)
		bark.set_shader_parameter("moss_color", p.moss_color.darkened(0.25))
		fol.set_shader_parameter("leaf_atlas", leaf_atlas())
		fol.set_shader_parameter("translucency", p.translucency)
	_materials[key] = [bark, fol]
	return _materials[key]


static func ensure_globals() -> void:
	if _globals_ok:
		return
	_globals_ok = true
	# at runtime, globals from Project Settings are already registered; the list query is editor-only
	var have: Array = Array(RenderingServer.global_shader_parameter_get_list()) if Engine.is_editor_hint() else []
	for n: StringName in GLOBALS:
		var known := have.has(n) if Engine.is_editor_hint() else ProjectSettings.has_setting("shader_globals/" + n)
		if not known:
			RenderingServer.global_shader_parameter_add(n, GLOBALS[n][0], GLOBALS[n][2])


## UV rectangle of an atlas tile, inset a little against bleeding.
static func tile_rect(tile: int) -> Rect2:
	const M := 0.004
	return Rect2((tile % 2) * 0.5 + M, (tile / 2) * 0.5 + M, 0.5 - 2.0 * M, 0.5 - 2.0 * M)


static func leaf_atlas() -> Texture2D:
	if _atlas == null:
		if ResourceLoader.exists(ATLAS_PATH):
			_atlas = load(ATLAS_PATH)
		else:
			_atlas = ImageTexture.create_from_image(paint_leaf_atlas(512))
	return _atlas


static func bark_texture(normal: bool) -> Texture2D:
	if (_bark_normal if normal else _bark_noise) == null:
		var n := FastNoiseLite.new()
		n.noise_type = FastNoiseLite.TYPE_CELLULAR
		n.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
		n.fractal_type = FastNoiseLite.FRACTAL_FBM
		n.fractal_octaves = 3
		n.frequency = 0.03
		n.seed = 11
		var t := NoiseTexture2D.new()
		t.width = 256
		t.height = 256
		t.seamless = true
		t.generate_mipmaps = true
		t.noise = n
		if normal:
			t.as_normal_map = true
			t.bump_strength = 6.0
			_bark_normal = t
		else:
			_bark_noise = t
	return _bark_normal if normal else _bark_noise


# --- leaf atlas painting -------------------------------------------------------------------------------------
# Greyscale detail + alpha; the shader tints it per profile. Each tile's bottom edge is where the card attaches.

static func paint_leaf_atlas(size := 1024) -> Image:
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.75, 0.75, 0.75, 0.0))
	var h := size / 2
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	_paint_leaves(img, Rect2i(0, 0, h, h), rng)
	_paint_needles(img, Rect2i(h, 0, h, h), rng)
	_paint_frond(img, Rect2i(0, h, h, h), rng)
	_paint_moss(img, Rect2i(h, h, h, h), rng)
	img.generate_mipmaps()
	return img


static func _paint_leaves(img: Image, tile: Rect2i, rng: RandomNumberGenerator) -> void:
	var twig := [Vector2(0.5, 1.0), Vector2(0.49, 0.7), Vector2(0.52, 0.42), Vector2(0.5, 0.2)]
	for i in 3:
		_line(img, tile, twig[i], twig[i + 1], 0.014 * (1.0 - i * 0.25), 0.45)
	var n := 11
	for i in n:
		var t := lerpf(0.1, 0.85, float(i) / (n - 1))
		var side := 1.0 if i % 2 == 0 else -1.0
		var ang := side * rng.randf_range(0.85, 1.35) * (1.0 - t * 0.4)
		_leaf(img, tile, _along(twig, t), ang, rng.randf_range(0.27, 0.34) * (1.0 - t * 0.25),
			rng.randf_range(0.12, 0.15), rng.randf_range(0.78, 1.0))
	_leaf(img, tile, twig[3], rng.randf_range(-0.15, 0.15), 0.2, 0.12, 0.95)


static func _paint_needles(img: Image, tile: Rect2i, rng: RandomNumberGenerator) -> void:
	var stems := [[Vector2(0.5, 1.0), Vector2(0.5, 0.05)]]
	for i in 4:
		var t := lerpf(0.3, 0.75, i / 3.0)
		var a := Vector2(0.5, 1.0 - t * 0.95)
		var side := 1.0 if i % 2 == 0 else -1.0
		stems.append([a, a + Vector2(side * 0.24, -0.2)])
	for s in stems:
		_line(img, tile, s[0], s[1], 0.01, 0.5)
		var slen: float = (s[1] - s[0]).length()
		var dir: Vector2 = (s[1] - s[0]) / slen
		var ang0 := atan2(dir.x, -dir.y)
		var count := int(slen / 0.012)
		for k in count:
			var p: Vector2 = s[0].lerp(s[1], (k + 0.5) / count)
			for side in [-1.0, 1.0]:
				var a: float = ang0 + side * rng.randf_range(0.6, 0.9)
				var l := rng.randf_range(0.07, 0.1) * (1.0 - 0.4 * float(k) / count)
				var tip := p + Vector2(sin(a), -cos(a)) * l
				_line(img, tile, p, tip, 0.008, rng.randf_range(0.7, 1.0))


static func _paint_frond(img: Image, tile: Rect2i, rng: RandomNumberGenerator) -> void:
	_line(img, tile, Vector2(0.5, 1.0), Vector2(0.5, 0.0), 0.016, 0.55)
	var n := 46
	for i in n:
		var y := 1.0 - (i + 0.5) / n
		for side in [-1.0, 1.0]:
			_leaf(img, tile, Vector2(0.5, y), side * (PI * 0.5 - rng.randf_range(0.15, 0.3)),
				rng.randf_range(0.42, 0.48), 0.032, rng.randf_range(0.75, 1.0), 1.0)


static func _paint_moss(img: Image, tile: Rect2i, rng: RandomNumberGenerator) -> void:
	for i in 34:
		var x := rng.randf_range(0.12, 0.88)
		var l := rng.randf_range(0.45, 0.97)
		var lum := rng.randf_range(0.6, 1.0)
		var segs := 8
		var prev := Vector2(x, 1.0)
		var ph := rng.randf() * TAU
		for k in segs:
			var t := float(k + 1) / segs
			var p := Vector2(x + sin(t * 7.0 + ph) * 0.02, 1.0 - t * l)
			_line(img, tile, prev, p, lerpf(0.02, 0.005, t), lum)
			if rng.randf() < 0.5:
				var side := 1.0 if rng.randf() < 0.5 else -1.0
				_line(img, tile, p, p + Vector2(side * 0.035, -0.06), 0.005, lum * 0.9)
			prev = p


static func _along(pts: Array, t: float) -> Vector2:
	var f := t * (pts.size() - 1)
	var i := mini(int(f), pts.size() - 2)
	return (pts[i] as Vector2).lerp(pts[i + 1], f - i)


## Filled leaf shape. base/length/width in tile units (y down); angle 0 points up.
static func _leaf(img: Image, tile: Rect2i, base: Vector2, angle: float, length: float, width: float, lum: float,
		pointy := 0.8) -> void:
	var s := float(tile.size.x)
	var b := base * s + Vector2(tile.position)
	var L := length * s
	var W := width * s * 0.5
	var dir := Vector2(sin(angle), -cos(angle))
	var nrm := Vector2(-dir.y, dir.x)
	var tip := b + dir * L
	var lo := (b.min(tip) - Vector2(W + 2.0, W + 2.0)).max(Vector2(tile.position))
	var hi := (b.max(tip) + Vector2(W + 2.0, W + 2.0)).min(Vector2(tile.end - Vector2i.ONE))
	for y in range(int(lo.y), int(hi.y) + 1):
		for x in range(int(lo.x), int(hi.x) + 1):
			var d := Vector2(x + 0.5, y + 0.5) - b
			var u := d.dot(dir) / L
			if u <= 0.0 or u >= 1.0:
				continue
			var v := d.dot(nrm)
			var hw := W * pow(sin(PI * pow(u, pointy)), 0.8)
			var edge := hw - absf(v)
			if edge <= -1.0:
				continue
			var c := lum * (0.86 + 0.14 * clampf(v / maxf(hw, 0.001), -1.0, 1.0))
			c *= 1.0 - 0.25 * clampf(1.0 - absf(v) / 1.3, 0.0, 1.0)
			c *= 0.94 + 0.06 * sin((u * L - absf(v) * 0.9) * 0.45)
			c *= lerpf(0.82, 1.0, clampf(edge / 3.0, 0.0, 1.0))
			_blend(img, x, y, c, clampf(edge + 0.5, 0.0, 1.0))


static func _line(img: Image, tile: Rect2i, a: Vector2, b: Vector2, width: float, lum: float) -> void:
	var s := float(tile.size.x)
	var pa := a * s + Vector2(tile.position)
	var pb := b * s + Vector2(tile.position)
	var r := maxf(width * s * 0.5, 0.6)
	var lo := (pa.min(pb) - Vector2(r + 2.0, r + 2.0)).max(Vector2(tile.position))
	var hi := (pa.max(pb) + Vector2(r + 2.0, r + 2.0)).min(Vector2(tile.end - Vector2i.ONE))
	var ab := pb - pa
	var l2 := maxf(ab.length_squared(), 0.0001)
	for y in range(int(lo.y), int(hi.y) + 1):
		for x in range(int(lo.x), int(hi.x) + 1):
			var p := Vector2(x + 0.5, y + 0.5)
			var t := clampf((p - pa).dot(ab) / l2, 0.0, 1.0)
			var edge := r - p.distance_to(pa + ab * t)
			if edge > -1.0:
				_blend(img, x, y, lum, clampf(edge + 0.5, 0.0, 1.0))


static func _blend(img: Image, x: int, y: int, lum: float, a: float) -> void:
	if a <= 0.0:
		return
	var old := img.get_pixel(x, y)
	var c := old.lerp(Color(lum, lum, lum), a)
	c.a = a + old.a * (1.0 - a)
	img.set_pixel(x, y, c)
