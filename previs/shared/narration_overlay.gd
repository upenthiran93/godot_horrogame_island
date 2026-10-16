class_name NarrationOverlay
extends CanvasLayer
## Plain-text overlay for previs placeholders: subtitles, readable documents,
## title cards, fades to black and sound-cue captions.

var _label: Label
var _token := 0

var _note_panel: PanelContainer
var _note_title: Label
var _note_body: Label
var _note_token := 0

var _card: VBoxContainer
var _card_num: Label
var _card_title: Label
var _card_sub: Label
var _card_token := 0

var _fade: ColorRect
var _fade_tween: Tween

var _blur: ColorRect
var _blur_tween: Tween
var _blur_amt := 0.0

var _sfx: Label
var _sfx_token := 0

var _slats: Control
var _slate: Label


func _init() -> void:
	layer = 100
	add_to_group("previs_narration")

	# Screen blur (falls, passing out): copies the 3D view behind it and samples a blurred mip level.
	_blur = ColorRect.new()
	_blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_blur.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;\nuniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;\nuniform float amount : hint_range(0.0, 8.0) = 0.0;\nvoid fragment() {\n\tCOLOR = textureLod(screen_tex, SCREEN_UV, amount);\n}\n"
	var smat := ShaderMaterial.new()
	smat.shader = sh
	_blur.material = smat
	_blur.visible = false
	add_child(_blur)

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)

	# Locker vents: black with a band of horizontal slits across the middle of the screen.
	_slats = Control.new()
	_slats.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_slats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slats.visible = false
	var rows := 9
	var band_top := 0.3
	var band_bottom := 0.62
	var bars := [[0.0, band_top]]
	for r in rows:
		var y0 := band_top + (band_bottom - band_top) * (r + 0.42) / rows
		var y1 := band_top + (band_bottom - band_top) * (r + 1.0) / rows
		bars.append([y0, y1])
	bars.append([band_bottom, 1.0])
	for bar in bars:
		var c := ColorRect.new()
		c.color = Color(0.0, 0.0, 0.0, 0.97)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.anchor_left = 0.0
		c.anchor_right = 1.0
		c.anchor_top = bar[0]
		c.anchor_bottom = bar[1]
		_slats.add_child(c)
	add_child(_slats)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_label.offset_left = 80
	_label.offset_right = -80
	_label.offset_top = -160
	_label.offset_bottom = -48
	_label.add_theme_font_size_override("font_size", 28)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 8)
	add_child(_label)

	# Readable document ("paper") on the right half of the screen.
	_note_panel = PanelContainer.new()
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color(0.86, 0.83, 0.74, 0.96)
	paper.set_content_margin_all(24)
	_note_panel.add_theme_stylebox_override("panel", paper)
	_note_panel.anchor_left = 0.55
	_note_panel.anchor_right = 0.96
	_note_panel.anchor_top = 0.06
	_note_panel.anchor_bottom = 0.06
	_note_panel.grow_vertical = Control.GROW_DIRECTION_END
	_note_panel.visible = false
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	_note_panel.add_child(vb)
	_note_title = Label.new()
	_note_title.add_theme_font_size_override("font_size", 24)
	_note_title.add_theme_color_override("font_color", Color(0.12, 0.1, 0.08))
	vb.add_child(_note_title)
	_note_body = Label.new()
	_note_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note_body.add_theme_font_size_override("font_size", 17)
	_note_body.add_theme_color_override("font_color", Color(0.15, 0.13, 0.1))
	vb.add_child(_note_body)
	add_child(_note_panel)

	# Chapter / title card, centred.
	_card = VBoxContainer.new()
	_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card.alignment = BoxContainer.ALIGNMENT_CENTER
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.visible = false
	_card_num = _card_label(22, Color(0.7, 0.72, 0.75))
	_card_title = _card_label(64, Color(0.92, 0.9, 0.86))
	_card_sub = _card_label(22, Color(0.7, 0.72, 0.75))
	add_child(_card)

	# Sound / event cue caption, top-left (previs stand-in for audio).
	_sfx = Label.new()
	_sfx.position = Vector2(32, 24)
	_sfx.add_theme_font_size_override("font_size", 20)
	_sfx.add_theme_color_override("font_color", Color(1.0, 0.82, 0.45))
	_sfx.add_theme_color_override("font_outline_color", Color.BLACK)
	_sfx.add_theme_constant_override("outline_size", 6)
	add_child(_sfx)

	# Slate, top-right: chapter / shot / area, so moments are easy to point at in review.
	_slate = Label.new()
	_slate.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_slate.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_slate.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_slate.offset_left = -700
	_slate.offset_right = -24
	_slate.offset_top = 18
	_slate.add_theme_font_size_override("font_size", 18)
	_slate.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	_slate.add_theme_color_override("font_outline_color", Color.BLACK)
	_slate.add_theme_constant_override("outline_size", 6)
	add_child(_slate)


func _card_label(size: int, color: Color) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	_card.add_child(l)
	return l


func show_line(text: String, hold: float = 3.0) -> void:
	_token += 1
	var my_token := _token
	_label.text = text
	if hold > 0.0:
		# process_always = false, so the timer pauses with the playblast.
		await get_tree().create_timer(hold, false).timeout
		if my_token == _token:
			_label.text = ""


func show_note(title: String, body: String, hold: float = 6.0) -> void:
	_note_token += 1
	var my_token := _note_token
	_note_title.text = title
	_note_body.text = body
	_note_panel.visible = true
	if hold > 0.0:
		await get_tree().create_timer(hold, false).timeout
		if my_token == _note_token:
			_note_panel.visible = false


func hide_note() -> void:
	_note_token += 1
	_note_panel.visible = false


func show_card(num: String, title: String, sub: String, hold: float = 4.0) -> void:
	_card_token += 1
	var my_token := _card_token
	_card_num.text = num
	_card_title.text = title
	_card_sub.text = sub
	_card.visible = true
	if hold > 0.0:
		await get_tree().create_timer(hold, false).timeout
		if my_token == _card_token:
			_card.visible = false


## to_black = true fades to black and holds; false fades up from black.
func fade(to_black: bool, seconds: float = 1.2) -> void:
	if _fade_tween:
		_fade_tween.kill()
	_fade.color.a = 0.0 if to_black else 1.0
	_fade_tween = create_tween()
	_fade_tween.tween_property(_fade, "color:a", 1.0 if to_black else 0.0, maxf(seconds, 0.01))


func set_black(on: bool) -> void:
	if _fade_tween:
		_fade_tween.kill()
	_fade.color.a = 1.0 if on else 0.0


func show_sfx(text: String, hold: float = 2.0) -> void:
	_sfx_token += 1
	var my_token := _sfx_token
	_sfx.text = "[SFX] " + text
	if hold > 0.0:
		await get_tree().create_timer(hold, false).timeout
		if my_token == _sfx_token:
			_sfx.text = ""


## 0 = sharp, about 5 = heavy blur. Blur is hidden again once it is back at 0.
func set_blur(amount: float, seconds: float = 1.0) -> void:
	if _blur_tween:
		_blur_tween.kill()
	var smat := _blur.material as ShaderMaterial
	_blur.visible = true
	_blur_tween = create_tween()
	_blur_tween.tween_method(func(v: float):
		_blur_amt = v
		smat.set_shader_parameter("amount", v), _blur_amt, amount, maxf(seconds, 0.01))
	if amount <= 0.0:
		_blur_tween.tween_callback(func(): _blur.visible = false)


func set_slate(text: String) -> void:
	_slate.text = text


func set_slats(on: bool) -> void:
	_slats.visible = on


func clear() -> void:
	_token += 1
	_note_token += 1
	_card_token += 1
	_sfx_token += 1
	_label.text = ""
	_note_panel.visible = false
	_card.visible = false
	_sfx.text = ""
	_slats.visible = false
	set_black(false)
	set_blur(0.0, 0.0)
