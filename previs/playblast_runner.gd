extends Node
## Playblast runner — plays previs chapters in order: all, one, or an inclusive range.
##
## Command line (anything after `--`):
##   --from=2 --to=3     play chapters 2 through 3
##   --chapter=2         play only chapter 2
##   --at=s07_scaffold   start the first chapter at a shot marker (or --at=95 for seconds)
##   --view=cinematic    start in the cinematic cameras instead of first person
##   --list              print discovered chapters (and their shot markers) and quit
##   --quit              quit when the sequence ends
## Example:
##   godot --path <project> res://previs/playblast_runner.tscn -- --from=2 --to=3
##
## Debug keys: N = next chapter, R = restart chapter, Space = pause, V = first person / cinematic, Esc = quit.

const CHAPTERS_DIR := "res://previs/chapters"

@export var from_chapter: int = 1
@export var to_chapter: int = -1  ## -1 = last chapter
@export var quit_when_done: bool = false
## Start the first chapter at this shot marker name or time in seconds ("" = from the top).
@export var start_at: String = ""
@export_enum("first_person", "cinematic") var view: String = "first_person"

var _chapters: Array[Dictionary] = []  # { number, name, path }
var _current: Node = null
var _skip := false
var _restart := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(NarrationOverlay.new())
	_chapters = _discover_chapters()
	if _parse_args():
		return
	_run()


## Returns true if the runner should stop (e.g. --list).
func _parse_args() -> bool:
	var args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	for arg in args:
		if arg.begins_with("--from="):
			from_chapter = int(arg.get_slice("=", 1))
		elif arg.begins_with("--to="):
			to_chapter = int(arg.get_slice("=", 1))
		elif arg.begins_with("--chapter="):
			from_chapter = int(arg.get_slice("=", 1))
			to_chapter = from_chapter
		elif arg.begins_with("--view="):
			view = arg.get_slice("=", 1)
		elif arg.begins_with("--at="):
			start_at = arg.get_slice("=", 1)
		elif arg == "--quit":
			quit_when_done = true
		elif arg == "--list":
			for c in _chapters:
				print("  %02d  %s  (%s)" % [c["number"], c["name"], c["path"]])
				_print_shots(c)
			get_tree().quit()
			return true
	return false


func _discover_chapters() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var dir := DirAccess.open(CHAPTERS_DIR)
	if dir == null:
		push_error("[playblast] missing folder %s" % CHAPTERS_DIR)
		return out
	for folder in dir.get_directories():
		# Folders are named chNN_short_name.
		if not folder.begins_with("ch"):
			continue
		var num_str := folder.substr(2).get_slice("_", 0)
		if not num_str.is_valid_int():
			continue
		var scene_path := _find_chapter_scene(CHAPTERS_DIR.path_join(folder))
		if scene_path.is_empty():
			push_warning("[playblast] no chapterNN_*.tscn in %s" % folder)
			continue
		out.append({"number": int(num_str), "name": folder, "path": scene_path})
	out.sort_custom(func(a, b): return a["number"] < b["number"])
	return out


func _print_shots(c: Dictionary) -> void:
	var packed := load(c["path"]) as PackedScene
	if packed == null:
		return
	var inst := packed.instantiate()
	var timeline := inst.get_node_or_null("Timeline") as AnimationPlayer
	if timeline and timeline.has_animation("play"):
		var anim := timeline.get_animation("play")
		for m in anim.get_marker_names():
			print("        %7.1fs  %s" % [anim.get_marker_time(m), m])
	inst.free()


func _find_chapter_scene(folder: String) -> String:
	for f in DirAccess.get_files_at(folder):
		var clean := f.trim_suffix(".remap")
		if clean.begins_with("chapter") and clean.ends_with(".tscn"):
			return folder.path_join(clean)
	return ""


func _run() -> void:
	if _chapters.is_empty():
		push_error("[playblast] no chapters found")
		return
	var last: int = to_chapter if to_chapter > 0 else _chapters.back()["number"]
	var queue := _chapters.filter(
		func(c): return c["number"] >= from_chapter and c["number"] <= last)
	if queue.is_empty():
		push_error("[playblast] no chapters in range %d..%d" % [from_chapter, last])
		return

	print("[playblast] playing chapters %d..%d" % [from_chapter, last])
	var i := 0
	while i < queue.size():
		var restart_requested: bool = await _play_chapter(queue[i])
		if not restart_requested:
			i += 1

	print("[playblast] sequence finished")
	if quit_when_done:
		get_tree().quit()


## Plays one chapter to the end. Returns true if a restart was requested.
func _play_chapter(c: Dictionary) -> bool:
	var packed := load(c["path"]) as PackedScene
	if packed == null:
		push_error("[playblast] could not load %s" % c["path"])
		return false
	_current = packed.instantiate()
	_current.process_mode = Node.PROCESS_MODE_PAUSABLE
	if "view" in _current:
		_current.view = view
	add_child(_current)

	var timeline := _current.get_node_or_null("Timeline") as AnimationPlayer
	if timeline == null or not timeline.has_animation("play"):
		push_error("[playblast] %s has no Timeline/'play' animation" % c["name"])
		_current.queue_free()
		return false

	print("[playblast] > %s  (%.1fs)" % [c["name"], timeline.get_animation("play").length])
	timeline.play("play")
	if not start_at.is_empty() and _current.has_method("seek_to"):
		_current.seek_to(start_at)
		start_at = ""  # only the first chapter of the run starts mid-way
	while timeline.is_playing() and not _skip and not _restart:
		await get_tree().process_frame

	var restart_requested := _restart
	_skip = false
	_restart = false
	get_tree().paused = false
	_current.queue_free()
	_current = null
	get_tree().call_group("previs_narration", "clear")
	await get_tree().process_frame  # let the old chapter (and its camera) free first
	return restart_requested


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_N:
			_skip = true
		KEY_R:
			_restart = true
		KEY_SPACE:
			get_tree().paused = not get_tree().paused
		KEY_V:
			view = "cinematic" if view == "first_person" else "first_person"
			if _current and _current.has_method("set_view"):
				_current.set_view(view)
			print("[playblast] view: %s" % view)
		KEY_ESCAPE:
			get_tree().quit()
