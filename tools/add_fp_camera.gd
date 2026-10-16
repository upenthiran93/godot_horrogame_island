extends SceneTree
## Builds the first-person camera (Cam_FP) into every previs chapter that has an fp_gaze.json.
## The eye follows the protagonist's blocking already on the Timeline (position, facing, pose),
## and the gaze script says where the player looks. Edits the chapter scene in place:
## only the Cam_FP node, its two tracks and the `slats` method keys are replaced.
## Re-run after changing the protagonist's blocking or the gaze file:
##   godot --headless --path . --script res://tools/add_fp_camera.gd [-- --only=1]

const C := preload("res://tools/build_common.gd")
const CHAPTERS := "res://previs/chapters/"
const HERO := "Actors/Actor_Protagonist"
const DT := 0.1

var eye_h := 1.64
var crouch_h := 1.0
var anim: Animation


func _init() -> void:
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = "ch%02d_" % a.get_slice("=", 1).to_int()
	for folder in DirAccess.get_directories_at(CHAPTERS):
		if not only.is_empty() and not folder.begins_with(only):
			continue
		var gaze_path := CHAPTERS + folder + "/fp_gaze.json"
		if not FileAccess.file_exists(gaze_path):
			continue
		var scene := ""
		for f in DirAccess.get_files_at(CHAPTERS + folder):
			if f.begins_with("chapter") and f.ends_with(".tscn"):
				scene = CHAPTERS + folder + "/" + f
		if scene.is_empty():
			continue
		var gz = JSON.parse_string(FileAccess.get_file_as_string(gaze_path))
		if gz == null:
			push_error("bad JSON in " + gaze_path)
			continue
		build(scene, gz)
	quit()


func build(path: String, gz: Dictionary) -> void:
	eye_h = gz.get("eye_height", 1.64)
	crouch_h = gz.get("crouch_height", 1.0)
	var root: Node = (load(path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	var tl := root.get_node("Timeline") as AnimationPlayer
	anim = tl.get_animation("play")

	# drop the previous build
	for i in range(anim.get_track_count() - 1, -1, -1):
		if str(anim.track_get_path(i)).begins_with("Cam_FP:"):
			anim.remove_track(i)
	var mtrack := -1
	for i in anim.get_track_count():
		if anim.track_get_type(i) == Animation.TYPE_METHOD and str(anim.track_get_path(i)) == ".":
			mtrack = i
	for k in range(anim.track_get_key_count(mtrack) - 1, -1, -1):
		if anim.method_track_get_name(mtrack, k) == &"slats":
			anim.track_remove_key(mtrack, k)

	var cam := root.get_node_or_null("Cam_FP") as Camera3D
	if cam == null:
		cam = Camera3D.new()
		cam.name = "Cam_FP"
		root.add_child(cam)
		cam.owner = root
		root.move_child(cam, tl.get_index())
	cam.fov = 75
	cam.near = 0.03
	cam.far = 900
	cam.cull_mask = 0xFFFFF & ~(1 << 1)  # layer 2 = the protagonist's own body

	var pos_t := find_track(HERO + ":position")
	var rot_t := find_track(HERO + ":rotation")
	var pose_tracks := {}
	for p in ["Idle", "Walk", "Run", "Crouch", "Climb"]:
		var i := find_track(HERO + "/Pose_" + p + ":visible")
		if i >= 0:
			pose_tracks[p] = i

	# shots from the markers
	var names := Array(anim.get_marker_names())
	names.sort_custom(func(a, b): return anim.get_marker_time(a) < anim.get_marker_time(b))
	var shots_cfg: Dictionary = gz.get("shots", {})
	var pos_keys := []
	var rot_keys := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var cur_yaw := 0.0
	var cur_pitch := 0.0
	var cur_roll := 0.0
	var slats_on := false
	for si in names.size():
		var shot: String = names[si]
		var t0 := anim.get_marker_time(shot)
		var t1 := anim.length if si == names.size() - 1 else anim.get_marker_time(names[si + 1])
		var cfg: Dictionary = shots_cfg.get(shot, {})
		var segs: Array = cfg.get("gaze", [[0.0, "ahead"]])
		var shakes: Array = cfg.get("shakes", [])
		var samples := []
		var n := maxi(int(ceil((t1 - t0) / DT)), 1)
		var prev_eye := Vector3.INF
		var prev_seg := -1
		for i in n + 1:
			var t := minf(t0 + i * DT, t1 - 0.02)
			var local := t - t0
			var si2 := 0
			for k in segs.size():
				if segs[k][0] <= local + 0.0001:
					si2 = k
			var spec = segs[si2][1]
			if spec is String:
				spec = {}
			var hero: Vector3 = anim.value_track_interpolate(pos_t, t)
			var yaw: float = (anim.value_track_interpolate(rot_t, t) as Vector3).y
			var pose := "Idle"
			for p in pose_tracks:
				if discrete_at(pose_tracks[p], t):
					pose = p
			var eye := hero + Vector3(0, crouch_h if pose == "Crouch" else eye_h, 0)
			if spec.has("eye"):
				eye = v3(spec["eye"])
			elif spec.has("eyeg"):
				var e: Array = spec["eyeg"]
				eye = C.gv(e[0], e[1], e[2])
			# where to look
			var t_yaw: float
			var t_pitch: float
			var t_roll: float = float(spec.get("roll", 0.0))
			var target = null
			if spec.has("look"):
				target = v3(spec["look"])
			elif spec.has("lookg"):
				var l: Array = spec["lookg"]
				target = C.gv(l[0], l[1], l[2])
			elif spec.has("track"):
				var ti := find_track(spec["track"] + ":position")
				if ti >= 0:
					target = (anim.value_track_interpolate(ti, t) as Vector3) + Vector3(0, spec.get("dy", 0.0), 0)
			if target != null:
				var d: Vector3 = target - eye
				t_yaw = atan2(-d.x, -d.z)
				t_pitch = atan2(d.y, Vector2(d.x, d.z).length())
			else:
				# camera yaw faces the actor's +Z forward
				t_yaw = yaw + PI
				t_pitch = spec.get("pitch", 0.45 if pose == "Climb" else -0.12)
			# head turn: snap at a cut (new shot or eye jump), otherwise ease toward the target
			var cut := i == 0 or eye.distance_to(prev_eye) > 1.0
			if cut:
				cur_yaw = cur_yaw + wrapf(t_yaw - cur_yaw, -PI, PI)
				cur_pitch = t_pitch
				cur_roll = t_roll
				if i > 0:
					samples.append([t - 0.01, samples.back()[1], samples.back()[2]])
			else:
				var a := 1.0 - exp(-float(spec.get("turn", 4.0)) * DT)
				cur_yaw += wrapf(t_yaw - cur_yaw, -PI, PI) * a
				cur_pitch += (t_pitch - cur_pitch) * a
				cur_roll += (t_roll - cur_roll) * a
			var shaken := eye
			for s in shakes:
				if local >= s[0] and local <= s[1]:
					shaken += Vector3(rng.randf() - 0.5, rng.randf() - 0.5, rng.randf() - 0.5) * float(s[2])
			samples.append([t, shaken, Vector3(cur_pitch, cur_yaw, cur_roll)])
			prev_eye = eye
			# vents on/off at gaze segment changes
			if si2 != prev_seg:
				var want: bool = spec.get("slats", false)
				if want != slats_on or i == 0:
					insert_method(mtrack, t, "slats", [want])
					slats_on = want
				prev_seg = si2
		var noisy := not shakes.is_empty()
		pos_keys.append_array(samples.map(func(s): return [s[0], s[1]]) if noisy else simplify(samples.map(func(s): return [s[0], s[1]]), 0.02))
		rot_keys.append_array(simplify(samples.map(func(s): return [s[0], s[2]]), 0.004))

	var pi := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(pi, ^"Cam_FP:position")
	var ri := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ri, ^"Cam_FP:rotation")
	for k in pos_keys:
		anim.track_insert_key(pi, k[0], k[1])
	for k in rot_keys:
		anim.track_insert_key(ri, k[0], k[1])
	cam.position = pos_keys[0][1]
	cam.rotation = rot_keys[0][1]

	var ps := PackedScene.new()
	ps.pack(root)
	ResourceSaver.save(ps, path)
	print("  update %s  (Cam_FP: %d position / %d rotation keys)" % [path, pos_keys.size(), rot_keys.size()])
	root.free()


func find_track(path: String) -> int:
	for i in anim.get_track_count():
		if str(anim.track_get_path(i)) == path:
			return i
	return -1


func discrete_at(track: int, t: float):
	var v = null
	for k in anim.track_get_key_count(track):
		if anim.track_get_key_time(track, k) > t + 0.0001:
			break
		v = anim.track_get_key_value(track, k)
	return v


func insert_method(track: int, t: float, method: String, args: Array) -> void:
	var tt := snappedf(t, 0.01)
	while anim.track_find_key(track, tt, Animation.FIND_MODE_EXACT) >= 0:
		tt += 0.01
	anim.track_insert_key(track, tt, {"method": StringName(method), "args": args})


static func v3(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])


static func simplify(s: Array, tol: float) -> Array:
	if s.size() <= 2:
		return s
	var out := [s[0]]
	var a := 0
	var j := 2
	while j < s.size():
		var ok := true
		for i in range(a + 1, j):
			var f: float = (s[i][0] - s[a][0]) / maxf(s[j][0] - s[a][0], 0.0001)
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
