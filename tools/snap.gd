extends Node3D
## Debug: render views of the blockout or a chapter to PNGs.
## godot --path . --write-movie /tmp/x.png --fixed-fps 1 res://tools/snap.tscn -- --views="x,y,z,lx,ly,lz;..."
##   or -- --chapter=res://previs/...tscn --times=1,5,20
var views := []
var times := []
var chapter: Node = null
var i := -1


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--views="):
			for v in a.get_slice("=", 1).split(";"):
				var f := v.split_floats(",")
				views.append([Vector3(f[0], f[1], f[2]), Vector3(f[3], f[4], f[5])])
		elif a.begins_with("--chapter="):
			chapter = (load(a.get_slice("=", 1)) as PackedScene).instantiate()
			if "--view=cinematic" in OS.get_cmdline_user_args():
				chapter.view = "cinematic"
			add_child(chapter)
		elif a.begins_with("--times="):
			times = Array(a.get_slice("=", 1).split_floats(","))
	if chapter == null:
		for f in DirAccess.get_directories_at("res://game/levels"):
			add_child(load("res://game/levels/%s/%s_blockout.tscn" % [f, f]).instantiate())
		var env := WorldEnvironment.new()
		var e := Environment.new()
		e.background_mode = Environment.BG_COLOR
		e.background_color = Color(0.3, 0.35, 0.42)
		e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		e.ambient_light_color = Color(0.6, 0.62, 0.66)
		env.environment = e
		add_child(env)
		var sun := DirectionalLight3D.new()
		sun.rotation = Vector3(-0.9, 0.6, 0)
		add_child(sun)
		var cam := Camera3D.new()
		cam.name = "SnapCam"
		cam.fov = 60
		add_child(cam)
		cam.current = true


func _process(_d: float) -> void:
	i += 1
	if chapter:
		if i >= times.size():
			get_tree().quit()
			return
		var tl := chapter.get_node("Timeline") as AnimationPlayer
		if not tl.is_playing():
			tl.play("play")
		chapter.seek_to(str(times[i]))
		tl.pause()
		return
	if i >= views.size():
		get_tree().quit()
		return
	var cam := get_node("SnapCam") as Camera3D
	cam.position = views[i][0]
	cam.look_at(views[i][1])
