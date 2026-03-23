extends RefCounted
class_name SettingsMenuStyles
@warning_ignore("shadowed_global_identifier")
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
static func apply_modern_styles(nodes: Dictionary, icons: Dictionary) -> void:
	var panel: Control = nodes.get("panel") as Control
	if panel:
		var panel_style: StyleBoxFlat = UIStyleManager.create_panel_style(0.98, 0) as StyleBoxFlat
		panel.add_theme_stylebox_override("panel", panel_style)
	var apply_button: Button = nodes.get("apply_button") as Button
	if apply_button:
		UIStyleManager.apply_button_style(apply_button, "accent", "large")
		apply_button.icon = icons.get("check") as Texture2D
		apply_button.expand_icon = true
		UIStyleManager.add_hover_scale_effect(apply_button, 1.06)
		UIStyleManager.add_press_feedback(apply_button)
		apply_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var ai_settings_button: Button = nodes.get("ai_settings_button") as Button
	if ai_settings_button:
		UIStyleManager.apply_button_style(ai_settings_button, "primary", "large")
		ai_settings_button.icon = icons.get("creative") as Texture2D
		ai_settings_button.expand_icon = true
		UIStyleManager.add_hover_scale_effect(ai_settings_button, 1.06)
		UIStyleManager.add_press_feedback(ai_settings_button)
		ai_settings_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var back_button: Button = nodes.get("back_button") as Button
	if back_button:
		UIStyleManager.apply_button_style(back_button, "primary", "large")
		back_button.icon = icons.get("back") as Texture2D
		back_button.expand_icon = true
		UIStyleManager.add_hover_scale_effect(back_button, 1.06)
		UIStyleManager.add_press_feedback(back_button)
		back_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var delete_logs_button: Button = nodes.get("delete_logs_button") as Button
	if delete_logs_button:
		UIStyleManager.apply_button_style(delete_logs_button, "danger", "medium")
		delete_logs_button.icon = icons.get("delete") as Texture2D
		delete_logs_button.expand_icon = true
		UIStyleManager.add_hover_scale_effect(delete_logs_button, 1.05)
		UIStyleManager.add_press_feedback(delete_logs_button)
		delete_logs_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var master_volume_hbox: Control = nodes.get("master_volume_hbox") as Control
	if master_volume_hbox and master_volume_hbox.has_node("MasterVolumeSlider"):
		master_volume_hbox.get_node("MasterVolumeSlider").mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var music_volume_hbox: Control = nodes.get("music_volume_hbox") as Control
	if music_volume_hbox and music_volume_hbox.has_node("MusicVolumeSlider"):
		music_volume_hbox.get_node("MusicVolumeSlider").mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var sfx_volume_hbox: Control = nodes.get("sfx_volume_hbox") as Control
	if sfx_volume_hbox and sfx_volume_hbox.has_node("SFXVolumeSlider"):
		sfx_volume_hbox.get_node("SFXVolumeSlider").mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var voice_preview_button: Button = nodes.get("voice_preview_button") as Button
	if voice_preview_button:
		UIStyleManager.apply_button_style(voice_preview_button, "secondary", "medium")
		UIStyleManager.add_press_feedback(voice_preview_button)
		voice_preview_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var voice_capture_button: Button = nodes.get("voice_capture_button") as Button
	if voice_capture_button:
		UIStyleManager.apply_button_style(voice_capture_button, "secondary", "medium")
		voice_capture_button.icon = icons.get("mic") as Texture2D
		voice_capture_button.expand_icon = true
		UIStyleManager.add_press_feedback(voice_capture_button)
		voice_capture_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var reset_tutorials_button: Button = nodes.get("reset_tutorials_button") as Button
	if reset_tutorials_button:
		UIStyleManager.apply_button_style(reset_tutorials_button, "accent", "medium")
		UIStyleManager.add_press_feedback(reset_tutorials_button)
		reset_tutorials_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var tab_tutorial: Control = nodes.get("tab_tutorial") as Control
	if tab_tutorial:
		if tab_tutorial.has_node("TutorialInfoPanel"):
			var info_panel: Control = tab_tutorial.get_node("TutorialInfoPanel")
			var info_style: StyleBoxFlat = UIStyleManager.create_panel_style(0.92, UIStyleManager.CORNER_RADIUS_MEDIUM) as StyleBoxFlat
			info_style.border_width_left = 3
			info_style.border_width_top = 0
			info_style.border_width_right = 0
			info_style.border_width_bottom = 0
			info_style.border_color = Color(0.4, 0.7, 1.0, 0.8)
			info_panel.add_theme_stylebox_override("panel", info_style)
		if tab_tutorial.has_node("ProgressPanel"):
			var progress_panel: Control = tab_tutorial.get_node("ProgressPanel")
			var progress_style: StyleBoxFlat = UIStyleManager.create_panel_style(0.94, UIStyleManager.CORNER_RADIUS_MEDIUM) as StyleBoxFlat
			progress_style.border_width_left = 0
			progress_style.border_width_top = 2
			progress_style.border_width_right = 0
			progress_style.border_width_bottom = 2
			progress_style.border_color = Color(0.7, 0.9, 1.0, 0.5)
			progress_panel.add_theme_stylebox_override("panel", progress_style)
	var tutorial_list_container: Control = nodes.get("tutorial_list_container") as Control
	if tutorial_list_container:
		for child in tutorial_list_container.get_children():
			if child is PanelContainer:
				var item_style: StyleBoxFlat = UIStyleManager.create_panel_style(0.9, UIStyleManager.CORNER_RADIUS_SMALL) as StyleBoxFlat
				item_style.border_width_left = 2
				item_style.border_width_top = 0
				item_style.border_width_right = 0
				item_style.border_width_bottom = 0
				item_style.border_color = Color(0.5, 0.5, 0.5, 0.3)
				child.add_theme_stylebox_override("panel", item_style)
				var trigger_button: Variant = child.find_child("Trigger_*", true, false)
				if trigger_button and trigger_button is Button:
					UIStyleManager.apply_button_style(trigger_button, "primary", "small")
					UIStyleManager.add_press_feedback(trigger_button)
					(trigger_button as Button).mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
