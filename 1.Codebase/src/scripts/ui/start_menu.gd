extends Control
const ERROR_CONTEXT := "StartMenu"
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
const IntroStoryScript = preload("res://1.Codebase/src/scripts/ui/intro_story.gd")
const ICON_JOURNAL = preload("res://1.Codebase/src/assets/ui/icon_journal.svg")
const ICON_ACHIEVEMENTS = preload("res://1.Codebase/src/assets/ui/icon_achievements.svg")
const ICON_SETTINGS = preload("res://1.Codebase/src/assets/ui/icon_settings.svg")
const ICON_PLAY = preload("res://1.Codebase/src/assets/ui/icon_play.svg")
const ICON_SAVE = preload("res://1.Codebase/src/assets/ui/icon_save.svg")
const ICON_INFO = preload("res://1.Codebase/src/assets/ui/icon_info.svg")
const ICON_QUIT = preload("res://1.Codebase/src/assets/ui/icon_quit.svg")
const ICON_CREATIVE = preload("res://1.Codebase/src/assets/ui/icon_creative.svg")
const ICON_TERMS = preload("res://1.Codebase/src/assets/ui/icon_terms.svg")
const ICON_YOUTUBE = preload("res://1.Codebase/src/assets/ui/icon_youtube.svg")
const ICON_GITHUB = preload("res://1.Codebase/src/assets/ui/icon_github.svg")
const ICON_REBIRTH = preload("res://1.Codebase/src/assets/ui/icon_refresh.svg")
const GITHUB_URL = "https://github.com/dun4law/Final-Year-Project"
const YOUTUBE_URL = "https://www.youtube.com/watch?v=dQw4w9WgXcQ/"
const LYRICS_EASTER_EGG_URL := "https://www.youtube.com/watch?v=O7-81uAmgIw"
const GAME_VERSION = "V1.0 Alpha"
const _GEMINI_KEY_MISSING_MESSAGE := "Gemini is selected, but no Gemini API key is configured. Open Settings > AI Settings to enter your key, or switch to OpenRouter/Ollama."
const VERBOSE_LOGS := GameConstants.Debug.ENABLE_VERBOSE_LOGS
var current_language: String = "en"
var audio_manager: Node = null
var game_state: Node = null
var error_reporter: Node = null
var font_manager: Node = null
var github_button: TextureButton
var youtube_button: TextureButton
var version_label: Label
@onready var menu_container: CenterContainer = $MenuContainer
@onready var panel: Panel = $MenuContainer/Panel
@onready var content_container: VBoxContainer = $MenuContainer/Panel/VBoxContainer
@onready var spacer: Control = $MenuContainer/Panel/VBoxContainer/Spacer
@onready var logo_texture: TextureRect = $MenuContainer/Panel/VBoxContainer/LogoContainer/Logo
@onready var background_overlay: ColorRect = $BackgroundOverlay
@onready var scroll_container: ScrollContainer = $MenuContainer/Panel/VBoxContainer/ScrollContainer
@onready var buttons_container: VBoxContainer = $MenuContainer/Panel/VBoxContainer/ScrollContainer/ButtonsContainer
@onready var primary_buttons_grid: GridContainer = $MenuContainer/Panel/VBoxContainer/ScrollContainer/ButtonsContainer/PrimaryButtonsGrid
@onready var start_button: Button = $MenuContainer/Panel/VBoxContainer/ScrollContainer/ButtonsContainer/PrimaryButtonsGrid/StartButton
@onready var continue_button: Button = $MenuContainer/Panel/VBoxContainer/ScrollContainer/ButtonsContainer/PrimaryButtonsGrid/ContinueButton
@onready var continue_info_label: Label = $MenuContainer/Panel/VBoxContainer/ScrollContainer/ButtonsContainer/ContinueInfo
@onready var save_load_button: Button = $MenuContainer/Panel/VBoxContainer/ScrollContainer/ButtonsContainer/PrimaryButtonsGrid/SaveLoadButton
@onready var journal_button: Button = $MenuContainer/Panel/VBoxContainer/ScrollContainer/ButtonsContainer/PrimaryButtonsGrid/JournalButton
@onready var achievements_button: Button = $MenuContainer/Panel/VBoxContainer/ScrollContainer/ButtonsContainer/PrimaryButtonsGrid/AchievementsButton
@onready var settings_button: Button = $MenuContainer/Panel/VBoxContainer/ScrollContainer/ButtonsContainer/PrimaryButtonsGrid/SettingsButton
@onready var intro_button: Button = $MenuContainer/Panel/VBoxContainer/ScrollContainer/ButtonsContainer/PrimaryButtonsGrid/IntroButton
@onready var quit_button: Button = $MenuContainer/Panel/VBoxContainer/ScrollContainer/ButtonsContainer/PrimaryButtonsGrid/QuitButton
@onready var creative_statement_button: Button = $MenuContainer/Panel/VBoxContainer/FooterButtons/CreativeStatementButton
@onready var terms_button: Button = $MenuContainer/Panel/VBoxContainer/FooterButtons/TermsButton
@onready var fsm_challenge_button: Button = null  
var fsm_challenge_overlay_scene = preload("res://1.Codebase/src/scenes/ui/fsm_challenge_overlay.tscn")
var fsm_challenge_overlay: Control = null
var _exit_confirmation_dialog: ConfirmationDialog = null
var _pending_quit_request: bool = false
const _GLORIA_SEQUENCE := [KEY_G, KEY_L, KEY_O, KEY_R, KEY_I, KEY_A]
var _gloria_seq_index: int = 0
var _gloria_seq_timer: float = 0.0
const _GLORIA_SEQ_TIMEOUT := 3.0
const _SUPER_SEQUENCE := [KEY_S, KEY_U, KEY_P, KEY_E, KEY_R]
var _super_seq_index: int = 0
var _super_seq_timer: float = 0.0
const _SUPER_SEQ_TIMEOUT := 3.0
var _logo_click_count: int = 0
var _logo_click_timer: float = 0.0
const _LOGO_CLICK_TIMEOUT := 4.0
const _LOGO_CLICK_TARGET := 7
var _youtube_click_count: int = 0
var _youtube_click_timer: float = 0.0
const _YOUTUBE_CLICK_TIMEOUT := 2.5
var _fsm_inbox_prayer_index: int = 0
var _fsm_inbox_popup: Control = null
var _lyrics_click_count: int = 0
var _lyrics_click_timer: float = 0.0
const _LYRICS_CLICK_TIMEOUT := 5.0
const _LYRICS_CLICK_TARGET := 5
var _lyrics_label: Label = null
@onready var all_buttons: Array = [
	start_button,
	continue_button,
	save_load_button,
	journal_button,
	achievements_button,
	settings_button,
	intro_button,
	quit_button,
	creative_statement_button,
	terms_button,
]
func _ready():
	_report_info("Initializing start menu (version: %s, lang: %s)" % [GAME_VERSION, current_language])
	var tree := get_tree()
	if tree:
		tree.set_auto_accept_quit(false)
	_create_exit_confirmation_dialog()
	_refresh_services()
	if font_manager and font_manager.has_method("load_font_settings"):
		font_manager.load_font_settings()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	content_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_social_buttons()
	var state := _get_game_state()
	if state and state.has_method("load_game"):
		state.load_game()
		state.just_loaded_from_save = false
	_load_language_from_settings()
	current_language = state.current_language if state else "en"
	if font_manager and font_manager.has_method("apply_language_font"):
		font_manager.apply_language_font(current_language)
	update_ui_text()
	_apply_styles()
	update_ui_text()
	_apply_styles()
	_set_creative_statement_text()
	_assign_icons()
	_refresh_continue_state()
	_setup_fsm_challenge_button()
	if tree:
		await tree.process_frame
	_update_layout()
	if not resized.is_connected(_on_control_resized):
		resized.connect(_on_control_resized)
	if _should_auto_resume():
		_debug_log("[StartMenu] Auto-resuming interrupted game session...")
		_auto_resume_game()
		return
	_animate_menu_entrance()
	_animate_social_buttons()
	if start_button:
		start_button.grab_focus()
	var audio := _get_audio_manager()
	if audio and not audio.is_music_playing():
		audio.play_music("background_music", true)
	_connect_button_sounds()
	_setup_logo_easter_egg()
	_setup_lyrics_easter_egg()
func _setup_logo_easter_egg() -> void:
	if not logo_texture:
		return
	logo_texture.mouse_filter = Control.MOUSE_FILTER_STOP
	logo_texture.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	logo_texture.gui_input.connect(_on_logo_gui_input)
func _on_logo_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_logo_click_count += 1
		_logo_click_timer = _LOGO_CLICK_TIMEOUT
		if _logo_click_count >= _LOGO_CLICK_TARGET:
			_logo_click_count = 0
			_logo_click_timer = 0.0
			_show_gloria_diary_easter_egg()
func _setup_lyrics_easter_egg() -> void:
	_lyrics_label = Label.new()
	_lyrics_label.text = "仿佛似是歡樂 仿佛也是冷漠 · 世事何曾是絕對"
	_lyrics_label.add_theme_font_size_override("font_size", 10)
	_lyrics_label.add_theme_color_override("font_color", Color(0.55, 0.50, 0.65, 0.35))
	_lyrics_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lyrics_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_lyrics_label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_lyrics_label.gui_input.connect(_on_lyrics_gui_input)
	content_container.add_child(_lyrics_label)
func _on_lyrics_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	_lyrics_click_count += 1
	_lyrics_click_timer = _LYRICS_CLICK_TIMEOUT
	if _lyrics_label and is_instance_valid(_lyrics_label):
		var tw := create_tween()
		tw.tween_property(_lyrics_label, "modulate", Color(0.85, 0.75, 1.0, 1.0), 0.12)
		tw.tween_property(_lyrics_label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
	if _lyrics_click_count >= _LYRICS_CLICK_TARGET:
		_lyrics_click_count = 0
		_lyrics_click_timer = 0.0
		OS.shell_open(LYRICS_EASTER_EGG_URL)
		_debug_log("[StartMenu] Easter egg triggered: 世事何曾是絕對")
func _process(delta: float) -> void:
	if _gloria_seq_index > 0:
		_gloria_seq_timer -= delta
		if _gloria_seq_timer <= 0.0:
			_gloria_seq_index = 0
	if _logo_click_count > 0:
		_logo_click_timer -= delta
		if _logo_click_timer <= 0.0:
			_logo_click_count = 0
	if _youtube_click_count > 0:
		_youtube_click_timer -= delta
		if _youtube_click_timer <= 0.0:
			_youtube_click_count = 0
	if _super_seq_index > 0:
		_super_seq_timer -= delta
		if _super_seq_timer <= 0.0:
			_super_seq_index = 0
	if _lyrics_click_count > 0:
		_lyrics_click_timer -= delta
		if _lyrics_click_timer <= 0.0:
			_lyrics_click_count = 0
func _exit_tree() -> void:
	if get_tree():
		get_tree().set_auto_accept_quit(true)
	_cleanup_exit_confirmation_dialog()
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			_request_quit_confirmation()
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if fsm_challenge_overlay and fsm_challenge_overlay.visible:
		return
	var key_code := (event as InputEventKey).keycode
	if key_code == _GLORIA_SEQUENCE[_gloria_seq_index]:
		_gloria_seq_index += 1
		_gloria_seq_timer = _GLORIA_SEQ_TIMEOUT
		if _gloria_seq_index >= _GLORIA_SEQUENCE.size():
			_gloria_seq_index = 0
			_gloria_seq_timer = 0.0
			_show_teacher_chan_easter_egg()
			get_viewport().set_input_as_handled()
			return
	else:
		_gloria_seq_index = 0
		_gloria_seq_timer = 0.0
	if key_code == _SUPER_SEQUENCE[_super_seq_index]:
		_super_seq_index += 1
		_super_seq_timer = _SUPER_SEQ_TIMEOUT
		if _super_seq_index >= _SUPER_SEQUENCE.size():
			_super_seq_index = 0
			_super_seq_timer = 0.0
			_show_cant_touch_easter_egg()
		get_viewport().set_input_as_handled()
		return
	else:
		_super_seq_index = 0
		_super_seq_timer = 0.0
	match key_code:
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			if get_viewport().gui_get_focus_owner() == null:
				_on_start_button_pressed()
				get_viewport().set_input_as_handled()
		KEY_C:
			if continue_button and not continue_button.disabled:
				_on_continue_button_pressed()
				get_viewport().set_input_as_handled()
		KEY_S:
			_on_settings_button_pressed()
			get_viewport().set_input_as_handled()
		KEY_A:
			_on_achievements_button_pressed()
			get_viewport().set_input_as_handled()
		KEY_I:
			_on_intro_button_pressed()
			get_viewport().set_input_as_handled()
		KEY_L:
			_on_save_load_button_pressed()
			get_viewport().set_input_as_handled()
		KEY_J:
			_on_journal_button_pressed()
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			_on_quit_button_pressed()
			get_viewport().set_input_as_handled()
func _setup_social_buttons():
	var social_layer = MarginContainer.new()
	social_layer.name = "SocialLayer"
	social_layer.layout_mode = 1
	social_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	social_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(social_layer)
	var main_vbox = VBoxContainer.new()
	main_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.alignment = BoxContainer.ALIGNMENT_END
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	social_layer.add_child(main_vbox)
	var bottom_row = HBoxContainer.new()
	bottom_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(bottom_row)
	var social_margin = MarginContainer.new()
	social_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	social_margin.size_flags_vertical = Control.SIZE_SHRINK_END
	social_margin.add_theme_constant_override("margin_left", 30)
	social_margin.add_theme_constant_override("margin_bottom", 30)
	bottom_row.add_child(social_margin)
	var social_buttons_box = HBoxContainer.new()
	social_buttons_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	social_buttons_box.add_theme_constant_override("separation", 12)
	social_buttons_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	social_margin.add_child(social_buttons_box)
	youtube_button = TextureButton.new()
	youtube_button.name = "YouTubeButton"
	youtube_button.texture_normal = ICON_YOUTUBE
	youtube_button.ignore_texture_size = true
	youtube_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	youtube_button.custom_minimum_size = Vector2(48, 48)
	youtube_button.size = Vector2(48, 48)
	social_buttons_box.add_child(youtube_button)
	youtube_button.pressed.connect(_on_youtube_button_pressed)
	_add_hover_scale(youtube_button)
	github_button = TextureButton.new()
	github_button.name = "GitHubButton"
	github_button.texture_normal = ICON_GITHUB
	github_button.ignore_texture_size = true
	github_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	github_button.custom_minimum_size = Vector2(48, 48)
	github_button.size = Vector2(48, 48)
	social_buttons_box.add_child(github_button)
	github_button.pressed.connect(_on_github_button_pressed)
	_add_hover_scale(github_button)
	var spacer = Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(spacer)
	var version_margin = MarginContainer.new()
	version_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	version_margin.size_flags_vertical = Control.SIZE_SHRINK_END
	version_margin.add_theme_constant_override("margin_right", 24)
	version_margin.add_theme_constant_override("margin_bottom", 24)
	bottom_row.add_child(version_margin)
	version_label = Label.new()
	var version_format: String = _tr("UI_VERSION")
	if version_format.find("%s") >= 0:
		version_label.text = version_format % GAME_VERSION
	else:
		version_label.text = "Version " + GAME_VERSION
	version_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	version_margin.add_child(version_label)
func _load_texture_safe(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var tex = load(path)
		if tex is Texture2D:
			return tex
	var file_path = path
	if path.begins_with("res://"):
		file_path = ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(file_path):
		file_path = path.replace("res://", "")
	if FileAccess.file_exists(file_path):
		var image = Image.load_from_file(file_path)
		if image:
			return ImageTexture.create_from_image(image)
	_report_warning("Failed to load texture", {"path": path})
	return null
func _add_hover_scale(btn: TextureButton):
	btn.pivot_offset = btn.size / 2
	btn.mouse_entered.connect(func():
		var t = create_tween()
		t.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.1)
		_on_button_hover()
	)
	btn.mouse_exited.connect(func():
		var t = create_tween()
		t.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
	)
func _animate_menu_entrance():
	if not is_inside_tree():
		return
	var tree := get_tree()
	if not tree:
		return
	panel.modulate.a = 0.0
	UIStyleManager.fade_in(panel, 0.5)
	for i in range(all_buttons.size()):
		var button = all_buttons[i]
		if button:
			button.modulate.a = 0.0
			await tree.create_timer(0.05).timeout
			if not is_inside_tree():
				return
			UIStyleManager.fade_in(button, 0.3)
			button.pivot_offset = button.size / 2
			button.scale = Vector2(0.9, 0.9)
			var scale_tween = button.create_tween()
			scale_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			scale_tween.tween_property(button, "scale", Vector2.ONE, 0.4)
	await tree.create_timer(0.8).timeout
	if not is_inside_tree():
		return
	if start_button and start_button.is_inside_tree():
		UIStyleManager.pulse_effect(start_button, 1.08, 1.5)
func _animate_social_buttons():
	if youtube_button:
		youtube_button.modulate.a = 0.0
		UIStyleManager.fade_in(youtube_button, 0.5)
	if github_button:
		github_button.modulate.a = 0.0
		UIStyleManager.fade_in(github_button, 0.5)
	if version_label:
		version_label.modulate.a = 0.0
		UIStyleManager.fade_in(version_label, 0.5)
func update_ui_text():
	start_button.text = _tr("MENU_NEW_GAME")
	continue_button.text = _tr("MENU_CONTINUE")
	save_load_button.text = _tr("MENU_SAVE_LOAD")
	journal_button.text = _tr("MENU_JOURNAL")
	achievements_button.text = _tr("MENU_ACHIEVEMENTS")
	intro_button.text = _tr("MENU_HOW_TO_PLAY")
	terms_button.text = _tr("MENU_TERMS")
	settings_button.text = _tr("MENU_SETTINGS")
	quit_button.text = _tr("MENU_QUIT")
	_refresh_continue_state()
	if logo_texture:
		logo_texture.visible = true
func _apply_styles():
	if background_overlay:
		background_overlay.visible = true
		background_overlay.color = Color(0.03, 0.05, 0.1, 0.30)
		background_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style = panel.get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		style.bg_color = Color(0.05, 0.08, 0.15, 0.40)
		style.border_width_left = 0
		style.border_width_top = 0
		style.border_width_right = 0
		style.border_width_bottom = 0
		style.corner_radius_top_left = 24
		style.corner_radius_top_right = 24
		style.corner_radius_bottom_right = 24
		style.corner_radius_bottom_left = 24
		style.shadow_size = 20
		style.shadow_color = Color(0, 0, 0, 0.5)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if logo_texture:
		logo_texture.modulate = Color(1, 1, 1, 0.95)
	if scroll_container:
		scroll_container.mouse_filter = Control.MOUSE_FILTER_PASS
	_apply_button_styles()
func _apply_button_styles():
	if start_button:
		UIStyleManager.apply_button_style(start_button, "accent", "large")
		UIStyleManager.add_hover_scale_effect(start_button, 1.08)
		UIStyleManager.add_press_feedback(start_button)
	for button in [continue_button, save_load_button, journal_button, achievements_button, settings_button, quit_button]:
		if button:
			UIStyleManager.apply_button_style(button, "primary", "large")
			UIStyleManager.add_hover_scale_effect(button, 1.05)
			UIStyleManager.add_press_feedback(button)
	if intro_button:
		UIStyleManager.apply_button_style(intro_button, "accent", "medium")
		UIStyleManager.add_hover_scale_effect(intro_button, 1.06)
		UIStyleManager.add_press_feedback(intro_button)
	for button in [creative_statement_button, terms_button]:
		if button:
			UIStyleManager.apply_button_style(button, "primary", "small")
			UIStyleManager.add_hover_scale_effect(button, 1.04)
			UIStyleManager.add_press_feedback(button)
	for button in all_buttons:
		if button:
			button.focus_mode = Control.FOCUS_ALL
			button.mouse_filter = Control.MOUSE_FILTER_PASS
			button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
func _set_creative_statement_text():
	if not creative_statement_button:
		return
	creative_statement_button.text = _tr("MENU_CREATIVE_STATEMENT")
func _refresh_continue_state():
	if not continue_button:
		return
	var has_save := false
	var latest_info: Dictionary = { }
	var state := _get_game_state()
	if state and state.has_method("get_latest_save_info"):
		var latest_variant: Variant = state.get_latest_save_info()
		if latest_variant is Dictionary:
			latest_info = latest_variant
			has_save = latest_info.get("exists", false)
	continue_button.disabled = not has_save
	continue_button.focus_mode = Control.FOCUS_ALL if has_save else Control.FOCUS_NONE
	if continue_info_label:
		continue_info_label.visible = true
		if has_save:
			continue_info_label.modulate = Color(1.0, 1.0, 1.0, 0.9)
			continue_info_label.text = _format_continue_info(latest_info)
		else:
			continue_info_label.modulate = Color(1.0, 1.0, 1.0, 0.6)
			continue_info_label.text = _tr("MENU_NO_SAVE_DATA")
func _format_continue_info(info: Dictionary) -> String:
	var reality := int(info.get("reality_score", 0))
	var missions := int(info.get("missions_completed", 0))
	var timestamp_text := _format_save_timestamp(int(info.get("timestamp", 0)))
	var source_text := _get_save_source_label(info)
	return _tr("MENU_LAST_SAVE_FMT") % [reality, missions, source_text, timestamp_text]
func _get_save_source_label(info: Dictionary) -> String:
	var is_autosave: bool = bool(info.get("is_autosave", false))
	if is_autosave:
		return _tr("MENU_AUTOSAVE")
	var slot := int(info.get("save_slot", 0))
	if slot <= 0:
		return _tr("MENU_MANUAL_SAVE")
	return _tr("MENU_SLOT_FMT") % slot
func _format_save_timestamp(timestamp: int) -> String:
	if timestamp <= 0:
		return _tr("MENU_UNKNOWN_TIME")
	var dt := Time.get_datetime_dict_from_unix_time(timestamp)
	if not (dt is Dictionary):
		return _tr("MENU_UNKNOWN_TIME")
	var year := int(dt.get("year", 0))
	var month := int(dt.get("month", 0))
	var day := int(dt.get("day", 0))
	var hour := int(dt.get("hour", 0))
	var minute := int(dt.get("minute", 0))
	return _tr("MENU_TIMESTAMP_FMT") % [year, month, day, hour, minute]
func _setup_fsm_challenge_button():
	var state := _get_game_state()
	if not state:
		return
	var fsm_module = state.get_fsm_challenge_module()
	if not fsm_module:
		return
	if fsm_module.is_challenge_active:
		fsm_module.check_and_reset_if_missed()
	if fsm_module.challenge_crashed:
		return
	if fsm_module.is_challenge_active:
		_create_fsm_progress_button(fsm_module.current_day)
	else:
		_create_fsm_join_button()
func _create_fsm_join_button():
	var target_container: Container = primary_buttons_grid if primary_buttons_grid else buttons_container
	if not target_container:
		return
	fsm_challenge_button = Button.new()
	fsm_challenge_button.name = "FSMChallengeButton"
	fsm_challenge_button.text = _tr("START_FSM_JOIN")
	fsm_challenge_button.icon = ICON_REBIRTH
	fsm_challenge_button.expand_icon = true
	fsm_challenge_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var insert_index = 5
	target_container.add_child(fsm_challenge_button)
	target_container.move_child(fsm_challenge_button, insert_index)
	UIStyleManager.apply_button_style(fsm_challenge_button, "primary", "large")
	UIStyleManager.add_hover_scale_effect(fsm_challenge_button, 1.05)
	fsm_challenge_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	fsm_challenge_button.pressed.connect(_on_fsm_challenge_join_pressed)
	fsm_challenge_button.mouse_entered.connect(_on_button_hover)
	all_buttons.append(fsm_challenge_button)
	_update_layout()
func _create_fsm_progress_button(day: int):
	var target_container: Container = primary_buttons_grid if primary_buttons_grid else buttons_container
	if not target_container:
		return
	fsm_challenge_button = Button.new()
	fsm_challenge_button.name = "FSMChallengeButton"
	fsm_challenge_button.text = _tr("START_FSM_DAY") % day
	fsm_challenge_button.icon = ICON_REBIRTH
	fsm_challenge_button.expand_icon = true
	fsm_challenge_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var insert_index = 5
	target_container.add_child(fsm_challenge_button)
	target_container.move_child(fsm_challenge_button, insert_index)
	UIStyleManager.apply_button_style(fsm_challenge_button, "primary", "large")
	UIStyleManager.add_hover_scale_effect(fsm_challenge_button, 1.05)
	fsm_challenge_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	fsm_challenge_button.pressed.connect(_on_fsm_challenge_continue_pressed)
	fsm_challenge_button.mouse_entered.connect(_on_button_hover)
	all_buttons.append(fsm_challenge_button)
	_update_layout()
func _on_fsm_challenge_join_pressed():
	var audio := _get_audio_manager()
	if audio:
		audio.play_sfx("happy_click", 0.9)
	_show_fsm_challenge_day(1, true)
func _on_fsm_challenge_continue_pressed():
	var audio := _get_audio_manager()
	if audio:
		audio.play_sfx("ui_click", 0.8)
	var state := _get_game_state()
	if not state:
		return
	var fsm_module = state.get_fsm_challenge_module()
	if not fsm_module:
		return
	if fsm_module.can_advance_day():
		fsm_module.advance_to_next_day()
	_show_fsm_challenge_day(fsm_module.current_day)
func _show_fsm_challenge_day(day: int, show_invitation: bool = false):
	if not fsm_challenge_overlay:
		fsm_challenge_overlay = fsm_challenge_overlay_scene.instantiate()
		add_child(fsm_challenge_overlay)
		fsm_challenge_overlay.close_requested.connect(_on_fsm_challenge_closed)
	fsm_challenge_overlay.show_challenge(day, show_invitation)
func _on_fsm_challenge_closed():
	if fsm_challenge_button:
		var old_button = fsm_challenge_button
		all_buttons.erase(old_button)
		old_button.queue_free()
		fsm_challenge_button = null
	_setup_fsm_challenge_button()
	var state := _get_game_state()
	if state:
		state.save_game()
	var audio := _get_audio_manager()
	if audio:
		await get_tree().create_timer(0.6).timeout
		if not audio.is_music_playing():
			audio.play_music("background_music", true)
func _update_layout():
	if not is_inside_tree():
		return
	var vp_size = get_viewport_rect().size
	custom_minimum_size = vp_size
	menu_container.custom_minimum_size = vp_size
	var panel_width = clamp(vp_size.x * 0.50, 600.0, 900.0)
	var panel_height = clamp(vp_size.y * 0.80, 580.0, 850.0)
	panel.custom_minimum_size = Vector2(panel_width, panel_height)
	panel.size = panel.custom_minimum_size
	var social_layer = get_node_or_null("SocialLayer")
	if social_layer and social_layer is Control:
		(social_layer as Control).custom_minimum_size = vp_size
	var button_width = clamp((panel_width - 80.0) / 2.0, 240.0, 320.0)
	var button_height = clamp(vp_size.y * 0.065, 50.0, 65.0)
	for button in all_buttons:
		if not button:
			continue
		if button == terms_button or button == creative_statement_button:
			var footer_width = clamp((panel_width - 60.0) / 2.0, 220.0, 280.0)
			button.custom_minimum_size = Vector2(footer_width, 32.0)
		else:
			button.custom_minimum_size = Vector2(button_width, button_height)
	if continue_info_label:
		continue_info_label.custom_minimum_size = Vector2(panel_width - 80.0, 24.0)
	if spacer:
		spacer.custom_minimum_size.y = clamp(vp_size.y * 0.02, 10.0, 20.0)
	var separation = int(clamp(vp_size.y * 0.015, 10.0, 16.0))
	content_container.add_theme_constant_override("separation", separation)
func _on_control_resized():
	_update_layout()
func _connect_button_sounds():
	for button in all_buttons:
		if button and not button.mouse_entered.is_connected(_on_button_hover):
			button.mouse_entered.connect(_on_button_hover)
		if button and not button.pressed.is_connected(_on_any_button_pressed):
			button.pressed.connect(_on_any_button_pressed)
func _on_any_button_pressed() -> void:
	var audio := _get_audio_manager()
	if audio and audio.has_method("unlock_web_audio"):
		audio.unlock_web_audio()
func _on_button_hover():
	_unlock_audio_on_gesture()
	var audio := _get_audio_manager()
	if audio:
		audio.play_sfx("menu_click", 0.5)
func _unlock_audio_on_gesture() -> void:
	var audio := _get_audio_manager()
	if audio and audio.has_method("unlock_web_audio"):
		audio.unlock_web_audio()
func _on_start_button_pressed():
	var audio := _get_audio_manager()
	if audio:
		audio.play_sfx("happy_click")
	if not _can_start_game_with_current_ai_settings():
		return
	var state := _get_game_state()
	if state:
		state.new_game()
	if not IntroStoryScript.has_seen_intro():
		get_tree().change_scene_to_file("res://1.Codebase/src/scenes/ui/intro_story.tscn")
	else:
		get_tree().change_scene_to_file("res://1.Codebase/src/scenes/ui/story_scene.tscn")
func _on_continue_button_pressed():
	var audio := _get_audio_manager()
	if audio:
		audio.play_sfx("menu_click")
	if not _can_start_game_with_current_ai_settings():
		return
	var state := _get_game_state()
	if state and state.load_game():
		_fade_to_scene("res://1.Codebase/src/scenes/ui/story_scene.tscn")
	else:
		_report_warning("Failed to load game for continue")
func _fade_to_scene(scene_path: String) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.04, 0.04, 0.08, 0.0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 200
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var label := Label.new()
	label.text = _tr("LOADING_TEXT_DEFAULT")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.78, 0.84, 1.0, 0.9))
	overlay.add_child(label)
	var scene_tree := get_tree()
	scene_tree.root.add_child(overlay)
	var tween := overlay.create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.35)
	tween.tween_callback(func() -> void:
		scene_tree.change_scene_to_file(scene_path)
		var fade := overlay.create_tween()
		fade.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		fade.tween_interval(0.9)
		fade.tween_property(overlay, "color:a", 0.0, 0.6)
		fade.tween_callback(overlay.queue_free)
	)
func _can_start_game_with_current_ai_settings() -> bool:
	if not ServiceLocator:
		return true
	var ai_manager = ServiceLocator.get_ai_manager()
	if not is_instance_valid(ai_manager):
		return true
	if ai_manager.has_method("load_ai_settings"):
		ai_manager.load_ai_settings()
	var provider := int(ai_manager.current_provider)
	if provider != AIConfigManager.AIProvider.GEMINI:
		return true
	var key := String(ai_manager.gemini_api_key).strip_edges()
	if not key.is_empty():
		return true
	var message := _GEMINI_KEY_MISSING_MESSAGE
	if _is_web_runtime():
		message += " (Note: GitHub Secrets are not readable by the browser at runtime. Keys must be embedded at build-time or entered by the player.)"
	_show_error_notification(message)
	return false
func _is_web_runtime() -> bool:
	var normalized_name := OS.get_name().to_lower()
	if normalized_name == "html5":
		return true
	for feature in ["web", "html5", "emscripten", "javascript"]:
		if OS.has_feature(feature):
			return true
	return false
func _on_save_load_button_pressed():
	var audio := _get_audio_manager()
	if audio:
		audio.play_sfx("menu_click")
	var save_menu_scene: PackedScene = load("res://1.Codebase/src/scenes/ui/save_load_menu.tscn") as PackedScene
	if save_menu_scene:
		var save_menu_instance: Node = save_menu_scene.instantiate()
		var save_menu_control: Control = save_menu_instance as Control
		if save_menu_control:
			add_child(save_menu_control)
func _on_achievements_button_pressed():
	var audio := _get_audio_manager()
	if audio:
		audio.play_sfx("menu_click")
	var achievement_scene: PackedScene = load("res://1.Codebase/src/scenes/ui/achievement_viewer.tscn") as PackedScene
	if achievement_scene:
		var achievement_instance: Node = achievement_scene.instantiate()
		var achievement_control: Control = achievement_instance as Control
		if achievement_control:
			add_child(achievement_control)
			_debug_log("[StartMenu] Achievement viewer opened successfully")
		else:
			_report_warning("Failed to cast achievement instance to Control")
			_show_error_notification("Failed to open achievements viewer")
	else:
		_report_warning("Failed to load achievement_viewer.tscn")
		_show_error_notification("Achievements viewer not available")
func _on_journal_button_pressed():
	var audio := _get_audio_manager()
	if audio:
		audio.play_sfx("menu_click")
	var journal_scene: PackedScene = load("res://1.Codebase/src/scenes/ui/journal_system.tscn") as PackedScene
	if journal_scene:
		var journal_instance: Node = journal_scene.instantiate()
		var journal_control: Control = journal_instance as Control
		if journal_control:
			add_child(journal_control)
			_debug_log("[StartMenu] Journal opened successfully")
		else:
			_report_warning("Failed to cast journal instance to Control")
			_show_error_notification("Failed to open journal")
	else:
		_report_warning("Failed to load journal_system.tscn")
		_show_error_notification("Journal not available")
func _on_settings_button_pressed():
	var audio := _get_audio_manager()
	if audio:
		audio.play_sfx("menu_click")
	get_tree().change_scene_to_file("res://1.Codebase/src/scenes/ui/settings_menu.tscn")
func _on_quit_button_pressed():
	var audio := _get_audio_manager()
	if audio:
		audio.play_sfx("angry_click")
	_request_quit_confirmation()
func _request_quit_confirmation() -> void:
	if _exit_confirmation_dialog:
		_pending_quit_request = true
		_refresh_exit_dialog_text()
		_exit_confirmation_dialog.popup_centered()
	else:
		_perform_quit_game()
func _perform_quit_game() -> void:
	var state := _get_game_state()
	if state and state.has_method("autosave"):
		state.is_session_active = false
		var success: bool = state.autosave()
		if not success:
			_report_warning("Autosave failed before quit")
	get_tree().quit()
func _on_intro_button_pressed():
	var audio := _get_audio_manager()
	if audio:
		audio.play_sfx("menu_click")
	var intro_scene: PackedScene = load("res://1.Codebase/src/scenes/ui/intro_page.tscn") as PackedScene
	if intro_scene:
		var intro_instance: Node = intro_scene.instantiate()
		var intro_control: Control = intro_instance as Control
		if intro_control:
			add_child(intro_control)
func _on_creative_statement_button_pressed():
	var audio := _get_audio_manager()
	if audio:
		audio.play_sfx("menu_click")
	var statement_scene: PackedScene = load("res://1.Codebase/src/scenes/ui/creative_statement.tscn") as PackedScene
	if statement_scene:
		var statement_instance: Node = statement_scene.instantiate()
		var statement_control: Control = statement_instance as Control
		if statement_control:
			add_child(statement_control)
func _on_terms_button_pressed():
	var audio := _get_audio_manager()
	if audio:
		audio.play_sfx("menu_click")
	var terms_scene: PackedScene = load("res://1.Codebase/src/scenes/ui/terms_page.tscn") as PackedScene
	if terms_scene:
		var terms_instance: Node = terms_scene.instantiate()
		var terms_control: Control = terms_instance as Control
		if terms_control:
			add_child(terms_control)
func _on_youtube_button_pressed():
	var achievement_sys: Node = null
	if ServiceLocator and ServiceLocator.has_method("get_achievement_system"):
		achievement_sys = ServiceLocator.get_achievement_system()
	var has_noodler := false
	if achievement_sys and achievement_sys.has_method("is_unlocked"):
		has_noodler = achievement_sys.is_unlocked("faithful_noodler")
	if has_noodler:
		_youtube_click_count += 1
		_youtube_click_timer = _YOUTUBE_CLICK_TIMEOUT
		if _youtube_click_count >= 3:
			_youtube_click_count = 0
			_youtube_click_timer = 0.0
			_show_fsm_inbox_easter_egg()
			return
	OS.shell_open(YOUTUBE_URL)
func _on_github_button_pressed():
	OS.shell_open(GITHUB_URL)
func _show_error_notification(message: String) -> void:
	_debug_log("[StartMenu] Showing error notification: %s" % message)
	var error_label := Label.new()
	error_label.text = message
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	error_label.add_theme_font_size_override("font_size", 18)
	error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	error_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	error_label.offset_top = -100
	error_label.offset_bottom = -50
	add_child(error_label)
	var tween := create_tween()
	tween.tween_property(error_label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.5)
	tween.tween_property(error_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(error_label.queue_free)
func _should_auto_resume() -> bool:
	var state := _get_game_state()
	if not state:
		return false
	var autosave_path = "user://gda1_autosave.dat"
	if not FileAccess.file_exists(autosave_path):
		return false
	var file = FileAccess.open(autosave_path, FileAccess.READ)
	if not file:
		return false
	var save_data = file.get_var()
	file.close()
	if not save_data is Dictionary:
		return false
	var was_session_active = bool(save_data.get("is_session_active", false))
	var has_valid_data = save_data.has("reality_score") or save_data.has("player_stats_data")
	return was_session_active and has_valid_data
func _auto_resume_game() -> void:
	var state := _get_game_state()
	if not state:
		_report_warning("GameState not available for auto-resume")
		return
	var success = state.load_game()
	if success:
		_debug_log("[StartMenu] Game state loaded successfully, transitioning to story scene...")
		_fade_to_scene("res://1.Codebase/src/scenes/ui/story_scene.tscn")
	else:
		_report_warning("Failed to load autosave for auto-resume")
		_animate_menu_entrance()
func _refresh_services() -> void:
	if not ServiceLocator:
		return
	audio_manager = ServiceLocator.get_audio_manager()
	game_state = ServiceLocator.get_game_state()
	error_reporter = ServiceLocator.get_error_reporter()
	font_manager = ServiceLocator.get_font_manager()
func _get_audio_manager() -> Node:
	if is_instance_valid(audio_manager):
		return audio_manager
	if ServiceLocator:
		audio_manager = ServiceLocator.get_audio_manager()
	return audio_manager
func _get_game_state() -> Node:
	if is_instance_valid(game_state):
		return game_state
	if ServiceLocator:
		game_state = ServiceLocator.get_game_state()
	return game_state
func _report_info(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, message, details)
func _report_warning(message: String, details: Dictionary = { }) -> void:
	if not is_instance_valid(error_reporter) and ServiceLocator:
		error_reporter = ServiceLocator.get_error_reporter()
	if error_reporter and error_reporter.has_method("report_warning"):
		error_reporter.report_warning(ERROR_CONTEXT, message, details)
func _debug_log(message: String) -> void:
	if VERBOSE_LOGS:
		ErrorReporterBridge.report_info(ERROR_CONTEXT, message)
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key, current_language)
	return key
func _load_language_from_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		var saved_language: String = config.get_value("game", "language", "en")
		if game_state:
			game_state.current_language = saved_language
			current_language = saved_language
		if LocalizationManager:
			LocalizationManager.set_language(saved_language)
	_report_info("Current game language: %s" % current_language)
func _assign_icons() -> void:
	if journal_button:
		journal_button.icon = ICON_JOURNAL
		journal_button.expand_icon = true
	if achievements_button:
		achievements_button.icon = ICON_ACHIEVEMENTS
		achievements_button.expand_icon = true
	if settings_button:
		settings_button.icon = ICON_SETTINGS
		settings_button.expand_icon = true
	if start_button:
		start_button.icon = ICON_PLAY
		start_button.expand_icon = true
	if continue_button:
		continue_button.icon = ICON_PLAY
		continue_button.expand_icon = true
	if save_load_button:
		save_load_button.icon = ICON_SAVE
		save_load_button.expand_icon = true
	if intro_button:
		intro_button.icon = ICON_INFO
		intro_button.expand_icon = true
	if quit_button:
		quit_button.icon = ICON_QUIT
		quit_button.expand_icon = true
	if creative_statement_button:
		creative_statement_button.icon = ICON_CREATIVE
		creative_statement_button.expand_icon = true
	if terms_button:
		terms_button.icon = ICON_TERMS
		terms_button.expand_icon = true
func _create_exit_confirmation_dialog() -> void:
	_exit_confirmation_dialog = ConfirmationDialog.new()
	add_child(_exit_confirmation_dialog)
	_refresh_exit_dialog_text()
	_exit_confirmation_dialog.confirmed.connect(_on_exit_confirmed)
	if _exit_confirmation_dialog.has_signal("canceled"):
		_exit_confirmation_dialog.canceled.connect(_on_exit_cancelled)
func _refresh_exit_dialog_text() -> void:
	if not _exit_confirmation_dialog:
		return
	_exit_confirmation_dialog.dialog_text = _tr("GAME_EXIT_CONFIRM_TEXT")
	_exit_confirmation_dialog.title = _tr("GAME_EXIT_CONFIRM_TITLE")
	_exit_confirmation_dialog.ok_button_text = _tr("GAME_EXIT_CONFIRM_OK")
	_exit_confirmation_dialog.cancel_button_text = _tr("GAME_EXIT_CONFIRM_CANCEL")
func _on_exit_confirmed() -> void:
	_pending_quit_request = false
	_perform_quit_game()
func _on_exit_cancelled() -> void:
	_pending_quit_request = false
func _cleanup_exit_confirmation_dialog() -> void:
	if not _exit_confirmation_dialog:
		return
	if _exit_confirmation_dialog.confirmed.is_connected(_on_exit_confirmed):
		_exit_confirmation_dialog.confirmed.disconnect(_on_exit_confirmed)
	if _exit_confirmation_dialog.has_signal("canceled") and _exit_confirmation_dialog.canceled.is_connected(_on_exit_cancelled):
		_exit_confirmation_dialog.canceled.disconnect(_on_exit_cancelled)
	_exit_confirmation_dialog.queue_free()
	_exit_confirmation_dialog = null
func _build_easter_egg_overlay(title_text: String, body_text: String, close_key: String = "EASTER_EGG_CLOSE") -> Control:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.05, 0.92)
	overlay.add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(700, 520)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.06, 0.12, 0.97)
	sb.corner_radius_top_left = 18
	sb.corner_radius_top_right = 18
	sb.corner_radius_bottom_left = 18
	sb.corner_radius_bottom_right = 18
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.5, 0.4, 0.7, 0.6)
	sb.shadow_size = 16
	sb.shadow_color = Color(0, 0, 0, 0.6)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 16)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 28)
	margin.add_child(vbox)
	panel.add_child(margin)
	var title_lbl := Label.new()
	title_lbl.text = title_text
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(0.85, 0.75, 1.0))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)
	var sep := HSeparator.new()
	sep.modulate = Color(0.5, 0.4, 0.7, 0.5)
	vbox.add_child(sep)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	var body_lbl := RichTextLabel.new()
	body_lbl.bbcode_enabled = true
	body_lbl.text = body_text
	body_lbl.fit_content = true
	body_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_lbl.add_theme_font_size_override("normal_font_size", 16)
	body_lbl.add_theme_color_override("default_color", Color(0.9, 0.88, 0.95))
	scroll.add_child(body_lbl)
	var close_btn := Button.new()
	close_btn.text = _tr(close_key)
	close_btn.custom_minimum_size = Vector2(160, 44)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UIStyleManager.apply_button_style(close_btn, "primary", "medium")
	UIStyleManager.add_hover_scale_effect(close_btn, 1.06)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.pressed.connect(overlay.queue_free)
	vbox.add_child(close_btn)
	overlay.modulate.a = 0.0
	UIStyleManager.fade_in(overlay, 0.35)
	return overlay
func _show_teacher_chan_easter_egg() -> void:
	var audio := _get_audio_manager()
	if audio:
		audio.play_sfx("group_present", 0.8)
	var title := _tr("EASTER_EGG_TEACHER_CHAN_TITLE")
	var body := _tr("EASTER_EGG_TEACHER_CHAN_BODY")
	var popup := _build_easter_egg_overlay(title, body)
	add_child(popup)
	_debug_log("[StartMenu] Easter egg triggered: Teacher Chan's Real Lesson")
func _show_gloria_diary_easter_egg() -> void:
	var audio := _get_audio_manager()
	if audio:
		audio.play_sfx("angry_click", 0.7)
	var title := _tr("EASTER_EGG_GLORIA_DIARY_TITLE")
	var body := _tr("EASTER_EGG_GLORIA_DIARY_BODY")
	var popup := _build_easter_egg_overlay(title, body)
	add_child(popup)
	_debug_log("[StartMenu] Easter egg triggered: Gloria's Unmasked Diary")
func _show_fsm_inbox_easter_egg() -> void:
	if is_instance_valid(_fsm_inbox_popup):
		_fsm_inbox_popup.queue_free()
	_fsm_inbox_prayer_index = 0
	_fsm_inbox_popup = _build_fsm_inbox_popup()
	add_child(_fsm_inbox_popup)
	_debug_log("[StartMenu] Easter egg triggered: FSM Divine Inbox")
func _build_fsm_inbox_popup() -> Control:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.03, 0.0, 0.93)
	overlay.add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(680, 480)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.10, 0.06, 0.97)
	sb.corner_radius_top_left = 18
	sb.corner_radius_top_right = 18
	sb.corner_radius_bottom_left = 18
	sb.corner_radius_bottom_right = 18
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.3, 0.7, 0.4, 0.6)
	sb.shadow_size = 16
	sb.shadow_color = Color(0, 0, 0, 0.6)
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
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)
	var title_lbl := Label.new()
	title_lbl.text = _tr("EASTER_EGG_FSM_INBOX_TITLE")
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(0.6, 1.0, 0.65))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)
	var sep := HSeparator.new()
	sep.modulate = Color(0.3, 0.7, 0.4, 0.5)
	vbox.add_child(sep)
	var intro_lbl := RichTextLabel.new()
	intro_lbl.bbcode_enabled = true
	intro_lbl.text = _tr("EASTER_EGG_FSM_INBOX_INTRO")
	intro_lbl.fit_content = true
	intro_lbl.add_theme_font_size_override("normal_font_size", 15)
	intro_lbl.add_theme_color_override("default_color", Color(0.85, 0.92, 0.85))
	vbox.add_child(intro_lbl)
	var prayer_panel := Panel.new()
	prayer_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var prayer_sb := StyleBoxFlat.new()
	prayer_sb.bg_color = Color(0.0, 0.06, 0.02, 0.8)
	prayer_sb.corner_radius_top_left = 10
	prayer_sb.corner_radius_top_right = 10
	prayer_sb.corner_radius_bottom_left = 10
	prayer_sb.corner_radius_bottom_right = 10
	prayer_panel.add_theme_stylebox_override("panel", prayer_sb)
	vbox.add_child(prayer_panel)
	var prayer_margin := MarginContainer.new()
	prayer_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	prayer_margin.add_theme_constant_override("margin_left", 20)
	prayer_margin.add_theme_constant_override("margin_right", 20)
	prayer_margin.add_theme_constant_override("margin_top", 16)
	prayer_margin.add_theme_constant_override("margin_bottom", 16)
	prayer_panel.add_child(prayer_margin)
	var prayer_body := RichTextLabel.new()
	prayer_body.name = "PrayerBody"
	prayer_body.bbcode_enabled = true
	prayer_body.fit_content = true
	prayer_body.add_theme_font_size_override("normal_font_size", 15)
	prayer_body.add_theme_color_override("default_color", Color(0.9, 0.95, 0.9))
	prayer_body.text = _get_fsm_prayer_text(0)
	prayer_margin.add_child(prayer_body)
	var bless_btn := Button.new()
	bless_btn.name = "BlessBtn"
	bless_btn.text = _tr("EASTER_EGG_FSM_BLESS_BTN")
	bless_btn.custom_minimum_size = Vector2(220, 48)
	bless_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UIStyleManager.apply_button_style(bless_btn, "accent", "medium")
	UIStyleManager.add_hover_scale_effect(bless_btn, 1.06)
	bless_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	bless_btn.pressed.connect(_on_fsm_bless_pressed.bind(overlay))
	vbox.add_child(bless_btn)
	overlay.modulate.a = 0.0
	UIStyleManager.fade_in(overlay, 0.35)
	return overlay
func _get_fsm_prayer_text(index: int) -> String:
	var prayers := [
		"EASTER_EGG_FSM_PRAYER_1_TEXT",
		"EASTER_EGG_FSM_PRAYER_2_TEXT",
		"EASTER_EGG_FSM_PRAYER_3_TEXT",
		"EASTER_EGG_FSM_PRAYER_4_TEXT",
		"EASTER_EGG_FSM_PRAYER_5_TEXT",
	]
	if index < prayers.size():
		return _tr(prayers[index])
	return ""
func _get_fsm_prayer_result(index: int) -> String:
	var results := [
		"EASTER_EGG_FSM_PRAYER_1_RESULT",
		"EASTER_EGG_FSM_PRAYER_2_RESULT",
		"EASTER_EGG_FSM_PRAYER_3_RESULT",
		"EASTER_EGG_FSM_PRAYER_4_RESULT",
		"EASTER_EGG_FSM_PRAYER_5_RESULT",
	]
	if index < results.size():
		return _tr(results[index])
	return ""
func _on_fsm_bless_pressed(overlay: Control) -> void:
	if not is_instance_valid(overlay):
		return
	var audio := _get_audio_manager()
	if audio:
		audio.play_sfx("happy_click", 0.9)
	var prayer_body: RichTextLabel = overlay.find_child("PrayerBody", true, false) as RichTextLabel
	var bless_btn: Button = overlay.find_child("BlessBtn", true, false) as Button
	var total_prayers := 5
	if _fsm_inbox_prayer_index < total_prayers:
		if prayer_body:
			prayer_body.text = _get_fsm_prayer_result(_fsm_inbox_prayer_index)
		_fsm_inbox_prayer_index += 1
		if _fsm_inbox_prayer_index < total_prayers:
			if bless_btn:
				bless_btn.text = _get_fsm_prayer_text(_fsm_inbox_prayer_index)
				bless_btn.custom_minimum_size = Vector2(360, 48)
		else:
			if prayer_body:
				await get_tree().create_timer(1.2).timeout
				if is_instance_valid(prayer_body):
					prayer_body.text = _tr("EASTER_EGG_FSM_FAREWELL")
			if bless_btn:
				bless_btn.text = _tr("EASTER_EGG_FSM_CLOSE_BTN")
				bless_btn.pressed.disconnect(_on_fsm_bless_pressed.bind(overlay))
				bless_btn.pressed.connect(overlay.queue_free)
func _show_cant_touch_easter_egg() -> void:
	var audio := _get_audio_manager()
	if audio:
		audio.play_sfx("group_present", 0.9)
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.05, 0.92)
	overlay.add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(700, 580)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.06, 0.12, 0.97)
	sb.corner_radius_top_left = 18
	sb.corner_radius_top_right = 18
	sb.corner_radius_bottom_left = 18
	sb.corner_radius_bottom_right = 18
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.5, 0.4, 0.7, 0.6)
	sb.shadow_size = 16
	sb.shadow_color = Color(0, 0, 0, 0.6)
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
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)
	var title_lbl := Label.new()
	title_lbl.text = _tr("EASTER_EGG_CANT_TOUCH_TITLE")
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(0.85, 0.75, 1.0))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)
	var sep := HSeparator.new()
	sep.modulate = Color(0.5, 0.4, 0.7, 0.5)
	vbox.add_child(sep)
	var img_texture := _load_texture_safe("res://1.Codebase/src/assets/ui/easter_egg_cant_touch.png")
	if img_texture:
		var img_rect := TextureRect.new()
		img_rect.texture = img_texture
		img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		img_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		img_rect.custom_minimum_size = Vector2(160, 160)
		vbox.add_child(img_rect)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	var body_lbl := RichTextLabel.new()
	body_lbl.bbcode_enabled = true
	body_lbl.text = _tr("EASTER_EGG_CANT_TOUCH_BODY")
	body_lbl.fit_content = true
	body_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_lbl.add_theme_font_size_override("normal_font_size", 16)
	body_lbl.add_theme_color_override("default_color", Color(0.9, 0.88, 0.95))
	scroll.add_child(body_lbl)
	var secret_btn := Button.new()
	secret_btn.text = _tr("EASTER_EGG_SUPER_GIRLS_BTN")
	secret_btn.custom_minimum_size = Vector2(50, 36)
	secret_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	secret_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	secret_btn.add_theme_font_size_override("font_size", 18)
	secret_btn.add_theme_color_override("font_color", Color(0.8, 0.55, 0.95, 0.75))
	secret_btn.pressed.connect(_show_super_girls_easter_egg)
	vbox.add_child(secret_btn)
	var close_btn := Button.new()
	close_btn.text = _tr("EASTER_EGG_CLOSE")
	close_btn.custom_minimum_size = Vector2(160, 44)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UIStyleManager.apply_button_style(close_btn, "primary", "medium")
	UIStyleManager.add_hover_scale_effect(close_btn, 1.06)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.pressed.connect(overlay.queue_free)
	vbox.add_child(close_btn)
	overlay.modulate.a = 0.0
	UIStyleManager.fade_in(overlay, 0.35)
	add_child(overlay)
	_debug_log("[StartMenu] Easter egg triggered: Can't Touch This")
func _show_super_girls_easter_egg() -> void:
	const SUPER_GIRLS_URL := "https://youtube.com/@supergirlsgroup"
	const CLICKS_NEEDED := 5
	var counter := [0]  
	var panel_tween: Tween = null
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.05, 0.85)
	overlay.add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(400, 260)
	panel.pivot_offset = Vector2(200, 130)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.05, 0.18, 0.97)
	sb.corner_radius_top_left = 18
	sb.corner_radius_top_right = 18
	sb.corner_radius_bottom_left = 18
	sb.corner_radius_bottom_right = 18
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.95, 0.55, 0.85, 0.85)
	sb.shadow_size = 20
	sb.shadow_color = Color(0.6, 0.0, 0.5, 0.45)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)
	var title_lbl := Label.new()
	title_lbl.text = _tr("EASTER_EGG_SUPER_GIRLS_TITLE")
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.7, 0.9))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title_lbl)
	var sep := HSeparator.new()
	sep.modulate = Color(0.85, 0.45, 0.75, 0.5)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sep)
	var hint_lbl := Label.new()
	hint_lbl.text = _tr("EASTER_EGG_SUPER_GIRLS_HINT").format({"remaining": CLICKS_NEEDED})
	hint_lbl.add_theme_font_size_override("font_size", 15)
	hint_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.95))
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hint_lbl)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(spacer)
	var close_btn2 := Button.new()
	close_btn2.text = _tr("EASTER_EGG_CLOSE")
	close_btn2.custom_minimum_size = Vector2(120, 40)
	close_btn2.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UIStyleManager.apply_button_style(close_btn2, "primary", "medium")
	UIStyleManager.add_hover_scale_effect(close_btn2, 1.06)
	close_btn2.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn2.pressed.connect(overlay.queue_free)
	vbox.add_child(close_btn2)
	panel.gui_input.connect(func(event: InputEvent) -> void:
		if not (event is InputEventMouseButton):
			return
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			counter[0] += 1
			var remaining: int = CLICKS_NEEDED - counter[0] as int
			if remaining > 0:
				hint_lbl.text = _tr("EASTER_EGG_SUPER_GIRLS_CLICK").format({"remaining": remaining})
				if is_instance_valid(panel):
					if is_instance_valid(panel_tween):
						panel_tween.kill()
					panel_tween = create_tween()
					panel_tween.tween_property(panel, "scale", Vector2(1.06, 1.06), 0.07)
					panel_tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.07)
			else:
				OS.shell_open(SUPER_GIRLS_URL)
				overlay.queue_free()
	)
	overlay.modulate.a = 0.0
	UIStyleManager.fade_in(overlay, 0.25)
	add_child(overlay)
	_debug_log("[StartMenu] Easter egg triggered: Super Girls")
