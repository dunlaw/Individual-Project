extends RefCounted
class_name SettingsMenuLayoutBuilder
static func add_settings_banner(main_vbox: Control, texture: Texture2D) -> void:
	var banner := TextureRect.new()
	banner.name = "SettingsBanner"
	banner.texture = texture
	banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	banner.custom_minimum_size = Vector2(64, 64)
	banner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_vbox.add_child(banner)
	main_vbox.move_child(banner, 1)
static func create_tab_page(tab_container: TabContainer, tab_name: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = tab_name + "Scroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var vbox := VBoxContainer.new()
	vbox.name = tab_name + "VBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 15)
	scroll.add_child(margin)
	margin.add_child(vbox)
	tab_container.add_child(scroll)
	return vbox
static func move_control(node: Control, new_parent: Control) -> void:
	if node and node.get_parent():
		node.get_parent().remove_child(node)
		new_parent.add_child(node)
		node.visible = true
static func add_separator(parent: Control) -> void:
	var sep := HSeparator.new()
	sep.modulate = Color(1, 1, 1, 0.3)
	parent.add_child(sep)
static func ensure_audio_label(hbox: Control, label_name: String) -> void:
	if not hbox:
		return
	if hbox.has_node(label_name):
		return
	var label := Label.new()
	label.name = label_name
	label.custom_minimum_size.x = 140
	hbox.add_child(label)
	hbox.move_child(label, 0)
static func rebuild_tabs(
	main_vbox: Control,
	original_scroll: Control,
	nodes: Dictionary,
	on_gloria_voice_toggled: Callable,
	create_ai_log_page_fn: Callable,
) -> Dictionary:
	original_scroll.visible = false
	var tab_container := TabContainer.new()
	tab_container.name = "SettingsTabs"
	tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(tab_container)
	main_vbox.move_child(tab_container, 1)
	var tab_gameplay := create_tab_page(tab_container, "Gameplay")
	var tab_display  := create_tab_page(tab_container, "Display")
	var tab_audio    := create_tab_page(tab_container, "Audio")
	var tab_voice    := create_tab_page(tab_container, "Voice")
	var tab_tutorial := create_tab_page(tab_container, "Tutorial")
	var tab_developer := create_tab_page(tab_container, "Developer")
	var tab_ai_log: VBoxContainer = create_ai_log_page_fn.call(tab_container)
	move_control(nodes.get("language_label"), tab_gameplay)
	move_control(nodes.get("language_option"), tab_gameplay)
	add_separator(tab_gameplay)
	var gameplay_settings_box := VBoxContainer.new()
	gameplay_settings_box.name = "GameplayExtras"
	gameplay_settings_box.add_theme_constant_override("separation", 10)
	tab_gameplay.add_child(gameplay_settings_box)
	var text_speed_label  := Label.new()
	var text_speed_option := OptionButton.new()
	var screen_shake_check := CheckBox.new()
	var max_rounds_label  := Label.new()
	var max_rounds_spinbox := SpinBox.new()
	gameplay_settings_box.add_child(text_speed_label)
	gameplay_settings_box.add_child(text_speed_option)
	gameplay_settings_box.add_child(screen_shake_check)
	gameplay_settings_box.add_child(max_rounds_label)
	gameplay_settings_box.add_child(max_rounds_spinbox)
	add_separator(tab_gameplay)
	move_control(nodes.get("touch_controls_checkbox"), tab_gameplay)
	add_separator(tab_gameplay)
	move_control(nodes.get("ai_settings_button"), tab_gameplay)
	move_control(nodes.get("delete_logs_button"), tab_gameplay)
	move_control(nodes.get("fullscreen_label"), tab_display)
	move_control(nodes.get("fullscreen_option"), tab_display)
	add_separator(tab_display)
	move_control(nodes.get("resolution_label"), tab_display)
	move_control(nodes.get("resolution_option"), tab_display)
	add_separator(tab_display)
	move_control(nodes.get("font_size_label"), tab_display)
	move_control(nodes.get("font_size_option"), tab_display)
	add_separator(tab_display)
	move_control(nodes.get("english_font_label"), tab_display)
	move_control(nodes.get("english_font_option"), tab_display)
	move_control(nodes.get("chinese_font_label"), tab_display)
	move_control(nodes.get("chinese_font_option"), tab_display)
	move_control(nodes.get("mute_check_box"), tab_audio)
	add_separator(tab_audio)
	ensure_audio_label(nodes.get("master_volume_hbox"), "MasterVolumeLabel")
	move_control(nodes.get("master_volume_hbox"), tab_audio)
	ensure_audio_label(nodes.get("music_volume_hbox"), "MusicVolumeLabel")
	move_control(nodes.get("music_volume_hbox"), tab_audio)
	ensure_audio_label(nodes.get("sfx_volume_hbox"), "SFXVolumeLabel")
	move_control(nodes.get("sfx_volume_hbox"), tab_audio)
	add_separator(tab_audio)
	var gloria_voice_check := CheckBox.new()
	gloria_voice_check.name = "GloriaVoiceCheck"
	gloria_voice_check.toggled.connect(on_gloria_voice_toggled)
	tab_audio.add_child(gloria_voice_check)
	move_control(nodes.get("voice_description"), tab_voice)
	move_control(nodes.get("voice_availability_label"), tab_voice)
	add_separator(tab_voice)
	move_control(nodes.get("voice_enabled_check"), tab_voice)
	move_control(nodes.get("voice_options_box"), tab_voice)
	return {
		"tab_container":    tab_container,
		"tab_gameplay":     tab_gameplay,
		"tab_display":      tab_display,
		"tab_audio":        tab_audio,
		"tab_voice":        tab_voice,
		"tab_tutorial":     tab_tutorial,
		"tab_developer":    tab_developer,
		"tab_ai_log":       tab_ai_log,
		"text_speed_label": text_speed_label,
		"text_speed_option": text_speed_option,
		"screen_shake_check": screen_shake_check,
		"max_rounds_label": max_rounds_label,
		"max_rounds_spinbox": max_rounds_spinbox,
		"gloria_voice_check": gloria_voice_check,
	}
