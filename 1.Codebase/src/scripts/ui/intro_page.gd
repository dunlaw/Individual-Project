extends Control
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
const CreditsContent = preload("res://1.Codebase/src/scripts/core/credits_content.gd")
const ICON_INFO = preload("res://1.Codebase/src/assets/ui/icon_info.svg")
const ICON_HOME = preload("res://1.Codebase/src/assets/ui/icon_home.svg")
const GODOT_LOGO = preload("res://1.Codebase/src/assets/engine_logo.png")
const US_LOGO = preload("res://1.Codebase/src/assets/us_logo_1.png")
const STATS_ILLUSTRATION = preload("res://1.Codebase/src/assets/ui/intro/intro_stats_illustration.png")
const INTRO_IMAGE_WIDTH_RATIO := 0.56
const INTRO_IMAGE_HEIGHT_RATIO := 0.24
const HIDDEN_CREDITS_MUSIC := "hidden_credits_backup"
var current_language: String = "en"
var _audio_manager: Node = null
var _credits_click_count: int = 0
var _hidden_credits_popup: Control = null
var _previous_music: String = ""
func _ready():
	current_language = GameState.current_language if GameState else "en"
	_create_stats_tab()
	_create_voice_script_tab()
	_apply_modern_styling()
	_localize_content()
	_setup_hidden_credits()
	var panel = $MenuContainer/Panel
	if panel:
		UIStyleManager.fade_in(panel, 0.4)
		UIStyleManager.slide_in_from_bottom(panel, 0.5, 30.0)
	_enforce_fullscreen()
	_update_illustration_sizes()
	if not resized.is_connected(_on_intro_page_resized):
		resized.connect(_on_intro_page_resized)
func _enforce_fullscreen() -> void:
	var menu_container = $MenuContainer
	var panel = $MenuContainer/Panel
	if menu_container:
		menu_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	if panel:
		var viewport_size = get_viewport_rect().size
		var target_size = viewport_size * 0.9
		panel.custom_minimum_size = target_size
func _on_intro_page_resized() -> void:
	_enforce_fullscreen()
	_update_illustration_sizes()
func _update_illustration_sizes() -> void:
	var panel = $MenuContainer/Panel
	var tab_container = $MenuContainer/Panel/VBoxContainer/TabContainer
	if not panel or not tab_container:
		return
	var viewport_size := get_viewport_rect().size
	var target_width := clampf(panel.custom_minimum_size.x * INTRO_IMAGE_WIDTH_RATIO, 320.0, 620.0)
	var target_height := clampf(viewport_size.y * INTRO_IMAGE_HEIGHT_RATIO, 150.0, 210.0)
	for illustration in tab_container.find_children("Illustration", "TextureRect", true, false):
		var image_rect := illustration as TextureRect
		if image_rect == null:
			continue
		image_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		image_rect.custom_minimum_size = Vector2(target_width, target_height)
func _apply_modern_styling():
	var panel = $MenuContainer/Panel
	if panel:
		UIStyleManager.apply_panel_style(panel, 0.95, UIStyleManager.CORNER_RADIUS_LARGE)
	var characters_button = $MenuContainer/Panel/VBoxContainer/CharactersButton
	var close_button = $MenuContainer/Panel/VBoxContainer/CloseButton
	if characters_button:
		UIStyleManager.apply_button_style(characters_button, "accent", "large")
		characters_button.icon = ICON_INFO
		characters_button.expand_icon = true
		UIStyleManager.add_hover_scale_effect(characters_button, 1.06)
		UIStyleManager.add_press_feedback(characters_button)
		characters_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		characters_button.text = _tr("INTRO_BUTTON_CHARACTERS")
	if close_button:
		UIStyleManager.apply_button_style(close_button, "primary", "large")
		close_button.icon = ICON_HOME
		close_button.expand_icon = true
		UIStyleManager.add_hover_scale_effect(close_button, 1.06)
		UIStyleManager.add_press_feedback(close_button)
		close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		close_button.text = _tr("INTRO_BUTTON_CLOSE")
	var title_label = $MenuContainer/Panel/VBoxContainer/TitleLabel
	if title_label:
		title_label.add_theme_color_override("font_color", Color(0.94, 0.96, 1.0))
func _localize_content():
	var title_label = $MenuContainer/Panel/VBoxContainer/TitleLabel
	if title_label:
		title_label.text = _tr("INTRO_TITLE")
	var tab_container = $MenuContainer/Panel/VBoxContainer/TabContainer
	if not tab_container:
		return
	tab_container.set_tab_title(0, _tr("INTRO_TAB_WORLD_TITLE"))
	tab_container.set_tab_title(1, _tr("INTRO_TAB_GAMEPLAY_TITLE"))
	tab_container.set_tab_title(2, _tr("INTRO_TAB_MECHANICS_TITLE"))
	tab_container.set_tab_title(3, _tr("INTRO_TAB_STATS_TITLE"))
	tab_container.set_tab_title(4, _tr("INTRO_TAB_CREDITS_TITLE"))
	var localize_tab_sections = func(tab_name: String):
		var tab = tab_container.get_node_or_null(tab_name)
		if not tab: return
		var vbox = tab.get_node_or_null("Margin/VBox")
		if not vbox: return
		for section in vbox.get_children():
			if not section is VBoxContainer: continue
			var sec_title = section.get_node_or_null("Title")
			var sec_content = section.get_node_or_null("Content")
			if sec_title and sec_title.text.begins_with("INTRO_"):
				sec_title.text = _tr(sec_title.text)
			if sec_content and sec_content.text.begins_with("INTRO_"):
				sec_content.text = _tr(sec_content.text)
	localize_tab_sections.call("World")
	localize_tab_sections.call("Gameplay")
	localize_tab_sections.call("Mechanics")
	localize_tab_sections.call("Stats")
	localize_tab_sections.call("Credits")
func _create_stats_tab():
	var tab_container = $MenuContainer/Panel/VBoxContainer/TabContainer
	if not tab_container:
		return
	if tab_container.has_node("Stats"):
		return
	var scroll = ScrollContainer.new()
	scroll.name = "Stats"
	var margin = MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 24)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)
	scroll.add_child(margin)
	var illustration = TextureRect.new()
	illustration.name = "Illustration"
	illustration.texture = STATS_ILLUSTRATION
	illustration.expand_mode = 5
	illustration.stretch_mode = 5
	vbox.add_child(illustration)
	var sections = [
		{"title": "INTRO_TAB_STATS_REALITY_TITLE", "body": "INTRO_TAB_STATS_REALITY_BODY"},
		{"title": "INTRO_TAB_STATS_POSITIVE_TITLE", "body": "INTRO_TAB_STATS_POSITIVE_BODY"},
		{"title": "INTRO_TAB_STATS_ENTROPY_TITLE", "body": "INTRO_TAB_STATS_ENTROPY_BODY"}
	]
	for section_data in sections:
		var section_vbox = VBoxContainer.new()
		section_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title = Label.new()
		title.name = "Title"
		title.text = section_data["title"]
		title.add_theme_font_size_override("font_size", 22)
		title.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
		var body = RichTextLabel.new()
		body.name = "Content"
		body.text = section_data["body"]
		body.fit_content = true
		body.bbcode_enabled = true
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body.add_theme_color_override("default_color", Color(0.9, 0.9, 0.9))
		section_vbox.add_child(title)
		section_vbox.add_child(body)
		vbox.add_child(section_vbox)
		if section_data != sections.back():
			var sep = HSeparator.new()
			sep.modulate = Color(1, 1, 1, 0.3)
			vbox.add_child(sep)
	tab_container.add_child(scroll)
	tab_container.move_child(scroll, 3)
	tab_container.set_tab_title(3, _tr("INTRO_TAB_STATS_TITLE"))
func _create_voice_script_tab() -> void:
	var tab_container = $MenuContainer/Panel/VBoxContainer/TabContainer
	if not tab_container:
		return
	if tab_container.has_node("VoiceScript"):
		return
	var scroll = ScrollContainer.new()
	scroll.name = "VoiceScript"
	var margin = MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 16)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)
	scroll.add_child(margin)
	_vs_add_section_heading(vbox, _tr("GUIDE_VOICE_SECTION_A"))
	_vs_add_trigger(vbox, _tr("GUIDE_VOICE_TRIGGER_OPEN"))
	for i in range(1, 5):
		_vs_add_line(vbox, _tr("GUIDE_VOICE_OPEN_%02d" % i))
	vbox.add_child(_vs_make_sep())
	_vs_add_section_heading(vbox, _tr("GUIDE_VOICE_SECTION_B"))
	_vs_add_trigger(vbox, _tr("GUIDE_VOICE_TRIGGER_GUILT"))
	for i in range(1, 9):
		_vs_add_line(vbox, _tr("GUIDE_VOICE_GUILT_%02d" % i))
	for i in range(1, 11):
		_vs_add_line(vbox, _tr("GUIDE_VOICE_PUA_%02d" % i))
	vbox.add_child(_vs_make_sep())
	_vs_add_section_heading(vbox, _tr("GUIDE_VOICE_SECTION_C"))
	_vs_add_trigger(vbox, _tr("GUIDE_VOICE_TRIGGER_ACCEPT"))
	for i in range(1, 5):
		_vs_add_line(vbox, _tr("GUIDE_VOICE_ACCEPT_%02d" % i))
	tab_container.add_child(scroll)
	tab_container.set_tab_title(tab_container.get_tab_count() - 1, _tr("GUIDE_TAB_VOICE_SCRIPT"))
func _vs_add_section_heading(parent: VBoxContainer, text: String) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(lbl)
func _vs_add_trigger(parent: VBoxContainer, text: String) -> void:
	var lbl = RichTextLabel.new()
	lbl.bbcode_enabled = true
	lbl.fit_content = true
	lbl.scroll_active = false
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("normal_font_size", 14)
	lbl.add_theme_color_override("default_color", Color(0.65, 0.85, 1.0, 0.85))
	lbl.text = "[i]" + text + "[/i]"
	parent.add_child(lbl)
func _vs_add_line(parent: VBoxContainer, text: String) -> void:
	var lbl = RichTextLabel.new()
	lbl.bbcode_enabled = true
	lbl.fit_content = true
	lbl.scroll_active = false
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("normal_font_size", 16)
	lbl.add_theme_color_override("default_color", Color(0.9, 0.9, 0.9))
	lbl.text = "• " + text
	parent.add_child(lbl)
func _vs_make_sep() -> HSeparator:
	var sep = HSeparator.new()
	sep.modulate = Color(1.0, 1.0, 1.0, 0.25)
	return sep
func _on_close_pressed():
	var audio := _get_audio_manager()
	if audio and audio.has_method("play_sfx"):
		audio.play_sfx("menu_click")
	var parent = get_parent()
	var parent_script = parent.get_script()
	if parent and (parent.name == "StartMenu" or (parent_script and parent_script.resource_path.contains("start_menu"))):
		queue_free()
	else:
		get_tree().change_scene_to_file("res://1.Codebase/src/scenes/ui/start_menu.tscn")
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match (event as InputEventKey).keycode:
		KEY_ESCAPE:
			_on_close_pressed()
			get_viewport().set_input_as_handled()
		KEY_C:
			_on_characters_button_pressed()
			get_viewport().set_input_as_handled()
		KEY_1, KEY_KP_1:
			var tab_container = $MenuContainer/Panel/VBoxContainer/TabContainer
			if tab_container: tab_container.current_tab = 0
			get_viewport().set_input_as_handled()
		KEY_2, KEY_KP_2:
			var tab_container = $MenuContainer/Panel/VBoxContainer/TabContainer
			if tab_container: tab_container.current_tab = 1
			get_viewport().set_input_as_handled()
		KEY_3, KEY_KP_3:
			var tab_container = $MenuContainer/Panel/VBoxContainer/TabContainer
			if tab_container: tab_container.current_tab = 2
			get_viewport().set_input_as_handled()
		KEY_4, KEY_KP_4:
			var tab_container = $MenuContainer/Panel/VBoxContainer/TabContainer
			if tab_container: tab_container.current_tab = 3
			get_viewport().set_input_as_handled()
		KEY_5, KEY_KP_5:
			var tab_container = $MenuContainer/Panel/VBoxContainer/TabContainer
			if tab_container: tab_container.current_tab = 4
			get_viewport().set_input_as_handled()
func _on_characters_button_pressed():
	var audio := _get_audio_manager()
	if audio and audio.has_method("play_sfx"):
		audio.play_sfx("menu_click")
	var characters_scene = load("res://1.Codebase/src/scenes/ui/characters_page.tscn")
	if characters_scene:
		var characters = characters_scene.instantiate()
		add_child(characters)
func _setup_hidden_credits() -> void:
	var tab_container = $MenuContainer/Panel/VBoxContainer/TabContainer
	if not tab_container:
		return
	var credits_tab = tab_container.get_node_or_null("Credits")
	if not credits_tab:
		return
	var illustration = credits_tab.get_node_or_null("Margin/VBox/Illustration")
	if not illustration:
		return
	illustration.mouse_filter = Control.MOUSE_FILTER_STOP
	illustration.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	illustration.gui_input.connect(_on_credits_illustration_input)
func _on_credits_illustration_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_credits_click_count += 1
		if _credits_click_count >= 5:
			_credits_click_count = 0
			_show_hidden_credits()
func _show_hidden_credits() -> void:
	if is_instance_valid(_hidden_credits_popup):
		_hidden_credits_popup.visible = true
		_play_hidden_credits_music()
		return
	_hidden_credits_popup = _create_hidden_credits_popup()
	add_child(_hidden_credits_popup)
	_play_hidden_credits_music()
func _create_hidden_credits_popup() -> Control:
	var overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.05, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(bg)
	var margin_outer = MarginContainer.new()
	margin_outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin_outer.add_theme_constant_override("margin_left", 80)
	margin_outer.add_theme_constant_override("margin_right", 80)
	margin_outer.add_theme_constant_override("margin_top", 50)
	margin_outer.add_theme_constant_override("margin_bottom", 50)
	overlay.add_child(margin_outer)
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UIStyleManager.apply_panel_style(panel, 0.97, UIStyleManager.CORNER_RADIUS_LARGE)
	margin_outer.add_child(panel)
	var margin_inner = MarginContainer.new()
	margin_inner.add_theme_constant_override("margin_left", 32)
	margin_inner.add_theme_constant_override("margin_right", 32)
	margin_inner.add_theme_constant_override("margin_top", 24)
	margin_inner.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin_inner)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin_inner.add_child(vbox)
	var title_lbl = Label.new()
	title_lbl.text = _tr("HIDDEN_CREDITS_TITLE")
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	vbox.add_child(title_lbl)
	var sep1 = HSeparator.new()
	sep1.modulate = Color(1.0, 0.85, 0.3, 0.5)
	vbox.add_child(sep1)
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	var content = RichTextLabel.new()
	content.bbcode_enabled = true
	content.fit_content = false
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_color_override("default_color", Color(0.9, 0.9, 0.9, 1.0))
	content.add_theme_font_size_override("normal_font_size", 15)
	content.text = CreditsContent.get_hidden_credits_text()
	scroll.add_child(content)
	var sep2 = HSeparator.new()
	sep2.modulate = Color(1.0, 0.85, 0.3, 0.5)
	vbox.add_child(sep2)
	var close_btn = Button.new()
	close_btn.text = _tr("HIDDEN_CREDITS_CLOSE")
	close_btn.custom_minimum_size = Vector2(200, 48)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UIStyleManager.apply_button_style(close_btn, "primary", "large")
	UIStyleManager.add_hover_scale_effect(close_btn, 1.05)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.pressed.connect(func():
		_hidden_credits_popup.visible = false
		_stop_hidden_credits_music()
	)
	vbox.add_child(close_btn)
	return overlay
func _play_hidden_credits_music() -> void:
	var audio := _get_audio_manager()
	if not audio:
		return
	if audio.has_method("get_current_music"):
		_previous_music = audio.get_current_music()
	if audio.has_method("stop_music") and audio.is_music_playing():
		audio.stop_music(1.0)
	if audio.has_method("play_music"):
		await get_tree().create_timer(1.1).timeout
		if is_instance_valid(audio):
			audio.play_music(HIDDEN_CREDITS_MUSIC, true)
func _stop_hidden_credits_music() -> void:
	var audio := _get_audio_manager()
	if not audio:
		return
	if audio.has_method("stop_music") and audio.is_music_playing():
		audio.stop_music(1.0)
	if not _previous_music.is_empty() and audio.has_method("play_music"):
		await get_tree().create_timer(1.1).timeout
		if is_instance_valid(audio):
			audio.play_music(_previous_music, true)
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key, current_language)
	return key
func _get_audio_manager() -> Node:
	if is_instance_valid(_audio_manager):
		return _audio_manager
	if ServiceLocator:
		_audio_manager = ServiceLocator.get_audio_manager()
	return _audio_manager
