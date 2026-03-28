extends RefCounted
class_name SettingsMenuUIText
static func apply_labels(nodes: Dictionary, tr_callable: Callable, voice_capture_active: bool) -> void:
	var tab_container: TabContainer = nodes.get("tab_container") as TabContainer
	if tab_container:
		tab_container.set_tab_title(0, tr_callable.call("SETTINGS_GAMEPLAY"))
		tab_container.set_tab_title(1, tr_callable.call("SETTINGS_DISPLAY"))
		tab_container.set_tab_title(2, tr_callable.call("SETTINGS_AUDIO_2"))
		tab_container.set_tab_title(3, tr_callable.call("SETTINGS_VOICE"))
		tab_container.set_tab_title(4, tr_callable.call("SETTINGS_TUTORIAL"))
		tab_container.set_tab_title(5, tr_callable.call("SETTINGS_DEVELOPER"))
		tab_container.set_tab_title(6, tr_callable.call("SETTINGS_AI_LOG"))
	var title_label: Label = nodes.get("title_label") as Label
	if title_label:
		title_label.text = tr_callable.call("SETTINGS_TITLE")
	var text_speed_label: Label = nodes.get("text_speed_label") as Label
	if text_speed_label:
		text_speed_label.text = tr_callable.call("SETTINGS_TEXT_SPEED_LABEL")
	var text_speed_option: OptionButton = nodes.get("text_speed_option") as OptionButton
	if text_speed_option:
		text_speed_option.set_item_text(0, tr_callable.call("SETTINGS_TEXT_SPEED_INSTANT"))
		text_speed_option.set_item_text(1, tr_callable.call("SETTINGS_TEXT_SPEED_FAST"))
		text_speed_option.set_item_text(2, tr_callable.call("SETTINGS_TEXT_SPEED_NORMAL"))
		text_speed_option.set_item_text(3, tr_callable.call("SETTINGS_TEXT_SPEED_SLOW"))
	var screen_shake_check: CheckBox = nodes.get("screen_shake_check") as CheckBox
	if screen_shake_check:
		screen_shake_check.text = tr_callable.call("SETTINGS_SCREEN_SHAKE")
	var max_rounds_label: Label = nodes.get("max_rounds_label") as Label
	if max_rounds_label:
		max_rounds_label.text = tr_callable.call("SETTINGS_MAX_ROUNDS_LABEL")
	var max_rounds_spinbox: SpinBox = nodes.get("max_rounds_spinbox") as SpinBox
	if max_rounds_spinbox:
		max_rounds_spinbox.tooltip_text = tr_callable.call("SETTINGS_MAX_ROUNDS_HINT")
	var touch_controls_checkbox: CheckBox = nodes.get("touch_controls_checkbox") as CheckBox
	if touch_controls_checkbox:
		touch_controls_checkbox.text = tr_callable.call("SETTINGS_TOUCH_CONTROLS")
	var force_mission_complete_check: CheckBox = nodes.get("force_mission_complete_check") as CheckBox
	if force_mission_complete_check:
		force_mission_complete_check.text = tr_callable.call("SETTINGS_FORCE_MISSION_END")
		force_mission_complete_check.tooltip_text = tr_callable.call("SETTINGS_DEV_FORCE_COMPLETE_HINT")
	var reality_score_label: Label = nodes.get("reality_score_label") as Label
	if reality_score_label:
		reality_score_label.text = tr_callable.call("SETTINGS_REALITY_SCORE")
	var positive_energy_label: Label = nodes.get("positive_energy_label") as Label
	if positive_energy_label:
		positive_energy_label.text = tr_callable.call("SETTINGS_POSITIVE_ENERGY")
	var entropy_level_label: Label = nodes.get("entropy_level_label") as Label
	if entropy_level_label:
		entropy_level_label.text = tr_callable.call("SETTINGS_ENTROPY_LEVEL")
	var honeymoon_charges_label: Label = nodes.get("honeymoon_charges_label") as Label
	if honeymoon_charges_label:
		honeymoon_charges_label.text = tr_callable.call("SETTINGS_HONEYMOON_CHARGES")
	var mission_turn_label: Label = nodes.get("mission_turn_label") as Label
	if mission_turn_label:
		mission_turn_label.text = tr_callable.call("SETTINGS_MISSION_TURN_COUNT")
	var tab_developer: Control = nodes.get("tab_developer") as Control
	if tab_developer:
		if tab_developer.has_node("QuickActionsLabel"):
			(tab_developer.get_node("QuickActionsLabel") as Label).text = tr_callable.call("SETTINGS_QUICK_ACTIONS")
		if tab_developer.has_node("TogglesLabel"):
			(tab_developer.get_node("TogglesLabel") as Label).text = tr_callable.call("SETTINGS_GAME_STATE_TOGGLES")
	var max_stats_button: Button = nodes.get("max_stats_button") as Button
	if max_stats_button:
		max_stats_button.text = tr_callable.call("SETTINGS_MAX_ALL_STATS")
	var reset_stats_button: Button = nodes.get("reset_stats_button") as Button
	if reset_stats_button:
		reset_stats_button.text = tr_callable.call("SETTINGS_RESET_ALL_STATS")
	var clear_debuffs_button: Button = nodes.get("clear_debuffs_button") as Button
	if clear_debuffs_button:
		clear_debuffs_button.text = tr_callable.call("SETTINGS_CLEAR_ALL_DEBUFFS")
	var add_honeymoon_button: Button = nodes.get("add_honeymoon_button") as Button
	if add_honeymoon_button:
		add_honeymoon_button.text = tr_callable.call("SETTINGS_ADD_HONEYMOON")
	var autosave_toggle: CheckBox = nodes.get("autosave_toggle") as CheckBox
	if autosave_toggle:
		autosave_toggle.text = tr_callable.call("SETTINGS_ENABLE_AUTOSAVE")
	var infinite_resources_toggle: CheckBox = nodes.get("infinite_resources_toggle") as CheckBox
	if infinite_resources_toggle:
		infinite_resources_toggle.text = tr_callable.call("SETTINGS_INFINITE_RESOURCES")
	var skip_dialogue_toggle: CheckBox = nodes.get("skip_dialogue_toggle") as CheckBox
	if skip_dialogue_toggle:
		skip_dialogue_toggle.text = tr_callable.call("SETTINGS_AUTO_ADVANCE_DIALOGUE")
	var god_mode_toggle: CheckBox = nodes.get("god_mode_toggle") as CheckBox
	if god_mode_toggle:
		god_mode_toggle.text = tr_callable.call("SETTINGS_GOD_MODE")
	var master_volume_hbox: Control = nodes.get("master_volume_hbox") as Control
	if master_volume_hbox and master_volume_hbox.has_node("MasterVolumeLabel"):
		(master_volume_hbox.get_node("MasterVolumeLabel") as Label).text = tr_callable.call("SETTINGS_MASTER_VOLUME")
	var music_volume_hbox: Control = nodes.get("music_volume_hbox") as Control
	if music_volume_hbox and music_volume_hbox.has_node("MusicVolumeLabel"):
		(music_volume_hbox.get_node("MusicVolumeLabel") as Label).text = tr_callable.call("SETTINGS_MUSIC_VOLUME")
	var sfx_volume_hbox: Control = nodes.get("sfx_volume_hbox") as Control
	if sfx_volume_hbox and sfx_volume_hbox.has_node("SFXVolumeLabel"):
		(sfx_volume_hbox.get_node("SFXVolumeLabel") as Label).text = tr_callable.call("SETTINGS_SFX_VOLUME")
	var gloria_voice_check: CheckBox = nodes.get("gloria_voice_check") as CheckBox
	if gloria_voice_check:
		gloria_voice_check.text = tr_callable.call("SETTINGS_GLORIA_VOICE")
	var mute_check_box: CheckBox = nodes.get("mute_check_box") as CheckBox
	if mute_check_box:
		mute_check_box.text = tr_callable.call("SETTINGS_MUTE_ALL")
	var voice_description: Label = nodes.get("voice_description") as Label
	if voice_description:
		voice_description.text = tr_callable.call("SETTINGS_VOICE_DESCRIPTION")
	var voice_enabled_check: CheckBox = nodes.get("voice_enabled_check") as CheckBox
	if voice_enabled_check:
		voice_enabled_check.text = tr_callable.call("SETTINGS_VOICE_ENABLED")
	var voice_output_check: CheckBox = nodes.get("voice_output_check") as CheckBox
	if voice_output_check:
		voice_output_check.text = tr_callable.call("SETTINGS_VOICE_OUTPUT")
	var voice_input_check: CheckBox = nodes.get("voice_input_check") as CheckBox
	if voice_input_check:
		voice_input_check.text = tr_callable.call("SETTINGS_VOICE_INPUT")
	var voice_choice_label: Label = nodes.get("voice_choice_label") as Label
	if voice_choice_label:
		voice_choice_label.text = tr_callable.call("SETTINGS_VOICE_PRESET")
	var voice_volume_label: Label = nodes.get("voice_volume_label") as Label
	if voice_volume_label:
		voice_volume_label.text = tr_callable.call("SETTINGS_VOICE_VOLUME")
	var voice_input_mode_label: Label = nodes.get("voice_input_mode_label") as Label
	if voice_input_mode_label:
		voice_input_mode_label.text = tr_callable.call("SETTINGS_MIC_MODE")
	var voice_proactive_check: CheckBox = nodes.get("voice_proactive_check") as CheckBox
	if voice_proactive_check:
		voice_proactive_check.text = tr_callable.call("SETTINGS_PROACTIVE_LISTENING")
	var voice_capture_button: Button = nodes.get("voice_capture_button") as Button
	if voice_capture_button and not voice_capture_active:
		voice_capture_button.text = tr_callable.call("SETTINGS_CAPTURE_MIC_TEST")
	var voice_preview_button: Button = nodes.get("voice_preview_button") as Button
	if voice_preview_button:
		voice_preview_button.text = tr_callable.call("SETTINGS_PLAY_SAMPLE")
	var voice_status_label: Label = nodes.get("voice_status_label") as Label
	if voice_status_label and not voice_status_label.text:
		voice_status_label.text = tr_callable.call("SETTINGS_VOICE_IDLE")
	var resolution_label: Label = nodes.get("resolution_label") as Label
	if resolution_label:
		resolution_label.text = tr_callable.call("SETTINGS_RESOLUTION")
	var fullscreen_label: Label = nodes.get("fullscreen_label") as Label
	if fullscreen_label:
		fullscreen_label.text = tr_callable.call("SETTINGS_DISPLAY_MODE")
	var language_label: Label = nodes.get("language_label") as Label
	if language_label:
		language_label.text = tr_callable.call("SETTINGS_LANGUAGE")
	var font_size_label: Label = nodes.get("font_size_label") as Label
	if font_size_label:
		font_size_label.text = tr_callable.call("SETTINGS_FONT_SIZE")
	var english_font_label: Label = nodes.get("english_font_label") as Label
	if english_font_label:
		english_font_label.text = tr_callable.call("SETTINGS_FONT_ENGLISH")
	var chinese_font_label: Label = nodes.get("chinese_font_label") as Label
	if chinese_font_label:
		chinese_font_label.text = tr_callable.call("SETTINGS_FONT_CHINESE")
	var german_font_label: Label = nodes.get("german_font_label") as Label
	if german_font_label:
		german_font_label.text = tr_callable.call("SETTINGS_FONT_GERMAN")
	var tab_tutorial: Control = nodes.get("tab_tutorial") as Control
	if tab_tutorial:
		if tab_tutorial.has_node("TutorialInfoPanel"):
			var info_panel: Control = tab_tutorial.get_node("TutorialInfoPanel")
			if info_panel.has_node("TutorialInfoTitle"):
				(info_panel.find_child("TutorialInfoTitle", true, false) as Label).text = tr_callable.call("SETTINGS_ABOUT_TUTORIALS")
			if info_panel.has_node("TutorialInfoDesc"):
				(info_panel.find_child("TutorialInfoDesc", true, false) as Label).text = tr_callable.call("SETTINGS_TUTORIAL_DESC")
		if tab_tutorial.has_node("ControlsHeader"):
			(tab_tutorial.get_node("ControlsHeader") as Label).text = tr_callable.call("SETTINGS_TUTORIAL_HEADER")
		if tab_tutorial.has_node("ProgressPanel"):
			var progress_panel: Control = tab_tutorial.get_node("ProgressPanel")
			if progress_panel.has_node("ProgressTitle"):
				(progress_panel.find_child("ProgressTitle", true, false) as Label).text = tr_callable.call("SETTINGS_YOUR_PROGRESS")
		if tab_tutorial.has_node("TutorialListLabel"):
			(tab_tutorial.get_node("TutorialListLabel") as Label).text = tr_callable.call("SETTINGS_ALL_TUTORIALS")
	var tutorial_enabled_toggle: CheckBox = nodes.get("tutorial_enabled_toggle") as CheckBox
	if tutorial_enabled_toggle:
		tutorial_enabled_toggle.text = tr_callable.call("SETTINGS_ENABLE_TUTORIALS")
	var reset_tutorials_button: Button = nodes.get("reset_tutorials_button") as Button
	if reset_tutorials_button:
		reset_tutorials_button.text = tr_callable.call("SETTINGS_RESET_ALL_TUTORIALS")
	var ai_settings_button: Button = nodes.get("ai_settings_button") as Button
	if ai_settings_button:
		ai_settings_button.text = tr_callable.call("SETTINGS_AI_PROVIDER")
	var apply_button: Button = nodes.get("apply_button") as Button
	if apply_button:
		apply_button.text = tr_callable.call("SETTINGS_APPLY")
	var delete_logs_button: Button = nodes.get("delete_logs_button") as Button
	if delete_logs_button:
		delete_logs_button.text = tr_callable.call("SETTINGS_DELETE_LOGS")
	var back_button: Button = nodes.get("back_button") as Button
	if back_button:
		back_button.text = tr_callable.call("SETTINGS_BACK")
	var delete_logs_dialog: AcceptDialog = nodes.get("delete_logs_dialog") as AcceptDialog
	if delete_logs_dialog:
		delete_logs_dialog.title = tr_callable.call("SETTINGS_DELETE_LOGS_TITLE")
		delete_logs_dialog.dialog_text = tr_callable.call("SETTINGS_DELETE_LOGS_CONFIRM")
		delete_logs_dialog.ok_button_text = tr_callable.call("SETTINGS_DELETE")
		delete_logs_dialog.cancel_button_text = tr_callable.call("SETTINGS_CANCEL")
	var fullscreen_option: OptionButton = nodes.get("fullscreen_option") as OptionButton
	if fullscreen_option:
		fullscreen_option.set_item_text(0, tr_callable.call("SETTINGS_WINDOWED"))
		fullscreen_option.set_item_text(1, tr_callable.call("SETTINGS_FULLSCREEN"))
		fullscreen_option.set_item_text(2, tr_callable.call("SETTINGS_BORDERLESS"))
