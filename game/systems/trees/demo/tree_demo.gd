extends Node3D
## Tree system showcase: a row of every preset (realistic behind, stylized in front) and two forests
## (realistic north, stylized south). Fly: hold right mouse + WASD, Q/E down/up, Shift fast.
## 1 calm · 2 breeze · 3 storm · F toggle forests · H hide HUD (fps, draw calls, triangles) · Esc quit.
##
## Benchmark (flies through both forests, prints averages; add --no-shadows or --only=realistic|stylized):
##   godot --path . --disable-vsync res://game/systems/trees/demo/tree_demo.tscn -- --bench
## Screenshots: ... -- --shots=/abs/dir --views="x,y,z,lx,ly,lz;..."

const WIND := [Vector2(0.15, 0.3), Vector2(0.6, 0.6), Vector2(1.8, 1.0)]  # strength, gustiness

@onready var cam: Camera3D = $Camera
@onready var hud: Label = $HUD/Stats
@onready var wind: TreeWind = $TreeWind

var yaw := 0.0
var pitch := -0.08
var looking := false
var hud_on := true

var shot_dir := ""
var views := []
var view_i := -1
var hold := 0

var bench := false
var bench_t := 0.0
var bench_log := []  # [fps, draws, prims]
const BENCH_PATH := [Vector3(-20, 0, -45), Vector3(-20, 0, -230), Vector3(40, 0, -230), Vector3(40, 0, -60),
	Vector3(-20, 0, 45), Vector3(-20, 0, 230), Vector3(40, 0, 230), Vector3(40, 0, 60)]
const BENCH_SPEED := 14.0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--bench":
			bench = true
		elif a == "--no-shadows":
			$Sun.shadow_enabled = false
		elif a.begins_with("--lod="):
			var d := a.get_slice("=", 1).split_floats(",")
			for f in [$RealisticForest, $StylizedForest]:
				f.lod_distances = Vector3(d[0], d[1], d[2])
		elif a.begins_with("--only="):
			$RealisticForest.visible = a.ends_with("realistic")
			$StylizedForest.visible = a.ends_with("stylized")
		elif a.begins_with("--shots="):
			shot_dir = a.get_slice("=", 1)
		elif a.begins_with("--views="):
			for v in a.get_slice("=", 1).split(";"):
				var f := v.split_floats(",")
				views.append([Vector3(f[0], f[1], f[2]), Vector3(f[3], f[4], f[5])])
	if bench or not shot_dir.is_empty():
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	yaw = cam.rotation.y
	pitch = cam.rotation.x


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_RIGHT:
		looking = e.pressed
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if looking else Input.MOUSE_MODE_VISIBLE
	elif e is InputEventMouseMotion and looking:
		yaw -= e.relative.x * 0.003
		pitch = clampf(pitch - e.relative.y * 0.003, -1.5, 1.5)
	elif e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_1, KEY_2, KEY_3:
				var w: Vector2 = WIND[e.keycode - KEY_1]
				wind.strength = w.x
				wind.gustiness = w.y
			KEY_F:
				for f in [$RealisticForest, $StylizedForest]:
					f.visible = not f.visible
			KEY_H:
				hud_on = not hud_on
				$HUD.visible = hud_on
			KEY_ESCAPE:
				get_tree().quit()


func _process(delta: float) -> void:
	if not shot_dir.is_empty():
		_shots()
	elif bench:
		_bench(delta)
	else:
		_fly(delta)
	cam.rotation = Vector3(pitch, yaw, 0.0)
	if hud_on:
		var trees := 0
		for f in [$RealisticForest, $StylizedForest]:
			trees += f.instance_count
		var vp := get_viewport().get_viewport_rid()
		hud.text = "%d fps   gpu %.2f ms   cpu %.2f ms\ndraw calls %d   triangles %s   objects %d\ntrees %d   wind %.2f\n%s" % [
			Engine.get_frames_per_second(), RenderingServer.viewport_get_measured_render_time_gpu(vp),
			RenderingServer.viewport_get_measured_render_time_cpu(vp) + RenderingServer.get_frame_setup_time_cpu(),
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			String.humanize_size(int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))).replace("B", ""),
			Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME), trees, wind.strength,
			"RMB+WASD fly · Shift fast · 1/2/3 wind · F forests · H hud"]


func _fly(delta: float) -> void:
	var v := Vector3(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_E)) - float(Input.is_key_pressed(KEY_Q)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W)))
	var speed := 30.0 if Input.is_key_pressed(KEY_SHIFT) else 8.0
	cam.position += Basis(Vector3.UP, yaw) * v * speed * delta


func _ground(p: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 300.0, p + Vector3.DOWN * 300.0)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return hit.position.y if hit else 0.0


func _bench(delta: float) -> void:
	bench_t += delta
	var seg_len := []
	var total := 0.0
	for i in BENCH_PATH.size() - 1:
		var l: float = BENCH_PATH[i].distance_to(BENCH_PATH[i + 1])
		seg_len.append(l)
		total += l
	var d := bench_t * BENCH_SPEED
	if d >= total:
		_bench_report()
		return
	var i := 0
	while d > seg_len[i]:
		d -= seg_len[i]
		i += 1
	var a: Vector3 = BENCH_PATH[i]
	var b: Vector3 = BENCH_PATH[i + 1]
	var p := a.lerp(b, d / seg_len[i])
	p.y = _ground(p) + 1.7
	cam.position = cam.position.lerp(p, minf(1.0, delta * 6.0)) if bench_t > 0.1 else p
	var dir := (b - a).normalized()
	yaw = lerp_angle(yaw, atan2(-dir.x, -dir.z), minf(1.0, delta * 2.0))
	pitch = -0.05
	if bench_t > 2.0:  # skip shader compile / startup frames
		var vp := get_viewport().get_viewport_rid()
		bench_log.append([1.0 / maxf(delta, 0.0001), Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), RenderingServer.viewport_get_measured_render_time_gpu(vp),
			RenderingServer.viewport_get_measured_render_time_cpu(vp) + RenderingServer.get_frame_setup_time_cpu()])


func _bench_report() -> void:
	var fps := []
	var gpu := []
	var draws := 0.0
	var prims := 0.0
	var cpu := 0.0
	for s in bench_log:
		fps.append(s[0])
		gpu.append(s[3])
		draws += s[1]
		prims += s[2]
		cpu += s[4]
	gpu.sort()
	fps.sort()
	var n := maxi(fps.size(), 1)
	var avg := 0.0
	for f in fps:
		avg += f
	var trees: int = $RealisticForest.instance_count + $StylizedForest.instance_count
	var gsum := 0.0
	for g in gpu:
		gsum += g
	print("TREE BENCH  trees %d  frames %d  avg fps %.0f  1%% low %.0f  avg draw calls %.0f  avg triangles %.0fk" % [
		trees, fps.size(), avg / n, fps[int(fps.size() * 0.01)] if fps.size() > 0 else 0.0, draws / n, prims / n / 1000.0])
	print("  gpu avg %.2f ms  p99 %.2f ms   render cpu avg %.2f ms   resolution %s" % [gsum / n,
		gpu[int(gpu.size() * 0.99)] if gpu.size() > 0 else 0.0, cpu / n, get_viewport().get_texture().get_size()])
	print("  GPU: %s" % RenderingServer.get_video_adapter_name())
	get_tree().quit()


func _shots() -> void:
	if hold > 0:
		hold -= 1
		if hold == 0:
			get_viewport().get_texture().get_image().save_png("%s/tree_shot_%02d.png" % [shot_dir, view_i])
		return
	view_i += 1
	if view_i >= views.size():
		get_tree().quit()
		return
	cam.position = views[view_i][0]
	cam.look_at(views[view_i][1])
	yaw = cam.rotation.y
	pitch = cam.rotation.x
	hold = 45 if view_i == 0 else 12
