extends SceneTree
## One-off generator for the previs chapter scenes, ported from the prototype's cinematic
## shot list (cinematic/script.js). Each shot gets its own camera (Cam_NN_Name), a marker on the
## `play` animation, and keys for the actors, props, lights and narration.
##   res://previs/chapters/ch01_the_old_harbor/chapter01_the_old_harbor.tscn
##   res://previs/chapters/ch02_base_camp/chapter02_base_camp.tscn
##   res://previs/chapters/ch03_the_line/chapter03_the_line.tscn
##   res://previs/chapters/ch04_the_old_village/chapter04_the_old_village.tscn
## Run:  godot --headless --path . --script res://tools/build_chapters.gd [-- --only=1|2] [--force]
## Never overwrites a chapter scene unless --force — after the first build, edit the Timeline in the editor.
## After a --force rebuild, run tools/add_fp_camera.gd again to put the first-person camera back.

const C := preload("res://tools/build_common.gd")
const S := preload("res://tools/story_text.gd")
const D1 := "Level/A01_Beach/Dynamic/"
const D3 := "Level/A03_Ravine/Dynamic/"
const D4 := "Level/A04_OldHarbor/Dynamic/"
const D5 := "Level/A05_BaseCamp/Dynamic/"
const D6 := "Level/A06_Ropeway/Dynamic/"
const HERO := "Actors/Actor_Protagonist"
const BEAST := "Actors/Actor_Creature"
const POSES := {
	"Idle": "SM_Pawn_Idle_Female_01", "Walk": "SM_Pawn_Walk_Female_01", "Run": "SM_Pawn_Run_Female_01",
	"Crouch": "SM_Pawn_Cower_Female_01", "Climb": "SM_Pawn_LadderClimb_Female_01",
}

var force := false


func _init() -> void:
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a == "--force":
			force = true
		elif a.begins_with("--only="):
			only = a.get_slice("=", 1)
	if only in ["", "1"]:
		build_ch01()
	if only in ["", "2"]:
		build_ch02()
	if only in ["", "3"]:
		build_ch03()
	if only in ["", "4"]:
		build_ch04()
	quit()


# =============================================================================
#  Chapter builder
# =============================================================================
class Chap:
	var root: Node3D
	var b: C
	var anim: Animation
	var T := 0.0
	var tracks := {}
	var last_val := {}
	var method_track := -1
	var used_method_times := {}
	var shot := 0
	var last_st := {}
	var prev_card := false
	var shots := []  # [marker, start, length, name, area title]
	var area_ids := []  # areas instanced under Level (one scene per playable area)
	var rng := RandomNumberGenerator.new()

	func _init(root_name: String) -> void:
		rng.seed = 7
		root = Node3D.new()
		root.name = root_name
		root.set_script(load("res://previs/shared/previs_chapter.gd"))
		b = C.new(root)
		anim = Animation.new()
		anim.resource_name = "play"
		method_track = anim.add_track(Animation.TYPE_METHOD)
		anim.track_set_path(method_track, NodePath("."))

	# ---------------------------------------------------------------- keys
	func track(path: String, discrete := false) -> int:
		if tracks.has(path):
			return tracks[path]
		var i := anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(i, NodePath(path))
		anim.track_set_interpolation_type(i, Animation.INTERPOLATION_LINEAR)
		anim.value_track_set_update_mode(i, Animation.UPDATE_DISCRETE if discrete else Animation.UPDATE_CONTINUOUS)
		tracks[path] = i
		return i

	func key(path: String, t: float, v, discrete := false) -> void:
		anim.track_insert_key(track(path, discrete), t, v)
		last_val[path] = v

	## Key only when the value changes (discrete state tracks).
	func state(path: String, t: float, v) -> void:
		if last_val.get(path, null) == v and tracks.has(path):
			return
		key(path, t, v, true)

	func tween(path: String, t0: float, t1: float, v0, v1) -> void:
		key(path, t0, v0)
		key(path, t1, v1)

	func call_at(t: float, method: String, args: Array) -> void:
		# Godot merges keys whose times are nearly equal, so same-time calls need at least 0.01 s apart.
		var tt := snappedf(t, 0.01)
		while used_method_times.has(tt):
			tt += 0.01
		used_method_times[tt] = true
		anim.track_insert_key(method_track, tt, {"method": StringName(method), "args": args})

	func sfx(t: float, text: String, hold := 2.0) -> void:
		call_at(t, "sfx", [text, hold])

	# ---------------------------------------------------------------- text
	static func read_dur(text: String) -> float:
		return clampf(1.4 + text.length() * 0.055, 2.5, 8.0)

	static func talk(lines: Array, start: float) -> Array:
		var at := start
		var out := []
		for l in lines:
			var dur: float = l[2] if l.size() > 2 else read_dur(l[1])
			out.append({"at": at, "dur": dur, "speaker": l[0], "text": l[1]})
			at += dur + 0.35
		return out

	static func thought(text: String, at: float, dur := -1.0) -> Dictionary:
		return {"at": at, "dur": dur if dur > 0 else clampf(1.4 + text.length() * 0.05, 2.5, 6.0), "speaker": "", "text": text}

	static func end_of(list: Array) -> float:
		var m := 0.0
		for s in list:
			m = maxf(m, s["at"] + s["dur"])
		return m

	# ---------------------------------------------------------------- routes / poses
	static func route(pts: Array) -> Dictionary:
		var P := []
		for p in pts:
			P.append(Vector3(p[0], C.G(p[0], p[1]), p[1]) if p.size() == 2 else Vector3(p[0], p[1], p[2]))
		var L := [0.0]
		for i in range(1, P.size()):
			L.append(L[i - 1] + P[i].distance_to(P[i - 1]))
		var total: float = L.back() if L.back() > 0 else 1.0
		return {"P": P, "L": L, "total": total, "frac": L.map(func(x): return x / total)}

	static func route_at(r: Dictionary, k: float) -> Dictionary:
		var P: Array = r["P"]
		var L: Array = r["L"]
		var d := clampf(k, 0, 1) * float(r["total"])
		var i := 1
		while i < P.size() - 1 and L[i] < d:
			i += 1
		var seg: float = L[i] - L[i - 1]
		var q := clampf((d - L[i - 1]) / (seg if seg > 0 else 1.0), 0, 1)
		var a: Vector3 = P[i - 1]
		var bb: Vector3 = P[i]
		var climb := absf(bb.y - a.y) > Vector2(bb.x - a.x, bb.z - a.z).length() * 1.5
		return {"pos": a.lerp(bb, q), "yaw": atan2(bb.x - a.x, bb.z - a.z), "pose": "Climb" if climb else "Walk", "visible": true}

	## Walk a route between scene fractions u0..u1; stand still before and after.
	static func walk(r: Dictionary, u0 := 0.0, u1 := 1.0, mod = null) -> Callable:
		return func(u: float) -> Dictionary:
			var span := u1 - u0
			var k := clampf((u - u0) / (span if span != 0 else 1.0), 0, 1)
			var st := route_at(r, k)
			if not (u > u0 and u < u1) and st["pose"] == "Walk":
				st["pose"] = "Idle"
			if mod != null:
				mod.call(st, u, k)
			return st

	static func still(pos: Vector3, yaw: float) -> Callable:
		return func(_u: float) -> Dictionary:
			return {"pos": pos, "yaw": yaw, "pose": "Idle", "visible": true}

	static func hidden(pos: Vector3) -> Callable:
		return func(_u: float) -> Dictionary:
			return {"pos": pos, "yaw": 0.0, "pose": "Idle", "visible": false}

	static func bump(k: float, a: float, b2: float) -> float:
		return C.ss(a, a + (b2 - a) * 0.3, k) * (1.0 - C.ss(b2 - (b2 - a) * 0.3, b2, k))

	# ---------------------------------------------------------------- cameras
	static func fixed(pos: Vector3, look: Vector3) -> Callable:
		return func(_u: float, _st: Dictionary) -> Dictionary:
			return {"pos": pos, "look": look}

	static func ease3(t: float) -> float:
		return 4 * t * t * t if t < 0.5 else 1 - pow(-2 * t + 2, 3) / 2

	static func dolly(p0: Vector3, p1: Vector3, l0: Vector3, l1: Vector3) -> Callable:
		return func(u: float, _st: Dictionary) -> Dictionary:
			var e := ease3(u)
			return {"pos": p0.lerp(p1, e), "look": l0.lerp(l1, e)}

	## Behind the protagonist, looking where they're going.
	static func follow(dist: float, h: float, ahead: float) -> Callable:
		return func(_u: float, st: Dictionary) -> Dictionary:
			var p: Vector3 = st["pos"]
			var f := Vector3(sin(st["yaw"]), 0, cos(st["yaw"]))
			var pos := p - f * dist
			pos.y = p.y + h
			var look := p + f * ahead
			look.y = p.y + 1.2
			return {"pos": pos, "look": look}

	## Beside the protagonist, looking at them.
	static func side(dist: float, h: float) -> Callable:
		return func(_u: float, st: Dictionary) -> Dictionary:
			var p: Vector3 = st["pos"]
			var r := Vector3(cos(st["yaw"]), 0, -sin(st["yaw"]))
			var pos := p + r * dist
			pos.y = p.y + h
			return {"pos": pos, "look": Vector3(p.x, p.y + 1.2, p.z)}

	# ---------------------------------------------------------------- simplify sampled keys
	static func simplify(s: Array, tol: float) -> Array:
		if s.size() <= 2:
			return s
		var out := [s[0]]
		var a := 0
		var j := 2
		while j < s.size():
			var ok := true
			for i in range(a + 1, j):
				var f: float = (s[i][0] - s[a][0]) / (s[j][0] - s[a][0])
				var v: Vector3 = s[a][1].lerp(s[j][1], f)
				if v.distance_to(s[i][1]) > tol:
					ok = false
					break
			if not ok:
				out.append(s[j - 1])
				a = j - 1
			j += 1
		out.append(s.back())
		return out

	func unwrap(path: String, v: Vector3) -> Vector3:
		if last_val.has(path) and last_val[path] is Vector3:
			var p: Vector3 = last_val[path]
			v.y = p.y + wrapf(v.y - p.y, -PI, PI)
		return v

	func emit_motion(base: String, samples: Array, pos_tol: float, rot_tol: float, noisy := false) -> void:
		var ps := samples.map(func(s): return [s[0], s[1]])
		var rs := []
		for s in samples:
			var r: Vector3 = s[2]
			if not rs.is_empty():
				var p: Vector3 = rs.back()[1]
				r = Vector3(p.x + wrapf(r.x - p.x, -PI, PI), p.y + wrapf(r.y - p.y, -PI, PI), r.z)
			elif last_val.has(base + ":rotation"):
				r = unwrap(base + ":rotation", r)
			rs.append([s[0], r])
		if not noisy:
			ps = simplify(ps, pos_tol)
			rs = simplify(rs, rot_tol)
		for k in ps:
			key(base + ":position", k[0], k[1])
		for k in rs:
			key(base + ":rotation", k[0], k[1])

	# ---------------------------------------------------------------- scenes
	static func slug(s: String) -> String:
		var out := ""
		for ch in s.to_lower():
			out += ch if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") else "_"
		while out.contains("__"):
			out = out.replace("__", "_")
		return out.trim_suffix("_").trim_prefix("_")

	static func pascal(s: String) -> String:
		var out := ""
		for w in slug(s).split("_"):
			out += w.capitalize().replace(" ", "")
		return out

	func scene(name: String, o: Dictionary) -> void:
		var subs: Array = o.get("subs", [])
		var notes: Array = o.get("notes", [])
		var cues: Array = o.get("cues", [])
		var end := end_of(subs)
		for n in notes:
			end = maxf(end, n["at"] + n["dur"])
		for c in cues:
			end = maxf(end, c[0])
		var d: float = o.get("d", maxf(end + 0.8, 3.0))
		shot += 1
		var tag := "s%02d_%s" % [shot, slug(name)]
		anim.add_marker(tag, T)
		# Only the shot's area is loaded (plus any listed in "areas" for shots that look across a boundary).
		var area: String = o.get("area", "")
		var shown: Array = o.get("areas", []).duplicate()
		if not area.is_empty():
			shown.push_front(area)
		for id in area_ids:
			state("Level/%s:visible" % id, T, id in shown)
		shots.append([tag, T, d, name, C.AREAS[area]["title"] if not area.is_empty() else ""])

		# fades / cards
		if o.has("card"):
			var cd: Array = o["card"]
			call_at(T, "black", [true])
			call_at(T + 0.01, "card", [cd[0], cd[1], cd[2], d - 0.2])
		elif o.get("fade", "") == "in":
			call_at(T, "fade_in", [1.4])
		elif prev_card:
			call_at(T, "black", [false])
		prev_card = o.has("card")
		call_at(T, "hide_note", [])

		# protagonist
		var dt := 0.1
		var n := maxi(int(ceil(d / dt)), 1)
		var actor = o.get("actor", null)
		if actor != null:
			var samples := []
			for i in n + 1:
				var u := minf(i * dt, d - 0.02) / d
				var st: Dictionary = actor.call(u)
				samples.append([T + u * d, st["pos"], Vector3(0, st["yaw"], 0)])
				state(HERO + ":visible", T + u * d if i > 0 else T, st["visible"])
				for p in POSES:
					state(HERO + "/Pose_" + p + ":visible", T + u * d if i > 0 else T, st["pose"] == p)
				last_st = st
			emit_motion(HERO, samples, 0.03, 0.03)

		# creature
		var beast = o.get("creature", null)
		if beast == null:
			state(BEAST + ":visible", T, false)
		else:
			var samples := []
			for i in n + 1:
				var u := minf(i * dt, d - 0.02) / d
				var c: Dictionary = beast.call(u)
				state(BEAST + ":visible", T + u * d if i > 0 else T, c["visible"])
				if c["visible"] or i == 0:
					samples.append([T + u * d, c["pos"], Vector3(0, c["yaw"], 0)])
			if not samples.is_empty():
				emit_motion(BEAST, samples, 0.03, 0.03)

		# cameras: o.cam (whole shot) or o.cams = [[u0, u1, cam], ...]
		var cams: Array = o.get("cams", [])
		if o.has("cam"):
			cams = [[0.0, 1.0, o["cam"]]]
		var ci := 0
		for spec in cams:
			ci += 1
			var cam_name := "Cam_%02d_%s" % [shot, pascal(name)] + ("" if cams.size() == 1 else "_%s" % char(64 + ci))
			var cam := Camera3D.new()
			cam.name = cam_name
			cam.fov = 60
			cam.near = 0.05
			cam.far = 900
			root.add_child(cam)
			b.own(cam)
			var u0: float = spec[0]
			var u1: float = spec[1]
			var fn: Callable = spec[2]
			var shake: float = o.get("shake", 0.0)
			var samples := []
			var steps := maxi(int(ceil((u1 - u0) * d / dt)), 1)
			for i in steps + 1:
				var u := lerpf(u0, u1, float(i) / steps)
				if u1 == 1.0:
					u = minf(u, (d - 0.02) / d)
				var st: Dictionary = actor.call(u) if actor != null else last_st
				var c: Dictionary = fn.call(u, st)
				var pos: Vector3 = c["pos"]
				var look: Vector3 = c["look"]
				# keep cameras above the ground (same rule as the prototype cinematic)
				pos.y = maxf(pos.y, C.G(pos.x, pos.z) + 1.0)
				look.y = maxf(look.y, C.G(look.x, look.z) + 0.8)
				if shake > 0:
					pos += Vector3(rng.randf() - 0.5, rng.randf() - 0.5, rng.randf() - 0.5) * shake
				var basis := Basis.looking_at(look - pos, Vector3.UP)
				samples.append([T + u * d, pos, basis.get_euler()])
				if i == 0:
					cam.transform = Transform3D(basis, pos)
			emit_motion(cam_name, samples, 0.02, 0.004, shake > 0)
			call_at(T + u0 * d, "cut_to", [NodePath(cam_name)])

		for s in subs:
			var text: String = s["text"] if s["speaker"] == "" else "%s: %s" % [s["speaker"].to_upper(), s["text"]]
			call_at(T + s["at"], "narrate", [text, s["dur"]])
		for nt in notes:
			call_at(T + nt["at"], "show_note", [nt["title"], nt["body"], nt["dur"]])
		for c in cues:
			c[1].call(T + c[0])
		T += d

	func finish() -> void:
		anim.length = T
		var lib := AnimationLibrary.new()
		lib.add_animation("play", anim)
		var tl := AnimationPlayer.new()
		tl.name = "Timeline"
		tl.add_animation_library("", lib)
		root.add_child(tl)
		b.own(tl)
		root.move_child(tl, root.get_child_count() - 1)


# =============================================================================
#  Shared scene furniture
# =============================================================================
func base_scene(ch: Chap, fog: float, areas: Array) -> void:
	var root := ch.root
	var env := WorldEnvironment.new()
	env.name = "WorldEnvironment"
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.035, 0.045, 0.065)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.3, 0.34, 0.42)
	e.ambient_light_energy = 0.8
	e.fog_enabled = true
	e.fog_light_color = Color(0.07, 0.09, 0.12)
	e.fog_density = fog
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	root.add_child(env)
	ch.b.own(env)
	var moon := DirectionalLight3D.new()
	moon.name = "MoonLight"
	var moon_dir := Vector3(-0.35, 0.45, 0.82).normalized()
	moon.transform = Transform3D(Basis.looking_at(-moon_dir, Vector3.UP), Vector3(0, 30, 0))
	moon.light_color = Color(0.7, 0.78, 1.0)
	moon.light_energy = 0.7
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 120
	root.add_child(moon)
	ch.b.own(moon)
	var level := ch.b.group(root, "Level")
	for id in areas:
		var inst := (load(C.area_blockout(id)) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		inst.name = id
		level.add_child(inst)
		ch.b.own(inst)
	ch.area_ids = areas

	var actors := ch.b.group(root, "Actors")
	var hero := ch.b.group(actors, "Actor_Protagonist")
	for p in POSES:
		var pose := ch.b.piece(hero, "Pose_" + p, POSES[p], Vector3.ZERO)
		pose.visible = p == "Idle"
	var beast := ch.b.group(actors, "Actor_Creature")
	beast.visible = false
	var black := Color(0.02, 0.02, 0.025)
	var cap := CapsuleMesh.new()
	cap.radius = 0.18
	cap.height = 1.9
	var body := MeshInstance3D.new()
	body.name = "Body"
	body.mesh = cap
	body.position = Vector3(0, 1.3, 0)
	body.material_override = ch.b.mat(black, {"roughness": 1.0})
	beast.add_child(body)
	ch.b.own(body)
	var head := ch.b.sphere(beast, "Head", 0.15, Vector3(0, 2.4, 0.04), black, {"roughness": 1.0})
	head.scale = Vector3(0.9, 1.3, 0.95)
	ch.b.box(beast, "ArmL", Vector3(0.06, 1.35, 0.06), Vector3(-0.27, 1.45, 0.05), black, Vector3(0, 0, -0.08), {"roughness": 1.0})
	ch.b.box(beast, "ArmR", Vector3(0.06, 1.35, 0.06), Vector3(0.27, 1.45, 0.05), black, Vector3(0, 0, 0.08), {"roughness": 1.0})
	ch.b.box(beast, "LegL", Vector3(0.08, 0.9, 0.08), Vector3(-0.1, 0.45, 0), black, Vector3.ZERO, {"roughness": 1.0})
	ch.b.box(beast, "LegR", Vector3(0.08, 0.9, 0.08), Vector3(0.1, 0.45, 0), black, Vector3.ZERO, {"roughness": 1.0})


func write_meta(folder: String, num: int, root_name: String, length: float, ch: Chap) -> void:
	var meta := {
		"chapter": num,
		"folder": folder,
		"root_node": root_name,
		"length_sec": snappedf(length, 0.1),
		"story_doc": "res://story/chapters/%s.md" % folder,
		"levels": ch.area_ids.map(func(id): return C.area_blockout(id)),
		"status": "draft",
		"notes": "Generated by tools/build_chapters.gd. Each shot loads only its own area (Level/<area>:visible).",
		"shots": ch.shots.map(func(s): return {"marker": s[0], "start": snappedf(s[1], 0.1), "length": snappedf(s[2], 0.1), "name": s[3], "area": s[4]}),
	}
	var f := FileAccess.open("res://previs/chapters/%s/chapter_meta.json" % folder, FileAccess.WRITE)
	f.store_string(JSON.stringify(meta, "  ", false))
	f.close()


func save(ch: Chap, folder: String, num: int) -> void:
	var path := "res://previs/chapters/%s/chapter%02d_%s.tscn" % [folder, num, folder.substr(5)]
	if C.save_scene(ch.root, path, force):
		write_meta(folder, num, ch.root.name, ch.T, ch)
		print("  %s: %.1f s, %d shots" % [folder, ch.T, ch.shots.size()])
	ch.root.free()


# =============================================================================
#  CHAPTER 1 — THE OLD HARBOR
# =============================================================================
func build_ch01() -> void:
	var ch := Chap.new("Chapter01_TheOldHarbor")
	base_scene(ch, 0.012, ["A01_Beach", "A02_Trail", "A03_Ravine", "A04_OldHarbor", "A05_BaseCamp"])
	var G := func(x: float, z: float) -> float: return C.G(x, z)

	# the captain's boat (chapter prop; the captain is a static pawn)
	var props := ch.b.group(ch.root, "Props")
	var boat := ch.b.group(props, "Boat", Vector3(0, 0.1, 78))
	var hull := Color(0.32, 0.36, 0.38)
	ch.b.box(boat, "Hull", Vector3(2.2, 0.9, 5), Vector3(0, 0, 0.3), hull)
	ch.b.box(boat, "Bow", Vector3(1.56, 0.9, 1.56), Vector3(0, 0, -2.2), hull, Vector3(0, PI / 4, 0))
	ch.b.box(boat, "Trim", Vector3(2.3, 0.12, 5.1), Vector3(0, 0.5, 0.3), Color(0.55, 0.5, 0.4))
	ch.b.box(boat, "Cabin", Vector3(1.6, 1.3, 1.7), Vector3(0, 1.0, 1.5), Color(0.25, 0.2, 0.15))
	ch.b.box(boat, "CabinRoof", Vector3(1.8, 0.1, 1.9), Vector3(0, 1.7, 1.5), Color(0.55, 0.5, 0.4))
	var lamp := OmniLight3D.new()
	lamp.name = "Lamp"
	lamp.position = Vector3(0.75, 1.5, 0.3)
	lamp.light_color = Color(1.0, 0.75, 0.45)
	lamp.light_energy = 1.5
	lamp.omni_range = 7
	boat.add_child(lamp)
	ch.b.own(lamp)
	ch.b.piece(boat, "Captain", "SM_Pawn_Idle_Male_01", Vector3(-0.45, 0.45, -0.3), PI)

	var A_tree := Vector3(C.path_x(36), C.G(C.path_x(36), 36), 36)
	var wx := C.path_x(25)
	var A_wall := Vector3(wx, C.G(wx, 25) + 1.15, 25)
	var sx := C.path_x(15) + 3.4
	var shrine := Vector3(sx, C.G(sx, 15), 15)
	var TX := C.TOWER.x
	var TZ := C.TOWER.y
	var G0 := C.G(TX, TZ)
	var MID := G0 + 5.5
	var TOP := G0 + 10.5
	var stalker_spot := C.gv(TX - 14.5, TZ)
	var body := Vector3(TX + 1.1, TOP + 0.6, TZ + 0.7)

	# initial states of everything the Timeline moves (so restarts / seeks are clean)
	ch.key("Props/Boat:position", 0.0, Vector3(0, 0.1, 78))
	ch.key("Props/Boat:rotation", 0.0, Vector3.ZERO)
	ch.key(D3 + "Scaffold:rotation", 0.0, Vector3.ZERO)
	ch.key(D3 + "Scaffold:position", 0.0, Vector3(2.5, C.SCAF_FLOOR, 6.5))
	ch.key(D4 + "ShedDoor:rotation", 0.0, Vector3(0, -1.9, 0))
	ch.state(D4 + "BoltCutters:visible", 0.0, true)
	ch.state(D4 + "Searchlight/Light:light_energy", 0.0, 0.0)
	ch.state(D4 + "Searchlight/Beam:visible", 0.0, false)
	ch.state(D4 + "GateChain:visible", 0.0, true)
	ch.key(D4 + "GateLeft:rotation", 0.0, Vector3.ZERO)
	ch.key(D4 + "GateRight:rotation", 0.0, Vector3.ZERO)
	ch.key(D1 + "ShiftingRock:position", 0.0, Vector3(22, -12.5, 114))
	ch.key("WorldEnvironment:environment:fog_density", 0.0, 0.012)

	ch.scene("Title", {"d": 6.0, "card": ["", "TIDEWATER", "previs playblast · story pass"]})
	ch.scene("Chapter 1", {"d": 4.0, "card": ["Chapter 1", "The Old Harbor", ""]})

	var captain := Chap.talk(S.CAPTAIN_INTRO, 1.2)
	var leave_at := Chap.end_of(captain) + 0.5
	ch.scene("The crossing", {
		"area": "A01_Beach",
		"fade": "in", "d": Chap.end_of(captain) + 3.5,
		"actor": Chap.hidden(Vector3(0, 0, 66)),
		"cam": Chap.dolly(Vector3(-26, 9, 100), Vector3(-7, 5, 84), Vector3(0, 3, 74), Vector3(0, 2.5, 66)),
		"subs": captain,
		"cues": [[leave_at, func(t: float):
			ch.sfx(t, "Boat engine revs; the boat pulls away", 3.0)
			# same motion as the prototype: accelerate to 7 m/s while turning back out to sea
			var pos := Vector3(0, 0.1, 78)
			var rot_y := 0.0
			var speed := 0.0
			var step := 0.05
			var k := 0
			while k * step < 30.0:
				speed = minf(7.0, speed + step * 0.8)
				if rot_y < PI:
					rot_y = minf(PI, rot_y + step * 0.4)
				pos.x += -sin(rot_y) * speed * step
				pos.z += -cos(rot_y) * speed * step
				if k % 10 == 0:
					ch.key("Props/Boat:position", t + k * step, pos)
					ch.key("Props/Boat:rotation", t + k * step, Vector3(0, rot_y, 0))
				k += 1
			ch.state("Props/Boat:visible", t + 30.0, false)]],
	})
	ch.scene("The boat leaves", {
		"area": "A01_Beach",
		"d": 9.0,
		"actor": Chap.still(Vector3(0, G.call(0, 66), 66), PI),
		"cam": Chap.fixed(Vector3(-2.5, 4.4, 58), Vector3(0, 3.2, 84)),
		"subs": Chap.talk(S.AFTER_BOAT, 1.2),
	})
	ch.scene("Ashore", {
		"area": "A01_Beach", "areas": ["A02_Trail"],
		"d": 7.0, "fade": "in",
		"actor": Chap.walk(Chap.route([[0, 66], [0, 58], [-1, 50]])),
		"cam": Chap.follow(3.4, 1.6, 2.5),
	})
	var tree := Chap.route([[-1, 50], [A_tree.x, A_tree.z], [1.5, 26]])
	var tf: float = tree["frac"][1]
	ch.scene("The fallen tree", {
		"area": "A02_Trail",
		"d": 12.0,
		"actor": Chap.walk(tree, 0.0, 1.0, func(st: Dictionary, _u: float, k: float):
			if Chap.bump(k, tf - 0.07, tf + 0.07) > 0.4:
				st["pose"] = "Crouch"),
		"cam": Chap.side(3.2, 1.4),
		"subs": [Chap.thought(S.T1["fallenTree"], 1.0)],
	})
	var wall := Chap.route([[A_wall.x, A_wall.z + 6], [A_wall.x, A_wall.z - 6], [A_wall.x + 0.6, A_wall.z - 10]])
	var wf: float = wall["frac"][1]
	ch.scene("The ruined wall", {
		"area": "A02_Trail",
		"d": 10.0,
		"actor": Chap.walk(wall, 0.0, 1.0, func(st: Dictionary, _u: float, k: float):
			var bmp := Chap.bump(k, wf - 0.12, wf + 0.1)
			var p: Vector3 = st["pos"]
			p.y += bmp * (A_wall.y - p.y + 0.05)
			st["pos"] = p
			if bmp > 0.3:
				st["pose"] = "Climb"),
		"cam": Chap.side(3.0, 1.4),
		"subs": [Chap.thought(S.T1["wall"], 1.2)],
	})
	ch.scene("The shrine", {
		"area": "A02_Trail",
		"d": 16.0,
		"actor": Chap.walk(Chap.route([[A_wall.x, A_wall.z - 10], [shrine.x + 2.4, shrine.z + 0.8]]), 0.0, 0.35),
		"cam": Chap.fixed(Vector3(shrine.x - 2.8, shrine.y + 1.9, shrine.z - 3.4), Vector3(shrine.x, shrine.y + 1.2, shrine.z)),
		"subs": [Chap.thought(S.T1["shrine"], 5.3)],
		"notes": [{"at": 9.3, "dur": 6.0, "title": S.NOTES1["shrine"][0], "body": S.NOTES1["shrine"][1]}],
		"cues": [[4.8, func(t: float): ch.sfx(t, "Whisper, close behind (2 s)", 2.2)]],
	})
	var scaffold := Chap.route([
		[shrine.x + 2.4, G.call(shrine.x + 2.4, shrine.z + 0.8), shrine.z + 0.8],
		[0, 4.1, 11.5], [0, 4.1, 4.2], [2.4, 5.6, 4.3], [4.6, 7.1, 4.3], [5.7, 7.1, 3.6], [5.7, 11.1, 2.2],
	])
	ch.scene("The scaffold", {
		"area": "A03_Ravine", "areas": ["A02_Trail"],
		"d": 24.0,
		"actor": Chap.walk(scaffold),
		"cam": Chap.follow(3.6, 1.6, 2.2),
		"subs": [Chap.thought(S.T1["scaffold"], 1.0), Chap.thought(S.T1["creak"], 13.0)],
		"cues": [
			[3.0, func(t: float): ch.sfx(t, "Wood creaks underfoot")],
			[10.0, func(t: float): ch.sfx(t, "Louder creak")],
			[17.0, func(t: float):
				ch.sfx(t, "Loud creak — the scaffold lurches")
				ch.key(D3 + "Scaffold:rotation", t, Vector3.ZERO)
				ch.key(D3 + "Scaffold:rotation", t + 0.15, Vector3(0.02, 0, -0.03))
				ch.key(D3 + "Scaffold:rotation", t + 0.4, Vector3(-0.01, 0, 0.015))
				ch.key(D3 + "Scaffold:rotation", t + 0.7, Vector3.ZERO)],
			[19.5, func(t: float):
				ch.key(D3 + "Scaffold:rotation", t, Vector3.ZERO)
				ch.key(D3 + "Scaffold:rotation", t + 0.2, Vector3(0.012, 0, -0.02))
				ch.key(D3 + "Scaffold:rotation", t + 0.5, Vector3.ZERO)],
		],
	})
	ch.scene("The collapse", {
		"area": "A03_Ravine", "areas": ["A02_Trail"],
		"d": 9.0,
		"actor": Chap.still(Vector3(5.7, 11.1, 2.0), 0.2),
		"cam": Chap.fixed(Vector3(-2.5, 7.0, 21), Vector3(3.5, 7.0, 4)),  # prototype: (-8, 6.5, 30) — sat inside the hillside pines
		"shake": 0.04,
		"subs": [Chap.thought(S.T1["collapse"], 3.0)],
		"cues": [[0.4, func(t: float):
			ch.sfx(t, "CRASH — the scaffold collapses into the ravine", 3.0)
			ch.key(D3 + "Scaffold:rotation", t, Vector3.ZERO)
			ch.key(D3 + "Scaffold:position", t, Vector3(2.5, C.SCAF_FLOOR, 6.5))
			ch.key(D3 + "Scaffold:rotation", t + 0.8, Vector3(0.12, 0, 0.08))
			ch.key(D3 + "Scaffold:rotation", t + 2.2, Vector3(0.95, 0.1, 0.35))
			ch.key(D3 + "Scaffold:position", t + 0.8, Vector3(2.5, C.SCAF_FLOOR - 0.4, 6.5))
			ch.key(D3 + "Scaffold:position", t + 2.2, Vector3(2.5, C.SCAF_FLOOR - 3.5, 6.9))]],
	})
	ch.scene("The harbor", {
		"area": "A04_OldHarbor",
		"d": 9.0, "fade": "in",
		"actor": Chap.walk(Chap.route([[12, -36], [11, -56]])),
		"cam": Chap.follow(4.2, 2.2, 3),
		"subs": [Chap.thought(S.T1["harbor"], 1.5)],
	})
	ch.scene("The gate", {
		"area": "A04_OldHarbor",
		"d": 13.0,
		"actor": Chap.walk(Chap.route([[11, -56], [10, -72]]), 0.0, 0.6),
		"cam": Chap.fixed(Vector3(5.5, 2.2, -62), Vector3(9.5, 1.5, -79.5)),
		"subs": [Chap.thought(S.T1["gateNear"], 0.6)],
		"notes": [{"at": 7.0, "dur": 5.5, "title": S.NOTES1["insignia"][0], "body": S.NOTES1["insignia"][1]}],
	})
	ch.scene("The maintenance shed", {
		"area": "A04_OldHarbor",
		"d": 8.0,
		"actor": Chap.walk(Chap.route([[10, -70], [-9, -66], [-14, -64.6]])),
		"cam": Chap.follow(4, 1.8, 2),
	})
	var roof_steps := [[15.8, "Footfall on the roof"], [16.3, "Footfall"], [16.9, "Footfall"], [17.5, "Footfall"]]
	var signout_cues := [
		[12.5, func(t: float):
			ch.sfx(t, "SLAM — the shed door bangs shut", 2.0)
			ch.tween(D4 + "ShedDoor:rotation", t, t + 0.25, Vector3(0, -1.9, 0), Vector3.ZERO)],
		[22.0, func(t: float):
			ch.sfx(t, "The door creaks slowly open", 3.0)
			ch.tween(D4 + "ShedDoor:rotation", t, t + 4.5, Vector3.ZERO, Vector3(0, -1.9, 0))],
	]
	for st in roof_steps:
		var txt: String = st[1]
		signout_cues.append([st[0], func(t: float): ch.sfx(t, txt, 0.5)])
	ch.scene("The sign-out sheet", {
		"area": "A04_OldHarbor",
		"d": 29.0,
		"actor": Chap.still(Vector3(-15.2, G.call(-15.2, -64.6), -64.6), 0.0),
		"cam": Chap.fixed(Vector3(-19.2, 1.7, -67.4), Vector3(-15.5, 1.4, -62.2)),
		"notes": [{"at": 2.5, "dur": 9.0, "title": S.NOTES1["signout"][0], "body": S.NOTES1["signout"][1]}],
		"subs": [Chap.thought(S.T1["doorSlam"], 13.4), Chap.thought(S.T1["roof"], 18.4), Chap.thought(S.T1["doorOpens"], 24.5)],
		"cues": signout_cues,
	})
	ch.scene("Out to the tower", {
		"area": "A04_OldHarbor",
		"d": 9.0, "fade": "in",
		"actor": Chap.walk(Chap.route([[-15.2, -65.0], [-13.5, -65.0], [-9.5, -65.0], [12, -63.5], [TX, TZ + 1.7]])),
		"cam": Chap.follow(4.6, 2.0, 2.5),
	})
	var climb := Chap.route([
		[TX, G0, TZ + 1.7], [TX, MID, TZ + 1.7], [TX, MID, TZ - 0.95],
		[TX, TOP, TZ - 0.95], [TX + 0.5, TOP, TZ - 0.3], [TX + 0.9, TOP, TZ - 0.6],
	])
	var cf: float = climb["frac"][4]
	ch.scene("The watchtower", {
		"area": "A04_OldHarbor",
		"d": 31.0,
		"actor": Chap.walk(climb, 0.0, 1.0, func(st: Dictionary, _u: float, k: float):
			if k < cf:
				st["yaw"] = PI),
		"cam": func(_u: float, st: Dictionary) -> Dictionary:
			var y: float = st["pos"].y
			return {"pos": Vector3(TX + 5.8, y * 0.5 + 2.2, TZ - 0.2), "look": Vector3(TX, y * 0.9 + 0.5, TZ)},
		"subs": [Chap.thought(S.T1["towerBase"], 1.0), Chap.thought(S.T1["towerMid"], 14.0)],
		"cues": [
			[2.0, func(t: float): ch.sfx(t, "Tower creaks")],
			[11.0, func(t: float): ch.sfx(t, "Deep groan from the timbers")],
			[19.0, func(t: float): ch.sfx(t, "Creak")],
			[26.5, func(t: float):
				ch.sfx(t, "Picks up the bolt cutters")
				ch.state(D4 + "BoltCutters:visible", t, false)],
		],
	})
	ch.scene("The body", {
		"area": "A04_OldHarbor",
		"d": 10.0,
		"actor": Chap.still(Vector3(TX + 0.9, TOP, TZ - 0.6), 0.15),
		"cam": Chap.fixed(Vector3(TX - 1.2, TOP + 1.5, TZ + 2.6), Vector3(body.x, body.y - 0.2, body.z)),
		"notes": [{"at": 0.8, "dur": 6.5, "title": S.NOTES1["body"][0], "body": S.NOTES1["body"][1]}],
		"subs": [Chap.thought(S.T1["body"], 7.8)],
	})
	var light_cues := []
	for c in [[0.4, true], [3.6, false], [3.9, true], [4.2, false], [4.5, true], [7.0, false]]:
		var on: bool = c[1]
		light_cues.append([c[0], func(t: float):
			ch.state(D4 + "Searchlight/Light:light_energy", t, 12.0 if on else 0.0)
			ch.state(D4 + "Searchlight/Beam:visible", t, on)])
	light_cues.append([0.4, func(t: float): ch.sfx(t, "CLANK — searchlight bangs on, electrical buzz", 3.0)])
	light_cues.append([7.0, func(t: float): ch.sfx(t, "Light dies — STINGER", 2.0)])
	ch.scene("The searchlight", {
		"area": "A04_OldHarbor",
		"d": 14.0,
		"actor": Chap.still(Vector3(TX + 0.9, TOP, TZ - 0.6), 0.15),
		"cam": Chap.fixed(Vector3(TX - 0.9, TOP + 1.6, TZ), stalker_spot + Vector3(0, 1.2, 0)),
		"creature": func(u: float) -> Dictionary:
			return {"visible": u < 0.5, "pos": stalker_spot, "yaw": PI / 2},
		"subs": [Chap.thought(S.T1["searchlight"], 1.2), Chap.thought(S.T1["lookedDown"], 8.6)],
		"cues": light_cues,
	})
	ch.scene("Run for the gate", {
		"area": "A04_OldHarbor",
		"d": 10.0, "fade": "in",
		"actor": Chap.walk(Chap.route([[TX, TZ + 1.7], [18, -63.5], [12, -70], [10.5, -77.5]]), 0.0, 1.0, func(st: Dictionary, u: float, _k: float):
			if u > 0 and u < 1:
				st["pose"] = "Run"),
		"cam": Chap.follow(4.6, 2.2, 2.0),
		"subs": [Chap.thought(S.T1["run"], 0.8)],
		"cues": [
			[1.5, func(t: float): ch.sfx(t, "Running footsteps BEHIND you", 2.5)],
			[5.5, func(t: float): ch.sfx(t, "Breathing, right at your ear", 2.0)],
		],
	})
	var cd := 21.0  # prototype length 17 s + the rumble beat from chapter1.js
	ch.scene("The chain", {
		"area": "A04_OldHarbor", "areas": ["A05_BaseCamp"],
		"d": cd,
		"actor": Chap.walk(Chap.route([[10, -77.5], [10, -86.5]]), 7.65 / cd, 17.0 / cd),
		"cam": Chap.fixed(Vector3(13.4, 1.6, -77.2), Vector3(10, 1.4, -80.4)),
		"creature": func(u: float) -> Dictionary:
			return {"visible": u > 3.4 / cd and u < 8.5 / cd, "pos": C.gv(10.5, -97), "yaw": 0.0},
		"subs": [Chap.thought(S.T1["gateOpen"], 9.0), Chap.thought(S.T1["rumble"], 15.0)],
		"cues": [
			[1.2, func(t: float): ch.sfx(t, "Cutters bite the chain", 1.0)],
			[2.2, func(t: float):
				ch.sfx(t, "SNAP — the chain drops", 1.5)
				ch.state(D4 + "GateChain:visible", t, false)],
			[4.0, func(t: float):
				ch.sfx(t, "Gate grinds open", 2.5)
				ch.tween(D4 + "GateLeft:rotation", t, t + 3.0, Vector3.ZERO, Vector3(0, 1.4, 0))
				ch.tween(D4 + "GateRight:rotation", t, t + 3.0, Vector3.ZERO, Vector3(0, -1.4, 0))],
			[5.5, func(t: float): ch.sfx(t, "STINGER — a figure beyond the gate", 2.0)],
			[14.0, func(t: float):
				ch.sfx(t, "Deep rumble (6 s) — far out at sea, the black stone rises", 6.0)
				ch.tween(D1 + "ShiftingRock:position", t, t + 6.0, Vector3(22, -12.5, 114), Vector3(22, -6.9, 114))],
			[19.4, func(t: float): ch.call_at(t, "fade_out", [1.5])],
		],
	})
	ch.finish()
	save(ch, "ch01_the_old_harbor", 1)


# =============================================================================
#  CHAPTER 2 — THE CLOSED AREA
# =============================================================================
func build_ch02() -> void:
	var ch := Chap.new("Chapter02_BaseCamp")
	base_scene(ch, 0.014, ["A04_OldHarbor", "A05_BaseCamp"])
	var G := func(x: float, z: float) -> float: return C.G(x, z)
	var GB := C.G(8, -100)

	ch.state(D5 + "BasePower:visible", 0.0, false)
	ch.state(D5 + "FuelCan:visible", 0.0, true)
	for l in ["Lever_Lighting", "Lever_Comms", "Lever_Main"]:
		ch.state(D5 + l + ":rotation", 0.0, Vector3(0.6, 0, 0))
	var PY := GB + 1.0                              # station platform top
	var CAR0 := Vector3(4.5, PY + 0.1, -136)        # car 2 parked on the up track
	ch.key(D5 + "CableCar:position", 0.0, CAR0)
	ch.state(D5 + "CableCar/CabinLight:light_energy", 0.0, 0.0)
	ch.state(D5 + "CableCar/RunLever:rotation", 0.0, Vector3(0.6, 0, 0))
	# the gate is open and the stone has risen (end of chapter 1)
	ch.key(D4 + "GateLeft:rotation", 0.0, Vector3(0, 1.4, 0))
	ch.key(D4 + "GateRight:rotation", 0.0, Vector3(0, -1.4, 0))
	ch.state(D4 + "GateChain:visible", 0.0, false)

	ch.scene("Chapter 2", {"d": 4.0, "card": ["Chapter 2", "Base Camp", ""]})
	ch.scene("The base camp", {
		"area": "A05_BaseCamp", "areas": ["A04_OldHarbor"],
		"d": 15.0, "fade": "in",
		"actor": Chap.still(Vector3(10, G.call(10, -86), -86), PI),
		"cam": Chap.dolly(Vector3(-6, 28, -52), Vector3(0, 24, -96), Vector3(12, 0, -100), Vector3(6, 16, -180)),
		"subs": [Chap.thought(S.T2["arrive"], 1.0), Chap.thought(S.T2["arrive2"], 8.2)],
	})
	ch.scene("The supply yard", {
		"area": "A05_BaseCamp",
		"d": 23.0,
		"actor": Chap.walk(Chap.route([[10, -86], [4, -92], [-6, -98.5], [-8.4, -99.4]]), 0.0, 0.37),
		"cams": [
			[0.0, 0.37, Chap.follow(4.0, 1.8, 2)],
			[0.37, 1.0, Chap.fixed(Vector3(-6.0, 1.9, -97.2), Vector3(-9.2, 1.2, -100.6))],
		],
		"notes": [{"at": 8.5, "dur": 7.5, "title": S.NOTE_MANIFEST[0], "body": S.NOTE_MANIFEST[1]}],
		"subs": [Chap.thought(S.T2B["supply"], 16.3)],
	})
	ch.scene("The cable car station", {
		"area": "A05_BaseCamp",
		"d": 22.0,
		"actor": Chap.walk(Chap.route([[-8.4, -99.4], [-3, -112], [3, -125], [5, GB, -128.6], [5, PY, -131.0], [9.2, PY, -131.6], [10.8, PY, -131.5]]), 0.0, 0.62, func(st: Dictionary, u: float, _k: float):
			if u > 0.62:
				st["yaw"] = PI / 2),
		"cams": [
			[0.0, 0.62, Chap.fixed(Vector3(0, GB + 1.6, -117), Vector3(6, PY + 6, -140))],
			[0.62, 1.0, Chap.fixed(Vector3(8.6, PY + 1.9, -129.9), Vector3(12.2, PY + 1.2, -131.8))],
		],
		"subs": [Chap.thought(S.T2B["stationLine"], 4.5), Chap.thought(S.T2B["stationDead"], 15.0)],
		"cues": [[14.2, func(t: float): ch.sfx(t, "Drive switch clicks — nothing", 1.5)]],
	})
	ch.scene("The generator", {
		"area": "A05_BaseCamp",
		"d": 19.0,
		"actor": Chap.walk(Chap.route([[10.8, PY, -131.5], [5, PY, -131.0], [5, GB, -128.6], [8, -112], [10, -97], [16, -88.5], [21.2, -88.4]])),
		"cam": Chap.follow(4.2, 1.8, 2),
		"subs": [Chap.thought(S.T2["genDry"], 13.2)],
		"cues": [[16.6, func(t: float): ch.sfx(t, "Hollow clank — empty tank")]],
	})
	ch.scene("Into the barracks", {
		"area": "A05_BaseCamp",
		"d": 9.0,
		"actor": Chap.walk(Chap.route([[21.2, -88.4], [26, -93.5], [26.5, -98.6], [26.5, -102]])),
		"cam": Chap.follow(4.2, 1.7, 2),
	})
	ch.scene("Elias's locker", {
		"area": "A05_BaseCamp",
		"d": 12.0,
		"actor": Chap.walk(Chap.route([[26.5, -102], [28.2, -111.2]]), 0.0, 0.6),
		"cam": Chap.fixed(Vector3(25.8, 1.7, -108.4), Vector3(28.2, 1.5, -113.6)),
		"notes": [{"at": 4.5, "dur": 7.0, "title": S.NOTES2["eliasLocker"][0], "body": S.NOTES2["eliasLocker"][1]}],
	})
	ch.scene("The fuel can", {
		"area": "A05_BaseCamp",
		"d": 14.0,
		"actor": Chap.walk(Chap.route([[28.2, -111.2], [33.1, -110.4]]), 0.0, 0.45),
		"cam": Chap.follow(3.6, 1.7, 2),
		"subs": [Chap.thought(S.T2["fuelGot"], 6.5)],
		"cues": [[4.5, func(t: float):
			ch.sfx(t, "Picks up the fuel can")
			ch.state(D5 + "FuelCan:visible", t, false)]],
	})

	# ENCOUNTER 1 — it comes through the barracks door; the protagonist hides in a locker.
	var barracks_route := Chap.route([[26.5, -97.5], [27, -103.5], [30.2, -107.9], [27.3, -106.8], [24.5, -103.5], [26.2, -98.3], [26.5, -94.5]])
	var to_locker := Chap.walk(Chap.route([[33.1, -110.4], [31.0, -111.2]]), 0.0, 0.2)
	var out_barracks := Chap.walk(Chap.route([[31.0, -111.2], [27, -106], [26.5, -98.6]]), 0.92, 1.0)
	var in_locker := Chap.hidden(Vector3(31.0, GB, -113.6))
	ch.scene("Footsteps at the door", {
		"area": "A05_BaseCamp",
		"d": 30.0,
		"actor": func(u: float) -> Dictionary:
			return to_locker.call(u) if u < 0.2 else (in_locker.call(u) if u < 0.92 else out_barracks.call(u)),
		"cams": [
			[0.0, 0.2, Chap.follow(3.6, 1.7, 2)],
			[0.2, 0.92, Chap.fixed(Vector3(29.6, 1.5, -108.6), Vector3(31.0, 1.3, -113.6))],
			[0.92, 1.0, Chap.follow(3.6, 1.7, 2)],
		],
		"creature": func(u: float) -> Dictionary:
			if u < 0.12:
				return {"visible": true, "pos": C.gv(26.5, -97.5), "yaw": PI}
			var st := Chap.route_at(barracks_route, clampf((u - 0.12) / 0.7, 0, 1))
			st["visible"] = u <= 0.9
			return st,
		"subs": [Chap.thought(S.T2["atDoor"], 1.0)],
		"cues": [
			[0.6, func(t: float): ch.sfx(t, "BANG — the barracks door")],
			[6.4, func(t: float): ch.sfx(t, "Locker door clicks shut, metal creaks (inside the locker)", 2.5)],
			[12.0, func(t: float): ch.sfx(t, "Slow footsteps on concrete", 2.5)],
			[17.0, func(t: float): ch.sfx(t, "Footsteps — closer", 2.5)],
			[23.0, func(t: float): ch.sfx(t, "Breathing through the locker vents", 2.5)],
		],
	})
	var fuel_cues := [
		[10.0, func(t: float): ch.sfx(t, "Fuel glugs into the tank", 2.0)],
		[12.8, func(t: float): ch.sfx(t, "Cord pull — engine sputters, dies", 1.6)],
		[14.8, func(t: float): ch.sfx(t, "Cord pull — sputters, dies", 1.6)],
		[16.8, func(t: float): ch.sfx(t, "Cord pull — the engine CATCHES and runs", 3.0)],
	]
	ch.scene("Fuelling the generator", {
		"area": "A05_BaseCamp",
		"d": 23.0,
		"actor": Chap.walk(Chap.route([[26.5, -101.5], [26.5, -98.6], [25, -93.5], [21.2, -88.4]]), 0.0, 0.45, func(st: Dictionary, u: float, _k: float):
			if u > 0.45:
				st["yaw"] = PI / 2),
		"cams": [
			[0.0, 0.45, Chap.follow(4.2, 1.8, 2)],
			[0.45, 1.0, Chap.fixed(Vector3(18.6, 1.8, -86.3), Vector3(22.5, 1.2, -89.5))],
		],
		"subs": [
			Chap.thought(S.T2["fuelPoured"], 12.0, 1.0),
			Chap.thought(S.T2["sputter0"], 13.0),
			Chap.thought(S.T2["sputter1"], 15.6),
			Chap.thought(S.T2["genRunning"], 18.5),
		],
		"cues": fuel_cues,
	})
	var LV := D5 + "Lever_"
	ch.scene("The breakers", {
		"area": "A05_BaseCamp",
		"d": 24.0,
		"actor": Chap.still(Vector3(19.5, G.call(19.5, -91.6), -91.6), PI),
		"cam": Chap.fixed(Vector3(21.0, G.call(21, -89.4) + 1.7, -89.4), Vector3(19.5, G.call(19.5, -93) + 1.3, -93.2)),
		"notes": [{"at": 0.8, "dur": 8.5, "title": S.NOTES2["panelNote"][0], "body": S.NOTES2["panelNote"][1]}],
		"subs": [Chap.thought(S.T2["wrongOrder"], 11.2), Chap.thought(S.T2B["powerOn"], 19.6)],
		"cues": [
			[9.5, func(t: float): ch.state(LV + "Main:rotation", t, Vector3(-0.6, 0, 0))],
			[10.6, func(t: float): ch.sfx(t, "SPARKS — a loud BANG (it can hear that)", 2.5)],
			[13.0, func(t: float):
				for l in ["Lighting", "Comms", "Main"]:
					ch.state(LV + l + ":rotation", t, Vector3(0.6, 0, 0))],
			[14.5, func(t: float):
				ch.sfx(t, "Clunk", 0.8)
				ch.state(LV + "Lighting:rotation", t, Vector3(-0.6, 0, 0))],
			[15.8, func(t: float):
				ch.sfx(t, "Clunk", 0.8)
				ch.state(LV + "Comms:rotation", t, Vector3(-0.6, 0, 0))],
			[17.0, func(t: float):
				ch.sfx(t, "Clunk", 0.8)
				ch.state(LV + "Main:rotation", t, Vector3(-0.6, 0, 0))],
			[17.9, func(t: float):
				ch.sfx(t, "Power hums up across the camp — the station lights come on", 3.0)
				ch.state(D5 + "BasePower:visible", t, true)
				ch.state(D5 + "CableCar/CabinLight:light_energy", t, 1.5)],
		],
	})
	# Back to the station with power; Elias on the intercom; the car leaves as it reaches the platform.
	ch.scene("Back to the station", {
		"area": "A05_BaseCamp",
		"d": 20.0,
		"actor": Chap.walk(Chap.route([[19.5, -91.6], [16, -98], [8, -112], [5, -124], [5, GB, -128.6], [5, PY, -131.0], [9.2, PY, -131.6], [10.8, PY, -131.5]]), 0.0, 0.8, func(st: Dictionary, u: float, _k: float):
			if u > 0.8:
				st["yaw"] = PI / 2),
		"cams": [
			[0.0, 0.55, Chap.follow(4.2, 2.0, 2)],
			[0.55, 1.0, Chap.fixed(Vector3(-1, PY + 3.5, -124), Vector3(8, PY + 2, -136))],
		],
		"subs": [Chap.thought(S.T2B["carLit"], 9.0)],
	})
	var radio := Chap.talk(S.RADIO_UP, 1.5)
	var radio_end := Chap.end_of(radio)
	ch.scene("The intercom", {
		"area": "A05_BaseCamp",
		"d": radio_end + 3.0,
		"actor": Chap.still(Vector3(10.8, PY, -131.5), PI / 2),
		"cam": Chap.fixed(Vector3(8.6, PY + 1.9, -129.9), Vector3(12.3, PY + 1.5, -131.4)),
		"subs": radio,
		"cues": [
			[0.0, func(t: float): ch.sfx(t, "The intercom crackles alive — static bed", radio_end)],
			[radio_end + 0.4, func(t: float): ch.sfx(t, "Static. Then nothing.", 2.0)],
		],
	})
	# THE CABLE CAR — wind up the drive while it runs at you; the car pulls out just in time.
	var depart := 18.5
	var rope_y := PY + 7.0
	var pylon_top := C.G(6, -175) + 16.0 + 0.2
	var car_at := func(t: float) -> Vector3:
		if t <= depart:
			return CAR0
		var dt2 := t - depart
		var z := -136.0 - 0.5 * 0.35 * dt2 * dt2
		var ry := rope_y if z >= -141.0 else lerpf(rope_y, pylon_top, (-141.0 - z) / 34.0)
		return Vector3(4.5, ry - (rope_y - CAR0.y), z)
	var d_car := 30.0
	var board := Chap.walk(Chap.route([[10.8, PY, -131.5], [6.4, PY, -135.7], [4.7, PY + 0.1, -135.7], [4.1, PY + 0.1, -136.6]]), 0.0, 5.5 / d_car)
	var creature_run := Chap.route([[6, -103], [6, -118], [5.5, GB, -128.6], [5.5, PY, -131.2], [5.5, PY, -133.4]])
	ch.scene("The cable car", {
		"area": "A05_BaseCamp",
		"d": d_car,
		"actor": func(u: float) -> Dictionary:
			var t := u * d_car
			if t < 5.5:
				return board.call(u)
			var yaw := -2.53 if t < 9.5 else 0.0
			return {"pos": car_at.call(t) + Vector3(-0.4, 0, -0.6), "yaw": yaw, "pose": "Idle", "visible": true},
		"cams": [
			[0.0, 5.5 / d_car, Chap.fixed(Vector3(1.5, PY + 1.8, -129), Vector3(5, PY + 1.2, -136))],
			[5.5 / d_car, depart / d_car, Chap.fixed(Vector3(4.2, PY + 2.0, -137.3), Vector3(5.5, PY + 0.5, -110))],
			[depart / d_car, 1.0, Chap.fixed(Vector3(11, PY + 2.5, -129), Vector3(4.5, PY + 4, -150))],
		],
		"creature": func(u: float) -> Dictionary:
			var t := u * d_car
			var st := Chap.route_at(creature_run, clampf((t - 13.5) / 7.0, 0, 1))
			st["visible"] = t >= 13.5
			return st,
		"subs": [
			Chap.thought(S.T2["sputter0"], 8.0),
			Chap.thought(S.T2["sputter1"], 15.5),
			Chap.thought(S.T2B["moving"], 22.5),
			Chap.thought(S.T2B["below"], 25.5),
		],
		"cues": [
			[0.0, func(t: float):
				for k in 25:
					ch.key(D5 + "CableCar:position", t + depart + k * 0.5, car_at.call(depart + k * 0.5))],
			[6.5, func(t: float):
				ch.sfx(t, "RUN lever — the drive motor starts winding up (it needs time)", 3.0)
				ch.tween(D5 + "CableCar/RunLever:rotation", t, t + 0.3, Vector3(0.6, 0, 0), Vector3(-0.6, 0, 0))],
			[11.0, func(t: float): ch.sfx(t, "A wail from the yard", 2.0)],
			[13.5, func(t: float): ch.sfx(t, "Running footsteps — coming fast", 3.0)],
			[18.5, func(t: float): ch.sfx(t, "CLUNK — the grip bites, the car lurches out", 2.0)],
			[20.5, func(t: float): ch.sfx(t, "It slams into the platform rail", 2.0)],
			[28.5, func(t: float): ch.call_at(t, "fade_out", [1.5])],
		],
	})
	ch.scene("End of Chapter 2", {"d": 7.0, "card": ["", "End of Chapter 2", "Chapter 3 — The Line.  To be continued…"]})
	ch.finish()
	save(ch, "ch02_base_camp", 2)


# =============================================================================
#  CHAPTER 3 — THE LINE (first part: the ride, the breakdown, the service path)
# =============================================================================
func build_ch03() -> void:
	var ch := Chap.new("Chapter03_TheLine")
	base_scene(ch, 0.016, ["A05_BaseCamp", "A06_Ropeway", "A07_ServicePath"])
	var G := func(x: float, z: float) -> float: return C.G(x, z)
	var CAR := D6 + "CableCar"
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var in_car := Vector3(0.3, 0, 0.4)  # where the protagonist stands in the cabin

	ch.key(CAR + ":position", 0.0, C.car_at_z(-146))
	ch.key(CAR + ":rotation", 0.0, Vector3.ZERO)
	ch.state(CAR + "/CabinLight:light_energy", 0.0, 1.5)
	ch.state(CAR + "/RunLever:rotation", 0.0, Vector3(-0.6, 0, 0))
	# the station's car (A05) has left
	ch.state(D5 + "CableCar:visible", 0.0, false)
	ch.state(D5 + "BasePower:visible", 0.0, true)

	# car motion for a ride shot: z from z0 to z1 over the shot (linear), as a Callable(t_local) -> pos
	var ride := func(z0: float, z1: float, d: float) -> Callable:
		return func(t: float) -> Vector3: return C.car_at_z(lerpf(z0, z1, clampf(t / d, 0, 1)))
	# keys for the car's position over a shot, and sway / shake on its rotation
	var key_ride := func(t0: float, d: float, at: Callable) -> void:
		var k := 0.0
		while k <= d + 0.001:
			ch.key(CAR + ":position", t0 + minf(k, d - 0.02), at.call(minf(k, d - 0.02)))
			k += 0.5
	var sway := func(t0: float, t1: float, amp: float, hz: float, decay: float) -> void:
		var t := t0
		while t <= t1:
			var a := amp * exp(-decay * (t - t0))
			ch.key(CAR + ":rotation", t, Vector3(a * sin(TAU * hz * (t - t0)), 0, a * 0.6 * cos(TAU * hz * 0.7 * (t - t0))))
			t += 0.1
		ch.key(CAR + ":rotation", t1 + 0.1, Vector3.ZERO)
	var shake := func(t0: float, t1: float, amp: float) -> void:
		var t := t0
		while t <= t1:
			ch.key(CAR + ":rotation", t, Vector3(rng.randf_range(-amp, amp), 0, rng.randf_range(-amp, amp)))
			t += 0.08
		ch.key(CAR + ":rotation", t1 + 0.08, Vector3.ZERO)
	var rider := func(at: Callable, d: float) -> Callable:
		return func(u: float) -> Dictionary:
			return {"pos": at.call(u * d) + in_car, "yaw": PI, "pose": "Idle", "visible": true}
	var outside := func(at: Callable, d: float, off: Vector3) -> Callable:
		return func(u: float, _st: Dictionary) -> Dictionary:
			var p: Vector3 = at.call(u * d)
			return {"pos": p + off, "look": p + Vector3(0, 1.4, 0)}

	ch.scene("Chapter 3", {"d": 4.0, "card": ["Chapter 3", "The Line", ""]})

	var d1 := 20.0
	var r1: Callable = ride.call(-146.0, -196.0, d1)
	var jolt1 := (175.0 - 146.0) / 50.0 * d1
	ch.scene("Above the camp", {
		"area": "A06_Ropeway", "areas": ["A05_BaseCamp"],
		"d": d1, "fade": "in",
		"actor": rider.call(r1, d1),
		"cam": outside.call(r1, d1, Vector3(-9, -3, 7)),
		"subs": [Chap.thought(S.T3["lookDown"], 2.0), Chap.thought(S.T3["tower"], jolt1 + 1.4)],
		"cues": [
			[0.0, func(t: float): key_ride.call(t, d1, r1)],
			[0.5, func(t: float): ch.sfx(t, "Cable hum; the cabin creaks as it climbs", 3.0)],
			[jolt1, func(t: float):
				ch.sfx(t, "CLUNK-CLUNK over the tower saddle — the cabin lurches and sways", 2.5)
				sway.call(t, t + 4.0, 0.06, 0.7, 0.8)],
		],
	})
	var d2 := 24.0
	var r2: Callable = ride.call(-205.0, -265.0, d2)
	var jolt2 := (235.0 - 205.0) / 60.0 * d2
	var creature_slope := Chap.route([[-4, -220], [-3.5, -242]])
	ch.scene("Something on the slope", {
		"area": "A06_Ropeway",
		"d": d2,
		"actor": rider.call(r2, d2),
		"cam": func(u: float, _st: Dictionary) -> Dictionary:
			var p: Vector3 = r2.call(u * d2)
			return {"pos": C.gv(-9, -214, 2.0), "look": p + Vector3(0, 1.0, 0)},
		"creature": func(u: float) -> Dictionary:
			var t := u * d2
			var st := Chap.route_at(creature_slope, clampf((t - 2.5) / 15.0, 0, 1))
			var car: Vector3 = r2.call(t)
			st["yaw"] = atan2(car.x - st["pos"].x, car.z - st["pos"].z)
			st["visible"] = t >= 2.5 and t <= 17.5
			return st,
		"subs": [Chap.thought(S.T3["slope"], 6.0)],
		"cues": [
			[0.0, func(t: float): key_ride.call(t, d2, r2)],
			[jolt2, func(t: float):
				ch.sfx(t, "CLUNK-CLUNK — tower two", 2.0)
				sway.call(t, t + 3.5, 0.05, 0.75, 0.9)],
		],
	})
	var d3 := 14.0
	var r3: Callable = ride.call(-268.0, -290.0, d3)
	ch.scene("It's ahead", {
		"area": "A06_Ropeway", "areas": ["A07_ServicePath"],
		"d": d3,
		"actor": rider.call(r3, d3),
		"cam": func(u: float, _st: Dictionary) -> Dictionary:
			var p: Vector3 = r3.call(u * d3)
			return {"pos": p + Vector3(-0.6, 1.8, 1.2), "look": p + Vector3(2.0, -2.0, -14)},
		"creature": func(u: float) -> Dictionary:
			var t := u * d3
			var pos := C.gv(12, -312)
			var car: Vector3 = r3.call(t)
			return {"visible": t >= 3.0 and t <= 9.0, "pos": pos, "yaw": atan2(car.x - pos.x, car.z - pos.z)},
		"subs": [Chap.thought(S.T3["ahead"], 9.5)],
		"cues": [
			[0.0, func(t: float): key_ride.call(t, d3, r3)],
			[3.0, func(t: float): ch.sfx(t, "Stinger (low) — a figure by the next tower", 2.0)],
		],
	})
	var d4 := 22.0
	var stop_at := func(t: float) -> Vector3:
		var k := clampf(t / 6.0, 0, 1)
		return C.car_at_z(lerpf(-290.0, C.CAR_STOP_Z, 1.0 - (1.0 - k) * (1.0 - k)))
	ch.scene("The breakdown", {
		"area": "A06_Ropeway", "areas": ["A07_ServicePath"],
		"d": d4,
		"actor": rider.call(stop_at, d4),
		"cam": func(u: float, _st: Dictionary) -> Dictionary:
			var p: Vector3 = stop_at.call(u * d4)
			return {"pos": C.gv(15, -297, 2.5), "look": p + Vector3(0, 1.0, 0)},
		"subs": [Chap.thought(S.T3["noStop"], 2.0), Chap.thought(S.T3["getOut"], 15.0)],
		"cues": [
			[0.0, func(t: float): key_ride.call(t, d4, stop_at)],
			[1.0, func(t: float):
				ch.sfx(t, "Grinding from the grip — the whole cabin judders", 4.0)
				shake.call(t, t + 6.0, 0.05)],
			[5.5, func(t: float): ch.sfx(t, "BANG — the grip slips and locks. The car stops dead.", 2.5)],
			[7.2, func(t: float): sway.call(t, t + 7.0, 0.09, 0.45, 0.45)],
			[8.0, func(t: float):
				for f in [[0.0, 0.3], [0.25, 1.5], [0.5, 0.2], [0.7, 1.2], [1.1, 0.0]]:
					ch.state(CAR + "/CabinLight:light_energy", t + f[0], f[1])
				ch.sfx(t, "The cabin light flickers and dies", 2.0)],
			[11.0, func(t: float): ch.sfx(t, "Silence. Wind. The cable creaks.", 3.0)],
		],
	})
	var d5 := 16.0
	var floor_y := C.car_at_z(C.CAR_STOP_Z).y
	var stop := C.car_at_z(C.CAR_STOP_Z)
	var climb_out := Chap.route([
		[stop.x + in_car.x, floor_y, stop.z + in_car.z], [stop.x + 0.95, floor_y, stop.z + 0.3],
		[5.95, floor_y, -303.0], [5.95, lerpf(floor_y, G.call(5.95, -303.0), 0.45), -303.0],
	])
	var P := C.SERVICE_PATH
	var X: Vector3 = C.stream_crossing()
	var dir2: Vector3 = Vector3(float(P[3][0]) - float(P[2][0]), 0.0, float(P[3][1]) - float(P[2][1])).normalized()
	var bank_in: Vector3 = X - dir2 * 4.0    # east bank (we arrive from the station side)
	var bank_out: Vector3 = X + dir2 * 4.0   # west bank
	var ladder_y: float = lerpf(floor_y, G.call(5.95, -303.0), 0.45)   # the rung where the player slips
	var ground: float = G.call(7.6, -302.4)
	ch.scene("Climbing out", {
		"area": "A06_Ropeway",
		"d": d5,
		"actor": Chap.walk(climb_out, 0.0, 1.0, func(st: Dictionary, _u: float, _k: float):
			if st["pose"] == "Climb":
				st["yaw"] = PI),
		"cams": [
			[0.0, 5.5 / d5, Chap.fixed(stop + Vector3(-0.8, 1.9, 1.3), stop + Vector3(1.6, 0.8, -0.6))],
			[5.5 / d5, 1.0, Chap.fixed(C.gv(11, -297.5, 1.6), Vector3(6, floor_y - 3.0, -303.5))],
		],
		"subs": [Chap.thought(S.T3["ladder"], 4.0)],
		"cues": [
			[2.5, func(t: float): ch.sfx(t, "The door rattles open — wind roars in", 2.5)],
			[6.0, func(t: float): ch.sfx(t, "Rungs ring under each step", 3.0)],
			[11.0, func(t: float): ch.sfx(t, "A knock on the pylon, far above. Then another.", 3.0)],
			[14.0, func(t: float): ch.sfx(t, "A rung gives way under the boot", 1.5)],
		],
	})
	# the fall: the rung goes, the player drops the last metres to the ground. The ropeway unloads here
	# (this shot loads only A07), so there is no way back up: the car and the line are gone from the level.
	var fall_pos := func(u: float) -> Dictionary:
		var k := clampf(u / 0.45, 0.0, 1.0)
		var y := lerpf(ladder_y, ground, k * k)
		return {"pos": Vector3(lerpf(5.95, 7.6, k), y, lerpf(-303.0, -302.4, k)), "yaw": 0.0, "pose": "Crouch" if u >= 0.45 else "Idle", "visible": true}
	ch.scene("The fall", {
		"area": "A07_ServicePath",
		"d": 5.0,
		"actor": fall_pos,
		"cam": Chap.fixed(Vector3(9.0, ground + 1.3, -299.5), Vector3(5.5, ladder_y - 2.0, -303.2)),
		"shake": 0.06,
		"subs": [Chap.thought(S.T3["fall"], 2.6)],
		"cues": [
			[0.2, func(t: float): ch.sfx(t, "Hand slips off the rung — the ladder rings", 1.2)],
			[1.1, func(t: float): ch.sfx(t, "THUD — the landing knocks the wind out of you", 2.0)],
			[1.4, func(t: float): ch.call_at(t, "blur_to", [5.0, 2.2])],
			[2.4, func(t: float): ch.call_at(t, "fade_out", [1.4])],
		],
	})
	# waking up in the dark on the forest side: the view sharpens and the player gets up
	ch.scene("Waking up", {
		"area": "A07_ServicePath",
		"d": 12.0,
		"actor": func(u: float) -> Dictionary:
			return {"pos": Vector3(7.6, ground, -302.4), "yaw": 0.0, "pose": "Crouch" if u < 0.6 else "Idle", "visible": true},
		"cam": Chap.fixed(Vector3(9.5, ground + 1.0, -298.5), Vector3(7.6, ground + 1.0, -302.4)),
		"subs": [Chap.thought(S.T3["wake"], 7.0)],
		"cues": [
			[0.5, func(t: float): ch.sfx(t, "Breathing, ragged. A ringing in the ears.", 3.0)],
			[3.5, func(t: float):
				ch.call_at(t, "fade_in", [2.5])
				ch.call_at(t, "blur_to", [0.0, 3.0])],
		],
	})
	ch.scene("The lit path", {
		"area": "A07_ServicePath",
		"d": 22.0,
		"actor": Chap.walk(Chap.route([[7.6, -302.4], P[0], P[1], P[2], [bank_in.x, bank_in.z]]), 0.0, 1.0),
		"cam": Chap.follow(4.0, 2.0, 2.5),
		"subs": [Chap.thought(S.T3["lights"], 3.0), Chap.thought(S.T3["up"], 13.0)],
		"cues": [[0.5, func(t: float): ch.sfx(t, "Lamps buzz along the fence line", 2.5)]],
	})
	ch.scene("The old stream", {
		"area": "A07_ServicePath",
		"d": 20.0,
		"actor": Chap.walk(Chap.route([[bank_in.x, bank_in.z], [X.x, X.y, X.z], [bank_out.x, bank_out.z]]), 0.0, 1.0),
		"cam": Chap.follow(3.6, 1.8, 2.5),
		"subs": [Chap.thought(S.T3["stream"], 2.5), Chap.thought(S.T3["bridge"], 11.0)],
		"cues": [
			[0.0, func(t: float): ch.sfx(t, "Running water under the planks", 4.0)],
			[10.0, func(t: float): ch.sfx(t, "Planks creak under the walker", 2.0)],
		],
	})
	ch.scene("The forest", {
		"area": "A07_ServicePath",
		"d": 26.0,
		"actor": Chap.walk(Chap.route([[bank_out.x, bank_out.z], [P[3][0], P[3][1]], [P[4][0], P[4][1]]]), 0.0, 1.0),
		"cam": Chap.follow(3.6, 1.8, 2.5),
		"subs": [Chap.thought(S.T3["forest"], 2.5)],
		"cues": [
			[7.0, func(t: float): ch.sfx(t, "Loose scree skitters downhill", 2.0)],
			[15.0, func(t: float): ch.sfx(t, "A branch cracks somewhere in the trees", 2.0)],
			[24.0, func(t: float): ch.call_at(t, "fade_out", [1.5])],
		],
	})
	ch.scene("End of Chapter 3 so far", {"d": 6.0, "card": ["", "End of Chapter 3 (so far)", "The rest of this chapter is still to be designed."]})
	ch.finish()
	save(ch, "ch03_the_line", 3)


# =============================================================================
#  CHAPTER 4 — THE OLD VILLAGE (PROPOSED: see story/chapters/ch04_the_old_village.md)
#  The player wakes in the sunken village hollow, reads the island's history in carvings, a ship's log
#  and company dig tags, learns the creature is the colonist, and leaves by the company's cargo lift.
# =============================================================================
const D10 := "Level/A10_FestivalRing/Dynamic/"
const D11 := "Level/A11_BurnedQuarter/Dynamic/"


func build_ch04() -> void:
	var ch := Chap.new("Chapter04_TheOldVillage")
	base_scene(ch, 0.02, ["A08_HollowEdge", "A09_VillageLanes", "A10_FestivalRing", "A11_BurnedQuarter"])
	var T4 := S.T4
	var LZ := C.LANE_Z
	var L := C.LANDING

	# the colonist's costume on the creature: a long coat and a brass button
	var beast := ch.root.get_node("Actors/Actor_Creature")
	ch.b.box(beast, "Coat", Vector3(0.5, 1.5, 0.3), Vector3(0, 0.95, 0), Color(0.04, 0.035, 0.03), Vector3.ZERO, {"roughness": 1.0})
	ch.b.sphere(beast, "Button", 0.03, Vector3(0, 1.45, 0.17), Color(0.8, 0.6, 0.2), {"emission": Color(1.0, 0.75, 0.2), "emission_energy": 2.0})

	# ---- authoring helpers --------------------------------------------------
	# waypoints [[t, x, z], ...] from a list of [x, z] points walked at a constant speed, starting at t0
	var wps := func(t0: float, speed: float, pts: Array) -> Array:
		var out := [[t0, pts[0][0], pts[0][1]]]
		var t := t0
		for i in range(1, pts.size()):
			t += Vector2(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1]).length() / speed
			out.append([t, pts[i][0], pts[i][1]])
		return out
	# an actor following timed waypoints [t, x, z, yaw?, pose?] on the ground: moves between waypoints,
	# stands still when two are at the same place. yaw = heading of the move (or the waypoint's own yaw when still);
	# pose = the pose for the move/stand that starts at that waypoint.
	var timed := func(pts: Array, d: float) -> Callable:
		var yaws := []
		var last := 0.0
		for i in pts.size():
			var w: Array = pts[i]
			if w.size() > 3 and w[3] != null:
				last = w[3]
			elif i > 0 and (absf(w[1] - pts[i - 1][1]) > 0.01 or absf(w[2] - pts[i - 1][2]) > 0.01):
				last = atan2(w[1] - pts[i - 1][1], w[2] - pts[i - 1][2])
			yaws.append(last)
		return func(u: float) -> Dictionary:
			var t := u * d
			var i := 0
			while i < pts.size() - 1 and t >= pts[i + 1][0]:
				i += 1
			var a: Array = pts[i]
			var pose_a: String = a[4] if a.size() > 4 else ""
			if i == pts.size() - 1 or t < pts[0][0]:
				return {"pos": C.gv(a[1], a[2]), "yaw": yaws[i], "pose": pose_a if pose_a != "" else "Idle", "visible": true}
			var n: Array = pts[i + 1]
			var k := clampf((t - a[0]) / maxf(n[0] - a[0], 0.001), 0.0, 1.0)
			var moving: bool = absf(n[1] - a[1]) > 0.01 or absf(n[2] - a[2]) > 0.01
			var x: float = lerpf(a[1], n[1], k)
			var z: float = lerpf(a[2], n[2], k)
			var yaw: float = atan2(n[1] - a[1], n[2] - a[2]) if moving else yaws[i]
			var pose: String = pose_a if pose_a != "" else ("Walk" if moving else "Idle")
			return {"pos": C.gv(x, z), "yaw": yaw, "pose": pose, "visible": true}
	# a creature / actor visible only between t0 and t1 (seconds into the shot)
	var seen := func(fn: Callable, d: float, t0: float, t1: float) -> Callable:
		return func(u: float) -> Dictionary:
			var st: Dictionary = fn.call(u)
			st["visible"] = u * d >= t0 and u * d <= t1
			return st
	var note := func(at: float, dur: float, n: Array) -> Dictionary:
		return {"at": at, "dur": dur, "title": n[0], "body": n[1]}
	# floodlights: [[seconds after t, energy], ...] for all five lamps
	var flood := func(t: float, vals: Array) -> void:
		for i in 5:
			for v in vals:
				ch.state(D10 + "FloodLights/Flood_%d:light_energy" % i, t + v[0] + i * 0.05, v[1])

	# ---- the state at the start of the chapter -------------------------------
	for i in 5:
		ch.state(D10 + "FloodLights/Flood_%d:light_energy" % i, 0.0, 0.0)
	ch.state(D10 + "DigRadio/Light:light_energy", 0.0, 0.0)
	ch.state(D10 + "LiftConsole/ScreenRed:visible", 0.0, true)
	ch.state(D10 + "LiftConsole/ScreenGreen:visible", 0.0, false)
	ch.state(D10 + "FuelCan:visible", 0.0, true)
	ch.state(D11 + "Keycard:visible", 0.0, true)
	ch.state(D11 + "Flare/Light:light_energy", 0.0, 0.0)
	var gen_pos := C.gv(-192.0, -326.0)
	ch.key(D10 + "Generator:position", 0.0, gen_pos)
	var lp: Array = C.lift_path()
	var lift_at := func(s: float) -> Vector3:
		var k := clampf(s, 0.0, float(lp.size() - 1))
		var i := mini(int(floor(k)), lp.size() - 2)
		var a: Vector3 = lp[i]
		var c: Vector3 = lp[i + 1]
		return a.lerp(c, k - float(i)) - Vector3(0, 0.8, 0)
	ch.key(D10 + "Lift:position", 0.0, lift_at.call(0.0))

	ch.scene("Chapter 4", {"d": 4.0, "card": ["Chapter 4", "The Old Village", ""]})

	# 1 ------------------------------------------------------------ waking up
	ch.scene("Waking up", {
		"area": "A08_HollowEdge", "d": 14.0, "fade": "in",
		"actor": func(u: float) -> Dictionary:
			return {"pos": C.gv(L.x, L.y), "yaw": PI, "pose": "Crouch" if u < 0.55 else "Idle", "visible": true},
		"cam": Chap.fixed(C.gv(L.x + 2.6, L.y + 2.2, 1.2), C.gv(L.x, L.y, 0.9)),
		"subs": [Chap.thought(T4["wake"], 5.5), Chap.thought(T4["drag"], 9.0)],
		"cues": [
			[0.0, func(t: float): ch.call_at(t, "blur_to", [5.0, 0.05])],
			[0.4, func(t: float): ch.sfx(t, "Breathing, ragged. A high ringing in the ears.", 3.0)],
			[3.0, func(t: float): ch.call_at(t, "blur_to", [0.0, 3.5])],
			[8.0, func(t: float): ch.sfx(t, "Wind sighing through the stones of the hollow", 3.0)],
		],
	})

	# 2 ------------------------------------------------------------ the hollow: lamps above, the buried steps
	var d2 := 22.0
	var w2: Array = wps.call(1.5, 1.6, [[L.x, L.y], [-129.5, -334.0], [C.STEPS_X + 0.4, -349.4]])
	ch.scene("The hollow", {
		"area": "A08_HollowEdge", "d": d2,
		"actor": timed.call(w2, d2),
		"cam": Chap.follow(5.0, 2.3, 3.0),
		"subs": [Chap.thought(T4["lamps"], 2.5), Chap.thought(T4["buried"], 14.5)],
		"cues": [
			[0.5, func(t: float): ch.sfx(t, "Far above: the faint hum of the lit path's lamps", 3.0)],
			[17.0, func(t: float): ch.sfx(t, "Loose stones tick down the rockfall and stop", 2.5)],
		],
	})

	# 3 ------------------------------------------------------------ the first houses
	var d3 := 20.0
	var w3: Array = wps.call(0.5, 1.8, [[C.STEPS_X + 0.4, -349.4], [-135.0, -338.0], [-146.0, -335.2], [-152.4, -335.2]])
	ch.scene("The first houses", {
		"area": "A08_HollowEdge", "areas": ["A09_VillageLanes"], "d": d3,
		"actor": timed.call(w3, d3),
		"cam": Chap.follow(4.5, 2.2, 3.0),
		"subs": [Chap.thought(T4["houses"], 8.5)],
		"cues": [[0.5, func(t: float): ch.sfx(t, "Silence. Water dripping into the well.", 3.0)]],
	})

	# 4 ------------------------------------------------------------ the year marks (find C)
	var d4 := 14.0
	var w4: Array = wps.call(1.0, 1.2, [[-152.4, -335.2], [-153.1, -337.8]])
	ch.scene("The year marks", {
		"area": "A09_VillageLanes", "d": d4,
		"actor": timed.call(w4, d4),
		"cam": Chap.fixed(C.gv(-150.6, -336.2, 1.7), C.gv(-153.1, -340.7, 1.3)),
		"subs": [Chap.thought(T4["marks"], 3.5), Chap.thought(T4["marks2"], 9.0)],
		"cues": [[7.0, func(t: float): ch.sfx(t, "Fingertips on the cut strokes. The last row stops mid-group.", 3.0)]],
	})

	# 5 ------------------------------------------------------------ the healing wall (find B)
	var d5 := 19.0
	var w5: Array = wps.call(0.5, 2.0, [[-153.1, -337.8], [-162.0, -336.3], [-173.0, -336.0], [-173.1, -337.4]])
	ch.scene("The healing wall", {
		"area": "A09_VillageLanes", "d": d5,
		"actor": timed.call(w5, d5),
		"cams": [
			[0.0, 0.6, Chap.follow(4.0, 2.2, 2.5)],
			[0.6, 1.0, Chap.fixed(C.gv(-170.5, -333.2, 1.8), C.gv(-173.0, -339.0, 1.4))],
		],
		"subs": [Chap.thought(T4["healing"], 11.5)],
		"cues": [[11.5, func(t: float): ch.sfx(t, "A faint glow in the carved crystals, or the moon on the stone", 3.0)]],
	})

	# 6 ------------------------------------------------------------ the guest house, the log (find D)
	var d6 := 36.0
	var w6: Array = wps.call(0.5, 1.4, [[-173.1, -337.4], [-169.0, -333.5], [-168.0, -329.8], [-168.0, -326.6], [-166.6, -326.0]])
	ch.scene("The guest house", {
		"area": "A09_VillageLanes", "d": d6,
		"actor": timed.call(w6, d6),
		"cams": [
			[0.0, 0.3, Chap.fixed(C.gv(-176.0, -332.5, 2.4), C.gv(-168.0, -329.0, 1.2))],
			[0.3, 1.0, Chap.fixed(C.gv(-171.9, -323.4, 2.4), C.gv(-165.0, -325.8, 0.9))],
		],
		"subs": [Chap.thought(T4["guest"], 6.0), Chap.thought(T4["log"], 12.2), Chap.thought(T4["creak"], 31.4)],
		"notes": [
			note.call(13.0, 6.0, S.LOG_PAGES[0]),
			note.call(19.5, 6.0, S.LOG_PAGES[1]),
			note.call(26.0, 5.0, S.LOG_PAGES[2]),
		],
		"cues": [
			[4.0, func(t: float): ch.sfx(t, "Old beds, laid out in a row. Dust. A rusted lantern.", 3.0)],
			[31.0, func(t: float): ch.sfx(t, "CREAK — a floorboard, overhead. There is no overhead.", 2.5)],
		],
	})

	# 7 ------------------------------------------------------------ the figure in the window
	var d7 := 14.0
	var yaw_look := atan2(-1.4, -8.5)
	var w7: Array = [[0.0, -166.6, -326.0, yaw_look], [9.0, -166.6, -326.0]] + wps.call(9.0, 1.4, [[-166.6, -326.0], [-168.0, -328.2], [-168.0, -331.5]]).slice(1)
	ch.scene("The figure in the window", {
		"area": "A09_VillageLanes", "d": d7,
		"actor": timed.call(w7, d7),
		"cam": Chap.fixed(C.gv(-166.8, -323.4, 1.9), C.gv(-168.0, -334.5, 1.3)),
		"creature": seen.call(timed.call([[0.0, -168.0, -334.6, 0.0]], d7), d7, 3.4, 7.4),
		"subs": [Chap.thought(T4["window"], 4.0), Chap.thought(T4["gone"], 9.5)],
		"cues": [
			[3.4, func(t: float): ch.sfx(t, "Stinger (low) — a tall figure in a long coat, standing in the lane", 2.5)],
			[7.6, func(t: float): ch.sfx(t, "The lane is empty. Coat-hem prints in the mud.", 2.5)],
		],
	})

	# 8 ------------------------------------------------------------ the festival ring (find A)
	var d8 := 24.0
	var w8: Array = wps.call(0.5, 1.9, [[-168.0, -331.5], [-176.0, -335.0], [-186.0, -335.5], [-193.0, -336.5], [-197.5, -337.4], [-202.4, -338.4]])
	ch.scene("The festival ring", {
		"area": "A10_FestivalRing", "areas": ["A09_VillageLanes"], "d": d8,
		"actor": timed.call(w8, d8),
		"cams": [
			[0.0, 0.7, Chap.follow(4.5, 2.3, 3.0)],
			[0.7, 1.0, Chap.fixed(C.gv(-197.5, -344.0, 2.6), C.gv(-205.0, -335.0, 1.2))],
		],
		"subs": [Chap.thought(T4["ring"], 19.5)],
		"cues": [
			[3.0, func(t: float): ch.sfx(t, "The wind drops. The ring of stones stands ahead, very still.", 3.0)],
			[18.0, func(t: float): ch.sfx(t, "Open hands carved on every inward face; three empty sockets", 3.0)],
		],
	})

	# 9 ------------------------------------------------------------ the dig site (find E)
	var d9 := 24.0
	var w9: Array = wps.call(1.0, 1.4, [[-202.4, -338.4], [-201.0, -343.5], [-199.5, -346.0], [-197.5, -349.8], [-196.6, -351.3]])
	ch.scene("The dig site", {
		"area": "A10_FestivalRing", "d": d9,
		"actor": timed.call(w9, d9),
		"cams": [
			[0.0, 0.5, Chap.follow(4.2, 2.4, 2.5)],
			[0.5, 1.0, Chap.fixed(C.gv(-192.5, -348.2, 2.0), C.gv(-196.4, -352.6, 1.0))],
		],
		"subs": [Chap.thought(T4["dig"], 5.0)],
		"notes": [
			note.call(1.5, 5.0, S.DIG_TAG),
			note.call(13.5, 8.0, S.DIG_LOG),
		],
		"cues": [[7.0, func(t: float): ch.sfx(t, "Orange tape snaps in the wind. Fresh spoil heaps.", 3.0)]],
	})

	# 10 ----------------------------------------------------------- the generator
	var d10 := 26.0
	var p10a: Array = wps.call(1.0, 1.3, [[-196.6, -351.3], [-198.2, -348.0]])
	var p10b: Array = wps.call(5.0, 1.9, [[-198.2, -348.0], [-196.0, -340.0], [-193.0, -332.0], [-192.0, -328.0]])
	var w10: Array = [[0.0, -196.6, -351.3, PI]] + p10a + [[5.0, -198.2, -348.0]] + p10b.slice(1)
	ch.scene("The generator", {
		"area": "A10_FestivalRing", "d": d10,
		"actor": timed.call(w10, d10),
		"cams": [
			[0.0, 0.2, Chap.fixed(C.gv(-193.0, -347.5, 2.0), C.gv(-198.0, -348.5, 0.9))],
			[0.2, 0.62, Chap.follow(4.5, 2.3, 3.0)],
			[0.62, 1.0, Chap.fixed(C.gv(-187.5, -331.5, 2.0), C.gv(-192.0, -327.2, 1.0))],
		],
		"subs": [Chap.thought(T4["genUp"], 16.2), Chap.thought(T4["genLoud"], 21.5)],
		"cues": [
			[4.4, func(t: float): ch.state(D10 + "FuelCan:visible", t, false)],
			[17.5, func(t: float): ch.sfx(t, "A fist of fuel into the tank. The cord, once, twice...", 2.5)],
			[19.5, func(t: float):
				ch.sfx(t, "ROAR — the generator catches. The whole hollow rings with it.", 3.0)
				for k in 24:
					ch.key(D10 + "Generator:position", t + k * 0.1, gen_pos + Vector3(0, ((k % 2) * 2 - 1) * 0.012, 0))
				ch.key(D10 + "Generator:position", t + 2.5, gen_pos)],
			[20.5, func(t: float): flood.call(t, [[0.0, 0.0], [0.1, 3.0], [0.25, 0.4], [0.4, 5.0], [0.55, 1.0], [0.8, 6.0]])],
			[23.5, func(t: float): ch.sfx(t, "Far off in the dark: loose stone clatters. Something has heard.", 3.0)],
		],
	})

	# 11 ----------------------------------------------------------- the radio (the owner's first voice)
	var d11 := 34.0
	var w11: Array = wps.call(0.5, 1.9, [[-192.0, -328.0], [-193.5, -338.0], [-195.0, -346.0], [-196.6, -351.3]])
	var talk := Chap.talk(S.OWNER_RADIO, 15.5)
	var radio_cues := [[14.0, func(t: float): ch.sfx(t, "Static. Under it, a voice you know.", 2.0)]]
	for l in talk:
		var at: float = l["at"]
		var dur: float = l["dur"]
		radio_cues.append([at, func(t: float): ch.state(D10 + "DigRadio/Light:light_energy", t, 1.4)])
		radio_cues.append([at + dur, func(t: float): ch.state(D10 + "DigRadio/Light:light_energy", t, 0.0)])
	ch.scene("The radio", {
		"area": "A10_FestivalRing", "d": d11,
		"actor": timed.call(w11, d11),
		"cams": [
			[0.0, 0.4, Chap.follow(4.5, 2.3, 3.0)],
			[0.4, 1.0, Chap.fixed(C.gv(-193.6, -349.0, 1.7), C.gv(-196.6, -352.4, 1.1))],
		],
		"subs": talk,
		"cues": radio_cues,
	})

	# 12 ----------------------------------------------------------- the wrong code
	var d12 := 24.0
	var w12: Array = wps.call(0.5, 1.5, [[-196.6, -351.3], [-203.0, -350.8], [-208.4, -350.9], [-208.7, -352.2]])
	ch.scene("The wrong code", {
		"area": "A10_FestivalRing", "d": d12,
		"actor": timed.call(w12, d12),
		"cams": [
			[0.0, 0.4, Chap.follow(4.0, 2.2, 2.5)],
			[0.4, 1.0, Chap.fixed(C.gv(-205.8, -349.2, 1.8), C.gv(-208.8, -353.2, 1.3))],
		],
		"subs": [Chap.thought(T4["radio"], 0.8), Chap.thought(T4["code"], 5.0), Chap.thought(T4["wrong"], 17.0)],
		"notes": [note.call(10.0, 7.0, S.NOTE_LIFT_BAD)],
		"cues": [[11.0, func(t: float): ch.sfx(t, "Four beeps, then one long one: INVALID", 2.5)]],
	})

	# 13 ----------------------------------------------------------- the burned quarter (find F)
	var d13 := 30.0
	var w13: Array = wps.call(0.5, 1.2, [[-208.7, -352.2], [-212.0, -342.0], [-220.0, -336.5], [-225.3, -335.2]])
	ch.scene("The burned quarter", {
		"area": "A11_BurnedQuarter", "areas": ["A10_FestivalRing"], "d": d13,
		"actor": timed.call(w13, d13),
		"cams": [
			[0.0, 0.7, Chap.follow(5.2, 2.5, 3.5)],
			[0.7, 1.0, Chap.fixed(C.gv(-221.5, -331.0, 2.0), C.gv(-228.0, -335.0, 0.8))],
		],
		"subs": [Chap.thought(T4["burned"], 14.0), Chap.thought(T4["bones"], 23.0)],
		"cues": [
			[8.0, func(t: float): ch.sfx(t, "The wind drops. The air smells of old smoke.", 3.0)],
			[22.5, func(t: float): ch.sfx(t, "Bones, heaped together as if gathered. One hand still closed.", 3.0)],
		],
	})

	# 14 ----------------------------------------------------------- the keycard
	var d14 := 20.0
	var w14: Array = [[0.3, -225.3, -335.2], [3.6, -225.2, -331.2], [4.0, -225.2, -331.2, null, "Crouch"]]
	ch.scene("The keycard", {
		"area": "A11_BurnedQuarter", "d": d14,
		"actor": timed.call(w14, d14),
		"cam": Chap.fixed(C.gv(-222.4, -333.2, 1.7), C.gv(-226.2, -330.5, 0.5)),
		"subs": [Chap.thought(T4["guard"], 4.5), Chap.thought(T4["flare"], 13.5)],
		"notes": [note.call(7.0, 5.5, S.NOTE_KEYCARD)],
		"cues": [
			[7.5, func(t: float): ch.state(D11 + "Keycard:visible", t, false)],
			[15.5, func(t: float):
				for f in [[0.0, 0.3], [0.2, 2.0], [0.4, 0.5], [0.7, 4.0]]:
					ch.state(D11 + "Flare/Light:light_energy", t + f[0], f[1])
				ch.sfx(t, "The flare spits, flares red, and the quarter jumps out of the dark", 3.0)],
		],
	})

	# 15 ----------------------------------------------------------- it stands there (the creature is a man)
	var d15 := 20.0
	ch.scene("It stands there", {
		"area": "A11_BurnedQuarter", "d": d15,
		"actor": timed.call([[0.0, -225.2, -331.2, -1.69, "Crouch"]], d15),
		"cam": Chap.fixed(C.gv(-222.6, -329.2, 1.6), C.gv(-232.0, -332.0, 1.4)),
		"creature": func(u: float) -> Dictionary:
			var t := u * d15
			return {"visible": t >= 2.5 and t <= 16.2, "pos": C.gv(-232.0, -332.0), "yaw": lerpf(-PI / 2.0, PI / 2.0, C.ss(9.0, 12.0, t))},
		"subs": [Chap.thought(T4["stands"], 3.5)],
		"cues": [
			[2.5, func(t: float): ch.sfx(t, "Stinger — a tall figure in a long coat, back turned, in the red light", 3.0)],
			[9.0, func(t: float): ch.sfx(t, "It begins to turn. A brass button catches the flare.", 3.0)],
			[14.5, func(t: float):
				for f in [[0.0, 0.2], [0.25, 4.0], [0.5, 0.1], [0.9, 4.0]]:
					ch.state(D11 + "Flare/Light:light_energy", t + f[0], f[1])],
			[16.2, func(t: float): ch.sfx(t, "Nothing there. Wet coat-prints leading away.", 2.5)],
		],
	})

	# 16 ----------------------------------------------------------- the last carving (find G)
	var d16 := 24.0
	var w16: Array = wps.call(0.5, 1.1, [[-225.2, -331.2], [-229.5, -334.2], [-234.4, -335.2]])
	ch.scene("The last carving", {
		"area": "A11_BurnedQuarter", "d": d16,
		"actor": timed.call(w16, d16),
		"creature": seen.call(timed.call([[0.0, -225.0, -335.2, -PI / 2.0]], d16), d16, 18.0, 24.0),
		"cams": [
			[0.0, 0.72, Chap.fixed(C.gv(-230.8, -339.3, 1.9), C.gv(-235.5, -334.8, 1.6))],
			[0.72, 1.0, Chap.fixed(C.gv(-233.5, -329.5, 2.0), C.gv(-225.0, -335.2, 1.4))],
		],
		"subs": [Chap.thought(T4["carving"], 10.5)],
		"cues": [
			[10.0, func(t: float): ch.sfx(t, "The carving: the tall giver turns him black. A man on a cord. A stone rising from the sea.", 4.0)],
			[18.0, func(t: float): ch.sfx(t, "Stinger — slow steps in the ash, close behind", 2.5)],
		],
	})

	# 17 ----------------------------------------------------------- it hunts
	var d17 := 34.0
	var w17: Array = wps.call(0.8, 1.5, [[-234.4, -335.2], [-233.5, -331.5], [-231.2, -329.8], [-232.4, -326.4]])
	w17 = w17 + [[8.2, -232.4, -326.4, null, "Crouch"]]
	var c17: Array = [[0.0, -225.0, -335.2, -PI / 2.0], [10.0, -231.0, -332.0], [11.0, -231.0, -331.2, -0.28], [16.0, -231.0, -331.2], [19.0, -234.5, -334.5], [24.0, -235.5, -333.0, PI / 2.0]]
	ch.scene("It hunts", {
		"area": "A11_BurnedQuarter", "d": d17,
		"actor": timed.call(w17, d17),
		"creature": timed.call(c17, d17),
		"cams": [
			[0.0, 0.23, Chap.follow(4.0, 2.2, 3.0)],
			[0.23, 1.0, Chap.fixed(C.gv(-227.8, -322.0, 2.4), C.gv(-231.5, -329.5, 1.2))],
		],
		"subs": [Chap.thought(T4["hide"], 8.5)],
		"cues": [
			[11.0, func(t: float): ch.sfx(t, "Footfalls in the ash, slowing at the doorway", 3.0)],
			[13.0, func(t: float): ch.sfx(t, "A long, slow sniff. The air tastes of him.", 3.0)],
			[16.5, func(t: float): ch.sfx(t, "It turns away", 2.0)],
			[25.0, func(t: float): ch.sfx(t, "It stands at the carving, watching the lane", 3.0)],
		],
	})

	# 18 ----------------------------------------------------------- the real code
	var d18 := 50.0
	var p18: Array = wps.call(4.0, 1.3, [[-232.4, -326.4], [-230.5, -329.8], [-226.0, -335.0], [-214.0, -340.0], [-203.0, -346.0], [-197.0, -351.3]])
	var w18: Array = [[0.0, -232.4, -326.4, null, "Crouch"]] + p18
	var c18: Array = [[0.0, -235.5, -333.0, PI / 2.0], [22.0, -235.5, -333.0], [50.0, -214.0, -338.0]]
	ch.scene("The real code", {
		"area": "A10_FestivalRing", "areas": ["A11_BurnedQuarter"], "d": d18,
		"actor": timed.call(w18, d18),
		"creature": seen.call(timed.call(c18, d18), d18, 22.0, 50.0),
		"cams": [
			[0.0, 0.12, Chap.fixed(C.gv(-229.0, -322.0, 2.4), C.gv(-232.4, -326.4, 0.8))],
			[0.12, 0.74, Chap.follow(5.0, 2.4, 3.5)],
			[0.74, 1.0, Chap.fixed(C.gv(-193.6, -349.2, 1.7), C.gv(-196.6, -352.4, 1.1))],
		],
		"subs": [Chap.thought(T4["realCode"], 41.5)],
		"notes": [note.call(38.5, 7.0, S.DIG_LAST_PAGE)],
		"cues": [
			[22.0, func(t: float): ch.sfx(t, "Slow footsteps far behind, in the ash", 3.0)],
			[37.5, func(t: float): ch.sfx(t, "The radio is silent now, but its dial is still red", 3.0)],
		],
	})

	# 19 ----------------------------------------------------------- the cargo lift
	var d19 := 44.0
	var ride0 := 18.5
	var ride_len := 18.0
	var n := lp.size() - 1
	var path_to_console: Array = wps.call(0.5, 1.6, [[-197.0, -351.3], [-203.0, -350.8], [-208.4, -350.9], [-208.7, -352.2]])
	var path_to_platform: Array = wps.call(14.0, 1.3, [[-208.7, -352.2], [-211.0, -354.4], [-212.0, -355.6]])
	var w19: Array = [[0.0, -197.0, -351.3, 2.29]] + path_to_console + [[14.0, -208.7, -352.2]] + path_to_platform.slice(1)
	var ground_walk: Callable = timed.call(w19, d19)
	var top: Vector3 = lp.back()
	var landing := Vector3(C.LIFT_X, top.y - 0.75 + 0.08, C.LIFT_Z1 - 1.8)
	var c19: Array = [[12.0, -206.0, -338.0], [30.0, -211.3, -349.8, PI]]
	ch.scene("The cargo lift", {
		"area": "A10_FestivalRing", "d": d19,
		"actor": func(u: float) -> Dictionary:
			var t := u * d19
			if t < ride0:
				return ground_walk.call(u)
			var s := clampf((t - ride0) / ride_len, 0.0, 1.0) * n
			if t < ride0 + ride_len:
				return {"pos": lift_at.call(s) + Vector3(0, 0.08, 0), "yaw": PI, "pose": "Idle", "visible": true}
			var k := clampf((t - ride0 - ride_len) / 3.0, 0.0, 1.0)
			var p: Vector3 = lift_at.call(float(n)) + Vector3(0, 0.08, 0)
			return {"pos": p.lerp(landing, k), "yaw": PI, "pose": "Walk" if k < 1.0 else "Idle", "visible": true},
		"creature": seen.call(timed.call(c19, d19), d19, 12.0, 44.0),
		"cams": [
			[0.0, 0.27, Chap.follow(4.0, 2.2, 2.5)],
			[0.27, 0.40, Chap.fixed(C.gv(-206.2, -349.8, 1.8), C.gv(-210.6, -354.2, 1.6))],
			[0.40, 0.85, func(u: float, _st: Dictionary) -> Dictionary:
				var s := clampf((u * d19 - ride0) / ride_len, 0.0, 1.0) * n
				var p: Vector3 = lift_at.call(s)
				return {"pos": C.gv(-206.5, -349.0, 2.4), "look": p + Vector3(0, 1.4, 0)}],
			[0.85, 1.0, Chap.fixed(Vector3(C.LIFT_X + 4.0, top.y + 1.0, C.LIFT_Z1 - 0.5), Vector3(-211.3, C.G(-211.3, -349.8) + 1.5, -349.8))],
		],
		"subs": [Chap.thought(T4["lift"], 19.0), Chap.thought(T4["top"], 40.0)],
		"notes": [note.call(10.0, 6.0, S.NOTE_LIFT_GOOD)],
		"cues": [
			[10.6, func(t: float):
				ch.state(D10 + "LiftConsole/ScreenRed:visible", t, false)
				ch.state(D10 + "LiftConsole/ScreenGreen:visible", t, true)
				ch.sfx(t, "A long green beep: CODE ACCEPTED", 2.5)],
			[17.8, func(t: float): ch.sfx(t, "The safety gate clangs shut", 2.0)],
			[ride0, func(t: float):
				ch.sfx(t, "Motor whine. The platform lurches and starts to climb the wall.", 3.0)
				var k := 0.0
				while k <= ride_len + 0.001:
					ch.key(D10 + "Lift:position", t + k, lift_at.call(clampf(k / ride_len, 0.0, 1.0) * n))
					k += 0.5],
			[28.0, func(t: float): ch.sfx(t, "Below, in the floodlights: it has reached the foot of the lift. It stops.", 3.0)],
			[34.0, func(t: float):
				ch.sfx(t, "The generator coughs and dies. The floodlights go out one by one.", 3.0)
				flood.call(t, [[0.0, 2.0], [0.2, 0.0], [0.45, 3.0], [0.7, 0.0]])],
			[40.5, func(t: float): ch.call_at(t, "fade_out", [1.5])],
		],
	})
	ch.scene("End of Chapter 4 so far", {"d": 6.0, "card": ["", "End of Chapter 4 (so far)", "Next: the lit service path, the stream and the forest."]})
	ch.finish()
	save(ch, "ch04_the_old_village", 4)
