class_name PrevisChapter
extends Node3D
## Root script for every previs chapter.
## The Timeline's call_method tracks (path ".") call narrate(), clear_narration(), cut_to(),
## show_note(), card(), fade_out()/fade_in(), sfx() and slats().
## Run standalone (Run Current Scene) and the Timeline autoplays; under the runner, the runner plays it.
## The `play` animation carries one marker per shot, so playback can start at any shot.
##
## Two views of the same Timeline:
##   first_person — Cam_FP, the player's eyes (built by tools/add_fp_camera.gd from fp_gaze.json)
##   cinematic    — the per-shot cameras Cam_NN_*, switched by cut_to() keys
## Press V while playing to switch.

const FP_CAMERA := ^"Cam_FP"
const PROTAGONIST := ^"Actors/Actor_Protagonist"
## Render layer the protagonist's own body is moved to, so Cam_FP doesn't see it.
const SELF_LAYER := 2

@export var autoplay_standalone := true
## Standalone only: start at this shot marker (e.g. "s07_scaffold") or time in seconds ("95").
@export var start_at := ""
@export_enum("first_person", "cinematic") var view := "first_person"

var _cine_cam := NodePath()
var _slats := false
var _meta := {}            # chapter_meta.json next to this scene
var _shot_info := {}       # marker -> {name, area}
var _markers: Array = []   # [time, marker] sorted
var _slate_marker := "~"


func _ready() -> void:
	_load_meta()
	_hide_body_from_fp()
	set_view(view)
	if autoplay_standalone and get_parent() == get_tree().root:
		var timeline := get_node_or_null("Timeline") as AnimationPlayer
		if timeline and timeline.has_animation("play"):
			timeline.play("play")
			if not start_at.is_empty():
				seek_to(start_at)


func _unhandled_input(event: InputEvent) -> void:
	# Standalone only; under the runner the runner handles V.
	if get_parent() == get_tree().root and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_V:
		toggle_view()


func _process(_delta: float) -> void:
	_update_slate()


## Top-right slate: "CH 01 · SHOT 08 — The shrine / AREA 02 · Trail".
## Shot names and areas come from chapter_meta.json ("shots": [{marker, name, area}]).
func _update_slate() -> void:
	var timeline := get_node_or_null("Timeline") as AnimationPlayer
	if timeline == null or not timeline.has_animation("play") or _markers.is_empty():
		return
	var t := timeline.current_animation_position
	var marker := ""
	for m in _markers:
		if m[0] <= t + 0.001:
			marker = m[1]
	if marker == _slate_marker:
		return
	_slate_marker = marker
	var info: Dictionary = _shot_info.get(marker, {})
	var shot_num := marker.substr(1).get_slice("_", 0) if marker.begins_with("s") else "?"
	var title: String = info.get("name", marker.get_slice("_", 1).capitalize() if marker != "" else "")
	var text := "CH %02d · SHOT %s — %s" % [int(_meta.get("chapter", 0)), shot_num, title]
	var area: String = info.get("area", "")
	if not area.is_empty():
		text += "\n" + area
	_overlay().set_slate(text)


func _load_meta() -> void:
	var timeline := get_node_or_null("Timeline") as AnimationPlayer
	if timeline and timeline.has_animation("play"):
		var anim := timeline.get_animation("play")
		for m in anim.get_marker_names():
			_markers.append([anim.get_marker_time(m), String(m)])
		_markers.sort_custom(func(a, b): return a[0] < b[0])
	if scene_file_path.is_empty():
		return
	var path := scene_file_path.get_base_dir().path_join("chapter_meta.json")
	if not FileAccess.file_exists(path):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		_meta = parsed
		for s in _meta.get("shots", []):
			_shot_info[s.get("marker", "")] = s


## Show a subtitle line. hold <= 0 keeps it until the next line or clear_narration().
func narrate(text: String, hold: float = 3.0) -> void:
	_overlay().show_line(text, hold)


func clear_narration() -> void:
	_overlay().clear()


## Hard cut to another camera, e.g. cut_to(^"Cam_B"). In first-person view the cut is
## remembered but Cam_FP stays current.
func cut_to(camera_path: NodePath) -> void:
	_cine_cam = camera_path
	if _first_person():
		return
	var cam := get_node_or_null(camera_path) as Camera3D
	if cam:
		cam.make_current()
	else:
		push_warning("[previs] cut_to: no Camera3D at %s" % camera_path)


func set_view(mode: String) -> void:
	view = mode
	if _first_person():
		(get_node(FP_CAMERA) as Camera3D).make_current()
	elif not _cine_cam.is_empty():
		cut_to(_cine_cam)
	_overlay().set_slats(_slats and _first_person())


func toggle_view() -> void:
	set_view("cinematic" if view == "first_person" else "first_person")
	print("[previs] view: %s" % view)


## Locker vents over the screen (first-person view only).
func slats(on: bool) -> void:
	_slats = on
	_overlay().set_slats(on and _first_person())


## Readable document overlay (notes, memos, reports).
func show_note(title: String, body: String, hold: float = 6.0) -> void:
	_overlay().show_note(title, body, hold)


func hide_note() -> void:
	_overlay().hide_note()


## Title / chapter card over black.
func card(num: String, title: String, sub: String = "", hold: float = 4.0) -> void:
	_overlay().show_card(num, title, sub, hold)


func fade_out(seconds: float = 1.2) -> void:
	_overlay().fade(true, seconds)


func fade_in(seconds: float = 1.4) -> void:
	_overlay().fade(false, seconds)


func black(on: bool) -> void:
	_overlay().set_black(on)


## Placeholder for a sound cue: a caption in the top-left corner.
func sfx(text: String, hold: float = 2.0) -> void:
	_overlay().show_sfx(text, hold)


## Jump the Timeline to a shot marker name or a time in seconds, keeping the right camera.
func seek_to(where: String) -> void:
	var timeline := get_node_or_null("Timeline") as AnimationPlayer
	if timeline == null or not timeline.has_animation("play"):
		return
	var anim := timeline.get_animation("play")
	var t := 0.0
	if where.is_valid_float():
		t = where.to_float()
	elif anim.has_marker(where):
		t = anim.get_marker_time(where)
	else:
		push_warning("[previs] no shot marker '%s'. Markers: %s" % [where, anim.get_marker_names()])
		return
	if not timeline.is_playing():
		timeline.play("play")
	timeline.seek(t, true)
	_overlay().clear()
	_slate_marker = "~"

	# Method keys before t are skipped by seek, so re-apply the last camera cut and vent state.
	var cam_path := NodePath()
	var vents := false
	for i in anim.get_track_count():
		if anim.track_get_type(i) != Animation.TYPE_METHOD:
			continue
		for k in anim.track_get_key_count(i):
			if anim.track_get_key_time(i, k) > t:
				break
			match anim.method_track_get_name(i, k):
				&"cut_to":
					cam_path = anim.method_track_get_params(i, k)[0]
				&"slats":
					vents = anim.method_track_get_params(i, k)[0]
	if not cam_path.is_empty():
		cut_to(cam_path)
	slats(vents)


## Screen blur: 0 = sharp, about 5 = heavy. Used for falls and passing out.
func blur_to(amount: float, seconds: float = 1.0) -> void:
	_overlay().set_blur(amount, seconds)


func _first_person() -> bool:
	return view == "first_person" and has_node(FP_CAMERA)


func _hide_body_from_fp() -> void:
	var body := get_node_or_null(PROTAGONIST)
	if body == null:
		return
	for n in body.find_children("*", "VisualInstance3D", true, false):
		(n as VisualInstance3D).layers = 1 << (SELF_LAYER - 1)


func _overlay() -> NarrationOverlay:
	var overlay := get_tree().get_first_node_in_group("previs_narration") as NarrationOverlay
	if overlay == null:
		overlay = NarrationOverlay.new()
		add_child(overlay)
	return overlay
