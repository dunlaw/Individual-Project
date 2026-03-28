extends Control
const EXIT_MODE_MAIN_MENU := 0
const EXIT_MODE_OVERLAY := 1
const VERBOSE_LOGS := GameConstants.Debug.ENABLE_VERBOSE_LOGS
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
const ERROR_CONTEXT := "SettingsMenu"
@warning_ignore("shadowed_global_identifier")
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
const GameSave = preload("res://1.Codebase/src/scripts/core/game_save.gd")
const SettingsMenuAudioSectionScript = preload("res://1.Codebase/src/scripts/ui/settings_menu_audio_section.gd")
const SettingsMenuDisplaySectionScript = preload("res://1.Codebase/src/scripts/ui/settings_menu_display_section.gd")
const SettingsMenuVoiceSectionScript = preload("res://1.Codebase/src/scripts/ui/settings_menu_voice_section.gd")
const SettingsMenuDeveloperSectionScript = preload("res://1.Codebase/src/scripts/ui/settings_menu_developer_section.gd")
const SettingsMenuAIAnalyticsScript = preload("res://1.Codebase/src/scripts/ui/settings_menu_ai_analytics.gd")
const SettingsMenuAILogControllerScript = preload("res://1.Codebase/src/scripts/ui/settings_menu_ai_log_controller.gd")
const SettingsMenuSaveLoadScript = preload("res://1.Codebase/src/scripts/ui/settings_menu_save_load.gd")
const SettingsMenuDeveloperHandlersScript = preload("res://1.Codebase/src/scripts/ui/settings_menu_developer_handlers.gd")
const SettingsMenuTutorialHandlersScript = preload("res://1.Codebase/src/scripts/ui/settings_menu_tutorial_handlers.gd")
const SettingsMenuAgentServerSectionScript = preload("res://1.Codebase/src/scripts/ui/settings_menu_agent_server_section.gd")
const SettingsMenuTutorialSectionScript = preload("res://1.Codebase/src/scripts/ui/settings_menu_tutorial_section.gd")
const SettingsMenuStylesScript = preload("res://1.Codebase/src/scripts/ui/settings_menu_styles.gd")
const SettingsMenuAILogSectionScript = preload("res://1.Codebase/src/scripts/ui/settings_menu_ai_log_section.gd")
const SettingsMenuAILogRendererScript = preload("res://1.Codebase/src/scripts/ui/settings_menu_ai_log_renderer.gd")
const SettingsMenuAILogExportScript = preload("res://1.Codebase/src/scripts/ui/settings_menu_ai_log_export.gd")
const SettingsMenuUITextScript = preload("res://1.Codebase/src/scripts/ui/settings_menu_ui_text.gd")
const SettingsMenuLogActionsScript = preload("res://1.Codebase/src/scripts/ui/settings_menu_log_actions.gd")
const SettingsMenuVoiceHandlersScript = preload("res://1.Codebase/src/scripts/ui/settings_menu_voice_handlers.gd")
const SettingsMenuLayoutBuilderScript = preload("res://1.Codebase/src/scripts/ui/settings_menu_layout_builder.gd")
const ICON_CHECK = preload("res://1.Codebase/src/assets/ui/icon_check.svg")
const ICON_BACK = preload("res://1.Codebase/src/assets/ui/icon_back.svg")
const ICON_DELETE = preload("res://1.Codebase/src/assets/ui/icon_delete.svg")
const ICON_CREATIVE = preload("res://1.Codebase/src/assets/ui/icon_creative.svg")
const ICON_MIC = preload("res://1.Codebase/src/assets/ui/icon_mic.svg")
const ICON_REFRESH = preload("res://1.Codebase/src/assets/ui/icon_refresh.svg")
const ICON_SAVE = preload("res://1.Codebase/src/assets/ui/icon_save.svg")
const ICON_HISTORY = preload("res://1.Codebase/src/assets/ui/icon_history.svg")
const ICON_OPTIONS = preload("res://1.Codebase/src/assets/ui/icon_options.svg")
const ICON_INFO = preload("res://1.Codebase/src/assets/ui/icon_info.svg")
const ICON_SYNC = preload("res://1.Codebase/src/assets/ui/icon_sync.svg")
const SETTINGS_BANNER = preload("res://1.Codebase/src/assets/ui/settings_background.png")
const FSM_IMG_GUIDE = preload("res://1.Codebase/src/assets/ui/guide_fsm.png")
const FSM_IMG_TEACHER = preload("res://1.Codebase/src/assets/characters/teacher_chan_pointing.png")
const FSM_IMG_GLORIA = preload("res://1.Codebase/src/assets/characters/gloria_protagonis_neutral.png")
signal close_requested
var selected_resolution: Vector2i = Vector2i(1024, 600)
var selected_mode: int = 0
var selected_language: String = "en"
var selected_font_size: int = 2
var selected_english_font: String = ""
var selected_chinese_font: String = ""
var master_volume: float = 100.0
var music_volume: float = 100.0
var sfx_volume: float = 100.0
var gloria_voice_enabled: bool = false
var is_muted: bool = false
var touch_controls_enabled: bool = false
var text_speed: float = 1.0
var screen_shake_enabled: bool = true
var max_rounds_per_mission: int = 0
var auto_advance_enabled: bool = false
var high_contrast_mode: bool = false
var _embedded_window_mode: bool = false
var _exit_mode: int = EXIT_MODE_MAIN_MENU
var resolutions = {
	0: Vector2i(1024, 600),
	1: Vector2i(1280, 720),
	2: Vector2i(1600, 900),
	3: Vector2i(1920, 1080),
	4: Vector2i(2560, 1440),
}
@onready var menu_container = $MenuContainer
@onready var panel = $MenuContainer/Panel
@onready var main_vbox = $MenuContainer/Panel/VBoxContainer
@onready var original_scroll = $MenuContainer/Panel/VBoxContainer/ScrollContainer
@onready var original_settings_vbox = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox
@onready var buttons_container = $MenuContainer/Panel/VBoxContainer/ButtonsContainer
@onready var title_label = $MenuContainer/Panel/VBoxContainer/TitleLabel
@onready var back_button = $MenuContainer/Panel/VBoxContainer/ButtonsContainer/BackButton
@onready var apply_button = $MenuContainer/Panel/VBoxContainer/ButtonsContainer/ApplyButton
@onready var ai_settings_button = $MenuContainer/Panel/VBoxContainer/ButtonsContainer/AISettingsButton
@onready var delete_logs_button = $MenuContainer/Panel/VBoxContainer/ButtonsContainer/DeleteLogsButton
@onready var delete_logs_dialog = $MenuContainer/Panel/DeleteLogsDialog
@onready var resolution_label = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/ResolutionLabel
@onready var resolution_option = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/ResolutionOption
@onready var fullscreen_label = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/FullscreenLabel
@onready var fullscreen_option = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/FullscreenOption
@onready var font_size_label = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/FontSizeLabel
@onready var font_size_option = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/FontSizeOption
@onready var english_font_label = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/EnglishFontLabel
@onready var english_font_option = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/EnglishFontOption
@onready var chinese_font_label = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/ChineseFontLabel
@onready var chinese_font_option = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/ChineseFontOption
@onready var language_label = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/LanguageLabel
@onready var language_option = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/LanguageOption
@onready var master_volume_hbox = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/MasterVolumeHBox
@onready var music_volume_hbox = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/MusicVolumeHBox
@onready var sfx_volume_hbox = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/SFXVolumeHBox
@onready var mute_check_box = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/MuteCheckBox
@onready var voice_description = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/VoiceInfoPanel/VoiceInfoMargin/VoiceInfoVBox/VoiceDescription
@onready var voice_availability_label = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/VoiceInfoPanel/VoiceInfoMargin/VoiceInfoVBox/VoiceAvailabilityLabel
@onready var voice_enabled_check = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/VoiceOptionsPanel/VoiceOptionsMargin/VoiceOptionsContainer/VoiceEnabledCheck
@onready var voice_options_box = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/VoiceOptionsPanel/VoiceOptionsMargin/VoiceOptionsContainer/VoiceOptionsVBox
@onready var voice_output_check = voice_options_box.get_node("VoiceOutputCheck")
@onready var voice_input_check = voice_options_box.get_node("VoiceInputCheck")
@onready var voice_choice_label = voice_options_box.get_node("VoiceVoiceHBox/VoiceChoiceLabel")
@onready var voice_voice_option = voice_options_box.get_node("VoiceVoiceHBox/VoiceVoiceOption")
@onready var voice_volume_slider = voice_options_box.get_node("VoiceVolumeHBox/VoiceVolumeSlider")
@onready var voice_volume_value = voice_options_box.get_node("VoiceVolumeHBox/VoiceVolumeValue")
@onready var voice_volume_label = voice_options_box.get_node("VoiceVolumeHBox/VoiceVolumeLabel")
@onready var voice_input_mode_option = voice_options_box.get_node("VoiceInputModeHBox/VoiceInputModeOption")
@onready var voice_input_mode_label = voice_options_box.get_node("VoiceInputModeHBox/VoiceInputModeLabel")
@onready var voice_proactive_check = voice_options_box.get_node("VoiceProactiveCheck")
@onready var voice_preview_button = voice_options_box.get_node("VoiceTestButtonsHBox/VoicePreviewButton")
@onready var voice_capture_button = voice_options_box.get_node("VoiceTestButtonsHBox/VoiceCaptureButton")
@onready var voice_status_label = voice_options_box.get_node("VoiceStatusPanel/VoiceStatusMargin/VoiceStatusLabel")
@onready var touch_controls_checkbox = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/TouchControlsCheckBox
var tab_container: TabContainer
var tab_gameplay: VBoxContainer
var tab_display: VBoxContainer
var tab_audio: VBoxContainer
var tab_voice: VBoxContainer
var tab_tutorial: VBoxContainer
var tab_developer: VBoxContainer
var tab_ai_log: VBoxContainer
var _ai_chart_width: float = 480.0
var _ai_chart_height: float = 190.0
var gloria_voice_check: CheckBox
var text_speed_label: Label
var text_speed_option: OptionButton
var screen_shake_check: CheckBox
var max_rounds_label: Label
var max_rounds_spinbox: SpinBox
var force_mission_complete_check: CheckBox
var force_gloria_button: Button
var force_gloria_status_label: Label
var force_trolley_button: Button
var force_trolley_status_label: Label
var force_honeymoon_check: CheckBox
var _gloria_triggered: bool = false
var _trolley_triggered: bool = false
var reality_score_label: Label
var reality_score_spinbox: SpinBox
var positive_energy_label: Label
var positive_energy_spinbox: SpinBox
var entropy_level_label: Label
var entropy_level_spinbox: SpinBox
var honeymoon_charges_label: Label
var honeymoon_charges_spinbox: SpinBox
var mission_turn_label: Label
var mission_turn_spinbox: SpinBox
var max_stats_button: Button
var reset_stats_button: Button
var clear_debuffs_button: Button
var skip_turn_button: Button
var add_honeymoon_button: Button
var autosave_toggle: CheckBox
var infinite_resources_toggle: CheckBox
var skip_dialogue_toggle: CheckBox
var god_mode_toggle: CheckBox
var tutorial_enabled_toggle: CheckBox
var tutorial_progress_label: Label
var reset_tutorials_button: Button
var tutorial_list_container: VBoxContainer
var _audio_manager: Node = null
var _game_state: Node = null
var _agent_server_section: SettingsMenuAgentServerSection = null
var _tutorial_section: SettingsMenuTutorialSection = null
var _ai_log_ctrl: SettingsMenuAILogController = null
var _dev_ctrl: SettingsMenuDeveloperHandlers = null
var _tutorial_ctrl: SettingsMenuTutorialHandlers = null
var _voice_ctrl: SettingsMenuVoiceHandlers = null
var _pending_voice_settings: Dictionary = {}
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key)
	return key
func _tr_bilingual(key: String) -> String:
	if LocalizationManager:
		var zh = LocalizationManager.get_translation(key, "zh")
		var en = LocalizationManager.get_translation(key, "en")
		if zh != key and zh != en:
			return zh + " (" + en + ")"
		return en
	return key
func _contains_non_ascii(text: String) -> bool:
	for i in text.length():
		if text.unicode_at(i) > 127:
			return true
	return false
func _pick_lang_segment(text: String) -> String:
	if not text.contains(" / "):
		return text
	var parts := text.split(" / ", false, 2)
	if parts.size() != 2:
		return text
	var left := parts[0].strip_edges()
	var right := parts[1].strip_edges()
	var left_non_ascii := _contains_non_ascii(left)
	var right_non_ascii := _contains_non_ascii(right)
	if left_non_ascii == right_non_ascii:
		return text
	return left if selected_language == "zh" else right
func _tr_ai(key: String, fallback: String = "") -> String:
	if LocalizationManager:
		var translated := LocalizationManager.get_translation(key, selected_language)
		if translated != key:
			return translated
	return fallback if not fallback.is_empty() else key
func _normalize_ai_log_language_texts(root: Node) -> void:
	SettingsMenuAILogSectionScript.normalize_language_texts(root, Callable(self, "_tr_ai"), _ai_log_ctrl)
func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_background_aliases()
	_enforce_fullscreen_layout()
	SettingsMenuLayoutBuilderScript.add_settings_banner(main_vbox, SETTINGS_BANNER)
	_rebuild_layout_into_tabs()
	load_settings()
	_initialize_font_options()
	var runtime_window := get_window()
	if runtime_window and runtime_window.has_method("is_embedded"):
		_embedded_window_mode = bool(runtime_window.call("is_embedded"))
	else:
		_embedded_window_mode = false
	var fallback_window_size: Vector2i = Vector2i(DisplayServer.window_get_size())
	_normalize_selected_resolution(fallback_window_size)
	var current_mode: int = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		selected_mode = 1
	elif current_mode == DisplayServer.WINDOW_MODE_WINDOWED and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS):
		selected_mode = 2
	elif current_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		selected_mode = 0
	else:
		selected_mode = clampi(selected_mode, 0, 2)
	_sync_display_options_with_state()
	var game_state := _get_game_state()
	selected_language = game_state.current_language if game_state else "en"
	if selected_language == "en":
		language_option.selected = 1
	elif selected_language == "de":
		language_option.selected = 2
	else:
		language_option.selected = 0
	if FontManager:
		selected_font_size = FontManager.get_font_size()
		font_size_option.selected = selected_font_size
	_sync_font_option_selection()
	_apply_selected_fonts_for_current_language()
	if master_volume_hbox.has_node("MasterVolumeSlider"):
		var s = master_volume_hbox.get_node("MasterVolumeSlider")
		s.min_value = 0.0
		s.max_value = 100.0
		s.value = master_volume
	if music_volume_hbox.has_node("MusicVolumeSlider"):
		var s = music_volume_hbox.get_node("MusicVolumeSlider")
		s.min_value = 0.0
		s.max_value = 100.0
		s.value = music_volume
	if sfx_volume_hbox.has_node("SFXVolumeSlider"):
		var s = sfx_volume_hbox.get_node("SFXVolumeSlider")
		s.min_value = 0.0
		s.max_value = 100.0
		s.value = sfx_volume
	mute_check_box.button_pressed = is_muted
	if gloria_voice_check:
		_set_button_pressed_safely(gloria_voice_check, gloria_voice_enabled)
	_apply_audio_settings()
	_initialize_voice_controls()
	var touch_controls = get_tree().get_root().find_child("TouchControls", true, false)
	if touch_controls:
		if not touch_controls_checkbox.toggled.is_connected(self._on_touch_controls_toggled):
			touch_controls_checkbox.toggled.connect(self._on_touch_controls_toggled)
		touch_controls_checkbox.button_pressed = touch_controls_enabled
	else:
		touch_controls_checkbox.disabled = true
	_initialize_new_controls()
	update_ui_text()
	_apply_modern_styles()
	_style_delete_logs_dialog()
	_refresh_display_mode_availability()
	UIStyleManager.fade_in($MenuContainer/Panel, 0.4)
	await get_tree().process_frame
	if apply_button:
		apply_button.grab_focus()
	_apply_exit_mode_state()
	_start_settings_bgm()
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if (event as InputEventKey).keycode == KEY_ESCAPE:
		if back_button and is_instance_valid(back_button):
			back_button.emit_signal("pressed")
			var vp := get_viewport()
			if vp:
				vp.set_input_as_handled()
func _start_settings_bgm() -> void:
	var audio := _get_audio_manager()
	if not audio or not audio.has_method("play_music"):
		return
	if not audio.has_method("has_sound") or not audio.has_sound("settings_bgm"):
		return
	if audio.has_method("suspend_gameplay_playlist"):
		audio.suspend_gameplay_playlist()
	if audio.has_method("stop_music"):
		audio.stop_music(0.5)
	get_tree().create_timer(0.6).timeout.connect(
		func():
			if is_instance_valid(audio) and audio.has_sound("settings_bgm"):
				audio.play_music("settings_bgm", true),
		CONNECT_ONE_SHOT
	)
func _exit_tree() -> void:
	_cleanup_ai_resources()
	var audio := _get_audio_manager()
	if not audio:
		return
	var music_pl = audio.get("music_player")
	if music_pl and is_instance_valid(music_pl):
		music_pl.stop()
		var music_bus_exists := AudioServer.get_bus_index("Music") != -1
		var mv: float = float(audio.get("music_volume") if audio.get("music_volume") != null else 0.7)
		var master_v: float = float(audio.get("master_volume") if audio.get("master_volume") != null else 0.8)
		music_pl.volume_db = 0.0 if music_bus_exists else linear_to_db(mv * master_v)
	audio.set("current_music", null)
	var raw_active = audio.get("_playlist_active")
	if raw_active and audio.has_method("resume_gameplay_playlist"):
		get_tree().create_timer(0.5).timeout.connect(
			func(): if is_instance_valid(audio): audio.resume_gameplay_playlist(),
			CONNECT_ONE_SHOT
		)
	elif audio.has_method("play_music") and audio.has_method("has_sound"):
		if audio.has_sound("background_music"):
			get_tree().create_timer(0.5).timeout.connect(
				func(): if is_instance_valid(audio): audio.play_music("background_music", true),
				CONNECT_ONE_SHOT
			)
func _rebuild_layout_into_tabs() -> void:
	var result := SettingsMenuLayoutBuilderScript.rebuild_tabs(
		main_vbox, original_scroll,
		{
			"language_label": language_label, "language_option": language_option,
			"touch_controls_checkbox": touch_controls_checkbox,
			"ai_settings_button": ai_settings_button, "delete_logs_button": delete_logs_button,
			"fullscreen_label": fullscreen_label, "fullscreen_option": fullscreen_option,
			"resolution_label": resolution_label, "resolution_option": resolution_option,
			"font_size_label": font_size_label, "font_size_option": font_size_option,
			"english_font_label": english_font_label, "english_font_option": english_font_option,
			"chinese_font_label": chinese_font_label, "chinese_font_option": chinese_font_option,
			"mute_check_box": mute_check_box,
			"master_volume_hbox": master_volume_hbox, "music_volume_hbox": music_volume_hbox,
			"sfx_volume_hbox": sfx_volume_hbox,
			"voice_description": voice_description,
			"voice_availability_label": voice_availability_label,
			"voice_enabled_check": voice_enabled_check, "voice_options_box": voice_options_box,
		},
		Callable(self, "_on_gloria_voice_toggled"),
		Callable(self, "_create_ai_log_tab_page"),
	)
	tab_container    = result["tab_container"]
	tab_gameplay     = result["tab_gameplay"]
	tab_display      = result["tab_display"]
	tab_audio        = result["tab_audio"]
	tab_voice        = result["tab_voice"]
	tab_tutorial     = result["tab_tutorial"]
	tab_developer    = result["tab_developer"]
	text_speed_label  = result["text_speed_label"]
	text_speed_option = result["text_speed_option"]
	screen_shake_check = result["screen_shake_check"]
	max_rounds_label  = result["max_rounds_label"]
	max_rounds_spinbox = result["max_rounds_spinbox"]
	gloria_voice_check = result["gloria_voice_check"]
func _create_ai_log_tab_page(tab_container: TabContainer) -> VBoxContainer:
	_ai_log_ctrl = SettingsMenuAILogControllerScript.new()
	var result: Dictionary = SettingsMenuAILogSectionScript.build_log_page(
		tab_container,
		{
			"history": ICON_HISTORY, "options": ICON_OPTIONS, "refresh": ICON_REFRESH,
			"save": ICON_SAVE, "delete": ICON_DELETE, "info": ICON_INFO,
			"check": ICON_CHECK, "sync": ICON_SYNC,
		},
		Callable(self, "_tr_ai"),
		_ai_chart_width,
		_ai_chart_height,
		{
			"toggle_log":            Callable(_ai_log_ctrl, "_on_ai_log_toggle_log_pressed"),
			"toggle_charts":         Callable(_ai_log_ctrl, "_on_ai_log_toggle_charts_pressed"),
			"refresh":               Callable(_ai_log_ctrl, "_on_ai_log_refresh_pressed"),
			"export_json":           Callable(_ai_log_ctrl, "_on_ai_export_pressed"),
			"export_csv":            Callable(_ai_log_ctrl, "_on_ai_export_csv_pressed"),
			"clear":                 Callable(_ai_log_ctrl, "_on_ai_log_clear_pressed"),
			"chart_size_changed":    Callable(_ai_log_ctrl, "_on_ai_chart_size_changed"),
			"chart_visibility_toggled": Callable(_ai_log_ctrl, "_on_ai_chart_visibility_toggled"),
			"tab_changed":           Callable(_ai_log_ctrl, "_on_ai_log_tab_changed"),
		},
	)
	_ai_log_ctrl.initialize(result, _ai_chart_width, _ai_chart_height, tab_container, Callable(self, "_tr_ai"))
	_normalize_ai_log_language_texts(result["outer_vbox"] as VBoxContainer)
	return result["outer_vbox"] as VBoxContainer
func _initialize_new_controls():
	_dev_ctrl = SettingsMenuDeveloperHandlersScript.new()
	_dev_ctrl.setup(
		Callable(self, "_get_game_state"),
		Callable(self, "_show_notification"),
		Callable(self, "_play_sfx"),
		Callable(self, "_report_info"),
	)
	var game_state := _get_game_state()
	var dev_result := SettingsMenuDeveloperSectionScript.build_section(
		tab_developer,
		{
			"text_speed_option": text_speed_option,
			"screen_shake_check": screen_shake_check,
			"max_rounds_spinbox": max_rounds_spinbox,
		},
		{
			"text_speed": text_speed,
			"screen_shake_enabled": screen_shake_enabled,
			"max_rounds_per_mission": max_rounds_per_mission,
		},
		game_state,
		{
			"on_text_speed_selected":          _on_text_speed_selected,
			"on_screen_shake_toggled":         _on_screen_shake_toggled,
			"on_max_rounds_changed":           _on_max_rounds_changed,
			"on_force_mission_complete_toggled": Callable(_dev_ctrl, "_on_force_mission_complete_toggled"),
			"on_force_gloria_pressed":         _on_force_gloria_pressed,
			"on_force_trolley_pressed":        _on_force_trolley_pressed,
			"on_force_honeymoon_toggled":      _on_force_honeymoon_toggled,
			"on_reality_score_changed":        Callable(_dev_ctrl, "_on_reality_score_changed"),
			"on_positive_energy_changed":      Callable(_dev_ctrl, "_on_positive_energy_changed"),
			"on_entropy_level_changed":        Callable(_dev_ctrl, "_on_entropy_level_changed"),
			"on_honeymoon_charges_changed":    Callable(_dev_ctrl, "_on_honeymoon_charges_changed"),
			"on_mission_turn_changed":         Callable(_dev_ctrl, "_on_mission_turn_changed"),
			"on_max_stats_pressed":            Callable(_dev_ctrl, "_on_max_stats_pressed"),
			"on_reset_stats_pressed":          Callable(_dev_ctrl, "_on_reset_stats_pressed"),
			"on_clear_debuffs_pressed":        Callable(_dev_ctrl, "_on_clear_debuffs_pressed"),
			"on_add_honeymoon_pressed":        Callable(_dev_ctrl, "_on_add_honeymoon_pressed"),
			"on_autosave_toggled":             Callable(_dev_ctrl, "_on_autosave_toggled"),
			"on_infinite_resources_toggled":   Callable(_dev_ctrl, "_on_infinite_resources_toggled"),
			"on_skip_dialogue_toggled":        Callable(_dev_ctrl, "_on_skip_dialogue_toggled"),
			"on_god_mode_toggled":             Callable(_dev_ctrl, "_on_god_mode_toggled"),
			"on_fsm_jump_to_day_pressed":      Callable(_dev_ctrl, "_on_fsm_jump_to_day_pressed"),
			"on_fsm_reset_pressed":            Callable(_dev_ctrl, "_on_fsm_reset_pressed"),
		},
		{
			"fsm_guide": FSM_IMG_GUIDE,
			"fsm_teacher": FSM_IMG_TEACHER,
			"fsm_gloria": FSM_IMG_GLORIA,
		},
	)
	force_mission_complete_check = dev_result.get("force_mission_complete_check")
	force_gloria_button = dev_result.get("force_gloria_button")
	force_gloria_status_label = dev_result.get("force_gloria_status_label")
	force_trolley_button = dev_result.get("force_trolley_button")
	force_trolley_status_label = dev_result.get("force_trolley_status_label")
	force_honeymoon_check = dev_result.get("force_honeymoon_check")
	reality_score_label = dev_result.get("reality_score_label")
	reality_score_spinbox = dev_result.get("reality_score_spinbox")
	positive_energy_label = dev_result.get("positive_energy_label")
	positive_energy_spinbox = dev_result.get("positive_energy_spinbox")
	entropy_level_label = dev_result.get("entropy_level_label")
	entropy_level_spinbox = dev_result.get("entropy_level_spinbox")
	honeymoon_charges_label = dev_result.get("honeymoon_charges_label")
	honeymoon_charges_spinbox = dev_result.get("honeymoon_charges_spinbox")
	mission_turn_label = dev_result.get("mission_turn_label")
	mission_turn_spinbox = dev_result.get("mission_turn_spinbox")
	max_stats_button = dev_result.get("max_stats_button")
	reset_stats_button = dev_result.get("reset_stats_button")
	clear_debuffs_button = dev_result.get("clear_debuffs_button")
	add_honeymoon_button = dev_result.get("add_honeymoon_button")
	autosave_toggle = dev_result.get("autosave_toggle")
	infinite_resources_toggle = dev_result.get("infinite_resources_toggle")
	skip_dialogue_toggle = dev_result.get("skip_dialogue_toggle")
	god_mode_toggle = dev_result.get("god_mode_toggle")
	_dev_ctrl.set_node_refs(dev_result)
	_initialize_agent_server_controls()
	_initialize_tutorial_controls()
func _initialize_agent_server_controls():
	if _agent_server_section == null:
		_agent_server_section = SettingsMenuAgentServerSectionScript.new()
	var agent_server := _get_agent_server()
	var controls: Dictionary = _agent_server_section.build_section(
		tab_developer,
		{
			"section_title": tr("AGENT_SERVER_SECTION_TITLE"),
			"description": tr("AGENT_SERVER_DESCRIPTION"),
			"enable": tr("AGENT_SERVER_ENABLE"),
			"ws": "WebSocket: ws://localhost:9876",
			"tcp": "TCP: localhost:9877",
			"mcp": "MCP Server: mcp/gda1_server.py",
			"how_to_connect": tr("AGENT_SERVER_HOW_TO_CONNECT"),
		},
		agent_server != null and agent_server.is_server_running(),
		Callable(self, "_on_agent_server_enabled_toggled"),
		Callable(self, "_on_agent_server_help_pressed"),
	)
	agent_server_enabled_check = controls.get("enabled_check", null) as CheckBox
	agent_server_status_label = controls.get("status_label", null) as Label
	agent_server_help_button = controls.get("help_button", null) as Button
	_update_agent_server_status()
func _initialize_tutorial_controls():
	_tutorial_ctrl = SettingsMenuTutorialHandlers.new()
	_tutorial_ctrl.setup(Callable(self, "_play_sfx"), Callable(self, "_show_notification"))
	var tutorial_system = ServiceLocator.get_tutorial_system() if ServiceLocator else null
	if _tutorial_section == null:
		_tutorial_section = SettingsMenuTutorialSection.new()
	var controls: Dictionary = _tutorial_section.build_section(
		tab_tutorial,
		tutorial_system,
		Callable(_tutorial_ctrl, "_on_tutorial_enabled_toggled"),
		Callable(_tutorial_ctrl, "_on_reset_tutorials_pressed"),
		Callable(_tutorial_ctrl, "_on_trigger_tutorial"),
	)
	tutorial_enabled_toggle = controls.get("tutorial_enabled_toggle", null) as CheckBox
	tutorial_progress_label = controls.get("tutorial_progress_label", null) as Label
	reset_tutorials_button  = controls.get("reset_tutorials_button",  null) as Button
	tutorial_list_container = controls.get("tutorial_list_container", null) as VBoxContainer
	_tutorial_ctrl.set_node_refs(tutorial_progress_label, tutorial_list_container)
	_tutorial_ctrl.update_progress_display()
func _on_text_speed_selected(index: int):
	match index:
		0: text_speed = 0.0
		1: text_speed = 2.0
		2: text_speed = 1.0
		3: text_speed = 0.5
	_play_sfx("menu_click")
func _on_screen_shake_toggled(toggled: bool):
	screen_shake_enabled = toggled
func _on_max_rounds_changed(value: float):
	max_rounds_per_mission = int(value)
	var game_state := _get_game_state()
	if game_state:
		game_state.settings["max_rounds_per_mission"] = max_rounds_per_mission
func _on_force_gloria_pressed():
	_play_sfx("menu_click")
	var flow = _get_story_flow_controller()
	if flow and flow.has_method("force_gloria_intervention"):
		flow.force_gloria_intervention()
		_gloria_triggered = true
		_update_debug_button_status(force_gloria_button, force_gloria_status_label, true, "✓ Queued! Close menu & pick a story choice.")
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(self):
			_close_menu()
	else:
		_update_debug_button_status(force_gloria_button, force_gloria_status_label, false, "✗ Not in story scene")
func _on_force_trolley_pressed():
	_play_sfx("menu_click")
	var flow = _get_story_flow_controller()
	if flow and flow.has_method("_schedule_trolley_problem"):
		flow._schedule_trolley_problem()
		_trolley_triggered = true
		_update_debug_button_status(force_trolley_button, force_trolley_status_label, true, "✓ Scheduled! Close menu to see effect.")
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(self):
			_close_menu()
	else:
		_update_debug_button_status(force_trolley_button, force_trolley_status_label, false, "✗ Not in story scene")
func _update_debug_button_status(button: Button, label: Label, success: bool, message: String) -> void:
	SettingsMenuDeveloperSectionScript.update_debug_button_status(button, label, success, message)
func _on_force_honeymoon_toggled(toggled: bool):
	_play_sfx("menu_click")
	var flow = _get_story_flow_controller()
	if flow and flow.has_method("force_honeymoon_phase"):
		flow.force_honeymoon_phase(toggled)
func _get_story_flow_controller() -> Object:
	if ServiceLocator:
		return ServiceLocator.get_story_flow_controller()
	return null
func _close_menu():
	if _exit_mode == EXIT_MODE_OVERLAY:
		close_requested.emit()
		queue_free()
	else:
		_on_back_button_pressed()
func _show_notification(message: String, success: bool = true):
	var notifier = ServiceLocator.get_notification_system() if ServiceLocator else null
	if notifier:
		if success:
			notifier.show_success(message)
		else:
			notifier.show_warning(message)
	else:
		_debug_log("[Settings] " + message)
func _enforce_fullscreen_layout() -> void:
	if menu_container:
		menu_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	if panel:
		var viewport_size = get_viewport_rect().size
		panel.custom_minimum_size = viewport_size
		panel.size = viewport_size
		panel.position = Vector2.ZERO
		if not menu_container.resized.is_connected(_on_viewport_resized):
			menu_container.resized.connect(_on_viewport_resized)
func _on_viewport_resized() -> void:
	var viewport_size = get_viewport_rect().size
	if panel:
		panel.custom_minimum_size = viewport_size
		panel.size = viewport_size
func update_ui_text():
	if tab_container:
		var ai_tab := tab_container.get_tab_count() - 1
		if ai_tab >= 0:
			_normalize_ai_log_language_texts(tab_container.get_child(ai_tab))
	SettingsMenuUITextScript.apply_labels({
		"tab_container": tab_container,
		"title_label": title_label,
		"text_speed_label": text_speed_label,
		"text_speed_option": text_speed_option,
		"screen_shake_check": screen_shake_check,
		"max_rounds_label": max_rounds_label,
		"max_rounds_spinbox": max_rounds_spinbox,
		"touch_controls_checkbox": touch_controls_checkbox,
		"force_mission_complete_check": force_mission_complete_check,
		"reality_score_label": reality_score_label,
		"positive_energy_label": positive_energy_label,
		"entropy_level_label": entropy_level_label,
		"honeymoon_charges_label": honeymoon_charges_label,
		"mission_turn_label": mission_turn_label,
		"tab_developer": tab_developer,
		"max_stats_button": max_stats_button,
		"reset_stats_button": reset_stats_button,
		"clear_debuffs_button": clear_debuffs_button,
		"add_honeymoon_button": add_honeymoon_button,
		"autosave_toggle": autosave_toggle,
		"infinite_resources_toggle": infinite_resources_toggle,
		"skip_dialogue_toggle": skip_dialogue_toggle,
		"god_mode_toggle": god_mode_toggle,
		"master_volume_hbox": master_volume_hbox,
		"music_volume_hbox": music_volume_hbox,
		"sfx_volume_hbox": sfx_volume_hbox,
		"gloria_voice_check": gloria_voice_check,
		"mute_check_box": mute_check_box,
		"voice_description": voice_description,
		"voice_enabled_check": voice_enabled_check,
		"voice_output_check": voice_output_check,
		"voice_input_check": voice_input_check,
		"voice_choice_label": voice_choice_label,
		"voice_volume_label": voice_volume_label,
		"voice_input_mode_label": voice_input_mode_label,
		"voice_proactive_check": voice_proactive_check,
		"voice_capture_button": voice_capture_button,
		"voice_preview_button": voice_preview_button,
		"voice_status_label": voice_status_label,
		"resolution_label": resolution_label,
		"fullscreen_label": fullscreen_label,
		"language_label": language_label,
		"font_size_label": font_size_label,
		"english_font_label": english_font_label,
		"chinese_font_label": chinese_font_label,
		"tab_tutorial": tab_tutorial,
		"tutorial_enabled_toggle": tutorial_enabled_toggle,
		"reset_tutorials_button": reset_tutorials_button,
		"ai_settings_button": ai_settings_button,
		"apply_button": apply_button,
		"delete_logs_button": delete_logs_button,
		"back_button": back_button,
		"delete_logs_dialog": delete_logs_dialog,
		"fullscreen_option": fullscreen_option,
	}, Callable(self, "_tr"), _voice_ctrl.voice_capture_active if _voice_ctrl else false)
	if _tutorial_ctrl:
		_tutorial_ctrl.update_progress_display()
	_refresh_display_mode_availability()
	_update_voice_availability_label()
func _set_button_pressed_safely(button: BaseButton, pressed: bool) -> void:
	if not button: return
	if button.has_method("set_pressed_no_signal"):
		button.call("set_pressed_no_signal", pressed)
		return
	var was_blocking := button.is_blocking_signals()
	button.set_block_signals(true)
	button.button_pressed = pressed
	button.set_block_signals(was_blocking)
func _ensure_background_aliases() -> void:
	if not BackgroundLoader: return
	var catalog = BackgroundLoader.get("backgrounds")
	if typeof(catalog) != TYPE_DICTIONARY: return
	if catalog.has("fire_area"): return
	if not catalog.has("fire"): return
	var source: Dictionary = catalog["fire"].duplicate(true)
	source["name"] = source.get("name", "Fire Area")
	catalog["fire_area"] = source
	var cache = BackgroundLoader.get("texture_cache")
	if cache is LRUCache and cache.has_key("fire"):
		cache.put("fire_area", cache.get_value("fire"))
func _cleanup_ai_resources(force_clear_callback: bool = false) -> void:
	_cancel_active_voice_capture()
	_disconnect_ai_signals()
	_clear_pending_ai_callback(force_clear_callback)
func _cancel_active_voice_capture() -> void:
	if _voice_ctrl:
		_voice_ctrl.cancel_capture(AIManager)
func _disconnect_ai_signals() -> void:
	if _voice_ctrl:
		_voice_ctrl.disconnect_ai_signals(AIManager)
func _clear_pending_ai_callback(force_clear: bool) -> void:
	if not AIManager: return
	var pending := AIManager.pending_callback
	if pending.is_null(): return
	if force_clear:
		AIManager.pending_callback = Callable()
		return
	if pending.is_valid():
		var target := pending.get_object()
		if target == self:
			AIManager.pending_callback = Callable()
	else:
		AIManager.pending_callback = Callable()
func _apply_modern_styles():
	SettingsMenuStylesScript.apply_modern_styles({
		"panel": panel,
		"apply_button": apply_button,
		"ai_settings_button": ai_settings_button,
		"back_button": back_button,
		"delete_logs_button": delete_logs_button,
		"master_volume_hbox": master_volume_hbox,
		"music_volume_hbox": music_volume_hbox,
		"sfx_volume_hbox": sfx_volume_hbox,
		"voice_preview_button": voice_preview_button,
		"voice_capture_button": voice_capture_button,
		"reset_tutorials_button": reset_tutorials_button,
		"tab_tutorial": tab_tutorial,
		"tutorial_list_container": tutorial_list_container,
	}, {
		"check": ICON_CHECK,
		"creative": ICON_CREATIVE,
		"back": ICON_BACK,
		"delete": ICON_DELETE,
		"mic": ICON_MIC,
	})
	_connect_button_sounds()
func _get_ai_manager() -> Node:
	return AIManager
func _get_audio_manager() -> Node:
	if is_instance_valid(_audio_manager):
		return _audio_manager
	if ServiceLocator:
		_audio_manager = ServiceLocator.get_audio_manager()
	return _audio_manager
func _get_game_state() -> Node:
	if is_instance_valid(_game_state):
		return _game_state
	if ServiceLocator:
		_game_state = ServiceLocator.get_game_state()
	return _game_state
func _play_sfx(sfx_name: String) -> void:
	var audio := _get_audio_manager()
	if audio and audio.has_method("play_sfx"):
		audio.play_sfx(sfx_name)
func _connect_button_sounds() -> void:
	var menu_click_buttons = [
		back_button, ai_settings_button,
		voice_preview_button, voice_capture_button,
		screen_shake_check, touch_controls_checkbox,
		mute_check_box, gloria_voice_check, delete_logs_button
	]
	for btn in menu_click_buttons:
		if btn:
			if not btn.pressed.is_connected(_play_sfx.bind("menu_click")):
				btn.pressed.connect(_play_sfx.bind("menu_click"))
	if apply_button:
		if not apply_button.pressed.is_connected(_play_sfx.bind("happy_click")):
			apply_button.pressed.connect(_play_sfx.bind("happy_click"))
	if delete_logs_dialog:
		var ok_btn = delete_logs_dialog.get_ok_button()
		if ok_btn and not ok_btn.pressed.is_connected(_play_sfx.bind("angry_click")):
			ok_btn.pressed.connect(_play_sfx.bind("angry_click"))
func _style_delete_logs_dialog() -> void:
	if not delete_logs_dialog: return
	var dialog_style: StyleBoxFlat = UIStyleManager.create_panel_style(0.96, UIStyleManager.CORNER_RADIUS_LARGE)
	delete_logs_dialog.add_theme_stylebox_override("panel", dialog_style)
	var ok_button: Button = delete_logs_dialog.get_ok_button()
	if ok_button:
		UIStyleManager.apply_button_style(ok_button, "danger", "medium")
		UIStyleManager.add_press_feedback(ok_button)
		ok_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var cancel_button: Button = delete_logs_dialog.get_cancel_button()
	if cancel_button:
		UIStyleManager.apply_button_style(cancel_button, "secondary", "medium")
		UIStyleManager.add_press_feedback(cancel_button)
		cancel_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
func _initialize_voice_controls():
	if AudioManager:
		var audio_snapshot: Dictionary = AudioManager.get_volume_settings()
		gloria_voice_enabled = bool(audio_snapshot.get("gloria_voice_enabled", gloria_voice_enabled))
		if gloria_voice_check:
			_set_button_pressed_safely(gloria_voice_check, gloria_voice_enabled)
	_voice_ctrl = SettingsMenuVoiceHandlersScript.new()
	_voice_ctrl.setup(
		Callable(self, "_get_ai_manager"),
		Callable(self, "_get_audio_manager"),
		Callable(self, "_apply_audio_settings"),
		Callable(self, "_play_sfx"),
		Callable(self, "_tr"),
		Callable(self, "_set_button_pressed_safely"),
	)
	_voice_ctrl.set_node_refs({
		"availability_label": voice_availability_label,
		"enabled_check":      voice_enabled_check,
		"options_box":        voice_options_box,
		"output_check":       voice_output_check,
		"input_check":        voice_input_check,
		"voice_option":       voice_voice_option,
		"volume_slider":      voice_volume_slider,
		"volume_value":       voice_volume_value,
		"input_mode_option":  voice_input_mode_option,
		"proactive_check":    voice_proactive_check,
		"preview_button":     voice_preview_button,
		"capture_button":     voice_capture_button,
		"status_label":       voice_status_label,
	})
	_voice_ctrl.initialize(_pending_voice_settings)
func _sync_voice_ui_state():
	if _voice_ctrl:
		_voice_ctrl.sync_ui_state()
func _update_voice_availability_label():
	if _voice_ctrl:
		_voice_ctrl.update_availability_label()
func _on_voice_enabled_toggled(button_pressed: bool):
	if _voice_ctrl:
		_voice_ctrl.on_voice_enabled_toggled(button_pressed)
func _on_voice_output_toggled(button_pressed: bool):
	if _voice_ctrl:
		_voice_ctrl.on_voice_output_toggled(button_pressed)
func _on_voice_input_toggled(button_pressed: bool):
	if _voice_ctrl:
		_voice_ctrl.on_voice_input_toggled(button_pressed)
func _on_voice_voice_option_selected(index: int):
	if _voice_ctrl:
		_voice_ctrl.on_voice_voice_option_selected(index)
func _on_voice_volume_changed(value: float):
	if _voice_ctrl:
		_voice_ctrl.on_voice_volume_changed(value)
func _on_voice_input_mode_selected(index: int):
	if _voice_ctrl:
		_voice_ctrl.on_voice_input_mode_selected(index)
func _on_voice_proactive_toggled(button_pressed: bool):
	if _voice_ctrl:
		_voice_ctrl.on_voice_proactive_toggled(button_pressed)
func _on_voice_preview_button_pressed():
	if _voice_ctrl:
		_voice_ctrl.on_voice_preview_button_pressed()
func _on_voice_capture_button_pressed():
	if _voice_ctrl:
		_voice_ctrl.on_voice_capture_button_pressed()
func _on_touch_controls_toggled(button_pressed: bool) -> void:
	touch_controls_enabled = button_pressed
	var touch_controls = get_tree().get_root().find_child("TouchControls", true, false)
	if touch_controls:
		touch_controls.visible = touch_controls_enabled
func _get_audio_settings_data() -> Dictionary:
	return {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"voice_volume": _voice_ctrl.voice_volume if _voice_ctrl else 80.0,
		"gloria_voice_enabled": gloria_voice_enabled,
		"muted": is_muted,
	}
func _on_master_volume_changed(value: float):
	master_volume = value
	SettingsMenuAudioSectionScript.update_volume_label(master_volume_hbox, "MasterVolumeValue", value)
	SettingsMenuAudioSectionScript.apply_audio_settings(_get_audio_settings_data())
func _on_music_volume_changed(value: float):
	music_volume = value
	SettingsMenuAudioSectionScript.update_volume_label(music_volume_hbox, "MusicVolumeValue", value)
	SettingsMenuAudioSectionScript.apply_audio_settings(_get_audio_settings_data())
func _on_sfx_volume_changed(value: float):
	sfx_volume = value
	SettingsMenuAudioSectionScript.update_volume_label(sfx_volume_hbox, "SFXVolumeValue", value)
	SettingsMenuAudioSectionScript.apply_audio_settings(_get_audio_settings_data())
func _on_gloria_voice_toggled(button_pressed: bool):
	gloria_voice_enabled = button_pressed
	print("[Godot-Cmd-Debug] Settings Menu - Gloria Voice toggled to: ", "ON" if button_pressed else "OFF")
	SettingsMenuAudioSectionScript.apply_audio_settings(_get_audio_settings_data())
func _on_mute_toggled(button_pressed: bool):
	is_muted = button_pressed
	SettingsMenuAudioSectionScript.apply_audio_settings(_get_audio_settings_data())
func _apply_audio_settings():
	SettingsMenuAudioSectionScript.apply_audio_settings(_get_audio_settings_data())
func _normalize_selected_resolution(fallback_size: Vector2i) -> void:
	selected_resolution = SettingsMenuDisplaySectionScript.normalize_resolution(
		selected_resolution, resolutions, fallback_size
	)
func _initialize_font_options() -> void:
	if english_font_option == null or chinese_font_option == null:
		return
	var en_fonts: Array = []
	var zh_fonts: Array = []
	if FontManager and FontManager.has_method("get_available_fonts_for_language"):
		en_fonts = FontManager.get_available_fonts_for_language("en")
		zh_fonts = FontManager.get_available_fonts_for_language("zh")
	if en_fonts.is_empty():
		en_fonts.append(_get_default_font("en"))
	if zh_fonts.is_empty():
		zh_fonts.append(_get_default_font("zh"))
	SettingsMenuDisplaySectionScript.populate_font_option(english_font_option, en_fonts)
	SettingsMenuDisplaySectionScript.populate_font_option(chinese_font_option, zh_fonts)
	if selected_english_font.is_empty():
		selected_english_font = en_fonts[0]
	if selected_chinese_font.is_empty():
		selected_chinese_font = zh_fonts[0]
	_sync_font_option_selection()
func _sync_font_option_selection() -> void:
	selected_english_font = SettingsMenuDisplaySectionScript.select_option_by_metadata(
		english_font_option, selected_english_font, _get_default_font("en")
	)
	selected_chinese_font = SettingsMenuDisplaySectionScript.select_option_by_metadata(
		chinese_font_option, selected_chinese_font, _get_default_font("zh")
	)
func _apply_selected_fonts_for_current_language() -> void:
	if not FontManager:
		return
	if FontManager.has_method("set_selected_font"):
		FontManager.set_selected_font("en", selected_english_font)
		FontManager.set_selected_font("zh", selected_chinese_font)
	if FontManager.has_method("apply_language_font"):
		FontManager.apply_language_font(selected_language)
func _sync_display_options_with_state() -> void:
	var resolution_key: int = SettingsMenuDisplaySectionScript.get_closest_resolution_key(
		selected_resolution, resolutions
	)
	resolution_option.select(resolution_key)
	fullscreen_option.select(clampi(selected_mode, 0, 2))
func _refresh_display_mode_availability() -> void:
	var tip: String = _tr("SETTINGS_EMBEDDED_TOOLTIP")
	resolution_option.disabled = _embedded_window_mode
	fullscreen_option.disabled = _embedded_window_mode
	if _embedded_window_mode:
		resolution_option.tooltip_text = tip
		fullscreen_option.tooltip_text = tip
	else:
		resolution_option.tooltip_text = ""
		fullscreen_option.tooltip_text = ""
func _on_resolution_changed(index: int):
	var selected_variant: Variant = resolutions.get(index, resolutions[0])
	selected_resolution = SettingsMenuDisplaySectionScript.coerce_vector2i(selected_variant, resolutions[0])
func _on_fullscreen_changed(index: int):
	selected_mode = index
func _on_language_changed(index: int):
	if index == 0:
		selected_language = "zh"
	elif index == 2:
		selected_language = "de"
	else:
		selected_language = "en"
	_report_info("Language changed to: %s" % selected_language)
	if LocalizationManager:
		LocalizationManager.set_language(selected_language)
	var game_state := _get_game_state()
	if game_state:
		game_state.current_language = selected_language
	_apply_selected_fonts_for_current_language()
	update_ui_text()
	save_settings()
func _on_font_size_changed(index: int):
	selected_font_size = index
	if FontManager:
		FontManager.set_font_size(selected_font_size)
		_report_info("Font size changed to: %s" % FontManager.get_font_size_name())
	else:
		_report_info("Font size changed to index: %s" % selected_font_size)
func _on_english_font_changed(index: int):
	selected_english_font = SettingsMenuDisplaySectionScript.get_option_metadata(english_font_option, index)
	_report_info("English font changed to: %s" % selected_english_font)
	_apply_selected_fonts_for_current_language()
func _on_chinese_font_changed(index: int):
	selected_chinese_font = SettingsMenuDisplaySectionScript.get_option_metadata(chinese_font_option, index)
	_report_info("Chinese font changed to: %s" % selected_chinese_font)
	_apply_selected_fonts_for_current_language()
func _on_apply_button_pressed():
	var window := get_window()
	var is_embedded_window: bool = false
	if window and window.has_method("is_embedded"):
		is_embedded_window = bool(window.call("is_embedded"))
	_apply_selected_fonts_for_current_language()
	selected_mode = clampi(selected_mode, 0, 2)
	var fallback_window_size: Vector2i = Vector2i(DisplayServer.window_get_size())
	_normalize_selected_resolution(fallback_window_size)
	var target_resolution: Vector2i = selected_resolution
	if not is_embedded_window and not OS.has_feature("web"):
		match selected_mode:
			0:
				if window:
					window.mode = Window.MODE_WINDOWED
					window.borderless = false
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
				await get_tree().process_frame
				if window:
					window.size = target_resolution
				DisplayServer.window_set_size(target_resolution)
			1:
				if window:
					window.borderless = false
					window.mode = Window.MODE_FULLSCREEN
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			2:
				if window:
					window.mode = Window.MODE_WINDOWED
					window.borderless = true
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
				await get_tree().process_frame
				if window:
					window.size = target_resolution
				DisplayServer.window_set_size(target_resolution)
		if selected_mode != 1:
			await get_tree().process_frame
			var screen_index: int = DisplayServer.window_get_current_screen()
			var screen_size: Vector2i = DisplayServer.screen_get_size(screen_index)
			var screen_position: Vector2i = DisplayServer.screen_get_position(screen_index)
			var window_size: Vector2i = DisplayServer.window_get_size()
			var centered_pos := screen_position + Vector2i(
				int((screen_size.x - window_size.x) / 2),
				int((screen_size.y - window_size.y) / 2),
			)
			DisplayServer.window_set_position(centered_pos)
	else:
		_debug_log("Display settings saved. Embedded window mode cannot resize/move the game window.")
	var game_state := _get_game_state()
	if game_state:
		game_state.current_language = selected_language
	if FontManager:
		FontManager.set_font_size(selected_font_size)
	_apply_audio_settings()
	if DisplayManager:
		var reported_size: Vector2i = DisplayServer.window_get_size()
		if selected_mode == 1 and not is_embedded_window:
			reported_size = target_resolution
		DisplayManager.current_window_size = reported_size
	_sync_display_options_with_state()
	save_settings()
	var feedback_text = _tr("SETTINGS_SETTINGS_APPLIED")
	_debug_log(feedback_text)
func _on_delete_logs_button_pressed():
	if AudioManager:
		AudioManager.play_sfx("menu_click")
	if delete_logs_dialog:
		delete_logs_dialog.popup_centered()
		var ok_button: Button = delete_logs_dialog.get_ok_button()
		if ok_button:
			ok_button.call_deferred("grab_focus")
func _on_delete_logs_confirmed():
	if AudioManager:
		AudioManager.play_sfx("happy_click")
	var notifier = ServiceLocator.get_notification_system() if ServiceLocator else null
	SettingsMenuLogActionsScript.delete_logs(_get_game_state(), notifier, Callable(self, "_tr"))
func _on_ai_settings_button_pressed():
	if _exit_mode == EXIT_MODE_OVERLAY:
		var ai_settings_scene = load("res://1.Codebase/src/scenes/ui/ai_settings_menu.tscn")
		if ai_settings_scene:
			var ai_settings = ai_settings_scene.instantiate()
			ai_settings.process_mode = Node.PROCESS_MODE_ALWAYS
			if ai_settings.has_method("set_overlay_mode"):
				ai_settings.set_overlay_mode(true)
			var parent = get_parent()
			if parent:
				parent.add_child(ai_settings)
				if ai_settings is Control:
					ai_settings.z_index = z_index + 10
		return
	var tree := get_tree()
	if not tree: return
	tree.paused = false
	tree.change_scene_to_file("res://1.Codebase/src/scenes/ui/ai_settings_menu.tscn")
func _on_back_button_pressed():
	save_settings()
	if _exit_mode == EXIT_MODE_OVERLAY:
		_emit_close_requested()
	else:
		close_requested.emit()
		_go_to_main_menu()
func _on_home_button_pressed():
	if _exit_mode == EXIT_MODE_OVERLAY:
		_emit_close_requested()
		EventBus.publish(
			"return_to_menu_requested",
			{
				"confirm": true,
				"source": "settings_menu",
			},
		)
	else:
		_go_to_main_menu()
func _get_default_font(language: String) -> String:
	return SettingsMenuSaveLoadScript.get_default_font(language)
func save_settings():
	SettingsMenuSaveLoadScript.save({
		"resolution": selected_resolution,
		"mode": selected_mode,
		"font_size": selected_font_size,
		"font_en": selected_english_font,
		"font_zh": selected_chinese_font,
		"high_contrast": high_contrast_mode,
		"language": selected_language,
		"text_speed": text_speed,
		"screen_shake": screen_shake_enabled,
		"max_rounds_per_mission": max_rounds_per_mission,
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"gloria_voice_enabled": gloria_voice_enabled,
		"muted": is_muted,
		"voice_enabled": _voice_ctrl.voice_enabled if _voice_ctrl else false,
		"voice_output_enabled": _voice_ctrl.voice_output_enabled if _voice_ctrl else false,
		"voice_input_enabled": _voice_ctrl.voice_input_enabled if _voice_ctrl else false,
		"voice_volume": _voice_ctrl.voice_volume if _voice_ctrl else 80.0,
		"voice_voice_name": _voice_ctrl.voice_voice_name if _voice_ctrl else "Aoede",
		"voice_input_mode": _voice_ctrl.voice_input_mode if _voice_ctrl else 0,
		"voice_proactive_enabled": _voice_ctrl.voice_proactive_enabled if _voice_ctrl else false,
		"touch_controls_enabled": touch_controls_enabled,
	}, _get_game_state())
func load_settings():
	var fallback_window_size: Vector2i = Vector2i(DisplayServer.window_get_size())
	var defaults := {
		"resolution": fallback_window_size,
		"font_en": _get_default_font("en"),
		"font_zh": _get_default_font("zh"),
		"gloria_voice_enabled": false,
		"voice_enabled": false,
		"voice_output_enabled": false,
		"voice_input_enabled": false,
		"voice_volume": 80.0,
		"voice_voice_name": "Aoede",
		"voice_input_mode": 0,
		"voice_proactive_enabled": false,
	}
	var data := SettingsMenuSaveLoadScript.load(
		defaults,
		_get_game_state(),
		Callable(self, "_apply_audio_settings"),
	)
	if not data.is_empty():
		selected_resolution = data["resolution"]
		_normalize_selected_resolution(fallback_window_size)
		selected_mode = data["mode"]
		selected_font_size = data["font_size"]
		selected_english_font = data["font_en"]
		selected_chinese_font = data["font_zh"]
		high_contrast_mode = data["high_contrast"]
		selected_language = data["language"]
		text_speed = data["text_speed"]
		screen_shake_enabled = data["screen_shake"]
		max_rounds_per_mission = data["max_rounds_per_mission"]
		master_volume = data["master_volume"]
		music_volume = data["music_volume"]
		sfx_volume = data["sfx_volume"]
		gloria_voice_enabled = data["gloria_voice_enabled"]
		is_muted = data["muted"]
		_pending_voice_settings = {
			"voice_enabled": data["voice_enabled"],
			"voice_output_enabled": data["voice_output_enabled"],
			"voice_input_enabled": data["voice_input_enabled"],
			"voice_volume": data["voice_volume"],
			"voice_voice_name": data["voice_voice_name"],
			"voice_input_mode": data["voice_input_mode"],
			"voice_proactive_enabled": data["voice_proactive_enabled"],
		}
		touch_controls_enabled = data["touch_controls_enabled"]
	else:
		_normalize_selected_resolution(fallback_window_size)
func _emit_close_requested() -> void:
	close_requested.emit()
	if _exit_mode == EXIT_MODE_OVERLAY:
		_cleanup_ai_resources()
	if not is_queued_for_deletion() and _exit_mode == EXIT_MODE_OVERLAY:
		queue_free()
func _go_to_main_menu() -> void:
	var tree := get_tree()
	if not tree: return
	_report_info("Returning to home page. Current game language: %s" % selected_language)
	_cleanup_ai_resources(true)
	tree.paused = false
	tree.change_scene_to_file("res://1.Codebase/menu_main.tscn")
func set_exit_mode(mode: int) -> void:
	_exit_mode = mode
	_apply_exit_mode_state()
func _apply_exit_mode_state() -> void:
	if title_label == null: return
	var callback := Callable(self, "_on_title_label_gui_input")
	if _exit_mode == EXIT_MODE_OVERLAY:
		var game_state := _get_game_state()
		var language: String = "en"
		if game_state != null:
			language = str(game_state.current_language)
		title_label.tooltip_text = _tr("SETTINGS_RETURN_TO_MISSION")
		title_label.mouse_filter = Control.MOUSE_FILTER_STOP
		if not title_label.gui_input.is_connected(callback):
			title_label.gui_input.connect(callback)
	else:
		title_label.tooltip_text = ""
		title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if title_label.gui_input.is_connected(callback):
			title_label.gui_input.disconnect(callback)
func _on_title_label_gui_input(event: InputEvent) -> void:
	if _exit_mode != EXIT_MODE_OVERLAY: return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_emit_close_requested()
var agent_server_enabled_check: CheckBox
var agent_server_status_label: Label
var agent_server_help_button: Button
var agent_server_help_popup: AcceptDialog
func _get_agent_server() -> Node:
	if ServiceLocator and ServiceLocator.has_method("get_game_agent_server"):
		var service = ServiceLocator.get_game_agent_server()
		if service != null:
			return service
	return null
func _on_agent_server_enabled_toggled(button_pressed: bool) -> void:
	_play_sfx("menu_click")
	var agent_server := _get_agent_server()
	if agent_server:
		if button_pressed:
			agent_server.enable_server()
			_show_notification("AI Agent Server enabled", true)
		else:
			agent_server.disable_server()
			_show_notification("AI Agent Server disabled", true)
		_update_agent_server_status()
func _on_agent_server_help_pressed() -> void:
	_play_sfx("menu_click")
	_show_agent_server_help_popup()
func _update_agent_server_status() -> void:
	if not agent_server_status_label:
		agent_server_status_label = find_child("AgentServerStatusLabel", true, false) as Label
	if not agent_server_status_label:
		return
	if _agent_server_section == null:
		_agent_server_section = SettingsMenuAgentServerSectionScript.new()
	var is_running := false
	var agent_count := 0
	var agent_server := _get_agent_server()
	if agent_server:
		is_running = agent_server.is_server_running()
		agent_count = agent_server.get_connected_count()
	_agent_server_section.update_status_label(agent_server_status_label, selected_language, is_running, agent_count)
func _show_agent_server_help_popup() -> void:
	if _agent_server_section == null:
		_agent_server_section = SettingsMenuAgentServerSectionScript.new()
	agent_server_help_popup = _agent_server_section.ensure_help_popup(
		self,
		agent_server_help_popup,
		tr("AGENT_SERVER_HELP_TITLE"),
		tr("AGENT_SERVER_HELP_TEXT"),
		tr("AGENT_SERVER_HELP_OK"),
	)
	agent_server_help_popup.popup_centered()
func _report_info(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, message, details)
func _debug_log(message: String) -> void:
	if VERBOSE_LOGS:
		ErrorReporterBridge.report_info(ERROR_CONTEXT, message)
