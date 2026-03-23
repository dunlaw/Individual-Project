extends RefCounted
class_name SettingsMenuTutorialSection
func build_section(
		tab_tutorial: VBoxContainer,
		tutorial_system: Variant,
		on_enabled_toggled: Callable,
		on_reset_pressed: Callable,
		on_trigger_tutorial: Callable,
	) -> Dictionary:
	var info_panel := PanelContainer.new()
	info_panel.name = "TutorialInfoPanel"
	var info_margin := MarginContainer.new()
	info_margin.add_theme_constant_override("margin_left", 15)
	info_margin.add_theme_constant_override("margin_right", 15)
	info_margin.add_theme_constant_override("margin_top", 12)
	info_margin.add_theme_constant_override("margin_bottom", 12)
	info_panel.add_child(info_margin)
	var info_vbox := VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 8)
	info_margin.add_child(info_vbox)
	var info_title := Label.new()
	info_title.name = "TutorialInfoTitle"
	info_title.add_theme_font_size_override("font_size", 18)
	info_title.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	info_vbox.add_child(info_title)
	var info_desc := Label.new()
	info_desc.name = "TutorialInfoDesc"
	info_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	info_vbox.add_child(info_desc)
	tab_tutorial.add_child(info_panel)
	_add_separator(tab_tutorial)
	var controls_header := Label.new()
	controls_header.name = "ControlsHeader"
	controls_header.add_theme_font_size_override("font_size", 20)
	controls_header.add_theme_color_override("font_color", Color(1, 0.8, 0.4))
	tab_tutorial.add_child(controls_header)
	var tutorial_enabled_toggle := CheckBox.new()
	if tutorial_system != null:
		tutorial_enabled_toggle.set_pressed_no_signal(bool(tutorial_system.get("tutorial_enabled")))
	if on_enabled_toggled.is_valid():
		tutorial_enabled_toggle.toggled.connect(on_enabled_toggled)
	tab_tutorial.add_child(tutorial_enabled_toggle)
	_add_separator(tab_tutorial)
	var progress_panel := PanelContainer.new()
	progress_panel.name = "ProgressPanel"
	var progress_margin := MarginContainer.new()
	progress_margin.add_theme_constant_override("margin_left", 15)
	progress_margin.add_theme_constant_override("margin_right", 15)
	progress_margin.add_theme_constant_override("margin_top", 10)
	progress_margin.add_theme_constant_override("margin_bottom", 10)
	progress_panel.add_child(progress_margin)
	var progress_vbox := VBoxContainer.new()
	progress_vbox.add_theme_constant_override("separation", 5)
	progress_margin.add_child(progress_vbox)
	var progress_title := Label.new()
	progress_title.name = "ProgressTitle"
	progress_title.add_theme_font_size_override("font_size", 16)
	progress_title.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	progress_vbox.add_child(progress_title)
	var tutorial_progress_label := Label.new()
	tutorial_progress_label.add_theme_font_size_override("font_size", 20)
	tutorial_progress_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	progress_vbox.add_child(tutorial_progress_label)
	tab_tutorial.add_child(progress_panel)
	_add_separator(tab_tutorial)
	var reset_tutorials_button := Button.new()
	reset_tutorials_button.custom_minimum_size = Vector2(250, 45)
	if on_reset_pressed.is_valid():
		reset_tutorials_button.pressed.connect(on_reset_pressed)
	tab_tutorial.add_child(reset_tutorials_button)
	_add_separator(tab_tutorial)
	var tutorial_list_label := Label.new()
	tutorial_list_label.name = "TutorialListLabel"
	tutorial_list_label.add_theme_font_size_override("font_size", 20)
	tutorial_list_label.add_theme_color_override("font_color", Color(1, 0.8, 0.4))
	tab_tutorial.add_child(tutorial_list_label)
	var tutorial_list_container := VBoxContainer.new()
	tutorial_list_container.add_theme_constant_override("separation", 6)
	tab_tutorial.add_child(tutorial_list_container)
	var tutorial_names := {
		"first_choice": {"name": "Making Choices", "icon": ""},
		"first_stat_change": {"name": "Reality Score", "icon": ""},
		"first_prayer": {"name": "Prayer System", "icon": ""},
		"first_mission": {"name": "Mission Journal", "icon": ""},
		"first_skill_check": {"name": "Skill Checks", "icon": ""},
		"first_gloria_intervention": {"name": "Gloria's Intervention", "icon": ""},
		"first_entropy_surge": {"name": "Entropy System", "icon": ""},
		"first_night_cycle": {"name": "Night Cycle", "icon": ""}
	}
	if tutorial_system != null and tutorial_system.has_method("get_all_tutorial_steps"):
		var steps_variant: Variant = tutorial_system.get_all_tutorial_steps()
		if not (steps_variant is Array):
			steps_variant = []
		var steps: Array = steps_variant
		var can_check_completed: bool = tutorial_system != null and tutorial_system.has_method("is_tutorial_completed")
		for step_variant in steps:
			if not (step_variant is Dictionary):
				continue
			var step: Dictionary = step_variant
			var step_id: String = String(step.get("id", "")).strip_edges()
			if step_id.is_empty():
				continue
			var tutorial_info = tutorial_names.get(step_id, {"name": step_id.replace("_", " ").capitalize(), "icon": "•"})
			var item_panel := PanelContainer.new()
			item_panel.name = "Panel_" + step_id
			var item_margin := MarginContainer.new()
			item_margin.add_theme_constant_override("margin_left", 12)
			item_margin.add_theme_constant_override("margin_right", 12)
			item_margin.add_theme_constant_override("margin_top", 8)
			item_margin.add_theme_constant_override("margin_bottom", 8)
			item_panel.add_child(item_margin)
			var hbox := HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 12)
			item_margin.add_child(hbox)
			var name_hbox := HBoxContainer.new()
			name_hbox.add_theme_constant_override("separation", 8)
			name_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var icon_label := Label.new()
			icon_label.text = String(tutorial_info.get("icon", ""))
			icon_label.add_theme_font_size_override("font_size", 20)
			name_hbox.add_child(icon_label)
			var label := Label.new()
			label.text = String(tutorial_info.get("name", step_id))
			label.add_theme_font_size_override("font_size", 16)
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			name_hbox.add_child(label)
			hbox.add_child(name_hbox)
			var status_label := Label.new()
			status_label.name = "Status_" + step_id
			status_label.custom_minimum_size = Vector2(110, 0)
			status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			status_label.add_theme_font_size_override("font_size", 14)
			if can_check_completed and tutorial_system.is_tutorial_completed(step_id):
				status_label.text = "✓ Completed"
				status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
			else:
				status_label.text = "Not Seen"
				status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			hbox.add_child(status_label)
			var trigger_button := Button.new()
			trigger_button.name = "Trigger_" + step_id
			trigger_button.text = " Show"
			trigger_button.custom_minimum_size = Vector2(100, 35)
			if on_trigger_tutorial.is_valid():
				trigger_button.pressed.connect(on_trigger_tutorial.bind(step_id))
			hbox.add_child(trigger_button)
			tutorial_list_container.add_child(item_panel)
	return {
		"tutorial_enabled_toggle": tutorial_enabled_toggle,
		"tutorial_progress_label": tutorial_progress_label,
		"reset_tutorials_button": reset_tutorials_button,
		"tutorial_list_container": tutorial_list_container,
	}
func _add_separator(parent: Control) -> void:
	var sep := HSeparator.new()
	sep.modulate = Color(1, 1, 1, 0.3)
	parent.add_child(sep)
