extends Control
signal close_requested()
const ERROR_CONTEXT := "FSMChallengeOverlay"
const VERBOSE_LOGS := GameConstants.Debug.ENABLE_VERBOSE_LOGS
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
const FSMDailyContentData = preload("res://1.Codebase/src/scripts/core/fsm_daily_content_data.gd")
const ICON_REFRESH = preload("res://1.Codebase/src/assets/ui/icon_refresh.svg")
const ICON_CHECK = preload("res://1.Codebase/src/assets/ui/icon_check.svg")
const FSMRebirthExplanationScene = preload("res://1.Codebase/src/scenes/ui/fsm_rebirth_explanation.tscn")
const INVITE_METADATA_KEY := "fsm_challenge_invite_seen"
const TIMER_FONT_SIZE_DEFAULT := 16
const TIMER_FONT_SIZE_LARGE := 26
@onready var background_dim: ColorRect = $BackgroundDim
@onready var challenge_panel: Panel = $ChallengePanel
@onready var title_label: Label = $ChallengePanel/MarginContainer/VBoxContainer/TitleLabel
@onready var day_label: Label = $ChallengePanel/MarginContainer/VBoxContainer/DayLabel
@onready var theme_label: RichTextLabel = $ChallengePanel/MarginContainer/VBoxContainer/ThemeLabel
@onready var content_scroll: ScrollContainer = $ChallengePanel/MarginContainer/VBoxContainer/ContentContainer/ContentScroll
@onready var content_label: RichTextLabel = $ChallengePanel/MarginContainer/VBoxContainer/ContentContainer/ContentScroll/Margin/ContentLabel
@onready var content_bg_panel: Panel = $ChallengePanel/MarginContainer/VBoxContainer/ContentContainer
@onready var sublimation_panel: Panel = $ChallengePanel/MarginContainer/VBoxContainer/SublimationPanel
@onready var sublimation_label: RichTextLabel = $ChallengePanel/MarginContainer/VBoxContainer/SublimationPanel/SublimationMargin/SublimationVBox/SublimationLabel
@onready var sublimation_header: Label = $ChallengePanel/MarginContainer/VBoxContainer/SublimationPanel/SublimationMargin/SublimationVBox/SublimationHeader
@onready var instruction_label: Label = $ChallengePanel/MarginContainer/VBoxContainer/InstructionLabel
@onready var input_container: VBoxContainer = $ChallengePanel/MarginContainer/VBoxContainer/InputContainer
@onready var text_input: TextEdit = $ChallengePanel/MarginContainer/VBoxContainer/InputContainer/TextInput
@onready var click_count_label: Label = $ChallengePanel/MarginContainer/VBoxContainer/ClickCountLabel
@onready var timer_label: Label = $ChallengePanel/MarginContainer/VBoxContainer/TimerLabel
@onready var button_container: HBoxContainer = $ChallengePanel/MarginContainer/VBoxContainer/ButtonContainer
@onready var copy_button: Button = $ChallengePanel/MarginContainer/VBoxContainer/ButtonContainer/CopyButton
@onready var submit_button: Button = $ChallengePanel/MarginContainer/VBoxContainer/ButtonContainer/SubmitButton
@onready var confirm_button: Button = $ChallengePanel/MarginContainer/VBoxContainer/ButtonContainer/ConfirmButton
@onready var close_button: Button = $ChallengePanel/MarginContainer/VBoxContainer/CloseRow/CloseButton
@onready var rebirth_explanation_button: Button = $ChallengePanel/MarginContainer/VBoxContainer/RebirthExplanationButton
@onready var completion_container: VBoxContainer = $ChallengePanel/MarginContainer/VBoxContainer/CompletionContainer
@onready var completion_title_label: Label = $ChallengePanel/MarginContainer/VBoxContainer/CompletionContainer/CompletionTitle
@onready var completion_theme_label: Label = $ChallengePanel/MarginContainer/VBoxContainer/CompletionContainer/CompletionTheme
@onready var completion_gloria_image: TextureRect = $ChallengePanel/MarginContainer/VBoxContainer/CompletionContainer/GloriaHappy
@onready var completion_fsm_image: TextureRect = $ChallengePanel/MarginContainer/VBoxContainer/CompletionContainer/FSMImage
@onready var invitation_panel: Panel = $InvitationPanel
@onready var invitation_title: Label = $InvitationPanel/MarginContainer/VBoxContainer/Title
@onready var invitation_body: RichTextLabel = $InvitationPanel/MarginContainer/VBoxContainer/Body
@onready var invitation_images: HBoxContainer = $InvitationPanel/MarginContainer/VBoxContainer/Images
@onready var invitation_happy: TextureRect = $InvitationPanel/MarginContainer/VBoxContainer/Images/HappyImage
@onready var invitation_sad: TextureRect = $InvitationPanel/MarginContainer/VBoxContainer/Images/SadImage
@onready var invitation_buttons: HBoxContainer = $InvitationPanel/MarginContainer/VBoxContainer/Buttons
@onready var invitation_accept: Button = $InvitationPanel/MarginContainer/VBoxContainer/Buttons/AcceptButton
@onready var invitation_decline: Button = $InvitationPanel/MarginContainer/VBoxContainer/Buttons/DeclineButton
@onready var invitation_badge: Label = $InvitationPanel/MarginContainer/VBoxContainer/InviteBadge
@onready var invitation_note: Label = $InvitationPanel/MarginContainer/VBoxContainer/InviteNote
@onready var invitation_fsm_image: TextureRect = $InvitationPanel/MarginContainer/VBoxContainer/Images/FSMImage
@onready var invitation_teacher: TextureRect = $InvitationPanel/MarginContainer/VBoxContainer/Images/TeacherChanImage
@onready var crash_panel: Panel = $CrashPanel
@onready var crash_back_button: Button = $CrashPanel/MarginContainer/VBoxContainer/BackButton
@onready var crash_icon: Label = $CrashPanel/MarginContainer/VBoxContainer/CrashIcon
@onready var crash_footer: Label = $CrashPanel/MarginContainer/VBoxContainer/CrashFooter
var current_day: int = 1
var click_count: int = 0
var required_clicks: int = GameConstants.FSMChallenge.REQUIRED_REPETITIONS
var game_state: Node = null
var audio_manager: Node = null
var is_showing_crash: bool = false
var timer_update_timer: Timer = null
var was_reset: bool = false  
var _is_invitation_active: bool = false
var _magic_tweens: Array = []
var _calendar_grid: ScrollContainer = null
var _floating_glorias: Array = []
var _gloria_velocities: Array = []
var _gloria_rot_speeds: Array = []
func _ready() -> void:
	_refresh_services()
	_setup_ui()
	_setup_timer()
	_connect_signals()
	hide()
	if crash_panel:
		crash_panel.hide()
func _refresh_services() -> void:
	if ServiceLocator:
		game_state = ServiceLocator.get_game_state()
		audio_manager = ServiceLocator.get_audio_manager()
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key)
	return key
func _setup_timer() -> void:
	timer_update_timer = Timer.new()
	add_child(timer_update_timer)
	timer_update_timer.wait_time = 1.0  
	timer_update_timer.timeout.connect(_update_timer_display)
	timer_update_timer.one_shot = false
func _setup_ui() -> void:
	if background_dim:
		background_dim.color = Color(0, 0, 0, 0.82)
		background_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	if challenge_panel:
		UIStyleManager.apply_panel_style(challenge_panel, 0.95, UIStyleManager.CORNER_RADIUS_LARGE)
	if copy_button:
		UIStyleManager.apply_button_style(copy_button, "primary", "medium")
		UIStyleManager.add_hover_scale_effect(copy_button, 1.06)
		UIStyleManager.add_press_feedback(copy_button)
		copy_button.text = _tr("FSM_CHALLENGE_BTN_COPY")
		copy_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if submit_button:
		UIStyleManager.apply_button_style(submit_button, "accent", "medium")
		UIStyleManager.add_hover_scale_effect(submit_button, 1.06)
		UIStyleManager.add_press_feedback(submit_button)
		submit_button.text = _tr("FSM_CHALLENGE_BTN_SUBMIT")
		submit_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if confirm_button:
		_apply_golden_button_style(confirm_button)
		UIStyleManager.add_hover_scale_effect(confirm_button, 1.06)
		UIStyleManager.add_press_feedback(confirm_button)
		confirm_button.text = _tr("FSM_CHALLENGE_BTN_CONFIRM")
		confirm_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		confirm_button.hide()
	if close_button:
		_apply_ghost_button_style(close_button)
		UIStyleManager.add_hover_scale_effect(close_button, 1.07)
		UIStyleManager.add_press_feedback(close_button)
		close_button.text = _tr("UI_CLOSE_BUTTON")
		close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if rebirth_explanation_button:
		var old_parent = rebirth_explanation_button.get_parent()
		if old_parent and close_button:
			var close_row = close_button.get_parent()
			if close_row:
				old_parent.remove_child(rebirth_explanation_button)
				close_row.add_child(rebirth_explanation_button)
				close_row.move_child(rebirth_explanation_button, 0)
				var spacer = Control.new()
				spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				close_row.add_child(spacer)
				close_row.move_child(spacer, 1)
		_apply_ghost_button_style(rebirth_explanation_button)
		UIStyleManager.add_press_feedback(rebirth_explanation_button)
		rebirth_explanation_button.text = _tr("FSM_CHALLENGE_BTN_REBIRTH_INFO")
		rebirth_explanation_button.add_theme_font_size_override("font_size", 12)
		rebirth_explanation_button.custom_minimum_size = Vector2(0, 0)
		rebirth_explanation_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if title_label:
		title_label.add_theme_font_size_override("font_size", 34)
		title_label.add_theme_color_override("font_color", Color(1, 0.92, 0.45))
		UIStyleManager.add_glow_effect(title_label, Color(1, 0.85, 0.2, 1), 0.45)
	if day_label:
		day_label.add_theme_font_size_override("font_size", 18)
		day_label.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
	if theme_label:
		theme_label.bbcode_enabled = true
		theme_label.fit_content = true
		theme_label.add_theme_font_size_override("normal_font_size", 18)
	if content_label:
		content_label.bbcode_enabled = true
		content_label.fit_content = true
		content_label.add_theme_font_size_override("normal_font_size", 18)
	if sublimation_panel:
		_apply_sublimation_panel_style(sublimation_panel)
	if sublimation_header:
		sublimation_header.add_theme_font_size_override("font_size", 14)
		sublimation_header.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 0.85))
	if sublimation_label:
		sublimation_label.bbcode_enabled = true
		sublimation_label.fit_content = true
		sublimation_label.add_theme_font_size_override("normal_font_size", 17)
	if timer_label:
		timer_label.add_theme_font_size_override("font_size", TIMER_FONT_SIZE_DEFAULT)
		timer_label.add_theme_color_override("font_color", Color(1, 0.88, 0.35))
		timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		timer_label.text = _tr("FSM_CHALLENGE_NEXT_DAY_TIMER") % "00:00:00"
		_apply_timer_pill_style(timer_label)
		timer_label.hide()
	if text_input:
		text_input.placeholder_text = _tr("FSM_CHALLENGE_INPUT_PLACEHOLDER")
		_apply_text_input_style(text_input)
	if input_container:
		var input_label = input_container.get_node_or_null("InputLabel")
		if input_label:
			input_label.text = _tr("FSM_CHALLENGE_INPUT_LABEL")
			input_label.add_theme_color_override("font_color", Color(0.7, 0.78, 0.92))
			input_label.add_theme_font_size_override("font_size", 15)
	if instruction_label:
		instruction_label.add_theme_color_override("font_color", Color(0.75, 0.82, 0.95))
		instruction_label.add_theme_font_size_override("font_size", 16)
	if click_count_label:
		click_count_label.add_theme_color_override("font_color", Color(1, 0.88, 0.35))
		click_count_label.add_theme_font_size_override("font_size", 16)
	if completion_title_label:
		completion_title_label.add_theme_font_size_override("font_size", 22)
		completion_title_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.65))
		completion_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if completion_theme_label:
		completion_theme_label.add_theme_font_size_override("font_size", 17)
		completion_theme_label.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0, 0.9))
	if completion_container:
		completion_container.hide()
	if crash_panel:
		_setup_crash_panel_style()
		var crash_title = crash_panel.get_node_or_null("MarginContainer/VBoxContainer/CrashTitle")
		if crash_title:
			crash_title.text = _tr("FSM_CHALLENGE_CRASH_TITLE")
			crash_title.add_theme_font_size_override("font_size", 32)
			crash_title.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		var crash_content = crash_panel.get_node_or_null("MarginContainer/VBoxContainer/CrashContent")
		if crash_content:
			crash_content.text = _tr("FSM_CHALLENGE_CRASH_CONTENT")
			crash_content.add_theme_font_size_override("normal_font_size", 18)
		if crash_back_button:
			UIStyleManager.apply_button_style(crash_back_button, "danger", "large")
			UIStyleManager.add_hover_scale_effect(crash_back_button, 1.06)
			UIStyleManager.add_press_feedback(crash_back_button)
			crash_back_button.text = _tr("MENU_HOME_BUTTON")
		if crash_icon:
			UIStyleManager.pulse_effect(crash_icon, 0.08, 1.5)
		if crash_footer:
			crash_footer.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6, 0.7))
	if invitation_panel:
		invitation_panel.hide()
	if invitation_title:
		invitation_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		invitation_title.add_theme_font_size_override("font_size", 34)
		invitation_title.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	if invitation_body:
		invitation_body.autowrap_mode = TextServer.AUTOWRAP_WORD
		invitation_body.add_theme_font_size_override("normal_font_size", 20)
	if invitation_badge:
		invitation_badge.add_theme_font_size_override("font_size", 18)
		invitation_badge.add_theme_color_override("font_color", Color(0.8, 0.7, 1, 0.8))
	if invitation_note:
		invitation_note.add_theme_font_size_override("font_size", 16)
		invitation_note.add_theme_color_override("font_color", Color(0.7, 0.75, 0.9, 0.7))
	if invitation_accept:
		UIStyleManager.apply_button_style(invitation_accept, "success", "large")
		UIStyleManager.add_hover_scale_effect(invitation_accept, 1.06)
		UIStyleManager.add_press_feedback(invitation_accept)
		invitation_accept.text = _tr("FSM_CHALLENGE_INVITE_ACCEPT")
	if invitation_decline:
		UIStyleManager.apply_button_style(invitation_decline, "danger", "large")
		UIStyleManager.add_hover_scale_effect(invitation_decline, 1.06)
		UIStyleManager.add_press_feedback(invitation_decline)
		invitation_decline.text = _tr("FSM_CHALLENGE_INVITE_DECLINE")
	_apply_magic_styles()
func _connect_signals() -> void:
	if copy_button:
		copy_button.pressed.connect(_on_copy_pressed)
	if submit_button:
		submit_button.pressed.connect(_on_submit_pressed)
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if rebirth_explanation_button:
		rebirth_explanation_button.pressed.connect(_on_rebirth_explanation_pressed)
	if content_label:
		content_label.gui_input.connect(_on_content_clicked)
	if crash_back_button:
		crash_back_button.pressed.connect(_on_crash_back_pressed)
	if invitation_accept:
		invitation_accept.pressed.connect(_on_invitation_accept)
	if invitation_decline:
		invitation_decline.pressed.connect(_on_invitation_decline)
func show_challenge(day: int, show_invitation: bool = false) -> void:
	if is_showing_crash:
		return
	_check_for_reset()
	_start_challenge_if_needed()
	if game_state:
		var fsm_module = game_state.get_fsm_challenge_module()
		if fsm_module:
			day = fsm_module.current_day
			if ErrorReporter and ErrorReporter.has_method("report_info"):
				ErrorReporter.report_info(ERROR_CONTEXT, "Challenge ensured active: day=%d, active=%s, was_reset=%s" % [day, str(fsm_module.is_challenge_active), str(was_reset)])
	current_day = day
	click_count = 0
	if ErrorReporter and ErrorReporter.has_method("report_info"):
		ErrorReporter.report_info(ERROR_CONTEXT, "Showing challenge for day %d" % day)
	var should_show_invite := show_invitation and not _has_seen_invitation()
	if should_show_invite:
		_show_invitation()
	else:
		_update_ui_for_day(day)
	show()
	UIStyleManager.fade_in(self, 0.35)
	if timer_update_timer:
		timer_update_timer.start()
		_update_timer_display()
	if audio_manager:
		audio_manager.play_sfx("ui_open", 0.8)
		audio_manager.play_music("mountain_king")
func _update_ui_for_day(day: int) -> void:
	var day_data = FSMDailyContentData.get_day_content(day)
	if day_data.is_empty():
		if ErrorReporter and ErrorReporter.has_method("report_warning"):
			ErrorReporter.report_warning(ERROR_CONTEXT, "No content found for day %d" % day)
		return
	if title_label:
		title_label.text = _tr("FSM_CHALLENGE_TITLE")
	if day_label:
		day_label.text = _tr("FSM_CHALLENGE_DAY_LABEL") % day
	if theme_label:
		theme_label.text = "[center][color=#FFD700]%s[/color][/center]\n[center]%s[/center]" % [_tr("FSM_CHALLENGE_THEME_PREFIX"), day_data["theme"]]
	_setup_content_with_image(day, day_data)
	_update_sublimation_display(day_data)
	if instruction_label:
		instruction_label.text = _tr("FSM_CHALLENGE_INSTRUCTION")
	if click_count_label:
		_update_click_count_label()
	if text_input:
		text_input.text = ""
	if confirm_button:
		confirm_button.hide()
	if copy_button and submit_button:
		copy_button.show()
		submit_button.show()
		input_container.show()
	_update_completion_state()
func _update_click_count_label() -> void:
	if click_count_label:
		click_count_label.text = _tr("FSM_CHALLENGE_CLICK_COUNT") % [click_count, required_clicks]
func _on_copy_pressed() -> void:
	var day_data = FSMDailyContentData.get_day_content(current_day)
	if not day_data.is_empty():
		DisplayServer.clipboard_set(day_data["content"])
		if audio_manager:
			audio_manager.play_sfx("ui_click", 0.7)
		if ErrorReporter and ErrorReporter.has_method("report_info"):
			ErrorReporter.report_info(ERROR_CONTEXT, "Content copied to clipboard")
func _normalize_challenge_text(text: String) -> String:
	var normalized := text.replace("\r\n", "\n").replace("\r", "\n")
	normalized = normalized.replace("\u00A0", " ")
	normalized = normalized.replace("\u200B", "")
	var lines := normalized.split("\n")
	for i in range(lines.size()):
		lines[i] = lines[i].strip_edges()
	return "\n".join(lines).strip_edges()
func _on_submit_pressed() -> void:
	if ErrorReporter and ErrorReporter.has_method("report_info"):
		ErrorReporter.report_info(ERROR_CONTEXT, "Submit pressed for day %d (click_count=%d/%d)" % [current_day, click_count, required_clicks])
	var day_data = FSMDailyContentData.get_day_content(current_day)
	if day_data.is_empty():
		if ErrorReporter and ErrorReporter.has_method("report_warning"):
			ErrorReporter.report_warning(ERROR_CONTEXT, "No day data found for day %d" % current_day)
		return
	var input_text := _normalize_challenge_text(text_input.text)
	var expected_text := _normalize_challenge_text(String(day_data["content"]))
	if input_text.is_empty():
		if audio_manager:
			audio_manager.play_sfx("ui_error", 0.8)
		if ErrorReporter and ErrorReporter.has_method("report_info"):
			ErrorReporter.report_info(ERROR_CONTEXT, "Empty input submitted for FSM challenge")
		return
	if input_text == expected_text:
		_increment_repetition()
	else:
		if audio_manager:
			audio_manager.play_sfx("ui_error", 0.8)
		if ErrorReporter and ErrorReporter.has_method("report_warning"):
			ErrorReporter.report_warning(ERROR_CONTEXT, "Input text does not match expected content")
func _on_content_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_increment_repetition()
func _increment_repetition() -> void:
	click_count += 1
	_update_click_count_label()
	if audio_manager:
		audio_manager.play_sfx("ui_click", 0.6)
	if ErrorReporter and ErrorReporter.has_method("report_info"):
		ErrorReporter.report_info(ERROR_CONTEXT, "Repetition %d/%d for day %d" % [click_count, required_clicks, current_day])
	if click_count >= required_clicks:
		_show_confirm_button()
func _show_confirm_button() -> void:
	if ErrorReporter and ErrorReporter.has_method("report_info"):
		ErrorReporter.report_info(ERROR_CONTEXT, "Showing confirm button (hiding submit/copy/input)")
	if copy_button and submit_button and input_container:
		copy_button.hide()
		submit_button.hide()
		input_container.hide()
	if confirm_button:
		confirm_button.disabled = false
		confirm_button.show()
	if audio_manager:
		audio_manager.play_sfx("ui_success", 0.9)
func _on_rebirth_explanation_pressed() -> void:
	if audio_manager:
		audio_manager.play_sfx("ui_click", 0.8)
	var explanation_overlay = FSMRebirthExplanationScene.instantiate()
	get_tree().root.add_child(explanation_overlay)
	explanation_overlay.close_requested.connect(func():
		if audio_manager:
			audio_manager.play_sfx("ui_click", 0.8)
			audio_manager.play_music("mountain_king")
	)
func _on_confirm_pressed() -> void:
	if not game_state:
		if ErrorReporter and ErrorReporter.has_method("report_warning"):
			ErrorReporter.report_warning(ERROR_CONTEXT, "Confirm pressed but no game_state available")
		return
	var fsm_module = game_state.get_fsm_challenge_module()
	if not fsm_module:
		if ErrorReporter and ErrorReporter.has_method("report_warning"):
			ErrorReporter.report_warning(ERROR_CONTEXT, "Confirm pressed but no fsm_module available")
		return
	if confirm_button:
		confirm_button.disabled = true
	if ErrorReporter and ErrorReporter.has_method("report_info"):
		ErrorReporter.report_info(ERROR_CONTEXT, "Confirm pressed for day %d (active=%s, crashed=%s, completed_days=%s)" % [current_day, str(fsm_module.is_challenge_active), str(fsm_module.challenge_crashed), str(fsm_module.days_completed)])
	if not fsm_module.is_challenge_active and not fsm_module.challenge_crashed:
		if ErrorReporter and ErrorReporter.has_method("report_warning"):
			ErrorReporter.report_warning(ERROR_CONTEXT, "Challenge not active on confirm, restarting challenge")
		fsm_module.start_challenge()
		current_day = fsm_module.current_day
	fsm_module.complete_day()
	if ErrorReporter and ErrorReporter.has_method("report_info"):
		ErrorReporter.report_info(ERROR_CONTEXT, "Day %d completion result: is_today_completed=%s" % [current_day, str(fsm_module.is_today_completed())])
	if game_state.has_method("save_game"):
		game_state.save_game()
	if audio_manager:
		audio_manager.play_sfx("asset_upgrade_confirm", 0.8)
	if current_day == GameConstants.FSMChallenge.DAYS_BEFORE_CRASH:
		await get_tree().create_timer(0.5).timeout
		_show_crash_screen()
	else:
		_update_completion_state()
		_update_timer_display()
		if ErrorReporter and ErrorReporter.has_method("report_info"):
			ErrorReporter.report_info(ERROR_CONTEXT, "Transitioned to completion/waiting state for day %d" % current_day)
func _show_crash_screen() -> void:
	is_showing_crash = true
	if challenge_panel:
		challenge_panel.hide()
	if crash_panel:
		crash_panel.show()
		crash_panel.modulate.a = 0.0
		var crash_tween := create_tween()
		crash_tween.tween_property(crash_panel, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		if background_dim:
			UIStyleManager.shake_effect(background_dim, 8.0, 0.5)
	if audio_manager:
		audio_manager.play_sfx("reality_distortion_activate", 1.0)
		audio_manager.play_music("gloria_intervention_bgm")
func _on_crash_back_pressed() -> void:
	if not game_state:
		return
	var fsm_module = game_state.get_fsm_challenge_module()
	if fsm_module and not fsm_module.challenge_crashed:
		fsm_module._trigger_crash()
	_close()
func _on_close_pressed() -> void:
	if audio_manager:
		audio_manager.play_sfx("menu_close", 0.7)
	_close()
func _close() -> void:
	if ErrorReporter and ErrorReporter.has_method("report_info"):
		ErrorReporter.report_info(ERROR_CONTEXT, "Closing overlay (day=%d, is_showing_crash=%s)" % [current_day, str(is_showing_crash)])
	hide()
	if crash_panel:
		crash_panel.hide()
	is_showing_crash = false
	_clear_magic_tweens()
	_remove_floating_gloria()
	if timer_update_timer:
		timer_update_timer.stop()
	if audio_manager:
		audio_manager.stop_music(0.5)
	close_requested.emit()
func _check_for_reset() -> void:
	if not game_state:
		return
	var fsm_module = game_state.get_fsm_challenge_module()
	if not fsm_module:
		return
	if ErrorReporter and ErrorReporter.has_method("report_info"):
		ErrorReporter.report_info(ERROR_CONTEXT, "Checking for reset: active=%s, crashed=%s, last_login=%s, current_day=%d" % [str(fsm_module.is_challenge_active), str(fsm_module.challenge_crashed), fsm_module.last_login_date, fsm_module.current_day])
	was_reset = fsm_module.check_and_reset_if_missed()
	if was_reset and ErrorReporter and ErrorReporter.has_method("report_warning"):
		ErrorReporter.report_warning(ERROR_CONTEXT, "Challenge reset due to missed day, challenge is now inactive, will restart")
func _update_timer_display() -> void:
	if not game_state or not timer_label:
		return
	var fsm_module = game_state.get_fsm_challenge_module()
	if not fsm_module:
		return
	if fsm_module.is_today_completed():
		var time_str = fsm_module.format_time_until_next_day()
		timer_label.text = _tr("FSM_CHALLENGE_NEXT_DAY_TIMER") % time_str
		timer_label.show()
	else:
		timer_label.hide()
	_update_completion_state()
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				if is_showing_crash:
					_on_crash_back_pressed()
				else:
					_close()
				get_viewport().set_input_as_handled()
			KEY_ENTER, KEY_KP_ENTER:
				get_viewport().set_input_as_handled()
				if _is_invitation_active:
					_on_invitation_accept()
					return
				if confirm_button and confirm_button.visible and not confirm_button.disabled:
					_on_confirm_pressed()
					return
				if submit_button and submit_button.visible:
					_on_submit_pressed()
					return
				if ErrorReporter and ErrorReporter.has_method("report_info"):
					ErrorReporter.report_info(ERROR_CONTEXT, "Enter key pressed but no action to take (confirm_visible=%s, submit_visible=%s)" % [str(confirm_button.visible if confirm_button else false), str(submit_button.visible if submit_button else false)])
func _show_invitation() -> void:
	_is_invitation_active = true
	if invitation_panel:
		invitation_panel.show()
		UIStyleManager.fade_in(invitation_panel, 0.6)
	if challenge_panel:
		challenge_panel.hide()
	if invitation_title:
		invitation_title.text = _tr("FSM_CHALLENGE_INVITE_TITLE")
		UIStyleManager.add_glow_effect(invitation_title, Color(1, 0.9, 0.4, 1), 0.35)
	if invitation_body:
		invitation_body.text = "[center]" + _tr("FSM_CHALLENGE_INVITE_BODY") + "[/center]"
	if invitation_happy:
		invitation_happy.tooltip_text = _tr("FSM_CHALLENGE_INVITE_ACCEPT_DESC")
		UIStyleManager.pulse_effect(invitation_happy, 0.04, 2.0)
	if invitation_sad:
		invitation_sad.tooltip_text = _tr("FSM_CHALLENGE_INVITE_DECLINE_DESC")
	if invitation_fsm_image:
		UIStyleManager.pulse_effect(invitation_fsm_image, 0.06, 2.5)
	if invitation_teacher:
		UIStyleManager.pulse_effect(invitation_teacher, 0.035, 2.2)
	if invitation_badge:
		UIStyleManager.pulse_effect(invitation_badge, 0.03, 1.8)
	_animate_invitation_images()
func _hide_invitation() -> void:
	_is_invitation_active = false
	if invitation_panel:
		invitation_panel.hide()
	if challenge_panel:
		challenge_panel.show()
func _on_invitation_accept() -> void:
	_mark_invitation_seen()
	_start_challenge_if_needed()
	_hide_invitation()
	_update_ui_for_day(current_day)
	_play_magic_pulse(invitation_happy)
func _on_invitation_decline() -> void:
	if audio_manager:
		audio_manager.play_sfx("ui_error", 0.8)
	_hide_invitation()
	_close()
func _start_challenge_if_needed() -> void:
	if not game_state:
		return
	var fsm_module = game_state.get_fsm_challenge_module()
	if not fsm_module:
		return
	if not fsm_module.is_challenge_active:
		fsm_module.start_challenge()
		if game_state.has_method("save_game"):
			game_state.save_game()
func _has_seen_invitation() -> bool:
	if not game_state:
		return false
	return bool(game_state.get_metadata(INVITE_METADATA_KEY, false))
func _mark_invitation_seen() -> void:
	if not game_state:
		return
	game_state.set_metadata(INVITE_METADATA_KEY, true)
func _update_completion_state() -> void:
	if not game_state:
		if completion_container:
			completion_container.hide()
		return
	var fsm_module = game_state.get_fsm_challenge_module()
	if not fsm_module:
		return
	var completed_today: bool = bool(fsm_module.is_today_completed())
	if VERBOSE_LOGS and ErrorReporter and ErrorReporter.has_method("report_info"):
		ErrorReporter.report_info(ERROR_CONTEXT, "Update completion state: day=%d, completed_today=%s, active=%s, days_completed=%s" % [current_day, str(completed_today), str(fsm_module.is_challenge_active), str(fsm_module.days_completed)])
	if completed_today:
		for node in [title_label, day_label, theme_label, content_bg_panel, content_scroll, instruction_label, input_container, button_container, click_count_label, rebirth_explanation_button, sublimation_panel]:
			if node: node.hide()
		if timer_label:
			timer_label.add_theme_font_size_override("font_size", TIMER_FONT_SIZE_LARGE)
			timer_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			timer_label.show()
		if completion_gloria_image:
			completion_gloria_image.hide()
		if completion_fsm_image:
			completion_fsm_image.hide()
		if completion_container:
			completion_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
			if not completion_container.visible:
				completion_container.show()
				completion_container.modulate.a = 0.0
				var comp_tween := create_tween()
				_magic_tweens.append(comp_tween)
				comp_tween.tween_property(completion_container, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			else:
				completion_container.show()
		if completion_title_label:
			completion_title_label.text = _tr("FSM_CHALLENGE_TODAY_DONE")
		var theme_text := FSMDailyContentData.get_day_theme(current_day)
		if completion_theme_label:
			completion_theme_label.text = _tr("FSM_CHALLENGE_LEARNED_FMT") % theme_text
		if not _calendar_grid or not is_instance_valid(_calendar_grid):
			_build_calendar_grid(fsm_module)
	else:
		if timer_label:
			timer_label.add_theme_font_size_override("font_size", TIMER_FONT_SIZE_DEFAULT)
			timer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if completion_container:
			completion_container.hide()
		if _calendar_grid and is_instance_valid(_calendar_grid):
			_calendar_grid.queue_free()
			_calendar_grid = null
		if title_label: title_label.show()
		if day_label: day_label.show()
		var is_confirm_phase = (click_count >= required_clicks)
		if theme_label: theme_label.show()
		if content_bg_panel: content_bg_panel.show()
		if content_scroll: content_scroll.show()
		if sublimation_panel: sublimation_panel.show()
		if instruction_label: instruction_label.show()
		if click_count_label: click_count_label.show()
		if rebirth_explanation_button: rebirth_explanation_button.show()
		if is_confirm_phase:
			if input_container: input_container.hide()
			if button_container: button_container.show()
			if copy_button: copy_button.hide()
			if submit_button: submit_button.hide()
			if confirm_button: confirm_button.show()
		else:
			if input_container: input_container.show()
			if button_container: button_container.show()
			if copy_button: copy_button.show()
			if submit_button: submit_button.show()
			if confirm_button: confirm_button.hide()
func _build_calendar_grid(fsm_module) -> void:
	if not completion_container:
		return
	if _calendar_grid and is_instance_valid(_calendar_grid):
		_calendar_grid.queue_free()
		_calendar_grid = null
	var completed_day_count: int = current_day
	_spawn_floating_gloria()
	var scroll := ScrollContainer.new()
	scroll.layout_mode = 2
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	completion_container.add_child(scroll)
	var center_box := VBoxContainer.new()
	center_box.layout_mode = 2
	center_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_box.alignment = BoxContainer.ALIGNMENT_CENTER
	center_box.add_theme_constant_override("separation", 16)
	scroll.add_child(center_box)
	var cal_title := Label.new()
	cal_title.text = "30 Day Rebirth Collection"
	cal_title.add_theme_font_size_override("font_size", 24)
	cal_title.add_theme_color_override("font_color", Color(1, 0.84, 0, 1))
	cal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_box.add_child(cal_title)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.layout_mode = 2
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	center_box.add_child(grid)
	_calendar_grid = scroll
	for day in range(1, 31):
		var cell := _create_calendar_cell(day, completed_day_count)
		grid.add_child(cell)
func _create_calendar_cell(day: int, completed_up_to: int) -> PanelContainer:
	var cell := PanelContainer.new()
	cell.custom_minimum_size = Vector2(150, 160)
	cell.clip_contents = true
	var is_completed := day <= completed_up_to
	var has_image := day >= 1 and day <= 8
	var style := StyleBoxFlat.new()
	if is_completed:
		style.bg_color = Color(0.1, 0.18, 0.12, 0.9)
		style.border_color = Color(0.4, 0.85, 0.45, 0.6)
	elif day == completed_up_to + 1:
		style.bg_color = Color(0.18, 0.15, 0.08, 0.9)
		style.border_color = Color(1, 0.84, 0, 0.5)
	else:
		style.bg_color = Color(0.08, 0.08, 0.14, 0.85)
		style.border_color = Color(0.3, 0.3, 0.45, 0.4)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	cell.add_theme_stylebox_override("panel", style)
	var margin := MarginContainer.new()
	margin.layout_mode = 2
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	cell.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.layout_mode = 2
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)
	var day_label_cell := Label.new()
	day_label_cell.text = "Day %d" % day
	day_label_cell.add_theme_font_size_override("font_size", 14)
	day_label_cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if is_completed:
		day_label_cell.add_theme_color_override("font_color", Color(0.5, 1.0, 0.65))
	else:
		day_label_cell.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7, 0.8))
	vbox.add_child(day_label_cell)
	if has_image:
		var tex_rect := TextureRect.new()
		var day_tex = load("res://1.Codebase/src/assets/rebirth_challenge/rebirth_day_%d.png" % day)
		if day_tex:
			tex_rect.texture = day_tex
		tex_rect.custom_minimum_size = Vector2(110, 110)
		tex_rect.expand_mode = 1
		tex_rect.stretch_mode = 5
		tex_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		if not is_completed:
			tex_rect.modulate = Color(0.3, 0.3, 0.3, 0.6)
		vbox.add_child(tex_rect)
	else:
		var question := Label.new()
		question.text = "?"
		question.add_theme_font_size_override("font_size", 48)
		question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		question.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		question.custom_minimum_size = Vector2(110, 110)
		if is_completed:
			question.add_theme_color_override("font_color", Color(0.5, 1.0, 0.65, 0.7))
		else:
			question.add_theme_color_override("font_color", Color(0.4, 0.4, 0.55, 0.5))
		vbox.add_child(question)
	if is_completed:
		var check_rect := TextureRect.new()
		check_rect.texture = ICON_CHECK
		check_rect.custom_minimum_size = Vector2(28, 28)
		check_rect.expand_mode = 1
		check_rect.stretch_mode = 5
		check_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		check_rect.modulate = Color(0.4, 1.0, 0.5, 0.9)
		vbox.add_child(check_rect)
	else:
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(28, 28)
		vbox.add_child(spacer)
	return cell
func _spawn_floating_gloria() -> void:
	_remove_floating_gloria()
	if not challenge_panel:
		return
	var gloria_tex = load("res://1.Codebase/src/assets/characters/gloria_protagonis_happy.png")
	if not gloria_tex:
		return
	var vp_size = get_viewport_rect().size
	var count := 10
	for i in range(count):
		var icon := TextureRect.new()
		icon.texture = gloria_tex
		var icon_size = randf_range(32, 64)
		icon.custom_minimum_size = Vector2(icon_size, icon_size)
		icon.size = Vector2(icon_size, icon_size)
		icon.expand_mode = 1
		icon.stretch_mode = 5
		icon.modulate = Color(1, 1, 1, randf_range(0.08, 0.18))
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var col := i % 5
		var row := i / 5
		icon.position = Vector2(
			(col + 0.5) * (vp_size.x / 5.0) - icon_size / 2.0 + randf_range(-60, 60),
			(row + 0.5) * (vp_size.y / 2.0) - icon_size / 2.0 + randf_range(-40, 40)
		)
		var speed = randf_range(25.0, 70.0)
		var angle = randf_range(0, TAU)
		_gloria_velocities.append(Vector2(cos(angle), sin(angle)) * speed)
		_gloria_rot_speeds.append(randf_range(-0.4, 0.4))
		challenge_panel.add_child(icon)
		challenge_panel.move_child(icon, 0)
		_floating_glorias.append(icon)
func _process(delta: float) -> void:
	var vp_size = get_viewport_rect().size
	for i in range(_floating_glorias.size()):
		var icon: TextureRect = _floating_glorias[i]
		if not icon or not is_instance_valid(icon) or not icon.visible:
			continue
		var vel: Vector2 = _gloria_velocities[i]
		icon.position += vel * delta
		icon.rotation += _gloria_rot_speeds[i] * delta
		var s = icon.size
		if icon.position.x <= 0:
			icon.position.x = 0
			vel.x *= -1
		elif icon.position.x + s.x >= vp_size.x:
			icon.position.x = vp_size.x - s.x
			vel.x *= -1
		if icon.position.y <= 0:
			icon.position.y = 0
			vel.y *= -1
		elif icon.position.y + s.y >= vp_size.y:
			icon.position.y = vp_size.y - s.y
			vel.y *= -1
		_gloria_velocities[i] = vel
func _remove_floating_gloria() -> void:
	for icon in _floating_glorias:
		if icon and is_instance_valid(icon):
			icon.queue_free()
	_floating_glorias.clear()
	_gloria_velocities.clear()
	_gloria_rot_speeds.clear()
func _apply_golden_button_style(btn: Button) -> void:
	var s_normal := StyleBoxFlat.new()
	s_normal.bg_color = Color(0.45, 0.32, 0.04, 0.9)
	s_normal.corner_radius_top_left = 10
	s_normal.corner_radius_top_right = 10
	s_normal.corner_radius_bottom_left = 10
	s_normal.corner_radius_bottom_right = 10
	s_normal.border_width_left = 2
	s_normal.border_width_top = 2
	s_normal.border_width_right = 2
	s_normal.border_width_bottom = 2
	s_normal.border_color = Color(1, 0.84, 0.1, 0.85)
	s_normal.shadow_color = Color(1, 0.75, 0.0, 0.35)
	s_normal.shadow_size = 8
	s_normal.content_margin_left = 18
	s_normal.content_margin_right = 18
	s_normal.content_margin_top = 10
	s_normal.content_margin_bottom = 10
	var s_hover := s_normal.duplicate()
	s_hover.bg_color = Color(0.55, 0.40, 0.06, 0.95)
	s_hover.border_color = Color(1, 0.92, 0.3, 1.0)
	s_hover.shadow_color = Color(1, 0.82, 0.1, 0.55)
	s_hover.shadow_size = 12
	var s_press := s_normal.duplicate()
	s_press.bg_color = Color(0.35, 0.24, 0.02, 1.0)
	btn.add_theme_stylebox_override("normal", s_normal)
	btn.add_theme_stylebox_override("hover", s_hover)
	btn.add_theme_stylebox_override("pressed", s_press)
	btn.add_theme_color_override("font_color", Color(1, 0.95, 0.5))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 0.7))
	btn.add_theme_font_size_override("font_size", 17)
func _apply_ghost_button_style(btn: Button) -> void:
	var s_normal := StyleBoxFlat.new()
	s_normal.bg_color = Color(0.1, 0.1, 0.18, 0.5)
	s_normal.corner_radius_top_left = 8
	s_normal.corner_radius_top_right = 8
	s_normal.corner_radius_bottom_left = 8
	s_normal.corner_radius_bottom_right = 8
	s_normal.border_width_left = 1
	s_normal.border_width_top = 1
	s_normal.border_width_right = 1
	s_normal.border_width_bottom = 1
	s_normal.border_color = Color(0.5, 0.5, 0.65, 0.5)
	s_normal.content_margin_left = 12
	s_normal.content_margin_right = 12
	s_normal.content_margin_top = 6
	s_normal.content_margin_bottom = 6
	var s_hover := s_normal.duplicate()
	s_hover.bg_color = Color(0.85, 0.25, 0.2, 0.8)
	s_hover.border_color = Color(1, 0.4, 0.35, 0.8)
	var s_press := s_normal.duplicate()
	s_press.bg_color = Color(0.7, 0.15, 0.1, 0.9)
	btn.add_theme_stylebox_override("normal", s_normal)
	btn.add_theme_stylebox_override("hover", s_hover)
	btn.add_theme_stylebox_override("pressed", s_press)
	btn.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75))
	btn.add_theme_color_override("font_hover_color", Color(1, 0.9, 0.9))
	btn.add_theme_font_size_override("font_size", 14)
func _apply_info_button_style(btn: Button) -> void:
	var s_normal := StyleBoxFlat.new()
	s_normal.bg_color = Color(0.08, 0.15, 0.28, 0.8)
	s_normal.corner_radius_top_left = 12
	s_normal.corner_radius_top_right = 12
	s_normal.corner_radius_bottom_left = 12
	s_normal.corner_radius_bottom_right = 12
	s_normal.border_width_left = 1
	s_normal.border_width_top = 1
	s_normal.border_width_right = 1
	s_normal.border_width_bottom = 1
	s_normal.border_color = Color(0.3, 0.6, 1.0, 0.55)
	s_normal.shadow_color = Color(0.2, 0.5, 1.0, 0.2)
	s_normal.shadow_size = 6
	s_normal.content_margin_left = 16
	s_normal.content_margin_right = 16
	s_normal.content_margin_top = 8
	s_normal.content_margin_bottom = 8
	var s_hover := s_normal.duplicate()
	s_hover.bg_color = Color(0.12, 0.22, 0.40, 0.9)
	s_hover.border_color = Color(0.4, 0.75, 1.0, 0.85)
	s_hover.shadow_color = Color(0.3, 0.6, 1.0, 0.4)
	s_hover.shadow_size = 10
	var s_press := s_normal.duplicate()
	s_press.bg_color = Color(0.06, 0.1, 0.22, 1.0)
	btn.add_theme_stylebox_override("normal", s_normal)
	btn.add_theme_stylebox_override("hover", s_hover)
	btn.add_theme_stylebox_override("pressed", s_press)
	btn.add_theme_color_override("font_color", Color(0.55, 0.82, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(0.75, 0.95, 1.0))
	btn.add_theme_font_size_override("font_size", 15)
func _apply_timer_pill_style(lbl: Label) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.18, 0.12, 0.02, 0.88)
	s.corner_radius_top_left = 20
	s.corner_radius_top_right = 20
	s.corner_radius_bottom_left = 20
	s.corner_radius_bottom_right = 20
	s.border_width_left = 2
	s.border_width_top = 2
	s.border_width_right = 2
	s.border_width_bottom = 2
	s.border_color = Color(1, 0.78, 0.15, 0.7)
	s.shadow_color = Color(1, 0.7, 0.0, 0.3)
	s.shadow_size = 8
	s.content_margin_left = 24
	s.content_margin_right = 24
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	lbl.add_theme_stylebox_override("normal", s)
func _apply_text_input_style(te: TextEdit) -> void:
	var s_normal := StyleBoxFlat.new()
	s_normal.bg_color = Color(0.06, 0.07, 0.12, 0.95)
	s_normal.corner_radius_top_left = 10
	s_normal.corner_radius_top_right = 10
	s_normal.corner_radius_bottom_left = 10
	s_normal.corner_radius_bottom_right = 10
	s_normal.border_width_left = 2
	s_normal.border_width_top = 2
	s_normal.border_width_right = 2
	s_normal.border_width_bottom = 2
	s_normal.border_color = Color(0.3, 0.38, 0.6, 0.6)
	s_normal.content_margin_left = 14
	s_normal.content_margin_right = 14
	s_normal.content_margin_top = 10
	s_normal.content_margin_bottom = 10
	var s_focus := s_normal.duplicate()
	s_focus.border_color = Color(0.4, 0.65, 1.0, 0.9)
	s_focus.shadow_color = Color(0.3, 0.55, 1.0, 0.25)
	s_focus.shadow_size = 6
	te.add_theme_stylebox_override("normal", s_normal)
	te.add_theme_stylebox_override("focus", s_focus)
	te.add_theme_color_override("font_color", Color(0.9, 0.92, 1.0))
	te.add_theme_color_override("font_placeholder_color", Color(0.45, 0.5, 0.65, 0.7))
	te.add_theme_font_size_override("font_size", 16)
func _apply_magic_styles() -> void:
	if challenge_panel:
		var cp_style := StyleBoxFlat.new()
		cp_style.bg_color = Color(0.06, 0.06, 0.12, 0.94)
		cp_style.corner_radius_top_left = 0
		cp_style.corner_radius_top_right = 0
		cp_style.corner_radius_bottom_left = 0
		cp_style.corner_radius_bottom_right = 0
		cp_style.shadow_color = Color(0, 0, 0, 0)
		cp_style.shadow_size = 0
		challenge_panel.add_theme_stylebox_override("panel", cp_style)
	if invitation_panel:
		var ip_style := StyleBoxFlat.new()
		ip_style.bg_color = Color(0.05, 0.04, 0.12, 0.92)
		ip_style.corner_radius_top_left = 0
		ip_style.corner_radius_top_right = 0
		ip_style.corner_radius_bottom_left = 0
		ip_style.corner_radius_bottom_right = 0
		ip_style.shadow_color = Color(0, 0, 0, 0)
		ip_style.shadow_size = 0
		invitation_panel.add_theme_stylebox_override("panel", ip_style)
	if content_bg_panel:
		var content_style := StyleBoxFlat.new()
		content_style.bg_color = Color(0.06, 0.07, 0.14, 0.88)
		content_style.corner_radius_top_left = 14
		content_style.corner_radius_top_right = 14
		content_style.corner_radius_bottom_left = 14
		content_style.corner_radius_bottom_right = 14
		content_style.border_width_left = 1
		content_style.border_width_top = 1
		content_style.border_width_right = 1
		content_style.border_width_bottom = 1
		content_style.border_color = Color(0.35, 0.42, 0.65, 0.5)
		content_style.shadow_color = Color(0, 0, 0, 0.4)
		content_style.shadow_size = 8
		content_style.shadow_offset = Vector2(0, 3)
		content_bg_panel.add_theme_stylebox_override("panel", content_style)
	if completion_container:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.06, 0.16, 0.10, 0.88)
		style.corner_radius_top_left = 18
		style.corner_radius_top_right = 18
		style.corner_radius_bottom_left = 18
		style.corner_radius_bottom_right = 18
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.3, 0.85, 0.45, 0.55)
		style.shadow_color = Color(0.1, 0.7, 0.3, 0.35)
		style.shadow_size = 14
		completion_container.add_theme_stylebox_override("panel", style)
func _setup_crash_panel_style() -> void:
	if not crash_panel:
		return
	var crash_style := StyleBoxFlat.new()
	crash_style.bg_color = Color(0.06, 0.02, 0.02, 0.96)
	crash_style.corner_radius_top_left = 0
	crash_style.corner_radius_top_right = 0
	crash_style.corner_radius_bottom_left = 0
	crash_style.corner_radius_bottom_right = 0
	crash_style.border_width_left = 0
	crash_style.border_width_top = 3
	crash_style.border_width_right = 0
	crash_style.border_width_bottom = 3
	crash_style.border_color = Color(1, 0.15, 0.15, 0.6)
	crash_style.shadow_color = Color(1, 0, 0, 0.15)
	crash_style.shadow_size = 20
	crash_panel.add_theme_stylebox_override("panel", crash_style)
func _animate_invitation_images() -> void:
	var images: Array = [invitation_happy, invitation_fsm_image, invitation_sad, invitation_teacher]
	var delay := 0.0
	for img in images:
		if not img:
			continue
		img.modulate.a = 0.0
		img.scale = Vector2(0.8, 0.8)
		if img.size != Vector2.ZERO:
			img.pivot_offset = img.size / 2
		var tween := create_tween()
		_magic_tweens.append(tween)
		tween.set_parallel(true)
		tween.tween_property(img, "modulate:a", 1.0, 0.4).set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(img, "scale", Vector2.ONE, 0.5).set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		delay += 0.15
func _play_magic_pulse(node: Control) -> void:
	if not node:
		return
	var tween = create_tween()
	_magic_tweens.append(tween)
	tween.set_loops(0)
	tween.tween_property(node, "scale", Vector2(1.05, 1.05), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "modulate", Color(1, 1, 1, 0.95), 0.3)
	tween.tween_property(node, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(node, "modulate", Color(1, 1, 1, 0.82), 0.4)
func _clear_magic_tweens() -> void:
	for t in _magic_tweens:
		if t:
			t.kill()
	_magic_tweens.clear()
func _setup_content_with_image(day: int, day_data: Dictionary) -> void:
	if not content_label:
		return
	var image_path := FSMDailyContentData.get_day_image_path(day)
	var content_text: String = day_data["content"]
	if image_path.is_empty():
		content_label.text = "[color=#E0E0E0]%s[/color]" % content_text
		return
	var paragraphs := content_text.split("\n")
	var non_empty: Array[String] = []
	for p in paragraphs:
		if not p.strip_edges().is_empty():
			non_empty.append(p)
	var split_at := mini(2, non_empty.size())
	var first_part := "\n".join(non_empty.slice(0, split_at))
	var second_part := "\n".join(non_empty.slice(split_at))
	var bbcode := ""
	bbcode += "[color=#E0E0E0]%s[/color]\n\n" % first_part
	bbcode += "[center][img=360x360]%s[/img][/center]" % image_path
	if not second_part.is_empty():
		bbcode += "\n\n[color=#E0E0E0]%s[/color]" % second_part
	content_label.text = bbcode
func _update_sublimation_display(day_data: Dictionary) -> void:
	if not sublimation_label or not sublimation_panel:
		return
	var sub_text: String = day_data.get("sublimation", "")
	if sub_text.is_empty():
		sublimation_panel.hide()
		return
	sublimation_panel.show()
	sublimation_label.text = "[center][color=#FFE566][i]\"%s\"[/i][/color][/center]" % sub_text
func _apply_sublimation_panel_style(panel: Panel) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.28, 0.18, 0.06, 0.88)
	style.border_color = Color(1.0, 0.78, 0.15, 0.75)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)
