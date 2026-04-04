extends Control
signal continue_requested
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
const ERROR_CONTEXT := "GloriaInterventionOverlay"
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
const CHAO_EASTER_EGG_URL := "https://music.apple.com/tw/song/%E5%98%88/589362359"
const VOICE_OPEN_IDS: Array[String] = [
	"gloria_open_01",
	"gloria_open_02",
	"gloria_open_03",
	"gloria_open_04",
]
const VOICE_GUILT_IDS: Array[String] = [
	"gloria_guilt_01",
	"gloria_guilt_02",
	"gloria_guilt_03",
	"gloria_guilt_04",
	"gloria_guilt_05",
	"gloria_guilt_06",
	"gloria_guilt_07",
	"gloria_guilt_08",
	"gloria_pua_01",
	"gloria_pua_02",
	"gloria_pua_03",
	"gloria_pua_04",
	"gloria_pua_05",
	"gloria_pua_06",
	"gloria_pua_07",
	"gloria_pua_08",
	"gloria_pua_09",
	"gloria_pua_10",
]
const VOICE_ACCEPT_IDS: Array[String] = [
	"gloria_accept_01",
	"gloria_accept_02",
	"gloria_accept_03",
	"gloria_accept_04",
]
@onready var content_panel: Panel = $ContentPanel
@onready var body_text: RichTextLabel = $ContentPanel/Margin/VBox/BodyText
@onready var continue_button: Button = $ContentPanel/Margin/VBox/ContinueButton
@onready var name_label: Label = $ContentPanel/Margin/VBox/PortraitRow/TitleBox/Name
@onready var subtitle_label: Label = $ContentPanel/Margin/VBox/PortraitRow/TitleBox/Subtitle
@onready var portrait: TextureRect = $ContentPanel/Margin/VBox/PortraitRow/Portrait
@onready var dim_background: ColorRect = $Dim
const CRYING_FACE_PATH = "res://1.Codebase/src/assets/characters/gloria_protagonis_sad.png"
const ANGRY_FACE_TEXTURE = preload("res://1.Codebase/src/assets/characters/gloria_protagonis_angry.png")
@onready var ai_guilt_text: RichTextLabel = $ContentPanel/Margin/VBox/AIGuiltText
@onready var horror_bg_container: Control = $HorrorBackground
var is_generating_guilt: bool = false
var _voice_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _has_played_main_voice: bool = false
var _audio_manager: Node = null
var _sound_catalog_reloaded: bool = false
var _playlist_was_active: bool = false
var _is_diary_judgment: bool = false
var _current_voice_key: String = ""
var _chao_click_count: int = 0
var _last_chao_click_time: int = 0
func _report_info(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, message, details)
func _report_warning(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, message, details)
func _report_error(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, -1, false, details)
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key)
	return key
func _ready() -> void:
	visible = false
	scale = Vector2(1.08, 1.08)
	modulate = Color(1, 1, 1, 0)
	_voice_rng.randomize()
	continue_button.pressed.connect(_on_continue_pressed)
	_setup_horror_background()
	_apply_styles()
	if subtitle_label:
		subtitle_label.gui_input.connect(_on_subtitle_gui_input)
	if _is_diary_judgment:
		_apply_diary_judgment_portrait()
	_apply_localization()
	_start_bgm()
	await get_tree().process_frame
	if body_text.get_parsed_text().is_empty() and (not ai_guilt_text or ai_guilt_text.text.is_empty()):
		_request_ai_guilt_trip()
	visible = true
	_animate_in()
func _start_bgm() -> void:
	var audio := _get_audio_manager()
	if not audio:
		return
	_playlist_was_active = audio.has_method("is_playlist_active") and audio.is_playlist_active()
	if audio.has_method("suspend_gameplay_playlist"):
		audio.suspend_gameplay_playlist()
	if audio.has_method("stop_music"):
		audio.stop_music(0.6)
	await get_tree().create_timer(0.6).timeout
	if is_inside_tree() and audio.has_method("play_music") and audio.has_method("has_sound"):
		if audio.has_sound("gloria_intervention_bgm"):
			audio.play_music("gloria_intervention_bgm", true)
func _stop_bgm() -> void:
	var audio := _get_audio_manager()
	if not audio:
		return
	if audio.has_method("stop_music"):
		audio.stop_music(0.5)
	if _playlist_was_active and audio.has_method("resume_gameplay_playlist"):
		get_tree().create_timer(0.6).timeout.connect(
			func(): if is_instance_valid(audio): audio.resume_gameplay_playlist(),
			CONNECT_ONE_SHOT
		)
func _setup_horror_background() -> void:
	if not horror_bg_container:
		return
	var face_texture = load(CRYING_FACE_PATH)
	if not face_texture:
		_report_warning("Failed to load horror texture: %s" % CRYING_FACE_PATH)
		return
	var faces_data = []
	var screen_size = get_viewport_rect().size if is_inside_tree() else Vector2(1920, 1080)
	for i in range(100):
		var scale_val = randf_range(0.2, 1.5)
		faces_data.append({
			"scale": scale_val,
			"pos": Vector2(
				randf_range(0, screen_size.x),
				randf_range(0, screen_size.y)
			),
			"rot": randf_range(-30, 30)
		})
	faces_data.sort_custom(func(a, b): return a["scale"] < b["scale"])
	for data in faces_data:
		var face = TextureRect.new()
		face.texture = face_texture
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var s = data["scale"]
		var base_size = 150.0
		face.size = Vector2(base_size * s, base_size * s)
		face.position = data["pos"] - (face.size / 2.0)
		face.rotation_degrees = data["rot"]
		var brightness = remap(s, 0.2, 1.5, 0.2, 0.8)
		var alpha = remap(s, 0.2, 1.5, 0.3, 0.9)
		face.modulate = Color(brightness + 0.2, brightness * 0.5, brightness * 0.5, alpha)
		horror_bg_container.add_child(face)
		var tween = face.create_tween()
		tween.set_loops()
		tween.tween_property(face, "scale", Vector2(1.05, 1.05), randf_range(2.0, 4.0)).as_relative().set_trans(Tween.TRANS_SINE)
		tween.tween_property(face, "scale", Vector2(0.95, 0.95), randf_range(2.0, 4.0)).as_relative().set_trans(Tween.TRANS_SINE)
func set_argument_text(text: String) -> void:
	_report_info("Received text from controller: %s" % text)
	var clean_text = _clean_text(text)
	apply_content("", clean_text)
func _clean_text(raw_text: String) -> String:
	var clean = raw_text.strip_edges()
	if "[SCENE_DIRECTIVES]" in clean:
		var parts = clean.split("[/SCENE_DIRECTIVES]")
		if parts.size() > 1:
			clean = parts[parts.size() - 1].strip_edges()
	var choice_markers = ["[Choice Preview]", "[choice preview]", "[CHOICE PREVIEW]", "[Choices]", "[choices]", "[CHOICES]"]
	for marker in choice_markers:
		var marker_pos = clean.find(marker)
		if marker_pos != -1:
			clean = clean.substr(0, marker_pos).strip_edges()
	var choice_prefixes = ["[Cautious]", "[Balanced]", "[Reckless]", "[Positive]", "[Complain]",
						   "[cautious]", "[balanced]", "[reckless]", "[positive]", "[complain]"]
	for prefix in choice_prefixes:
		var prefix_pos = clean.find(prefix)
		if prefix_pos != -1:
			clean = clean.substr(0, prefix_pos).strip_edges()
	if clean.begins_with("{"):
		var json = JSON.new()
		if json.parse(clean) == OK and json.data is Dictionary:
			var data = json.data
			if data.has("speech"): return _limit_text_length(String(data["speech"]))
			if data.has("text"): return _limit_text_length(String(data["text"]))
			if data.has("content"): return _limit_text_length(String(data["content"]))
			if data.has("message"): return _limit_text_length(String(data["message"]))
			if data.has("gloria_text"): return _limit_text_length(String(data["gloria_text"]))
			if data.has("story_text"): return _limit_text_length(String(data["story_text"]))
		var regex = RegEx.new()
		regex.compile("\"(speech|text|content|message|gloria_text|story_text)\"\\s*:\\s*\"(.*?)\"")
		var result = regex.search(clean)
		if result:
			return _limit_text_length(result.get_string(2))
		return "Gloria glares at you silently... (Data Error)"
	return _limit_text_length(clean)
func _limit_text_length(text: String) -> String:
	const MAX_CHARS = 800
	if text.length() > MAX_CHARS:
		var truncated = text.substr(0, MAX_CHARS)
		var last_period = truncated.rfind(".")
		var last_exclaim = truncated.rfind("!")
		var last_question = truncated.rfind("?")
		var break_point = max(last_period, max(last_exclaim, last_question))
		if break_point > MAX_CHARS * 0.6:
			return truncated.substr(0, break_point + 1)
		return truncated + "..."
	return text
func apply_content(base_line: String, argument_text: String) -> void:
	var final_text = _clean_text(argument_text)
	_report_info("Applying content to UI (length: %d)" % final_text.length())
	body_text.clear()
	body_text.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	body_text.push_color(Color(1, 0.9, 0.9))
	body_text.push_bold()
	body_text.push_font_size(32)
	var final_base_line = base_line
	if final_base_line.is_empty():
		if _is_diary_judgment:
			final_base_line = _tr("GLORIA_DIARY_JUDGMENT_HEADLINE")
		else:
			final_base_line = _tr("GLORIA_NEGATIVE_HEADLINE")
	body_text.add_text(final_base_line)
	body_text.pop()
	body_text.pop()
	body_text.pop()
	if not final_text.is_empty():
		body_text.newline()
		body_text.newline()
		body_text.push_font_size(24)
		body_text.add_text(final_text)
		body_text.pop()
	body_text.pop()
	continue_button.disabled = false
	continue_button.visible = true
	if body_text.get_v_scroll_bar():
		body_text.get_v_scroll_bar().value = 0
	if not _has_played_main_voice:
		_has_played_main_voice = true
		_play_random_gloria_voice("guilt")
func _animate_in() -> void:
	_play_random_gloria_voice("open")
	dim_background.modulate.a = 0.0
	var bg_tween := dim_background.create_tween()
	bg_tween.set_ease(Tween.EASE_OUT)
	bg_tween.set_trans(Tween.TRANS_CUBIC)
	bg_tween.tween_property(dim_background, "modulate:a", 1.0, 0.5)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "modulate:a", 1.0, 0.4)
	tween.tween_property(self, "scale", Vector2.ONE, 0.8)
	await get_tree().create_timer(0.3).timeout
	if portrait:
		var shake_tween = portrait.create_tween()
		shake_tween.set_loops(3)
		shake_tween.tween_property(portrait, "rotation", deg_to_rad(5), 0.05)
		shake_tween.tween_property(portrait, "rotation", deg_to_rad(-5), 0.05)
		shake_tween.tween_property(portrait, "rotation", 0.0, 0.05)
		var pulse_tween = portrait.create_tween()
		pulse_tween.set_loops()
		pulse_tween.set_ease(Tween.EASE_IN_OUT)
		pulse_tween.set_trans(Tween.TRANS_SINE)
		pulse_tween.tween_property(portrait, "scale", Vector2(1.2, 1.2), 0.8)
		pulse_tween.tween_property(portrait, "scale", Vector2.ONE, 0.8)
func _on_subtitle_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return
	var now := Time.get_ticks_msec()
	if _last_chao_click_time > 0 and (now - _last_chao_click_time) > GameConstants.EasterEgg.CLICK_TIMEOUT_MS:
		_chao_click_count = 0
	_last_chao_click_time = now
	_chao_click_count += 1
	_pulse_hidden_trigger()
	if _chao_click_count < GameConstants.EasterEgg.HIDDEN_TRIGGER_CLICKS:
		return
	_chao_click_count = 0
	_show_chao_easter_egg()
func _pulse_hidden_trigger() -> void:
	if not is_instance_valid(subtitle_label):
		return
	var tween := create_tween()
	tween.tween_property(subtitle_label, "scale", Vector2(1.03, 1.03), 0.08)
	tween.tween_property(subtitle_label, "scale", Vector2.ONE, 0.08)
func _show_chao_easter_egg() -> void:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = GameConstants.EasterEgg.POPUP_OVERLAY_Z_INDEX
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.0, 0.04, 0.94)
	overlay.add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := Panel.new()
	panel.custom_minimum_size = GameConstants.EasterEgg.CHAO_POPUP_SIZE
	panel.pivot_offset = GameConstants.EasterEgg.CHAO_POPUP_SIZE / 2.0
	panel.set_meta("chao_click_count", 0)
	panel.set_meta("chao_scale_tween", null)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.03, 0.08, 0.98)
	sb.corner_radius_top_left = 20
	sb.corner_radius_top_right = 20
	sb.corner_radius_bottom_left = 20
	sb.corner_radius_bottom_right = 20
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.95, 0.35, 0.55, 0.72)
	sb.shadow_size = 20
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.7)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)
	var title_lbl := Label.new()
	title_lbl.text = _tr("EASTER_EGG_GLORIA_CHAO_TITLE")
	title_lbl.add_theme_font_size_override("font_size", 28)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.78, 0.82))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title_lbl)
	var sep := HSeparator.new()
	sep.modulate = Color(0.95, 0.35, 0.55, 0.45)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sep)
	var body_lbl := RichTextLabel.new()
	body_lbl.bbcode_enabled = true
	body_lbl.text = _tr("EASTER_EGG_GLORIA_CHAO_BODY")
	body_lbl.fit_content = true
	body_lbl.scroll_active = false
	body_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_lbl.add_theme_font_size_override("normal_font_size", 20)
	body_lbl.add_theme_color_override("default_color", Color(0.98, 0.90, 0.92))
	body_lbl.add_theme_constant_override("line_separation", 10)
	body_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(body_lbl)
	var hint_lbl := Label.new()
	hint_lbl.text = _tr("EASTER_EGG_GLORIA_CHAO_HINT").format({"remaining": GameConstants.EasterEgg.POPUP_UNLOCK_CLICKS})
	hint_lbl.add_theme_font_size_override("font_size", 15)
	hint_lbl.add_theme_color_override("font_color", Color(0.95, 0.72, 0.76))
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hint_lbl)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(spacer)
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	btn_row.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(btn_row)
	var close_btn := Button.new()
	close_btn.text = _tr("EASTER_EGG_CLOSE")
	close_btn.custom_minimum_size = Vector2(150, 44)
	UIStyleManager.apply_button_style(close_btn, "danger", "medium")
	UIStyleManager.add_hover_scale_effect(close_btn, 1.06)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.pressed.connect(overlay.queue_free)
	btn_row.add_child(close_btn)
	panel.gui_input.connect(func(event: InputEvent) -> void:
		if not (event is InputEventMouseButton):
			return
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
			return
		var click_count := int(panel.get_meta("chao_click_count", 0)) + 1
		panel.set_meta("chao_click_count", click_count)
		var remaining: int = GameConstants.EasterEgg.POPUP_UNLOCK_CLICKS - click_count
		if remaining > 0:
			hint_lbl.text = _tr("EASTER_EGG_GLORIA_CHAO_HINT").format({"remaining": remaining})
			if is_instance_valid(panel):
				var existing_tween = panel.get_meta("chao_scale_tween", null)
				if existing_tween is Tween and is_instance_valid(existing_tween):
					existing_tween.kill()
				var scale_tween := create_tween()
				panel.set_meta("chao_scale_tween", scale_tween)
				scale_tween.tween_property(panel, "scale", Vector2(1.05, 1.05), 0.07)
				scale_tween.tween_property(panel, "scale", Vector2.ONE, 0.07)
			return
		OS.shell_open(CHAO_EASTER_EGG_URL)
		overlay.queue_free()
	)
	overlay.modulate.a = 0.0
	add_child(overlay)
	UIStyleManager.fade_in(overlay, 0.25)
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match (event as InputEventKey).keycode:
		KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			if continue_button and not continue_button.disabled:
				_on_continue_pressed()
				get_viewport().set_input_as_handled()
func _on_continue_pressed() -> void:
	_play_random_gloria_voice("accept")
	continue_button.disabled = true
	continue_requested.emit()
	if AudioManager:
		AudioManager.play_sfx("menu_click", 0.7)
	_animate_out()
func _animate_out() -> void:
	_stop_bgm()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.3)
	await tween.finished
	queue_free()
func _apply_styles() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.0, 0.05, 0.85)
	panel_style.border_color = Color(0.8, 0.0, 0.0, 0.9)
	panel_style.border_width_left = 4
	panel_style.border_width_top = 4
	panel_style.border_width_right = 4
	panel_style.border_width_bottom = 4
	panel_style.shadow_size = 50
	panel_style.shadow_color = Color(1.0, 0.0, 0.0, 0.3)
	content_panel.add_theme_stylebox_override("panel", panel_style)
	content_panel.anchor_left = 0.05
	content_panel.anchor_right = 0.95
	content_panel.anchor_top = 0.05
	content_panel.anchor_bottom = 0.95
	content_panel.offset_left = 0
	content_panel.offset_right = 0
	content_panel.offset_top = 0
	content_panel.offset_bottom = 0
	content_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	content_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	if UIStyleManager:
		UIStyleManager.apply_button_style(continue_button, "danger", "large")
		continue_button.custom_minimum_size = Vector2(300, 80)
		UIStyleManager.add_hover_scale_effect(continue_button, 1.1)
		UIStyleManager.add_press_feedback(continue_button)
	if FontManager:
		FontManager.apply_to_label(name_label, 48)
		FontManager.apply_to_label(subtitle_label, 32)
		FontManager.apply_to_rich_text(body_text, 28)
		FontManager.apply_to_button(continue_button, 32)
	if name_label:
		name_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
		name_label.add_theme_color_override("font_shadow_color", Color(0.5, 0.0, 0.0, 1.0))
		name_label.add_theme_constant_override("shadow_offset_x", 4)
		name_label.add_theme_constant_override("shadow_offset_y", 4)
	if subtitle_label:
		subtitle_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.6))
		subtitle_label.mouse_filter = Control.MOUSE_FILTER_STOP
	if body_text:
		body_text.add_theme_color_override("default_color", Color(1.0, 0.9, 0.9))
	if portrait:
		portrait.modulate = Color(1.2, 0.8, 0.8)
		portrait.custom_minimum_size = Vector2(300, 300)
func setup_diary_judgment_mode() -> void:
	_is_diary_judgment = true
	if is_inside_tree():
		_apply_localization()
		_apply_diary_judgment_portrait()
func _apply_diary_judgment_portrait() -> void:
	if not portrait:
		return
	portrait.texture = ANGRY_FACE_TEXTURE
	portrait.modulate = Color(1.3, 0.7, 0.7)
func _request_ai_guilt_trip() -> void:
	if not AIManager:
		return
	is_generating_guilt = true
	var lang = GameState.current_language if GameState else "en"
	var prompt = ""
	if _is_diary_judgment:
		prompt = _tr("GLORIA_AI_DIARY_JUDGMENT_PROMPT")
	else:
		prompt = _tr("GLORIA_AI_GUILT_TRIP_PROMPT")
	var context = {
		"purpose": "gloria_guilt",
		"language": lang
	}
	AIManager.generate_story(prompt, context, Callable(self, "_on_guilt_generated"))
func _on_guilt_generated(response: Dictionary) -> void:
	is_generating_guilt = false
	if not response.success:
		return
	var content = response.get("content", "")
	if content.strip_edges().is_empty():
		return
	var clean_content = _clean_text(content)
	ai_guilt_text.text = "[i]" + clean_content + "[/i]"
	UIStyleManager.fade_in(ai_guilt_text, 1.0)
func _get_voice_lang_code() -> String:
	var lang: String = GameState.current_language if GameState else "en"
	return "en" if lang == "en" else "zh"
func _get_audio_manager() -> Node:
	if is_instance_valid(_audio_manager):
		return _audio_manager
	if ServiceLocator and ServiceLocator.has_method("get_audio_manager"):
		_audio_manager = ServiceLocator.get_audio_manager()
	if _audio_manager == null and AudioManager:
		_audio_manager = AudioManager
	return _audio_manager
func _build_voice_keys(ids: Array[String], lang_code: String) -> Array[String]:
	var keys: Array[String] = []
	for voice_id in ids:
		keys.append("gloria/%s/%s" % [lang_code, voice_id])
	return keys
func _filter_existing_voice_keys(audio: Node, keys: Array[String]) -> Array[String]:
	if not audio or not audio.has_method("has_sound"):
		return keys
	var existing: Array[String] = []
	for key in keys:
		if audio.has_sound(key):
			existing.append(key)
	return existing
func _play_random_gloria_voice(category: String) -> void:
	var audio := _get_audio_manager()
	if not audio or not audio.has_method("play_sfx"):
		return
	var ids: Array[String] = []
	match category:
		"open":
			ids = VOICE_OPEN_IDS
		"guilt":
			ids = VOICE_GUILT_IDS
		"accept":
			ids = VOICE_ACCEPT_IDS
		_:
			return
	if ids.is_empty():
		return
	var lang_code := _get_voice_lang_code()
	var candidate_keys: Array[String] = _build_voice_keys(ids, lang_code)
	var playable_keys: Array[String] = _filter_existing_voice_keys(audio, candidate_keys)
	if playable_keys.is_empty() and (not _sound_catalog_reloaded) and audio.has_method("reload_sound_catalog"):
		audio.reload_sound_catalog()
		_sound_catalog_reloaded = true
		playable_keys = _filter_existing_voice_keys(audio, candidate_keys)
	if playable_keys.is_empty():
		return
	if not _current_voice_key.is_empty() and audio.has_method("stop_sfx"):
		audio.stop_sfx(_current_voice_key)
	var index: int = _voice_rng.randi_range(0, playable_keys.size() - 1)
	var chosen_key: String = playable_keys[index]
	_current_voice_key = chosen_key
	_report_info("GloriaVoice category=%s key=%s" % [category, chosen_key])
	audio.play_sfx(chosen_key, 0.95)
func _apply_localization() -> void:
	if _is_diary_judgment:
		name_label.text = " " + _tr("GLORIA_DIARY_JUDGMENT_NAME")
		subtitle_label.text = _tr("GLORIA_DIARY_JUDGMENT_HEADLINE")
		continue_button.text = _tr("GLORIA_ACCEPT_GUILT_BUTTON")
	else:
		name_label.text = " " + _tr("GLORIA_WATCHING_NAME")
		subtitle_label.text = _tr("GLORIA_NEGATIVITY_SUBTITLE")
		continue_button.text = _tr("GLORIA_ACCEPT_GUILT_BUTTON")
