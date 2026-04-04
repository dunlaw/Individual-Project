extends Control
signal guide_closed
const ERROR_CONTEXT := "GameGuidePage"
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
const SETTINGS_FILE := "user://settings.cfg"
const PIG_SNAKE_PIGEON_URL := "https://en.wikipedia.org/wiki/The_Pig,_the_Snake_and_the_Pigeon"
const PIG_SNAKE_PIGEON_CLICKS_NEEDED := 5
const PAGE_MARGIN := 20
const IMAGE_PATHS := {
	"journal": "res://1.Codebase/src/assets/ui/guide_journal.jpg",
	"fsm": "res://1.Codebase/src/assets/ui/guide_fsm.png",
}
const GUIDE_STEP_IMAGES := ["read_story", "make_choices", "journal", "watch_stats", "fsm"]
var panel: PanelContainer
var title_label: Label
var scroll_content: VBoxContainer
var close_button: Button
var current_language: String = "en"
var _image_cache: Dictionary = {}
var _step_images: Array[TextureRect] = []
var _fsm_image_click_count: int = 0
var _fsm_image_easter_egg_unlocked: bool = false
var _fsm_image_rect: TextureRect = null
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key)
	return key
func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if not resized.is_connected(_on_page_resized):
		resized.connect(_on_page_resized)
	_load_language()
	_build_ui()
	_animate_entrance()
func _load_language() -> void:
	var game_state: Node = ServiceLocator.get_game_state() if ServiceLocator else null
	if game_state and game_state.get("current_language") != null:
		current_language = String(game_state.get("current_language"))
		return
	var config := ConfigFile.new()
	if config.load(SETTINGS_FILE) == OK:
		current_language = String(config.get_value("game", "language", "en"))
func _get_steps() -> Array:
	var steps: Array = []
	for i in range(GUIDE_STEP_IMAGES.size()):
		var idx := i + 1
		steps.append({
			"heading": _tr("GUIDE_HEADING_%d" % idx),
			"image": GUIDE_STEP_IMAGES[i],
			"body": _tr("GUIDE_BODY_%d" % idx),
		})
	return steps
func _get_image_for_step(image_key: String) -> Texture2D:
	if _image_cache.has(image_key):
		return _image_cache[image_key] as Texture2D
	var path: String = IMAGE_PATHS.get(image_key, "")
	if path.is_empty():
		return null
	var texture := load(path) as Texture2D
	if texture == null:
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Guide image failed to load", { "image_key": image_key, "path": path })
		return null
	_image_cache[image_key] = texture
	return texture
func _build_ui() -> void:
	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.0, 0.0, 0.0, 0.85)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(background)
	var page_margin := MarginContainer.new()
	page_margin.name = "GuidePageMargin"
	page_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	page_margin.add_theme_constant_override("margin_left", PAGE_MARGIN)
	page_margin.add_theme_constant_override("margin_right", PAGE_MARGIN)
	page_margin.add_theme_constant_override("margin_top", PAGE_MARGIN)
	page_margin.add_theme_constant_override("margin_bottom", PAGE_MARGIN)
	add_child(page_margin)
	panel = PanelContainer.new()
	panel.name = "GuidePage"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_margin.add_child(panel)
	_fit_panel_to_viewport()
	var panel_style := UIStyleManager.create_panel_style(0.98, 16, Color(0.4, 0.6, 1.0, 0.8), Color(0.08, 0.10, 0.15, 1.0))
	panel_style.shadow_size = 15
	panel.add_theme_stylebox_override("panel", panel_style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)
	var outer_vbox := VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 15)
	margin.add_child(outer_vbox)
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	outer_vbox.add_child(title_label)
	var subtitle := Label.new()
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8, 0.8))
	subtitle.text = _tr("GAME_GUIDE_GLORIOUS_DELIVERANCE_AGENCY")
	outer_vbox.add_child(subtitle)
	outer_vbox.add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer_vbox.add_child(scroll)
	scroll_content = VBoxContainer.new()
	scroll_content.add_theme_constant_override("separation", 30)
	scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(scroll_content)
	_populate_steps()
	var button_container := HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	outer_vbox.add_child(button_container)
	close_button = Button.new()
	close_button.custom_minimum_size = Vector2(200.0, 50.0)
	close_button.add_theme_font_size_override("font_size", 18)
	close_button.pressed.connect(_on_close_pressed)
	button_container.add_child(close_button)
	UIStyleManager.apply_button_style(close_button, "accent", "large")
	UIStyleManager.add_hover_scale_effect(close_button, 1.05)
	UIStyleManager.add_press_feedback(close_button)
	_update_text()
func _fit_panel_to_viewport() -> void:
	if panel == null:
		return
	var viewport_size := get_viewport_rect().size
	var panel_width := maxf(viewport_size.x - (PAGE_MARGIN * 2.0), 560.0)
	var panel_height := maxf(viewport_size.y - (PAGE_MARGIN * 2.0), 420.0)
	panel.custom_minimum_size = Vector2(panel_width, panel_height)
	_update_step_image_sizes()
func _on_page_resized() -> void:
	_fit_panel_to_viewport()
func _update_step_image_sizes() -> void:
	if _step_images.is_empty():
		return
	var viewport_size := get_viewport_rect().size
	var image_width := clampf(panel.custom_minimum_size.x * 0.78, 300.0, 760.0)
	var image_height := clampf(viewport_size.y * 0.24, 140.0, 220.0)
	for image_rect in _step_images:
		if not is_instance_valid(image_rect):
			continue
		image_rect.custom_minimum_size = Vector2(image_width, image_height)
		image_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
func _populate_steps() -> void:
	var steps := _get_steps()
	for index in range(steps.size()):
		var step: Dictionary = steps[index]
		var step_container := VBoxContainer.new()
		step_container.add_theme_constant_override("separation", 12)
		scroll_content.add_child(step_container)
		var heading := Label.new()
		heading.text = String(step.get("heading", ""))
		heading.add_theme_font_size_override("font_size", 22)
		heading.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		step_container.add_child(heading)
		var image_key := String(step.get("image", ""))
		var img_texture := _get_image_for_step(image_key)
		if img_texture != null:
			var img_rect := TextureRect.new()
			img_rect.texture = img_texture
			img_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			_step_images.append(img_rect)
			_update_step_image_sizes()
			step_container.add_child(img_rect)
			if image_key == "fsm":
				_fsm_image_rect = img_rect
				img_rect.mouse_filter = Control.MOUSE_FILTER_STOP
				img_rect.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				img_rect.tooltip_text = _tr("EASTER_EGG_PIG_SNAKE_PIGEON_HINT").format({"remaining": PIG_SNAKE_PIGEON_CLICKS_NEEDED})
				img_rect.gui_input.connect(_on_fsm_image_gui_input)
		var body := RichTextLabel.new()
		body.bbcode_enabled = true
		body.fit_content = true
		body.scroll_active = false
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body.add_theme_font_size_override("normal_font_size", 15)
		body.add_theme_color_override("default_color", Color(0.9, 0.92, 0.95))
		body.text = String(step.get("body", ""))
		step_container.add_child(body)
		if index < steps.size() - 1:
			var step_sep := HSeparator.new()
			step_sep.modulate = Color(1.0, 1.0, 1.0, 0.3)
			scroll_content.add_child(step_sep)
func _update_text() -> void:
	title_label.text = _tr("GAME_GUIDE_HOW_TO_PLAY")
	close_button.text = _tr("GAME_GUIDE_GOT_IT")
func _animate_entrance() -> void:
	modulate.a = 0.0
	panel.scale = Vector2(0.8, 0.8)
	panel.pivot_offset = panel.size / 2.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
func _on_close_pressed() -> void:
	_mark_guide_seen()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.finished.connect(_on_fade_complete)
func _on_fade_complete() -> void:
	guide_closed.emit()
	queue_free()
func _mark_guide_seen() -> void:
	var config := ConfigFile.new()
	var _load_error := config.load(SETTINGS_FILE)
	config.set_value("game", "game_guide_seen", true)
	config.save(SETTINGS_FILE)
static func has_seen_guide() -> bool:
	var config := ConfigFile.new()
	if config.load(SETTINGS_FILE) != OK:
		return false
	return bool(config.get_value("game", "game_guide_seen", false))
static func reset_guide_seen() -> void:
	var config := ConfigFile.new()
	var _load_error := config.load(SETTINGS_FILE)
	config.set_value("game", "game_guide_seen", false)
	config.save(SETTINGS_FILE)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
func _on_fsm_image_gui_input(event: InputEvent) -> void:
	if _fsm_image_easter_egg_unlocked:
		return
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return
	_fsm_image_click_count += 1
	if _fsm_image_rect and is_instance_valid(_fsm_image_rect):
		var tween := create_tween()
		tween.tween_property(_fsm_image_rect, "scale", Vector2(1.06, 1.06), 0.08)
		tween.tween_property(_fsm_image_rect, "scale", Vector2.ONE, 0.08)
	if _fsm_image_click_count >= PIG_SNAKE_PIGEON_CLICKS_NEEDED:
		_fsm_image_easter_egg_unlocked = true
		OS.shell_open(PIG_SNAKE_PIGEON_URL)
		_show_pig_snake_pigeon_easter_egg()
		return
	var remaining := PIG_SNAKE_PIGEON_CLICKS_NEEDED - _fsm_image_click_count
	if _fsm_image_rect:
		_fsm_image_rect.tooltip_text = _tr("EASTER_EGG_PIG_SNAKE_PIGEON_CLICK").format({"remaining": remaining})
func _show_pig_snake_pigeon_easter_egg() -> void:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 20
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.02, 0.95)
	overlay.add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var popup_panel := Panel.new()
	popup_panel.custom_minimum_size = Vector2(600, 360)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.05, 0.09, 0.985)
	sb.border_color = Color(0.36, 0.5, 0.7, 0.82)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 18
	sb.corner_radius_top_right = 18
	sb.corner_radius_bottom_left = 18
	sb.corner_radius_bottom_right = 18
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.72)
	sb.shadow_size = 26
	popup_panel.add_theme_stylebox_override("panel", sb)
	center.add_child(popup_panel)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_bottom", 28)
	popup_panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 18)
	margin.add_child(vbox)
	var title_lbl := Label.new()
	title_lbl.text = _tr("EASTER_EGG_PIG_SNAKE_PIGEON_TITLE")
	title_lbl.add_theme_font_size_override("font_size", 26)
	title_lbl.add_theme_color_override("font_color", Color(0.88, 0.93, 0.98))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)
	var sep := HSeparator.new()
	sep.modulate = Color(0.36, 0.5, 0.7, 0.45)
	vbox.add_child(sep)
	var body_lbl := RichTextLabel.new()
	body_lbl.bbcode_enabled = true
	body_lbl.fit_content = true
	body_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_lbl.add_theme_font_size_override("normal_font_size", 22)
	body_lbl.add_theme_color_override("default_color", Color(0.9, 0.92, 0.96))
	body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_lbl.text = _tr("EASTER_EGG_PIG_SNAKE_PIGEON_BODY")
	vbox.add_child(body_lbl)
	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 12)
	vbox.add_child(button_row)
	var open_btn := Button.new()
	open_btn.text = _tr("EASTER_EGG_PIG_SNAKE_PIGEON_OPEN")
	open_btn.custom_minimum_size = Vector2(190, 44)
	UIStyleManager.apply_button_style(open_btn, "accent", "medium")
	UIStyleManager.add_hover_scale_effect(open_btn, 1.04)
	open_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	open_btn.pressed.connect(func() -> void:
		OS.shell_open(PIG_SNAKE_PIGEON_URL)
	)
	button_row.add_child(open_btn)
	var close_btn := Button.new()
	close_btn.text = _tr("EASTER_EGG_CLOSE")
	close_btn.custom_minimum_size = Vector2(150, 44)
	UIStyleManager.apply_button_style(close_btn, "normal", "medium")
	UIStyleManager.add_hover_scale_effect(close_btn, 1.04)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.pressed.connect(overlay.queue_free)
	button_row.add_child(close_btn)
	overlay.modulate.a = 0.0
	add_child(overlay)
	UIStyleManager.fade_in(overlay, 0.25)
