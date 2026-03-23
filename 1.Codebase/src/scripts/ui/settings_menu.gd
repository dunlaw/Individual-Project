extends Control
const EXIT_MODE_MAIN_MENU := 0
const EXIT_MODE_OVERLAY := 1
const VERBOSE_LOGS := GameConstants.Debug.ENABLE_VERBOSE_LOGS
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
const ERROR_CONTEXT := "SettingsMenu"
@warning_ignore("shadowed_global_identifier")
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
const SettingsMenuAgentServerSectionScript = preload("res://1.Codebase/src/scripts/ui/settings_menu_agent_server_section.gd")
const SettingsMenuTutorialSectionScript = preload("res://1.Codebase/src/scripts/ui/settings_menu_tutorial_section.gd")
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
var gloria_voice_enabled: bool = true
var is_muted: bool = false
var touch_controls_enabled: bool = false
var text_speed: float = 1.0
var screen_shake_enabled: bool = true
var max_rounds_per_mission: int = 0
var auto_advance_enabled: bool = false
var high_contrast_mode: bool = false
var voice_enabled: bool = false
var voice_output_enabled: bool = false
var voice_input_enabled: bool = false
var voice_volume: float = 80.0
var voice_voice_name: String = "Aoede"
var voice_input_mode: int = 0
var voice_proactive_enabled: bool = false
var voice_supported: bool = false
var voice_capture_active: bool = false
var _embedded_window_mode: bool = false
var _exit_mode: int = EXIT_MODE_MAIN_MENU
const VOICE_VOICE_NAMES = [
	"Aoede",
	"Callisto",
	"Elektra",
	"Orion",
	"Sol",
]
const VOICE_INPUT_MODE_LABELS := {
	0: "Push to talk",
	1: "Continuous",
}
const VOICE_CAPTURE_SECONDS := 4.0
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
var _ai_log_rows_container: VBoxContainer = null
var _ai_log_view_panel: Control = null
var _ai_analytics_view: Control = null
var _ai_showing_charts: bool = false
var _chart_success_by_provider: Control = null
var _chart_mode_pie: Control = null
var _chart_hourly_requests: Control = null
var _chart_tokens_by_provider: Control = null
var _chart_response_by_provider: Control = null
var _chart_hourly_tokens: Control = null
var _chart_input_output_tokens: Control = null
var _chart_success_per_hour: Control = null
var _chart_tps_by_provider: Control = null
var _chart_cumulative_tokens: Control = null
var _chart_calls_by_model: Control = null
var _ai_kpi_labels: Array = []
var _ai_chart_rows: Array[Control] = []
var _ai_chart_canvases: Array[Control] = []
var _ai_charts_open: bool = true
var _ai_chart_width: float = 480.0
var _ai_chart_height: float = 190.0
var _ai_chart_toggle_button: Button = null
var _ai_chart_width_spin: SpinBox = null
var _ai_chart_height_spin: SpinBox = null
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
	if root == null:
		return
	var title := root.find_child("AILogTitle", true, false) as Label
	if title:
		title.text = _tr_ai("SETTINGS_AI_LOG_TITLE", "AI Call Log")
	var toggle_log := root.find_child("AILogToggleLog", true, false) as Button
	if toggle_log:
		toggle_log.text = _tr_ai("SETTINGS_AI_LOG_TOGGLE_LOG", "Log")
	var toggle_charts := root.find_child("AILogToggleCharts", true, false) as Button
	if toggle_charts:
		toggle_charts.text = _tr_ai("SETTINGS_AI_LOG_TOGGLE_CHARTS", "Charts")
	var refresh_btn := root.find_child("AILogRefreshButton", true, false) as Button
	if refresh_btn:
		refresh_btn.tooltip_text = _tr_ai("SETTINGS_AI_LOG_REFRESH_TOOLTIP", "Refresh")
	var export_btn := root.find_child("AILogExportButton", true, false) as Button
	if export_btn:
		export_btn.tooltip_text = _tr_ai("SETTINGS_AI_LOG_EXPORT_JSON_TOOLTIP", "Export log to JSON")
	var export_csv_btn := root.find_child("AILogExportCsvButton", true, false) as Button
	if export_csv_btn:
		export_csv_btn.text = _tr_ai("SETTINGS_AI_LOG_EXPORT_CSV_SHORT", "CSV")
		export_csv_btn.tooltip_text = _tr_ai("SETTINGS_AI_LOG_EXPORT_CSV_TOOLTIP", "Export log and chart data to CSV")
	var clear_btn := root.find_child("AILogClearButton", true, false) as Button
	if clear_btn:
		clear_btn.tooltip_text = _tr_ai("SETTINGS_AI_LOG_CLEAR_TOOLTIP", "Clear log")
	var empty_lbl := root.find_child("AILogEmptyLabel", true, false) as Label
	if empty_lbl:
		empty_lbl.text = _tr_ai("SETTINGS_AI_LOG_EMPTY", "No AI calls recorded yet.")
	if _ai_chart_toggle_button:
		_ai_chart_toggle_button.text = _tr_ai("SETTINGS_AI_LOG_HIDE_GRAPHS", "Hide Graphs") if _ai_charts_open else _tr_ai("SETTINGS_AI_LOG_SHOW_GRAPHS", "Show Graphs")
func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_background_aliases()
	_enforce_fullscreen_layout()
	_add_settings_banner()
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
func _add_settings_banner():
	var banner = TextureRect.new()
	banner.name = "SettingsBanner"
	banner.texture = SETTINGS_BANNER
	banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	banner.custom_minimum_size = Vector2(64, 64)
	banner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_vbox.add_child(banner)
	main_vbox.move_child(banner, 1)
func _rebuild_layout_into_tabs():
	original_scroll.visible = false
	tab_container = TabContainer.new()
	tab_container.name = "SettingsTabs"
	tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var insert_idx = 1
	main_vbox.add_child(tab_container)
	main_vbox.move_child(tab_container, insert_idx)
	tab_gameplay = _create_tab_page("Gameplay")
	tab_display = _create_tab_page("Display")
	tab_audio = _create_tab_page("Audio")
	tab_voice = _create_tab_page("Voice")
	tab_tutorial = _create_tab_page("Tutorial")
	tab_developer = _create_tab_page("Developer")
	tab_ai_log = _create_ai_log_tab_page()
	_move_control(language_label, tab_gameplay)
	_move_control(language_option, tab_gameplay)
	_add_separator(tab_gameplay)
	var gameplay_settings_box = VBoxContainer.new()
	gameplay_settings_box.name = "GameplayExtras"
	gameplay_settings_box.add_theme_constant_override("separation", 10)
	tab_gameplay.add_child(gameplay_settings_box)
	text_speed_label = Label.new()
	text_speed_option = OptionButton.new()
	screen_shake_check = CheckBox.new()
	max_rounds_label = Label.new()
	max_rounds_spinbox = SpinBox.new()
	gameplay_settings_box.add_child(text_speed_label)
	gameplay_settings_box.add_child(text_speed_option)
	gameplay_settings_box.add_child(screen_shake_check)
	gameplay_settings_box.add_child(max_rounds_label)
	gameplay_settings_box.add_child(max_rounds_spinbox)
	_add_separator(tab_gameplay)
	_move_control(touch_controls_checkbox, tab_gameplay)
	_add_separator(tab_gameplay)
	_move_control(ai_settings_button, tab_gameplay)
	_move_control(delete_logs_button, tab_gameplay)
	_move_control(fullscreen_label, tab_display)
	_move_control(fullscreen_option, tab_display)
	_add_separator(tab_display)
	_move_control(resolution_label, tab_display)
	_move_control(resolution_option, tab_display)
	_add_separator(tab_display)
	_move_control(font_size_label, tab_display)
	_move_control(font_size_option, tab_display)
	_add_separator(tab_display)
	_move_control(english_font_label, tab_display)
	_move_control(english_font_option, tab_display)
	_move_control(chinese_font_label, tab_display)
	_move_control(chinese_font_option, tab_display)
	_move_control(mute_check_box, tab_audio)
	_add_separator(tab_audio)
	_ensure_audio_label(master_volume_hbox, "MasterVolumeLabel")
	_move_control(master_volume_hbox, tab_audio)
	_ensure_audio_label(music_volume_hbox, "MusicVolumeLabel")
	_move_control(music_volume_hbox, tab_audio)
	_ensure_audio_label(sfx_volume_hbox, "SFXVolumeLabel")
	_move_control(sfx_volume_hbox, tab_audio)
	_add_separator(tab_audio)
	gloria_voice_check = CheckBox.new()
	gloria_voice_check.name = "GloriaVoiceCheck"
	gloria_voice_check.toggled.connect(_on_gloria_voice_toggled)
	tab_audio.add_child(gloria_voice_check)
	_move_control(voice_description, tab_voice)
	_move_control(voice_availability_label, tab_voice)
	_add_separator(tab_voice)
	_move_control(voice_enabled_check, tab_voice)
	_move_control(voice_options_box, tab_voice)
func _create_tab_page(tab_name: String) -> VBoxContainer:
	var scroll = ScrollContainer.new()
	scroll.name = tab_name + "Scroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vbox = VBoxContainer.new()
	vbox.name = tab_name + "VBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 15)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)
	margin.add_child(vbox)
	tab_container.add_child(scroll)
	return vbox
func _create_ai_log_tab_page() -> VBoxContainer:
	var outer_vbox = VBoxContainer.new()
	outer_vbox.name = "AILogOuterVBox"
	outer_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_vbox.add_theme_constant_override("separation", 4)
	tab_container.add_child(outer_vbox)
	var header_margin = MarginContainer.new()
	header_margin.add_theme_constant_override("margin_top", 8)
	header_margin.add_theme_constant_override("margin_left", 14)
	header_margin.add_theme_constant_override("margin_right", 14)
	header_margin.add_theme_constant_override("margin_bottom", 4)
	header_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_vbox.add_child(header_margin)
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 6)
	header_margin.add_child(header_hbox)
	var title_lbl = Label.new()
	title_lbl.name = "AILogTitle"
	title_lbl.text = _tr_ai("SETTINGS_AI_LOG_TITLE", "AI Call Log")
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title_lbl)
	var log_toggle = Button.new()
	log_toggle.name = "AILogToggleLog"
	log_toggle.text = _tr_ai("SETTINGS_AI_LOG_TOGGLE_LOG", "Log")
	log_toggle.icon = ICON_HISTORY
	log_toggle.expand_icon = true
	log_toggle.toggle_mode = true
	log_toggle.button_pressed = true
	log_toggle.custom_minimum_size = Vector2(82, 32)
	log_toggle.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	log_toggle.pressed.connect(_on_ai_log_toggle_log_pressed)
	header_hbox.add_child(log_toggle)
	var charts_toggle = Button.new()
	charts_toggle.name = "AILogToggleCharts"
	charts_toggle.text = _tr_ai("SETTINGS_AI_LOG_TOGGLE_CHARTS", "Charts")
	charts_toggle.icon = ICON_OPTIONS
	charts_toggle.expand_icon = true
	charts_toggle.toggle_mode = true
	charts_toggle.button_pressed = false
	charts_toggle.custom_minimum_size = Vector2(92, 32)
	charts_toggle.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	charts_toggle.pressed.connect(_on_ai_log_toggle_charts_pressed)
	header_hbox.add_child(charts_toggle)
	var sep = VSeparator.new()
	sep.modulate = Color(1, 1, 1, 0.25)
	sep.custom_minimum_size = Vector2(2, 28)
	header_hbox.add_child(sep)
	var refresh_btn = Button.new()
	refresh_btn.name = "AILogRefreshButton"
	refresh_btn.icon = ICON_REFRESH
	refresh_btn.expand_icon = true
	refresh_btn.tooltip_text = _tr_ai("SETTINGS_AI_LOG_REFRESH_TOOLTIP", "Refresh")
	refresh_btn.custom_minimum_size = Vector2(36, 32)
	refresh_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	refresh_btn.pressed.connect(_on_ai_log_refresh_pressed)
	header_hbox.add_child(refresh_btn)
	var export_btn = Button.new()
	export_btn.name = "AILogExportButton"
	export_btn.icon = ICON_SAVE
	export_btn.expand_icon = true
	export_btn.tooltip_text = _tr_ai("SETTINGS_AI_LOG_EXPORT_JSON_TOOLTIP", "Export log to JSON")
	export_btn.custom_minimum_size = Vector2(36, 32)
	export_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	export_btn.pressed.connect(_on_ai_export_pressed)
	header_hbox.add_child(export_btn)
	var export_csv_btn = Button.new()
	export_csv_btn.name = "AILogExportCsvButton"
	export_csv_btn.text = _tr_ai("SETTINGS_AI_LOG_EXPORT_CSV_SHORT", "CSV")
	export_csv_btn.icon = ICON_SAVE
	export_csv_btn.expand_icon = true
	export_csv_btn.tooltip_text = _tr_ai("SETTINGS_AI_LOG_EXPORT_CSV_TOOLTIP", "Export log and chart data to CSV")
	export_csv_btn.custom_minimum_size = Vector2(72, 32)
	export_csv_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	export_csv_btn.pressed.connect(_on_ai_export_csv_pressed)
	header_hbox.add_child(export_csv_btn)
	var clear_btn = Button.new()
	clear_btn.name = "AILogClearButton"
	clear_btn.icon = ICON_DELETE
	clear_btn.expand_icon = true
	clear_btn.tooltip_text = _tr_ai("SETTINGS_AI_LOG_CLEAR_TOOLTIP", "Clear log")
	clear_btn.custom_minimum_size = Vector2(36, 32)
	clear_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	clear_btn.pressed.connect(_on_ai_log_clear_pressed)
	header_hbox.add_child(clear_btn)
	var log_view = VBoxContainer.new()
	log_view.name = "AILogTableView"
	log_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_view.add_theme_constant_override("separation", 2)
	_ai_log_view_panel = log_view
	outer_vbox.add_child(log_view)
	var col_widths := [170, 90, 160, 70, 80, 80, 75, 90, 100]
	var col_names_en := ["Time", "Provider", "Model", "Status", "In Tok", "Out Tok", "Time(s)", "Mode", "Purpose"]
	var header_panel = PanelContainer.new()
	header_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color(0.12, 0.22, 0.32, 1.0)
	header_style.set_corner_radius_all(4)
	header_style.border_width_bottom = 2
	header_style.border_color = Color(0.3, 0.6, 0.9, 0.6)
	header_panel.add_theme_stylebox_override("panel", header_style)
	var header_margin2 = MarginContainer.new()
	header_margin2.add_theme_constant_override("margin_top", 5)
	header_margin2.add_theme_constant_override("margin_left", 14)
	header_margin2.add_theme_constant_override("margin_right", 14)
	header_margin2.add_theme_constant_override("margin_bottom", 5)
	header_panel.add_child(header_margin2)
	var header_row = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 4)
	header_margin2.add_child(header_row)
	for i in range(col_names_en.size()):
		var lbl = Label.new()
		lbl.text = col_names_en[i]
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0))
		lbl.custom_minimum_size = Vector2(col_widths[i], 0)
		lbl.clip_text = true
		lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
		header_row.add_child(lbl)
	log_view.add_child(header_panel)
	var scroll = ScrollContainer.new()
	scroll.name = "AILogScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_view.add_child(scroll)
	_ai_log_rows_container = VBoxContainer.new()
	_ai_log_rows_container.name = "AILogRows"
	_ai_log_rows_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ai_log_rows_container.add_theme_constant_override("separation", 2)
	scroll.add_child(_ai_log_rows_container)
	var empty_lbl = Label.new()
	empty_lbl.name = "AILogEmptyLabel"
	empty_lbl.text = _tr_ai("SETTINGS_AI_LOG_EMPTY", "No AI calls recorded yet.")
	empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	empty_lbl.add_theme_font_size_override("font_size", 14)
	_ai_log_rows_container.add_child(empty_lbl)
	var analytics_scroll = ScrollContainer.new()
	analytics_scroll.name = "AIAnalyticsScroll"
	analytics_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	analytics_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	analytics_scroll.visible = false
	_ai_analytics_view = analytics_scroll
	outer_vbox.add_child(analytics_scroll)
	_build_analytics_content(analytics_scroll)
	tab_container.tab_changed.connect(_on_ai_log_tab_changed)
	_normalize_ai_log_language_texts(outer_vbox)
	return outer_vbox
func _build_analytics_content(parent_scroll: ScrollContainer) -> void:
	var av = VBoxContainer.new()
	av.name = "AIAnalyticsVBox"
	av.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	av.add_theme_constant_override("separation", 12)
	parent_scroll.add_child(av)
	var am = MarginContainer.new()
	am.add_theme_constant_override("margin_top", 10)
	am.add_theme_constant_override("margin_left", 14)
	am.add_theme_constant_override("margin_right", 14)
	am.add_theme_constant_override("margin_bottom", 14)
	am.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	av.add_child(am)
	var inner = VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 12)
	am.add_child(inner)
	_ai_chart_rows.clear()
	_ai_chart_canvases.clear()
	var controls_row = HBoxContainer.new()
	controls_row.add_theme_constant_override("separation", 8)
	controls_row.custom_minimum_size = Vector2(0, 34)
	inner.add_child(controls_row)
	var controls_title = Label.new()
	controls_title.text = _tr_ai("SETTINGS_AI_LOG_CHART_CONTROLS", "Chart Controls")
	controls_title.add_theme_font_size_override("font_size", 12)
	controls_title.add_theme_color_override("font_color", Color(0.7, 0.88, 1.0))
	controls_row.add_child(controls_title)
	var width_label = Label.new()
	width_label.text = "W"
	width_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	controls_row.add_child(width_label)
	_ai_chart_width_spin = SpinBox.new()
	_ai_chart_width_spin.min_value = 260
	_ai_chart_width_spin.max_value = 1400
	_ai_chart_width_spin.step = 10
	_ai_chart_width_spin.value = _ai_chart_width
	_ai_chart_width_spin.custom_minimum_size = Vector2(96, 0)
	_ai_chart_width_spin.value_changed.connect(_on_ai_chart_size_changed)
	controls_row.add_child(_ai_chart_width_spin)
	var height_label = Label.new()
	height_label.text = "H"
	height_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	controls_row.add_child(height_label)
	_ai_chart_height_spin = SpinBox.new()
	_ai_chart_height_spin.min_value = 140
	_ai_chart_height_spin.max_value = 760
	_ai_chart_height_spin.step = 10
	_ai_chart_height_spin.value = _ai_chart_height
	_ai_chart_height_spin.custom_minimum_size = Vector2(96, 0)
	_ai_chart_height_spin.value_changed.connect(_on_ai_chart_size_changed)
	controls_row.add_child(_ai_chart_height_spin)
	_ai_chart_toggle_button = Button.new()
	_ai_chart_toggle_button.text = _tr_ai("SETTINGS_AI_LOG_HIDE_GRAPHS", "Hide Graphs")
	_ai_chart_toggle_button.toggle_mode = true
	_ai_chart_toggle_button.button_pressed = true
	_ai_chart_toggle_button.custom_minimum_size = Vector2(118, 30)
	_ai_chart_toggle_button.pressed.connect(_on_ai_chart_visibility_toggled)
	controls_row.add_child(_ai_chart_toggle_button)
	var controls_sep = VSeparator.new()
	controls_sep.custom_minimum_size = Vector2(2, 22)
	controls_sep.modulate = Color(1, 1, 1, 0.2)
	controls_row.add_child(controls_sep)
	var export_csv_btn = Button.new()
	export_csv_btn.text = _tr_ai("SETTINGS_AI_LOG_EXPORT_CSV", "Export CSV")
	export_csv_btn.icon = ICON_SAVE
	export_csv_btn.expand_icon = true
	export_csv_btn.custom_minimum_size = Vector2(120, 30)
	export_csv_btn.pressed.connect(_on_ai_export_csv_pressed)
	controls_row.add_child(export_csv_btn)
	var controls_spacer = Control.new()
	controls_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_row.add_child(controls_spacer)
	var kpi_hbox = HBoxContainer.new()
	kpi_hbox.add_theme_constant_override("separation", 8)
	kpi_hbox.custom_minimum_size = Vector2(0, 78)
	inner.add_child(kpi_hbox)
	var kpi_icons := [ICON_INFO, ICON_CHECK, ICON_SYNC, ICON_REFRESH]
	var kpi_titles := [_tr_ai("SETTINGS_AI_LOG_KPI_TOTAL_CALLS", "Total Calls"), _tr_ai("SETTINGS_AI_LOG_KPI_SUCCESS_RATE", "Success Rate"), _tr_ai("SETTINGS_AI_LOG_KPI_TOTAL_TOKENS", "Total Tokens"), _tr_ai("SETTINGS_AI_LOG_KPI_AVG_RESPONSE", "Avg Response")]
	var kpi_defaults := ["0", "0%", "0", "0s"]
	var kpi_accent_colors := [
		Color(0.4, 0.75, 1.0), Color(0.35, 0.92, 0.55),
		Color(1.0, 0.80, 0.30), Color(0.85, 0.60, 1.0)]
	_ai_kpi_labels.clear()
	for i in range(kpi_titles.size()):
		var kpi_panel = PanelContainer.new()
		kpi_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var kpi_style = StyleBoxFlat.new()
		kpi_style.bg_color = Color(0.09, 0.14, 0.22, 1.0)
		kpi_style.set_corner_radius_all(8)
		kpi_style.border_width_bottom = 3
		kpi_style.border_color = kpi_accent_colors[i]
		kpi_panel.add_theme_stylebox_override("panel", kpi_style)
		var kpi_inner = VBoxContainer.new()
		kpi_inner.alignment = BoxContainer.ALIGNMENT_CENTER
		kpi_inner.add_theme_constant_override("separation", 3)
		kpi_panel.add_child(kpi_inner)
		var icon_row = HBoxContainer.new()
		icon_row.alignment = BoxContainer.ALIGNMENT_CENTER
		icon_row.add_theme_constant_override("separation", 4)
		kpi_inner.add_child(icon_row)
		var icon_rect = TextureRect.new()
		icon_rect.texture = kpi_icons[i]
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.custom_minimum_size = Vector2(16, 16)
		icon_rect.modulate = kpi_accent_colors[i]
		icon_row.add_child(icon_rect)
		var kpi_title = Label.new()
		kpi_title.text = kpi_titles[i]
		kpi_title.add_theme_font_size_override("font_size", 10)
		kpi_title.add_theme_color_override("font_color", kpi_accent_colors[i])
		kpi_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kpi_title.autowrap_mode = TextServer.AUTOWRAP_WORD
		icon_row.add_child(kpi_title)
		var kpi_val = Label.new()
		kpi_val.text = kpi_defaults[i]
		kpi_val.add_theme_font_size_override("font_size", 20)
		kpi_val.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
		kpi_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kpi_inner.add_child(kpi_val)
		kpi_hbox.add_child(kpi_panel)
		_ai_kpi_labels.append(kpi_val)
	_add_section_header(inner, ICON_CHECK, _tr_ai("SETTINGS_AI_LOG_HDR_PROVIDER_SUCCESS", "Provider Success Rate"))
	_ai_chart_rows.append(inner.get_child(inner.get_child_count() - 1) as Control)
	var row1 = HBoxContainer.new()
	row1.add_theme_constant_override("separation", 10)
	row1.custom_minimum_size = Vector2(0, _ai_chart_height)
	inner.add_child(row1)
	_ai_chart_rows.append(row1)
	_chart_success_by_provider = _make_chart_canvas(row1, AIChartCanvas.Type.HORIZONTAL_BAR,
		"Success Rate by Provider (%)")
	_chart_mode_pie = _make_chart_canvas(row1, AIChartCanvas.Type.PIE,
		"Call Mode Distribution")
	_add_section_header(inner, ICON_HISTORY, _tr_ai("SETTINGS_AI_LOG_HDR_REQUESTS_TIMELINE", "Requests Timeline (last 24 h)"))
	_ai_chart_rows.append(inner.get_child(inner.get_child_count() - 1) as Control)
	var row2 = HBoxContainer.new()
	row2.custom_minimum_size = Vector2(0, _ai_chart_height)
	inner.add_child(row2)
	_ai_chart_rows.append(row2)
	_chart_hourly_requests = _make_chart_canvas(row2, AIChartCanvas.Type.VERTICAL_BAR,
		"Requests / Hour (last 24 h)")
	_add_section_header(inner, ICON_INFO, _tr_ai("SETTINGS_AI_LOG_HDR_SUCCESS_ERROR", "Success / Error per Hour"))
	_ai_chart_rows.append(inner.get_child(inner.get_child_count() - 1) as Control)
	var row3 = HBoxContainer.new()
	row3.add_theme_constant_override("separation", 10)
	row3.custom_minimum_size = Vector2(0, _ai_chart_height)
	inner.add_child(row3)
	_ai_chart_rows.append(row3)
	_chart_success_per_hour = _make_chart_canvas(row3, AIChartCanvas.Type.LINE,
		"Success Count / Hour (last 24 h)")
	_chart_calls_by_model = _make_chart_canvas(row3, AIChartCanvas.Type.HORIZONTAL_BAR,
		"Calls by Model")
	_add_section_header(inner, ICON_SYNC, _tr_ai("SETTINGS_AI_LOG_HDR_TOKEN_LATENCY", "Token and Latency by Provider"))
	_ai_chart_rows.append(inner.get_child(inner.get_child_count() - 1) as Control)
	var row4 = HBoxContainer.new()
	row4.add_theme_constant_override("separation", 10)
	row4.custom_minimum_size = Vector2(0, _ai_chart_height)
	inner.add_child(row4)
	_ai_chart_rows.append(row4)
	_chart_tokens_by_provider = _make_chart_canvas(row4, AIChartCanvas.Type.HORIZONTAL_BAR,
		"Total Tokens by Provider")
	_chart_response_by_provider = _make_chart_canvas(row4, AIChartCanvas.Type.HORIZONTAL_BAR,
		"Avg Response Time / Provider (s)")
	_add_section_header(inner, ICON_OPTIONS, _tr_ai("SETTINGS_AI_LOG_HDR_TOKEN_BREAKDOWN", "Token Breakdown and Speed"))
	_ai_chart_rows.append(inner.get_child(inner.get_child_count() - 1) as Control)
	var row5 = HBoxContainer.new()
	row5.add_theme_constant_override("separation", 10)
	row5.custom_minimum_size = Vector2(0, _ai_chart_height)
	inner.add_child(row5)
	_ai_chart_rows.append(row5)
	_chart_input_output_tokens = _make_chart_canvas(row5, AIChartCanvas.Type.VERTICAL_BAR,
		"Input vs Output Tokens by Provider")
	_chart_tps_by_provider = _make_chart_canvas(row5, AIChartCanvas.Type.HORIZONTAL_BAR,
		"Avg Tokens / Second by Provider (TPS)")
	_add_section_header(inner, ICON_REFRESH, _tr_ai("SETTINGS_AI_LOG_HDR_TOKEN_TRENDS", "Token Trends (last 24 h)"))
	_ai_chart_rows.append(inner.get_child(inner.get_child_count() - 1) as Control)
	var row6 = HBoxContainer.new()
	row6.custom_minimum_size = Vector2(0, _ai_chart_height)
	inner.add_child(row6)
	_ai_chart_rows.append(row6)
	_chart_hourly_tokens = _make_chart_canvas(row6, AIChartCanvas.Type.LINE,
		"Token Usage / Hour (last 24 h)")
	var row7 = HBoxContainer.new()
	row7.custom_minimum_size = Vector2(0, _ai_chart_height)
	inner.add_child(row7)
	_ai_chart_rows.append(row7)
	_chart_cumulative_tokens = _make_chart_canvas(row7, AIChartCanvas.Type.LINE,
		"Cumulative Total Tokens (session)")
	_apply_ai_chart_layout()
func _add_section_header(parent: Control, icon_tex: Texture2D, text: String) -> void:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.custom_minimum_size = Vector2(0, 24)
	parent.add_child(hbox)
	var icon_rect = TextureRect.new()
	icon_rect.texture = icon_tex
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.custom_minimum_size = Vector2(18, 18)
	icon_rect.modulate = Color(0.55, 0.82, 1.0)
	hbox.add_child(icon_rect)
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.7, 0.88, 1.0))
	hbox.add_child(lbl)
	var sep = HSeparator.new()
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sep.modulate = Color(1, 1, 1, 0.15)
	hbox.add_child(sep)
func _make_chart_canvas(parent: Control, chart_type: int, title: String) -> Control:
	var canvas = AIChartCanvas.new()
	canvas.chart_type = chart_type
	canvas.chart_title = title
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.custom_minimum_size = Vector2(_ai_chart_width, _ai_chart_height)
	parent.add_child(canvas)
	_ai_chart_canvases.append(canvas)
	return canvas
func _on_ai_log_tab_changed(tab_idx: int) -> void:
	if tab_container and tab_idx == tab_container.get_tab_count() - 1:
		_refresh_ai_log_table()
		if _ai_showing_charts:
			_refresh_analytics_view()
func _on_ai_log_toggle_log_pressed() -> void:
	_ai_showing_charts = false
	if _ai_log_view_panel:
		_ai_log_view_panel.visible = true
	if _ai_analytics_view:
		_ai_analytics_view.visible = false
	_refresh_ai_log_table()
func _on_ai_log_toggle_charts_pressed() -> void:
	_ai_showing_charts = true
	if _ai_log_view_panel:
		_ai_log_view_panel.visible = false
	if _ai_analytics_view:
		_ai_analytics_view.visible = true
	_refresh_analytics_view()
func _on_ai_log_refresh_pressed() -> void:
	if _ai_showing_charts:
		_refresh_analytics_view()
	else:
		_refresh_ai_log_table()
func _on_ai_export_pressed() -> void:
	var ai_manager = ServiceLocator.get_ai_manager() if ServiceLocator else null
	var log_entries: Array = []
	if ai_manager and ai_manager.has_method("get_call_log"):
		log_entries = ai_manager.get_call_log()
	var metrics: Dictionary = {}
	if ai_manager and ai_manager.has_method("get_ai_metrics"):
		metrics = ai_manager.get_ai_metrics()
	var ts := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var path := "user://ai_call_log_%s.json" % ts
	var export_data := {
		"exported_at": Time.get_datetime_string_from_system(),
		"summary": metrics,
		"call_log": log_entries,
	}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(export_data, "\t"))
		file.close()
		var abs_path := ProjectSettings.globalize_path(path)
		var notifier = ServiceLocator.get_notification_system() if ServiceLocator else null
		if notifier:
			var msg = _tr_ai("SETTINGS_AI_LOG_EXPORT_JSON_SUCCESS", "Exported %d records to:\n%s") % [log_entries.size(), abs_path]
			notifier.show_success(msg)
	else:
		var notifier = ServiceLocator.get_notification_system() if ServiceLocator else null
		if notifier:
			var msg = _tr_ai("SETTINGS_AI_LOG_EXPORT_JSON_FAILED", "Export failed: could not write file.")
			notifier.show_warning(msg)
func _on_ai_export_csv_pressed() -> void:
	var ai_manager = ServiceLocator.get_ai_manager() if ServiceLocator else null
	var log_entries: Array = []
	if ai_manager and ai_manager.has_method("get_call_log"):
		log_entries = ai_manager.get_call_log()
	var analytics := _compute_ai_analytics(log_entries)
	var ts := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var path := "user://ai_usage_charts_%s.csv" % ts
	var lines: PackedStringArray = []
	lines.append("section,timestamp,provider,model,status,input_tokens,output_tokens,response_time_sec,mode,purpose,error")
	for entry in log_entries:
		var status_text := "ERR"
		if bool(entry.get("success", false)):
			status_text = str(int(entry.get("status_code", 200)))
		elif str(entry.get("mode", "")) in ["mock", "mock_fallback"]:
			status_text = "MOCK"
		lines.append(_csv_row([
			"call_log",
			str(entry.get("timestamp", "")),
			str(entry.get("provider", "")),
			str(entry.get("model", "")),
			status_text,
			str(int(entry.get("input_tokens", 0))),
			str(int(entry.get("output_tokens", 0))),
			"%.3f" % float(entry.get("response_time_sec", 0.0)),
			str(entry.get("mode", "")),
			str(entry.get("purpose", "")),
			str(entry.get("error", "")),
		]))
	lines.append("")
	lines.append("section,metric,label,value")
	_append_metric_series(lines, "provider_success_rate", analytics.get("provider_labels", []), analytics.get("provider_success_rates", []))
	_append_metric_series(lines, "provider_total_tokens", analytics.get("provider_labels", []), analytics.get("provider_tokens", []))
	_append_metric_series(lines, "provider_avg_response_seconds", analytics.get("provider_labels", []), analytics.get("provider_response_times", []))
	_append_metric_series(lines, "provider_input_tokens", analytics.get("provider_labels", []), analytics.get("provider_input_tokens", []))
	_append_metric_series(lines, "provider_output_tokens", analytics.get("provider_labels", []), analytics.get("provider_output_tokens", []))
	_append_metric_series(lines, "provider_tps", analytics.get("provider_labels", []), analytics.get("provider_tps", []))
	_append_metric_series(lines, "mode_distribution", analytics.get("mode_labels", []), analytics.get("mode_counts", []))
	_append_metric_series(lines, "model_calls", analytics.get("model_labels", []), analytics.get("model_counts", []))
	_append_metric_series(lines, "hourly_calls", analytics.get("hourly_labels", []), analytics.get("hourly_calls", []))
	_append_metric_series(lines, "hourly_tokens", analytics.get("hourly_labels", []), analytics.get("hourly_tokens", []))
	_append_metric_series(lines, "hourly_successes", analytics.get("hourly_labels", []), analytics.get("hourly_successes", []))
	_append_metric_series(lines, "cumulative_tokens", analytics.get("cumulative_labels", []), analytics.get("cumulative_tokens", []))
	lines.append(_csv_row(["summary", "total_calls", "", str(int(analytics.get("total", 0)))]))
	lines.append(_csv_row(["summary", "success_rate_percent", "", "%.2f" % float(analytics.get("success_rate", 0.0))]))
	lines.append(_csv_row(["summary", "total_tokens", "", str(int(analytics.get("total_tokens", 0)))]))
	lines.append(_csv_row(["summary", "avg_response_seconds", "", "%.3f" % float(analytics.get("avg_response_time", 0.0))]))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string("\n".join(lines))
		file.close()
		var abs_path := ProjectSettings.globalize_path(path)
		var notifier = ServiceLocator.get_notification_system() if ServiceLocator else null
		if notifier:
			notifier.show_success(_tr_ai("SETTINGS_AI_LOG_EXPORT_CSV_SUCCESS", "CSV exported:\n%s") % abs_path)
	else:
		var notifier = ServiceLocator.get_notification_system() if ServiceLocator else null
		if notifier:
			notifier.show_warning(_tr_ai("SETTINGS_AI_LOG_EXPORT_CSV_FAILED", "CSV export failed: could not write file."))
func _append_metric_series(lines: PackedStringArray, metric: String, labels: Array, values: Array) -> void:
	var count := mini(labels.size(), values.size())
	for idx in range(count):
		lines.append(_csv_row(["chart_metric", metric, str(labels[idx]), str(values[idx])]))
func _csv_row(cells: Array) -> String:
	var escaped: PackedStringArray = []
	for cell in cells:
		escaped.append(_csv_escape(str(cell)))
	return ",".join(escaped)
func _csv_escape(value: String) -> String:
	var v := value.replace("\"", "\"\"")
	if v.contains(",") or v.contains("\n") or v.contains("\r") or v.contains("\""):
		return "\"" + v + "\""
	return v
func _on_ai_chart_size_changed(_value: float) -> void:
	if is_instance_valid(_ai_chart_width_spin):
		_ai_chart_width = maxf(260.0, float(_ai_chart_width_spin.value))
	if is_instance_valid(_ai_chart_height_spin):
		_ai_chart_height = maxf(140.0, float(_ai_chart_height_spin.value))
	_apply_ai_chart_layout()
func _on_ai_chart_visibility_toggled() -> void:
	_ai_charts_open = _ai_chart_toggle_button.button_pressed if is_instance_valid(_ai_chart_toggle_button) else true
	_apply_ai_chart_layout()
func _apply_ai_chart_layout() -> void:
	for row in _ai_chart_rows:
		if is_instance_valid(row):
			row.visible = _ai_charts_open
			if row is HBoxContainer:
				row.custom_minimum_size = Vector2(0, _ai_chart_height)
	for canvas in _ai_chart_canvases:
		if is_instance_valid(canvas):
			canvas.visible = _ai_charts_open
			canvas.custom_minimum_size = Vector2(_ai_chart_width, _ai_chart_height)
	if is_instance_valid(_ai_chart_toggle_button):
		_ai_chart_toggle_button.text = _tr_ai("SETTINGS_AI_LOG_HIDE_GRAPHS", "Hide Graphs") if _ai_charts_open else _tr_ai("SETTINGS_AI_LOG_SHOW_GRAPHS", "Show Graphs")
func _on_ai_log_clear_pressed() -> void:
	var ai_manager = ServiceLocator.get_ai_manager() if ServiceLocator else null
	if ai_manager and ai_manager.has_method("clear_call_log"):
		ai_manager.clear_call_log()
	if _ai_showing_charts:
		_refresh_analytics_view()
	else:
		_refresh_ai_log_table()
func _refresh_analytics_view() -> void:
	var ai_manager = ServiceLocator.get_ai_manager() if ServiceLocator else null
	var log_entries: Array = []
	if ai_manager and ai_manager.has_method("get_call_log"):
		log_entries = ai_manager.get_call_log()
	var a := _compute_ai_analytics(log_entries)
	var kpi_vals := [
		str(a.get("total", 0)),
		"%.1f%%" % float(a.get("success_rate", 0.0)),
		_format_token_count(int(a.get("total_tokens", 0))),
		"%.2fs" % float(a.get("avg_response_time", 0.0)),
	]
	for i in range(min(_ai_kpi_labels.size(), kpi_vals.size())):
		if is_instance_valid(_ai_kpi_labels[i]):
			(_ai_kpi_labels[i] as Label).text = kpi_vals[i]
	if is_instance_valid(_chart_success_by_provider):
		(_chart_success_by_provider as AIChartCanvas).setup(
			AIChartCanvas.Type.HORIZONTAL_BAR,
			"Success Rate by Provider (%)",
			a.get("provider_labels", []),
			a.get("provider_success_rates", []),
			[Color(0.3, 0.9, 0.4), Color(0.35, 0.7, 1.0), Color(1.0, 0.7, 0.3),
			 Color(0.9, 0.5, 1.0), Color(0.4, 0.9, 0.9)],
		)
	if is_instance_valid(_chart_mode_pie):
		var mode_colors: Array[Color] = [
			Color(0.3, 0.85, 0.4), Color(0.8, 0.9, 0.3),
			Color(1.0, 0.5, 0.3), Color(0.65, 0.4, 1.0),
		]
		(_chart_mode_pie as AIChartCanvas).setup(
			AIChartCanvas.Type.PIE, "Call Mode Distribution",
			a.get("mode_labels", []), a.get("mode_counts", []), mode_colors,
		)
	if is_instance_valid(_chart_hourly_requests):
		(_chart_hourly_requests as AIChartCanvas).setup(
			AIChartCanvas.Type.VERTICAL_BAR, "Requests / Hour (last 24 h)",
			a.get("hourly_labels", []), a.get("hourly_calls", []),
			[Color(0.35, 0.7, 1.0)],
		)
	if is_instance_valid(_chart_success_per_hour):
		(_chart_success_per_hour as AIChartCanvas).setup(
			AIChartCanvas.Type.LINE, "Success Count / Hour (last 24 h)",
			a.get("hourly_labels", []), a.get("hourly_successes", []),
			[Color(0.3, 0.9, 0.4)],
		)
	if is_instance_valid(_chart_calls_by_model):
		(_chart_calls_by_model as AIChartCanvas).setup(
			AIChartCanvas.Type.HORIZONTAL_BAR, "Calls by Model",
			a.get("model_labels", []), a.get("model_counts", []),
			[Color(0.6, 0.82, 1.0)],
		)
	if is_instance_valid(_chart_tokens_by_provider):
		(_chart_tokens_by_provider as AIChartCanvas).setup(
			AIChartCanvas.Type.HORIZONTAL_BAR, "Total Tokens by Provider",
			a.get("provider_labels", []), a.get("provider_tokens", []),
			[Color(0.55, 0.82, 1.0)],
		)
	if is_instance_valid(_chart_response_by_provider):
		(_chart_response_by_provider as AIChartCanvas).setup(
			AIChartCanvas.Type.HORIZONTAL_BAR, "Avg Response Time / Provider (s)",
			a.get("provider_labels", []), a.get("provider_response_times", []),
			[Color(1.0, 0.72, 0.28)],
		)
	if is_instance_valid(_chart_input_output_tokens):
		var stacked_labels: Array = a.get("provider_labels", []).duplicate()
		var stacked_vals: Array = []
		var in_vals: Array = a.get("provider_input_tokens", [])
		var out_vals: Array = a.get("provider_output_tokens", [])
		for idx in range(stacked_labels.size()):
			stacked_labels.insert(idx * 2 + 1, stacked_labels[idx * 2] + " out")
			stacked_labels[idx * 2] = stacked_labels[idx * 2] + " in"
		for idx in range(in_vals.size()):
			stacked_vals.append(float(in_vals[idx]))
			stacked_vals.append(float(out_vals[idx]))
		(_chart_input_output_tokens as AIChartCanvas).setup(
			AIChartCanvas.Type.VERTICAL_BAR, "Input vs Output Tokens by Provider",
			stacked_labels, stacked_vals,
			[Color(0.35, 0.70, 1.0), Color(0.35, 0.95, 0.60)],
		)
	if is_instance_valid(_chart_tps_by_provider):
		(_chart_tps_by_provider as AIChartCanvas).setup(
			AIChartCanvas.Type.HORIZONTAL_BAR, "Avg TPS by Provider",
			a.get("provider_labels", []), a.get("provider_tps", []),
			[Color(0.78, 0.48, 1.0)],
		)
	if is_instance_valid(_chart_hourly_tokens):
		(_chart_hourly_tokens as AIChartCanvas).setup(
			AIChartCanvas.Type.LINE, "Token Usage / Hour (last 24 h)",
			a.get("hourly_labels", []), a.get("hourly_tokens", []), [],
		)
	if is_instance_valid(_chart_cumulative_tokens):
		(_chart_cumulative_tokens as AIChartCanvas).setup(
			AIChartCanvas.Type.LINE, "Cumulative Total Tokens (session, newest last)",
			a.get("cumulative_labels", []), a.get("cumulative_tokens", []),
			[Color(1.0, 0.82, 0.35)],
		)
func _compute_ai_analytics(log_entries: Array) -> Dictionary:
	var total := log_entries.size()
	var total_success := 0
	var total_tokens := 0
	var total_time := 0.0
	var by_provider: Dictionary = {}
	var by_mode: Dictionary = {}
	var by_model: Dictionary = {}
	var hourly: Dictionary = {}
	var now_unix := Time.get_unix_time_from_system()
	var cumulative_running := 0
	var cumulative_labels: Array = []
	var cumulative_tokens: Array = []
	for idx in range(log_entries.size()):
		var entry: Dictionary = log_entries[idx]
		var success := bool(entry.get("success", false))
		var in_tok := int(entry.get("input_tokens", 0))
		var out_tok := int(entry.get("output_tokens", 0))
		var tokens := in_tok + out_tok
		var rtime := float(entry.get("response_time_sec", 0.0))
		var provider := str(entry.get("provider", "UNKNOWN"))
		var model := str(entry.get("model", "UNKNOWN"))
		var mode := str(entry.get("mode", "unknown"))
		var ts_str := str(entry.get("timestamp", "")).replace("T", " ")
		if success:
			total_success += 1
		total_tokens += tokens
		total_time += rtime
		if not by_provider.has(provider):
			by_provider[provider] = {
				"calls": 0, "success": 0, "tokens": 0,
				"input_tokens": 0, "output_tokens": 0,
				"response_time": 0.0, "output_tokens_for_tps": 0, "tps_time": 0.0,
			}
		by_provider[provider]["calls"] = int(by_provider[provider]["calls"]) + 1
		if success:
			by_provider[provider]["success"] = int(by_provider[provider]["success"]) + 1
		by_provider[provider]["tokens"] = int(by_provider[provider]["tokens"]) + tokens
		by_provider[provider]["input_tokens"] = int(by_provider[provider]["input_tokens"]) + in_tok
		by_provider[provider]["output_tokens"] = int(by_provider[provider]["output_tokens"]) + out_tok
		by_provider[provider]["response_time"] = float(by_provider[provider]["response_time"]) + rtime
		if rtime > 0.0 and out_tok > 0:
			by_provider[provider]["output_tokens_for_tps"] = int(by_provider[provider]["output_tokens_for_tps"]) + out_tok
			by_provider[provider]["tps_time"] = float(by_provider[provider]["tps_time"]) + rtime
		by_mode[mode] = int(by_mode.get(mode, 0)) + 1
		by_model[model] = int(by_model.get(model, 0)) + 1
		if ts_str.length() >= 10:
			var entry_unix := Time.get_unix_time_from_datetime_string(ts_str)
			if entry_unix > 0:
				var hours_ago := (now_unix - entry_unix) / 3600.0
				if hours_ago >= 0.0 and hours_ago < 24.0:
					var bucket := int(hours_ago)
					if not hourly.has(bucket):
						hourly[bucket] = {"calls": 0, "tokens": 0, "successes": 0}
					hourly[bucket]["calls"] = int(hourly[bucket]["calls"]) + 1
					hourly[bucket]["tokens"] = int(hourly[bucket]["tokens"]) + tokens
					if success:
						hourly[bucket]["successes"] = int(hourly[bucket]["successes"]) + 1
		cumulative_running += tokens
		cumulative_labels.append(str(idx + 1))
		cumulative_tokens.append(float(cumulative_running))
	var provider_labels: Array = []
	var provider_success_rates: Array = []
	var provider_tokens: Array = []
	var provider_input_tokens: Array = []
	var provider_output_tokens: Array = []
	var provider_response_times: Array = []
	var provider_tps: Array = []
	for prov in by_provider.keys():
		var p: Dictionary = by_provider[prov]
		var calls := int(p.get("calls", 0))
		provider_labels.append(prov)
		provider_success_rates.append(float(p.get("success", 0)) / float(max(1, calls)) * 100.0)
		provider_tokens.append(float(p.get("tokens", 0)))
		provider_input_tokens.append(float(p.get("input_tokens", 0)))
		provider_output_tokens.append(float(p.get("output_tokens", 0)))
		provider_response_times.append(float(p.get("response_time", 0.0)) / float(max(1, calls)))
		var tps_out := int(p.get("output_tokens_for_tps", 0))
		var tps_t := float(p.get("tps_time", 0.0))
		provider_tps.append(float(tps_out) / max(0.001, tps_t))
	var hourly_labels: Array = []
	var hourly_calls: Array = []
	var hourly_tokens: Array = []
	var hourly_successes: Array = []
	for h in range(23, -1, -1):
		var d: Dictionary = hourly.get(h, {"calls": 0, "tokens": 0, "successes": 0})
		hourly_labels.insert(0, "%dh" % h if h > 0 else "now")
		hourly_calls.insert(0, float(d.get("calls", 0)))
		hourly_tokens.insert(0, float(d.get("tokens", 0)))
		hourly_successes.insert(0, float(d.get("successes", 0)))
	var mode_labels: Array = []
	var mode_counts: Array = []
	for m in by_mode.keys():
		mode_labels.append(m)
		mode_counts.append(float(by_mode[m]))
	var model_labels: Array = []
	var model_counts: Array = []
	for mdl in by_model.keys():
		model_labels.append(mdl)
		model_counts.append(float(by_model[mdl]))
	return {
		"total": total,
		"total_success": total_success,
		"success_rate": float(total_success) / float(max(1, total)) * 100.0,
		"total_tokens": total_tokens,
		"avg_response_time": total_time / float(max(1, total)),
		"provider_labels": provider_labels,
		"provider_success_rates": provider_success_rates,
		"provider_tokens": provider_tokens,
		"provider_input_tokens": provider_input_tokens,
		"provider_output_tokens": provider_output_tokens,
		"provider_response_times": provider_response_times,
		"provider_tps": provider_tps,
		"hourly_labels": hourly_labels,
		"hourly_calls": hourly_calls,
		"hourly_tokens": hourly_tokens,
		"hourly_successes": hourly_successes,
		"mode_labels": mode_labels,
		"mode_counts": mode_counts,
		"model_labels": model_labels,
		"model_counts": model_counts,
		"cumulative_labels": cumulative_labels,
		"cumulative_tokens": cumulative_tokens,
	}
func _format_token_count(n: int) -> String:
	if n >= 1_000_000:
		return "%.1fM" % (float(n) / 1_000_000.0)
	if n >= 1_000:
		return "%.1fK" % (float(n) / 1_000.0)
	return str(n)
func _refresh_ai_log_table() -> void:
	if not _ai_log_rows_container:
		return
	for child in _ai_log_rows_container.get_children():
		child.queue_free()
	var ai_manager = ServiceLocator.get_ai_manager() if ServiceLocator else null
	var log_entries: Array = []
	if ai_manager and ai_manager.has_method("get_call_log"):
		log_entries = ai_manager.get_call_log()
	if log_entries.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.name = "AILogEmptyLabel"
		empty_lbl.text = _tr_ai("SETTINGS_AI_LOG_EMPTY", "No AI calls recorded yet.")
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		empty_lbl.add_theme_font_size_override("font_size", 14)
		_ai_log_rows_container.add_child(empty_lbl)
		return
	var col_widths := [170, 90, 160, 70, 80, 80, 75, 90, 100]
	var reversed_entries: Array = log_entries.duplicate()
	reversed_entries.reverse()
	for row_idx in range(reversed_entries.size()):
		var entry: Dictionary = reversed_entries[row_idx]
		var row_panel = PanelContainer.new()
		row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row_style = StyleBoxFlat.new()
		var success: bool = bool(entry.get("success", false))
		var mode: String = str(entry.get("mode", ""))
		if not success:
			row_style.bg_color = Color(0.35, 0.12, 0.12, 0.85) if row_idx % 2 == 0 else Color(0.3, 0.1, 0.1, 0.85)
		elif mode == "mock" or mode == "mock_fallback":
			row_style.bg_color = Color(0.18, 0.22, 0.12, 0.85) if row_idx % 2 == 0 else Color(0.15, 0.19, 0.10, 0.85)
		else:
			row_style.bg_color = Color(0.12, 0.18, 0.12, 0.85) if row_idx % 2 == 0 else Color(0.10, 0.15, 0.10, 0.85)
		row_panel.add_theme_stylebox_override("panel", row_style)
		var row_margin = MarginContainer.new()
		row_margin.add_theme_constant_override("margin_top", 4)
		row_margin.add_theme_constant_override("margin_left", 14)
		row_margin.add_theme_constant_override("margin_right", 14)
		row_margin.add_theme_constant_override("margin_bottom", 4)
		row_panel.add_child(row_margin)
		var row_hbox = HBoxContainer.new()
		row_hbox.add_theme_constant_override("separation", 4)
		row_margin.add_child(row_hbox)
		var status_code: int = int(entry.get("status_code", 0))
		var status_text: String = ""
		var status_color := Color(0.9, 0.9, 0.9)
		if mode == "mock" or mode == "mock_fallback":
			status_text = "MOCK"
			status_color = Color(0.8, 0.9, 0.4)
		elif not success:
			status_text = str(status_code) if status_code > 0 else "ERR"
			status_color = Color(1.0, 0.4, 0.4)
		else:
			status_text = str(status_code) if status_code > 0 else "200"
			status_color = Color(0.4, 1.0, 0.4)
		var timestamp_str: String = str(entry.get("timestamp", ""))
		if timestamp_str.length() > 19:
			timestamp_str = timestamp_str.substr(0, 19)
		timestamp_str = timestamp_str.replace("T", " ")
		var cell_values: Array = [
			timestamp_str,
			str(entry.get("provider", "")),
			str(entry.get("model", "")),
			status_text,
			str(int(entry.get("input_tokens", 0))),
			str(int(entry.get("output_tokens", 0))),
			"%.2f" % float(entry.get("response_time_sec", 0.0)),
			str(entry.get("mode", "")),
			str(entry.get("purpose", "")),
		]
		var cell_colors: Array = [
			Color(0.85, 0.85, 0.85),
			Color(0.7, 0.85, 1.0),
			Color(0.85, 0.85, 1.0),
			status_color,
			Color(0.8, 1.0, 0.8),
			Color(0.8, 1.0, 0.8),
			Color(1.0, 0.9, 0.6),
			Color(0.9, 0.8, 1.0),
			Color(0.85, 0.85, 0.85),
		]
		for i in range(cell_values.size()):
			var cell_lbl = Label.new()
			cell_lbl.text = str(cell_values[i])
			cell_lbl.add_theme_font_size_override("font_size", 11)
			cell_lbl.add_theme_color_override("font_color", cell_colors[i])
			cell_lbl.custom_minimum_size = Vector2(col_widths[i], 0)
			cell_lbl.clip_text = true
			cell_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
			row_hbox.add_child(cell_lbl)
		if not success:
			var err_str: String = str(entry.get("error", ""))
			if not err_str.is_empty():
				row_panel.tooltip_text = "Error: " + err_str
		_ai_log_rows_container.add_child(row_panel)
func _move_control(node: Control, new_parent: Control):
	if node and node.get_parent():
		node.get_parent().remove_child(node)
		new_parent.add_child(node)
		node.visible = true
func _add_separator(parent: Control):
	var sep = HSeparator.new()
	sep.modulate = Color(1, 1, 1, 0.3)
	parent.add_child(sep)
func _initialize_new_controls():
	var game_state := _get_game_state()
	text_speed_option.add_item("Instant", 0)
	text_speed_option.add_item("Fast", 1)
	text_speed_option.add_item("Normal", 2)
	text_speed_option.add_item("Slow", 3)
	text_speed_option.item_selected.connect(_on_text_speed_selected)
	if text_speed == 0.0: text_speed_option.select(0)
	elif text_speed == 2.0: text_speed_option.select(1)
	elif text_speed == 1.0: text_speed_option.select(2)
	elif text_speed == 0.5: text_speed_option.select(3)
	else: text_speed_option.select(2)
	screen_shake_check.toggled.connect(_on_screen_shake_toggled)
	screen_shake_check.button_pressed = screen_shake_enabled
	max_rounds_spinbox.min_value = 0
	max_rounds_spinbox.max_value = 30
	max_rounds_spinbox.step = 1
	if game_state and game_state.settings.has("max_rounds_per_mission"):
		max_rounds_per_mission = int(game_state.settings["max_rounds_per_mission"])
	max_rounds_spinbox.value = max_rounds_per_mission
	max_rounds_spinbox.value_changed.connect(_on_max_rounds_changed)
	force_mission_complete_check = CheckBox.new()
	tab_developer.add_child(force_mission_complete_check)
	force_mission_complete_check.toggled.connect(_on_force_mission_complete_toggled)
	if game_state:
		force_mission_complete_check.button_pressed = game_state.debug_force_mission_complete
	var gloria_hbox = HBoxContainer.new()
	gloria_hbox.add_theme_constant_override("separation", 10)
	force_gloria_button = Button.new()
	force_gloria_button.text = "Queue Gloria (Next Turn)"
	force_gloria_button.custom_minimum_size = Vector2(250, 40)
	force_gloria_button.focus_mode = Control.FOCUS_NONE
	force_gloria_button.pressed.connect(_on_force_gloria_pressed)
	gloria_hbox.add_child(force_gloria_button)
	force_gloria_status_label = Label.new()
	force_gloria_status_label.text = ""
	force_gloria_status_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	gloria_hbox.add_child(force_gloria_status_label)
	tab_developer.add_child(gloria_hbox)
	var trolley_hbox = HBoxContainer.new()
	trolley_hbox.add_theme_constant_override("separation", 10)
	force_trolley_button = Button.new()
	force_trolley_button.text = "Force Trolley Problem Now"
	force_trolley_button.custom_minimum_size = Vector2(250, 40)
	force_trolley_button.focus_mode = Control.FOCUS_NONE
	force_trolley_button.pressed.connect(_on_force_trolley_pressed)
	trolley_hbox.add_child(force_trolley_button)
	force_trolley_status_label = Label.new()
	force_trolley_status_label.text = ""
	force_trolley_status_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	trolley_hbox.add_child(force_trolley_status_label)
	tab_developer.add_child(trolley_hbox)
	force_honeymoon_check = CheckBox.new()
	force_honeymoon_check.text = "Force Honeymoon Phase"
	tab_developer.add_child(force_honeymoon_check)
	force_honeymoon_check.toggled.connect(_on_force_honeymoon_toggled)
	if game_state:
		force_honeymoon_check.button_pressed = game_state.is_honeymoon_phase
	_add_separator(tab_developer)
	var reality_hbox = HBoxContainer.new()
	reality_hbox.add_theme_constant_override("separation", 10)
	reality_score_label = Label.new()
	reality_score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reality_hbox.add_child(reality_score_label)
	reality_score_spinbox = SpinBox.new()
	reality_score_spinbox.custom_minimum_size = Vector2(100, 0)
	reality_score_spinbox.min_value = 0
	reality_score_spinbox.max_value = 100
	reality_score_spinbox.step = 1
	if game_state:
		reality_score_spinbox.value = game_state.reality_score
	reality_hbox.add_child(reality_score_spinbox)
	tab_developer.add_child(reality_hbox)
	var positive_hbox = HBoxContainer.new()
	positive_hbox.add_theme_constant_override("separation", 10)
	positive_energy_label = Label.new()
	positive_energy_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	positive_hbox.add_child(positive_energy_label)
	positive_energy_spinbox = SpinBox.new()
	positive_energy_spinbox.custom_minimum_size = Vector2(100, 0)
	positive_energy_spinbox.min_value = 0
	positive_energy_spinbox.max_value = 100
	positive_energy_spinbox.step = 1
	if game_state:
		positive_energy_spinbox.value = game_state.positive_energy
	positive_hbox.add_child(positive_energy_spinbox)
	tab_developer.add_child(positive_hbox)
	var entropy_hbox = HBoxContainer.new()
	entropy_hbox.add_theme_constant_override("separation", 10)
	entropy_level_label = Label.new()
	entropy_level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entropy_hbox.add_child(entropy_level_label)
	entropy_level_spinbox = SpinBox.new()
	entropy_level_spinbox.custom_minimum_size = Vector2(100, 0)
	entropy_level_spinbox.min_value = 0
	entropy_level_spinbox.max_value = 100
	entropy_level_spinbox.step = 1
	if game_state:
		entropy_level_spinbox.value = game_state.entropy_level
	entropy_hbox.add_child(entropy_level_spinbox)
	tab_developer.add_child(entropy_hbox)
	var honeymoon_hbox = HBoxContainer.new()
	honeymoon_hbox.add_theme_constant_override("separation", 10)
	honeymoon_charges_label = Label.new()
	honeymoon_charges_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	honeymoon_hbox.add_child(honeymoon_charges_label)
	honeymoon_charges_spinbox = SpinBox.new()
	honeymoon_charges_spinbox.custom_minimum_size = Vector2(100, 0)
	honeymoon_charges_spinbox.min_value = 0
	honeymoon_charges_spinbox.max_value = 10
	honeymoon_charges_spinbox.step = 1
	if game_state:
		honeymoon_charges_spinbox.value = game_state.honeymoon_charges
	honeymoon_hbox.add_child(honeymoon_charges_spinbox)
	tab_developer.add_child(honeymoon_hbox)
	var mission_turn_hbox = HBoxContainer.new()
	mission_turn_hbox.add_theme_constant_override("separation", 10)
	mission_turn_label = Label.new()
	mission_turn_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mission_turn_hbox.add_child(mission_turn_label)
	mission_turn_spinbox = SpinBox.new()
	mission_turn_spinbox.custom_minimum_size = Vector2(100, 0)
	mission_turn_spinbox.min_value = 0
	mission_turn_spinbox.max_value = 100
	mission_turn_spinbox.step = 1
	if game_state:
		mission_turn_spinbox.value = game_state.mission_turn_count
	mission_turn_hbox.add_child(mission_turn_spinbox)
	tab_developer.add_child(mission_turn_hbox)
	reality_score_spinbox.value_changed.connect(_on_reality_score_changed)
	positive_energy_spinbox.value_changed.connect(_on_positive_energy_changed)
	entropy_level_spinbox.value_changed.connect(_on_entropy_level_changed)
	honeymoon_charges_spinbox.value_changed.connect(_on_honeymoon_charges_changed)
	mission_turn_spinbox.value_changed.connect(_on_mission_turn_changed)
	_add_separator(tab_developer)
	var quick_actions_label = Label.new()
	quick_actions_label.name = "QuickActionsLabel"
	quick_actions_label.add_theme_font_size_override("font_size", 20)
	quick_actions_label.add_theme_color_override("font_color", Color(1, 0.8, 0.4))
	tab_developer.add_child(quick_actions_label)
	var quick_actions_grid = GridContainer.new()
	quick_actions_grid.columns = 2
	quick_actions_grid.add_theme_constant_override("h_separation", 10)
	quick_actions_grid.add_theme_constant_override("v_separation", 10)
	tab_developer.add_child(quick_actions_grid)
	max_stats_button = Button.new()
	max_stats_button.custom_minimum_size = Vector2(200, 40)
	max_stats_button.pressed.connect(_on_max_stats_pressed)
	quick_actions_grid.add_child(max_stats_button)
	reset_stats_button = Button.new()
	reset_stats_button.custom_minimum_size = Vector2(200, 40)
	reset_stats_button.pressed.connect(_on_reset_stats_pressed)
	quick_actions_grid.add_child(reset_stats_button)
	clear_debuffs_button = Button.new()
	clear_debuffs_button.custom_minimum_size = Vector2(200, 40)
	clear_debuffs_button.pressed.connect(_on_clear_debuffs_pressed)
	quick_actions_grid.add_child(clear_debuffs_button)
	add_honeymoon_button = Button.new()
	add_honeymoon_button.custom_minimum_size = Vector2(200, 40)
	add_honeymoon_button.pressed.connect(_on_add_honeymoon_pressed)
	quick_actions_grid.add_child(add_honeymoon_button)
	_add_separator(tab_developer)
	var toggles_label = Label.new()
	toggles_label.name = "TogglesLabel"
	toggles_label.add_theme_font_size_override("font_size", 20)
	toggles_label.add_theme_color_override("font_color", Color(1, 0.8, 0.4))
	tab_developer.add_child(toggles_label)
	autosave_toggle = CheckBox.new()
	if game_state:
		autosave_toggle.set_pressed_no_signal(game_state.autosave_enabled)
	autosave_toggle.toggled.connect(_on_autosave_toggled)
	tab_developer.add_child(autosave_toggle)
	infinite_resources_toggle = CheckBox.new()
	if game_state:
		infinite_resources_toggle.set_pressed_no_signal(game_state.get_metadata("debug_infinite_resources", false))
	infinite_resources_toggle.toggled.connect(_on_infinite_resources_toggled)
	tab_developer.add_child(infinite_resources_toggle)
	skip_dialogue_toggle = CheckBox.new()
	if game_state:
		skip_dialogue_toggle.set_pressed_no_signal(game_state.settings.get("auto_advance_enabled", false))
	skip_dialogue_toggle.toggled.connect(_on_skip_dialogue_toggled)
	tab_developer.add_child(skip_dialogue_toggle)
	god_mode_toggle = CheckBox.new()
	if game_state:
		god_mode_toggle.set_pressed_no_signal(game_state.get_metadata("debug_god_mode", false))
	god_mode_toggle.toggled.connect(_on_god_mode_toggled)
	tab_developer.add_child(god_mode_toggle)
	_add_separator(tab_developer)
	var fsm_challenge_label = Label.new()
	fsm_challenge_label.text = "FSM Challenge Debug"
	fsm_challenge_label.add_theme_font_size_override("font_size", 18)
	tab_developer.add_child(fsm_challenge_label)
	var fsm_status_label = Label.new()
	fsm_status_label.name = "FSMStatusLabel"
	_update_fsm_status_label(fsm_status_label)
	tab_developer.add_child(fsm_status_label)
	var fsm_img_row = HBoxContainer.new()
	fsm_img_row.name = "FSMImageRow"
	fsm_img_row.alignment = BoxContainer.ALIGNMENT_CENTER
	fsm_img_row.add_theme_constant_override("separation", 18)
	fsm_img_row.custom_minimum_size = Vector2(0, 140)
	var _fsm_img_data := [
		{"tex": FSM_IMG_GUIDE,   "caption": _tr("FSM_IMG_CAPTION_GUIDE"),          "tint": Color(0.85, 0.95, 1.0, 1.0)},
		{"tex": FSM_IMG_TEACHER, "caption": "Teacher Chan",                         "tint": Color(1.0, 0.95, 0.75, 1.0)},
		{"tex": FSM_IMG_GLORIA,  "caption": _tr("FSM_IMG_CAPTION_GLORIA_NEUTRAL"), "tint": Color(0.85, 1.0, 0.88, 1.0)},
	]
	for img_entry in _fsm_img_data:
		var col = VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 4)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var img_panel = PanelContainer.new()
		var img_panel_style = StyleBoxFlat.new()
		img_panel_style.bg_color = Color(0.08, 0.10, 0.18, 0.85)
		img_panel_style.set_corner_radius_all(10)
		img_panel_style.border_width_bottom = 2
		img_panel_style.border_color = Color(0.35, 0.55, 0.90, 0.55)
		img_panel_style.content_margin_left = 6
		img_panel_style.content_margin_right = 6
		img_panel_style.content_margin_top = 6
		img_panel_style.content_margin_bottom = 6
		img_panel.add_theme_stylebox_override("panel", img_panel_style)
		var tex_rect = TextureRect.new()
		tex_rect.texture = img_entry["tex"]
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.custom_minimum_size = Vector2(100, 100)
		tex_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tex_rect.modulate = img_entry["tint"]
		img_panel.add_child(tex_rect)
		col.add_child(img_panel)
		var cap_lbl = Label.new()
		cap_lbl.text = img_entry["caption"]
		cap_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cap_lbl.add_theme_font_size_override("font_size", 11)
		cap_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.95, 0.85))
		col.add_child(cap_lbl)
		fsm_img_row.add_child(col)
	tab_developer.add_child(fsm_img_row)
	var fsm_jump_hbox = HBoxContainer.new()
	fsm_jump_hbox.add_theme_constant_override("separation", 8)
	var fsm_jump_label = Label.new()
	fsm_jump_label.text = "Jump to Day:"
	fsm_jump_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var fsm_jump_option = OptionButton.new()
	fsm_jump_option.name = "FSMJumpOption"
	fsm_jump_option.add_item(_tr_bilingual("FSM_JUMP_DAY_0"), 0)
	fsm_jump_option.add_item(_tr_bilingual("FSM_JUMP_DAY_1"), 1)
	fsm_jump_option.add_item(_tr_bilingual("FSM_JUMP_DAY_2"), 2)
	fsm_jump_option.add_item(_tr_bilingual("FSM_JUMP_DAY_3"), 3)
	fsm_jump_option.add_item(_tr_bilingual("FSM_JUMP_DAY_4"), 4)
	fsm_jump_option.add_item(_tr_bilingual("FSM_JUMP_DAY_5"), 5)
	fsm_jump_option.add_item(_tr_bilingual("FSM_JUMP_DAY_6"), 6)
	fsm_jump_option.add_item(_tr_bilingual("FSM_JUMP_DAY_7"), 7)
	fsm_jump_option.add_item("⚠️ " + _tr_bilingual("FSM_JUMP_DAY_8_INPROGRESS"), 78)
	fsm_jump_option.add_item(_tr_bilingual("FSM_JUMP_DAY_8_CRASHED"), 8)
	fsm_jump_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fsm_jump_button = Button.new()
	fsm_jump_button.text = "Apply"
	fsm_jump_button.pressed.connect(func():
		_on_fsm_jump_to_day_pressed(fsm_jump_option.get_selected_id(), fsm_status_label)
	)
	fsm_jump_hbox.add_child(fsm_jump_label)
	fsm_jump_hbox.add_child(fsm_jump_option)
	fsm_jump_hbox.add_child(fsm_jump_button)
	tab_developer.add_child(fsm_jump_hbox)
	var fsm_reset_button = Button.new()
	fsm_reset_button.text = "Reset FSM Challenge"
	fsm_reset_button.pressed.connect(func():
		_on_fsm_reset_pressed(fsm_status_label)
	)
	tab_developer.add_child(fsm_reset_button)
	_add_separator(tab_developer)
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
	var tutorial_system = ServiceLocator.get_tutorial_system() if ServiceLocator else null
	if _tutorial_section == null:
		_tutorial_section = SettingsMenuTutorialSectionScript.new()
	var controls: Dictionary = _tutorial_section.build_section(
		tab_tutorial,
		tutorial_system,
		Callable(self, "_on_tutorial_enabled_toggled"),
		Callable(self, "_on_reset_tutorials_pressed"),
		Callable(self, "_on_trigger_tutorial"),
	)
	tutorial_enabled_toggle = controls.get("tutorial_enabled_toggle", null) as CheckBox
	tutorial_progress_label = controls.get("tutorial_progress_label", null) as Label
	reset_tutorials_button = controls.get("reset_tutorials_button", null) as Button
	tutorial_list_container = controls.get("tutorial_list_container", null) as VBoxContainer
	_update_tutorial_progress_display()
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
func _on_force_mission_complete_toggled(toggled: bool):
	var game_state := _get_game_state()
	if game_state:
		game_state.debug_force_mission_complete = toggled
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
	if not is_instance_valid(label):
		return
	label.text = message
	if success:
		label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		if is_instance_valid(button):
			button.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	else:
		label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		if is_instance_valid(button):
			button.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
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
func _on_reality_score_changed(value: float):
	var game_state := _get_game_state()
	if game_state:
		game_state.reality_score = int(value)
func _on_positive_energy_changed(value: float):
	var game_state := _get_game_state()
	if game_state:
		game_state.positive_energy = int(value)
func _on_entropy_level_changed(value: float):
	var game_state := _get_game_state()
	if game_state:
		game_state.entropy_level = int(value)
func _on_honeymoon_charges_changed(value: float):
	var game_state := _get_game_state()
	if game_state:
		game_state.honeymoon_charges = int(value)
func _on_mission_turn_changed(value: float):
	var game_state := _get_game_state()
	if game_state:
		game_state.mission_turn_count = int(value)
func _on_max_stats_pressed():
	_play_sfx("menu_click")
	var game_state := _get_game_state()
	if game_state:
		game_state.reality_score = 100
		game_state.positive_energy = 100
		game_state.entropy_level = 0
		game_state.honeymoon_charges = 10
		reality_score_spinbox.value = 100
		positive_energy_spinbox.value = 100
		entropy_level_spinbox.value = 0
		honeymoon_charges_spinbox.value = 10
		_show_notification("All stats maximized!", true)
func _on_reset_stats_pressed():
	_play_sfx("menu_click")
	var game_state := _get_game_state()
	if game_state:
		game_state.reality_score = 50
		game_state.positive_energy = 50
		game_state.entropy_level = 0
		game_state.honeymoon_charges = 3
		game_state.mission_turn_count = 0
		reality_score_spinbox.value = 50
		positive_energy_spinbox.value = 50
		entropy_level_spinbox.value = 0
		honeymoon_charges_spinbox.value = 3
		mission_turn_spinbox.value = 0
		_show_notification("All stats reset to defaults!", true)
func _on_clear_debuffs_pressed():
	_play_sfx("menu_click")
	var game_state := _get_game_state()
	if game_state:
		if game_state.has_method("clear_all_debuffs") and game_state.clear_all_debuffs():
			_show_notification("All debuffs cleared!", true)
		else:
			_show_notification("Debuff system not available", false)
	else:
		_show_notification("GameState not available", false)
func _on_add_honeymoon_pressed():
	_play_sfx("menu_click")
	var game_state := _get_game_state()
	if game_state:
		game_state.honeymoon_charges = min(10, game_state.honeymoon_charges + 5)
		honeymoon_charges_spinbox.value = game_state.honeymoon_charges
		_show_notification("Added 5 honeymoon charges!", true)
func _on_autosave_toggled(toggled: bool):
	_play_sfx("menu_click")
	var game_state := _get_game_state()
	if game_state:
		game_state.autosave_enabled = toggled
		var msg = "Autosave enabled" if toggled else "Autosave disabled"
		_show_notification(msg, true)
func _on_infinite_resources_toggled(toggled: bool):
	_play_sfx("menu_click")
	var game_state := _get_game_state()
	if game_state:
		game_state.set_metadata("debug_infinite_resources", toggled)
		var msg = "Infinite resources enabled" if toggled else "Infinite resources disabled"
		_show_notification(msg, true)
func _on_skip_dialogue_toggled(toggled: bool):
	_play_sfx("menu_click")
	var game_state := _get_game_state()
	if game_state:
		game_state.settings["auto_advance_enabled"] = toggled
		var msg = "Auto-advance dialogue enabled" if toggled else "Auto-advance dialogue disabled"
		_show_notification(msg, true)
func _on_god_mode_toggled(toggled: bool):
	_play_sfx("menu_click")
	var game_state := _get_game_state()
	if game_state:
		game_state.set_metadata("debug_god_mode", toggled)
		var msg = "God mode enabled" if toggled else "God mode disabled"
		_show_notification(msg, true)
func _update_fsm_status_label(label: Label):
	var game_state := _get_game_state()
	if not game_state:
		label.text = "Status: GameState not available"
		return
	var fsm_module = game_state.get_fsm_challenge_module()
	if not fsm_module:
		label.text = "Status: FSM Module not available"
		return
	if fsm_module.challenge_crashed:
		label.text = "Status: Challenge Crashed (Day 8 completed)"
	elif fsm_module.is_challenge_active:
		label.text = "Status: Active | Day: %d | Start: %s | Days Completed: %s" % [
			fsm_module.current_day,
			fsm_module.challenge_start_date,
			str(fsm_module.days_completed)
		]
	else:
		label.text = "Status: Not started"
func _on_fsm_jump_to_day_pressed(target_day_id: int, status_label: Label):
	_play_sfx("menu_click")
	var game_state := _get_game_state()
	if not game_state:
		_show_notification("GameState not available", false)
		return
	var fsm_module = game_state.get_fsm_challenge_module()
	if not fsm_module:
		_show_notification("FSM Module not available", false)
		return
	fsm_module.reset()
	if target_day_id == 0:
		game_state.save_game()
		game_state.autosave()
		_update_fsm_status_label(status_label)
		var msg := "FSM Challenge: jumped to Not Started"
		_show_notification(msg, true)
		_report_info("%s (slot + autosave updated)" % msg)
		return
	var today_dt := Time.get_datetime_dict_from_system()
	var today_str := "%04d-%02d-%02d" % [today_dt.year, today_dt.month, today_dt.day]
	fsm_module.is_challenge_active = true
	fsm_module.challenge_start_date = today_str
	fsm_module.last_login_date = today_str
	fsm_module.challenge_completed = false
	fsm_module.challenge_crashed = false
	if target_day_id == 78:
		for d in range(1, 8):
			fsm_module.days_completed.append(d)
		fsm_module.current_day = 8
		fsm_module.challenge_crashed = false
		fsm_module.challenge_completed = false
		game_state.save_game()
		game_state.autosave()
		_update_fsm_status_label(status_label)
		var msg78 := "FSM Challenge: Day 8 In Progress (not yet complete)"
		_show_notification(msg78, true)
		_report_info("%s (slot + autosave updated)" % msg78)
		return
	for d in range(1, target_day_id + 1):
		fsm_module.days_completed.append(d)
	fsm_module.current_day = target_day_id
	if target_day_id >= GameConstants.FSMChallenge.DAYS_BEFORE_CRASH:
		fsm_module.challenge_crashed = true
		fsm_module.is_challenge_active = false
	game_state.save_game()
	game_state.autosave()
	_update_fsm_status_label(status_label)
	var msg := "FSM Challenge: jumped to Day %d completed" % target_day_id
	if fsm_module.challenge_crashed:
		msg += " (Crashed)"
	_show_notification(msg, true)
	_report_info("%s (slot + autosave updated)" % msg)
func _on_fsm_reset_pressed(status_label: Label):
	_play_sfx("menu_click")
	var game_state := _get_game_state()
	if not game_state:
		_show_notification("GameState not available", false)
		return
	var fsm_module = game_state.get_fsm_challenge_module()
	if not fsm_module:
		_show_notification("FSM Module not available", false)
		return
	fsm_module.reset()
	game_state.save_game()
	game_state.autosave()
	_update_fsm_status_label(status_label)
	var msg := "FSM Challenge has been reset"
	_show_notification(msg, true)
	_report_info("%s (slot + autosave updated)" % msg)
func _show_notification(message: String, success: bool = true):
	var notifier = ServiceLocator.get_notification_system() if ServiceLocator else null
	if notifier:
		if success:
			notifier.show_success(message)
		else:
			notifier.show_warning(message)
	else:
		_debug_log("[Settings] " + message)
func _on_tutorial_enabled_toggled(toggled: bool):
	_play_sfx("menu_click")
	var tutorial_system = ServiceLocator.get_tutorial_system() if ServiceLocator else null
	if tutorial_system:
		tutorial_system.set_tutorial_enabled(toggled)
		var msg = "Tutorials enabled" if toggled else "Tutorials disabled"
		_show_notification(msg, true)
func _on_reset_tutorials_pressed():
	_play_sfx("menu_click")
	var tutorial_system = ServiceLocator.get_tutorial_system() if ServiceLocator else null
	if tutorial_system:
		tutorial_system.reset_tutorials()
		_show_notification("All tutorials have been reset!", true)
		_update_tutorial_progress_display()
		_update_tutorial_status_labels()
func _on_trigger_tutorial(step_id: String):
	_play_sfx("menu_click")
	var tutorial_system = ServiceLocator.get_tutorial_system() if ServiceLocator else null
	if tutorial_system:
		tutorial_system.trigger_tutorial(step_id)
		_show_notification("Triggered: " + step_id.replace("_", " ").capitalize(), true)
func _update_tutorial_progress_display():
	if not tutorial_progress_label:
		return
	var tutorial_system = ServiceLocator.get_tutorial_system() if ServiceLocator else null
	if tutorial_system:
		var progress = tutorial_system.get_tutorial_progress()
		var completed_count = tutorial_system.get_completed_tutorials().size()
		var total_count = tutorial_system.get_all_tutorial_steps().size()
		tutorial_progress_label.text = "Progress: %d/%d (%.1f%%)" % [completed_count, total_count, progress]
func _update_tutorial_status_labels():
	if not tutorial_list_container:
		return
	var tutorial_system = ServiceLocator.get_tutorial_system() if ServiceLocator else null
	if not tutorial_system:
		return
	for child in tutorial_list_container.get_children():
		if child is PanelContainer:
			var status_label = child.find_child("Status_*", true, false)
			if status_label and status_label is Label:
				var step_id = status_label.name.replace("Status_", "")
				if tutorial_system.is_tutorial_completed(step_id):
					status_label.text = "✓ Completed"
					status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
				else:
					status_label.text = "Not Seen"
					status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
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
	if tab_container:
		tab_container.set_tab_title(0, _tr("SETTINGS_GAMEPLAY"))
		tab_container.set_tab_title(1, _tr("SETTINGS_DISPLAY"))
		tab_container.set_tab_title(2, _tr("SETTINGS_AUDIO_2"))
		tab_container.set_tab_title(3, _tr("SETTINGS_VOICE"))
		tab_container.set_tab_title(4, _tr("SETTINGS_TUTORIAL"))
		tab_container.set_tab_title(5, _tr("SETTINGS_DEVELOPER"))
		tab_container.set_tab_title(6, _tr("SETTINGS_AI_LOG"))
	title_label.text = _tr("SETTINGS_TITLE")
	text_speed_label.text = _tr("SETTINGS_TEXT_SPEED_LABEL")
	text_speed_option.set_item_text(0, _tr("SETTINGS_TEXT_SPEED_INSTANT"))
	text_speed_option.set_item_text(1, _tr("SETTINGS_TEXT_SPEED_FAST"))
	text_speed_option.set_item_text(2, _tr("SETTINGS_TEXT_SPEED_NORMAL"))
	text_speed_option.set_item_text(3, _tr("SETTINGS_TEXT_SPEED_SLOW"))
	screen_shake_check.text = _tr("SETTINGS_SCREEN_SHAKE")
	if max_rounds_label:
		max_rounds_label.text = _tr("SETTINGS_MAX_ROUNDS_LABEL")
	if max_rounds_spinbox:
		max_rounds_spinbox.tooltip_text = _tr("SETTINGS_MAX_ROUNDS_HINT")
	touch_controls_checkbox.text = _tr("SETTINGS_TOUCH_CONTROLS")
	if force_mission_complete_check:
		force_mission_complete_check.text = _tr("SETTINGS_FORCE_MISSION_END")
		force_mission_complete_check.tooltip_text = tr("SETTINGS_DEV_FORCE_COMPLETE_HINT")
	reality_score_label.text = _tr("SETTINGS_REALITY_SCORE")
	positive_energy_label.text = _tr("SETTINGS_POSITIVE_ENERGY")
	entropy_level_label.text = _tr("SETTINGS_ENTROPY_LEVEL")
	honeymoon_charges_label.text = _tr("SETTINGS_HONEYMOON_CHARGES")
	mission_turn_label.text = _tr("SETTINGS_MISSION_TURN_COUNT")
	if tab_developer.has_node("QuickActionsLabel"):
		tab_developer.get_node("QuickActionsLabel").text = _tr("SETTINGS_QUICK_ACTIONS")
	if tab_developer.has_node("TogglesLabel"):
		tab_developer.get_node("TogglesLabel").text = _tr("SETTINGS_GAME_STATE_TOGGLES")
	max_stats_button.text = _tr("SETTINGS_MAX_ALL_STATS")
	reset_stats_button.text = _tr("SETTINGS_RESET_ALL_STATS")
	clear_debuffs_button.text = _tr("SETTINGS_CLEAR_ALL_DEBUFFS")
	add_honeymoon_button.text = _tr("SETTINGS_ADD_HONEYMOON")
	autosave_toggle.text = _tr("SETTINGS_ENABLE_AUTOSAVE")
	infinite_resources_toggle.text = _tr("SETTINGS_INFINITE_RESOURCES")
	skip_dialogue_toggle.text = _tr("SETTINGS_AUTO_ADVANCE_DIALOGUE")
	god_mode_toggle.text = _tr("SETTINGS_GOD_MODE")
	if master_volume_hbox.has_node("MasterVolumeLabel"):
		master_volume_hbox.get_node("MasterVolumeLabel").text = _tr("SETTINGS_MASTER_VOLUME")
	if music_volume_hbox.has_node("MusicVolumeLabel"):
		music_volume_hbox.get_node("MusicVolumeLabel").text = _tr("SETTINGS_MUSIC_VOLUME")
	if sfx_volume_hbox.has_node("SFXVolumeLabel"):
		sfx_volume_hbox.get_node("SFXVolumeLabel").text = _tr("SETTINGS_SFX_VOLUME")
	if gloria_voice_check:
		gloria_voice_check.text = _tr("SETTINGS_GLORIA_VOICE")
	mute_check_box.text = _tr("SETTINGS_MUTE_ALL")
	voice_description.text = _tr("SETTINGS_VOICE_DESCRIPTION")
	voice_enabled_check.text = _tr("SETTINGS_VOICE_ENABLED")
	voice_output_check.text = _tr("SETTINGS_VOICE_OUTPUT")
	voice_input_check.text = _tr("SETTINGS_VOICE_INPUT")
	voice_choice_label.text = _tr("SETTINGS_VOICE_PRESET")
	voice_volume_label.text = _tr("SETTINGS_VOICE_VOLUME")
	voice_input_mode_label.text = _tr("SETTINGS_MIC_MODE")
	voice_proactive_check.text = _tr("SETTINGS_PROACTIVE_LISTENING")
	if not voice_capture_active:
		voice_capture_button.text = _tr("SETTINGS_CAPTURE_MIC_TEST")
	voice_preview_button.text = _tr("SETTINGS_PLAY_SAMPLE")
	if not voice_status_label.text:
		voice_status_label.text = _tr("SETTINGS_VOICE_IDLE")
	resolution_label.text = _tr("SETTINGS_RESOLUTION")
	fullscreen_label.text = _tr("SETTINGS_DISPLAY_MODE")
	language_label.text = _tr("SETTINGS_LANGUAGE")
	font_size_label.text = _tr("SETTINGS_FONT_SIZE")
	english_font_label.text = _tr("SETTINGS_FONT_ENGLISH")
	chinese_font_label.text = _tr("SETTINGS_FONT_CHINESE")
	if tab_tutorial:
		if tab_tutorial.has_node("TutorialInfoPanel"):
			var info_panel = tab_tutorial.get_node("TutorialInfoPanel")
			if info_panel.has_node("TutorialInfoTitle"):
				info_panel.find_child("TutorialInfoTitle", true, false).text = _tr("SETTINGS_ABOUT_TUTORIALS")
			if info_panel.has_node("TutorialInfoDesc"):
				info_panel.find_child("TutorialInfoDesc", true, false).text = _tr("SETTINGS_TUTORIAL_DESC")
		if tab_tutorial.has_node("ControlsHeader"):
			tab_tutorial.get_node("ControlsHeader").text = _tr("SETTINGS_TUTORIAL_HEADER")
		if tab_tutorial.has_node("ProgressPanel"):
			var progress_panel = tab_tutorial.get_node("ProgressPanel")
			if progress_panel.has_node("ProgressTitle"):
				progress_panel.find_child("ProgressTitle", true, false).text = _tr("SETTINGS_YOUR_PROGRESS")
		if tab_tutorial.has_node("TutorialListLabel"):
			tab_tutorial.get_node("TutorialListLabel").text = _tr("SETTINGS_ALL_TUTORIALS")
	if tutorial_enabled_toggle:
		tutorial_enabled_toggle.text = _tr("SETTINGS_ENABLE_TUTORIALS")
	if reset_tutorials_button:
		reset_tutorials_button.text = _tr("SETTINGS_RESET_ALL_TUTORIALS")
	_update_tutorial_progress_display()
	ai_settings_button.text = _tr("SETTINGS_AI_PROVIDER")
	apply_button.text = _tr("SETTINGS_APPLY")
	if delete_logs_button:
		delete_logs_button.text = _tr("SETTINGS_DELETE_LOGS")
	back_button.text = _tr("SETTINGS_BACK")
	if delete_logs_dialog:
		delete_logs_dialog.title = _tr("SETTINGS_DELETE_LOGS_TITLE")
		delete_logs_dialog.dialog_text = _tr("SETTINGS_DELETE_LOGS_CONFIRM")
		delete_logs_dialog.ok_button_text = _tr("SETTINGS_DELETE")
		delete_logs_dialog.cancel_button_text = _tr("SETTINGS_CANCEL")
	fullscreen_option.set_item_text(0, _tr("SETTINGS_WINDOWED"))
	fullscreen_option.set_item_text(1, _tr("SETTINGS_FULLSCREEN"))
	fullscreen_option.set_item_text(2, _tr("SETTINGS_BORDERLESS"))
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
	if not AIManager: return
	if voice_capture_active:
		AIManager.cancel_voice_capture()
		voice_capture_active = false
func _disconnect_ai_signals() -> void:
	if not AIManager: return
	if AIManager.voice_capability_changed.is_connected(_on_voice_capability_changed):
		AIManager.voice_capability_changed.disconnect(_on_voice_capability_changed)
	if AIManager.voice_audio_received.is_connected(_on_voice_audio_received):
		AIManager.voice_audio_received.disconnect(_on_voice_audio_received)
	if AIManager.voice_input_buffer_ready.is_connected(_on_voice_input_buffer_ready):
		AIManager.voice_input_buffer_ready.disconnect(_on_voice_input_buffer_ready)
	if AIManager.voice_transcription_ready.is_connected(_on_voice_transcription_ready):
		AIManager.voice_transcription_ready.disconnect(_on_voice_transcription_ready)
	if AIManager.voice_transcription_failed.is_connected(_on_voice_transcription_failed):
		AIManager.voice_transcription_failed.disconnect(_on_voice_transcription_failed)
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
	var panel_style = UIStyleManager.create_panel_style(0.98, 0)
	panel.add_theme_stylebox_override("panel", panel_style)
	if apply_button:
		UIStyleManager.apply_button_style(apply_button, "accent", "large")
		apply_button.icon = ICON_CHECK
		apply_button.expand_icon = true
		UIStyleManager.add_hover_scale_effect(apply_button, 1.06)
		UIStyleManager.add_press_feedback(apply_button)
		apply_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if ai_settings_button:
		UIStyleManager.apply_button_style(ai_settings_button, "primary", "large")
		ai_settings_button.icon = ICON_CREATIVE
		ai_settings_button.expand_icon = true
		UIStyleManager.add_hover_scale_effect(ai_settings_button, 1.06)
		UIStyleManager.add_press_feedback(ai_settings_button)
		ai_settings_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if back_button:
		UIStyleManager.apply_button_style(back_button, "primary", "large")
		back_button.icon = ICON_BACK
		back_button.expand_icon = true
		UIStyleManager.add_hover_scale_effect(back_button, 1.06)
		UIStyleManager.add_press_feedback(back_button)
		back_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if delete_logs_button:
		UIStyleManager.apply_button_style(delete_logs_button, "danger", "medium")
		delete_logs_button.icon = ICON_DELETE
		delete_logs_button.expand_icon = true
		UIStyleManager.add_hover_scale_effect(delete_logs_button, 1.05)
		UIStyleManager.add_press_feedback(delete_logs_button)
		delete_logs_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if master_volume_hbox.has_node("MasterVolumeSlider"):
		master_volume_hbox.get_node("MasterVolumeSlider").mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if music_volume_hbox.has_node("MusicVolumeSlider"):
		music_volume_hbox.get_node("MusicVolumeSlider").mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if sfx_volume_hbox.has_node("SFXVolumeSlider"):
		sfx_volume_hbox.get_node("SFXVolumeSlider").mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if voice_preview_button:
		UIStyleManager.apply_button_style(voice_preview_button, "secondary", "medium")
		UIStyleManager.add_press_feedback(voice_preview_button)
		voice_preview_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if voice_capture_button:
		UIStyleManager.apply_button_style(voice_capture_button, "secondary", "medium")
		voice_capture_button.icon = ICON_MIC
		voice_capture_button.expand_icon = true
		UIStyleManager.add_press_feedback(voice_capture_button)
		voice_capture_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if reset_tutorials_button:
		UIStyleManager.apply_button_style(reset_tutorials_button, "accent", "medium")
		UIStyleManager.add_press_feedback(reset_tutorials_button)
		reset_tutorials_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if tab_tutorial:
		if tab_tutorial.has_node("TutorialInfoPanel"):
			var info_panel = tab_tutorial.get_node("TutorialInfoPanel")
			var info_style = UIStyleManager.create_panel_style(0.92, UIStyleManager.CORNER_RADIUS_MEDIUM)
			info_style.border_width_left = 3
			info_style.border_width_top = 0
			info_style.border_width_right = 0
			info_style.border_width_bottom = 0
			info_style.border_color = Color(0.4, 0.7, 1.0, 0.8)
			info_panel.add_theme_stylebox_override("panel", info_style)
		if tab_tutorial.has_node("ProgressPanel"):
			var progress_panel = tab_tutorial.get_node("ProgressPanel")
			var progress_style = UIStyleManager.create_panel_style(0.94, UIStyleManager.CORNER_RADIUS_MEDIUM)
			progress_style.border_width_left = 0
			progress_style.border_width_top = 2
			progress_style.border_width_right = 0
			progress_style.border_width_bottom = 2
			progress_style.border_color = Color(0.7, 0.9, 1.0, 0.5)
			progress_panel.add_theme_stylebox_override("panel", progress_style)
	if tutorial_list_container:
		for child in tutorial_list_container.get_children():
			if child is PanelContainer:
				var item_style = UIStyleManager.create_panel_style(0.9, UIStyleManager.CORNER_RADIUS_SMALL)
				item_style.border_width_left = 2
				item_style.border_width_top = 0
				item_style.border_width_right = 0
				item_style.border_width_bottom = 0
				item_style.border_color = Color(0.5, 0.5, 0.5, 0.3)
				child.add_theme_stylebox_override("panel", item_style)
				var trigger_button = child.find_child("Trigger_*", true, false)
				if trigger_button and trigger_button is Button:
					UIStyleManager.apply_button_style(trigger_button, "primary", "small")
					UIStyleManager.add_press_feedback(trigger_button)
					trigger_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_connect_button_sounds()
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
	if voice_voice_option:
		voice_voice_option.clear()
		for voice_name in VOICE_VOICE_NAMES:
			voice_voice_option.add_item(voice_name)
	if voice_input_mode_option:
		voice_input_mode_option.clear()
		for mode in VOICE_INPUT_MODE_LABELS.keys():
			voice_input_mode_option.add_item(VOICE_INPUT_MODE_LABELS[mode], mode)
	if AudioManager:
		var audio_snapshot: Dictionary = AudioManager.get_volume_settings()
		voice_volume = float(audio_snapshot.get("voice_volume", voice_volume))
		gloria_voice_enabled = bool(audio_snapshot.get("gloria_voice_enabled", gloria_voice_enabled))
		if gloria_voice_check:
			_set_button_pressed_safely(gloria_voice_check, gloria_voice_enabled)
	var ai_voice_settings := { }
	if AIManager:
		ai_voice_settings = AIManager.get_voice_settings()
		voice_supported = bool(ai_voice_settings.get("native_voice_supported", voice_supported))
		voice_enabled = bool(ai_voice_settings.get("prefer_native_audio", voice_enabled))
		voice_output_enabled = bool(ai_voice_settings.get("voice_output_enabled", voice_output_enabled))
		voice_input_enabled = bool(ai_voice_settings.get("voice_input_enabled", voice_input_enabled))
		voice_voice_name = String(ai_voice_settings.get("preferred_voice_name", voice_voice_name))
		voice_input_mode = int(ai_voice_settings.get("voice_input_mode", voice_input_mode))
		voice_proactive_enabled = bool(ai_voice_settings.get("proactive_audio_enabled", voice_proactive_enabled))
		if not AIManager.voice_capability_changed.is_connected(_on_voice_capability_changed):
			AIManager.voice_capability_changed.connect(_on_voice_capability_changed)
		if not AIManager.voice_audio_received.is_connected(_on_voice_audio_received):
			AIManager.voice_audio_received.connect(_on_voice_audio_received)
		if not AIManager.voice_input_buffer_ready.is_connected(_on_voice_input_buffer_ready):
			AIManager.voice_input_buffer_ready.connect(_on_voice_input_buffer_ready)
		if not AIManager.voice_transcription_ready.is_connected(_on_voice_transcription_ready):
			AIManager.voice_transcription_ready.connect(_on_voice_transcription_ready)
		if not AIManager.voice_transcription_failed.is_connected(_on_voice_transcription_failed):
			AIManager.voice_transcription_failed.connect(_on_voice_transcription_failed)
	if not voice_supported:
		voice_enabled = false
		voice_output_enabled = false
		voice_input_enabled = false
	if voice_volume_slider:
		voice_volume_slider.value = voice_volume
	_update_voice_volume_display()
	if voice_voice_option:
		var voice_index := 0
		for i in range(voice_voice_option.item_count):
			if voice_voice_option.get_item_text(i) == voice_voice_name:
				voice_index = i
				break
		voice_voice_option.select(voice_index)
	if voice_input_mode_option:
		var selected_index := 0
		for i in range(voice_input_mode_option.item_count):
			if voice_input_mode_option.get_item_id(i) == voice_input_mode:
				selected_index = i
				break
		voice_input_mode_option.select(selected_index)
	_set_button_pressed_safely(voice_proactive_check, voice_proactive_enabled)
	_update_voice_availability_label()
	_sync_voice_ui_state()
	if not voice_status_label.text:
		_update_voice_status("Voice idle.")
func _sync_voice_ui_state():
	var supported := voice_supported
	if voice_enabled and not supported:
		voice_enabled = false
		voice_output_enabled = false
		voice_input_enabled = false
	if not (voice_enabled and supported):
		voice_capture_active = false
	_set_button_pressed_safely(voice_enabled_check, voice_enabled and supported)
	voice_enabled_check.disabled = AIManager == null
	voice_options_box.visible = voice_enabled and supported
	_set_button_pressed_safely(voice_output_check, voice_output_enabled)
	voice_output_check.disabled = not (voice_enabled and supported)
	_set_button_pressed_safely(voice_input_check, voice_input_enabled)
	voice_input_check.disabled = not (voice_enabled and supported)
	voice_volume_slider.editable = voice_enabled and supported
	voice_volume_slider.focus_mode = Control.FOCUS_ALL if voice_enabled and supported else Control.FOCUS_NONE
	voice_volume_slider.value = voice_volume
	_update_voice_volume_display()
	var continuous_available := voice_enabled and supported and voice_input_enabled
	voice_input_mode_option.disabled = not continuous_available
	_set_button_pressed_safely(voice_proactive_check, voice_proactive_enabled)
	voice_proactive_check.disabled = not (voice_enabled and supported and voice_output_enabled)
	voice_preview_button.disabled = not (voice_enabled and supported and voice_output_enabled)
	voice_capture_button.disabled = not (voice_enabled and supported and voice_input_enabled)
	voice_capture_button.text = _tr("SETTINGS_CANCEL_CAPTURE") if voice_capture_active else _tr("SETTINGS_CAPTURE_MIC_TEST")
	voice_description.visible = true
	voice_status_label.visible = voice_enabled and supported
	_update_voice_availability_label()
func _update_voice_availability_label():
	if not voice_availability_label: return
	if not AIManager:
		voice_availability_label.text = "Native voice unavailable (AI Manager missing)."
		return
	if voice_supported:
		var provider_name := ""
		var model_name := ""
		match AIManager.current_provider:
			AIManager.AIProvider.GEMINI:
				provider_name = "Gemini"
				model_name = AIManager.gemini_model
			AIManager.AIProvider.OPENROUTER:
				provider_name = "OpenRouter"
				model_name = AIManager.openrouter_model
			AIManager.AIProvider.OLLAMA:
				provider_name = "Ollama (Local)"
				model_name = AIManager.ollama_model
			_:
				provider_name = "Unknown"
		voice_availability_label.text = "Native audio ready via %s (%s)." % [provider_name, model_name]
	else:
		voice_availability_label.text = "Current model does not expose native audio."
func _try_enable_gemini_native_audio_support() -> bool:
	if not AIManager:
		return false
	if AIManager.current_provider != AIManager.AIProvider.GEMINI:
		return false
	AIManager.refresh_voice_capabilities()
	voice_supported = AIManager.is_native_voice_supported()
	_update_voice_availability_label()
	return voice_supported
func _update_voice_volume_display():
	if voice_volume_value:
		voice_volume_value.text = "%d%%" % int(round(voice_volume))
func _update_voice_status(message: String, is_error: bool = false):
	if not voice_status_label: return
	voice_status_label.text = message
	if is_error:
		voice_status_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	else:
		voice_status_label.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
func _gather_voice_preferences() -> Dictionary:
	return {
		"prefer_native_audio": voice_enabled,
		"voice_output_enabled": voice_output_enabled,
		"voice_input_enabled": voice_input_enabled,
		"preferred_voice_name": voice_voice_name,
		"voice_input_mode": voice_input_mode,
		"proactive_audio_enabled": voice_proactive_enabled,
	}
func _apply_voice_preferences():
	if not AIManager: return
	var prefs := _gather_voice_preferences()
	AIManager.apply_voice_settings(prefs)
	AIManager.refresh_voice_capabilities()
	AIManager.save_ai_settings()
	voice_supported = AIManager.is_native_voice_supported()
	_sync_voice_ui_state()
func _on_voice_capability_changed(supported: bool):
	voice_supported = supported
	if not supported:
		voice_enabled = false
		voice_output_enabled = false
		voice_input_enabled = false
	_update_voice_availability_label()
	_sync_voice_ui_state()
	var state_text := "enabled" if supported else "disabled"
	_update_voice_status("Native audio %s for current model." % state_text)
func _on_voice_audio_received(payload: Dictionary):
	if not (voice_enabled and voice_output_enabled): return
	var mime: String = str(payload.get("mime_type", "audio/pcm"))
	var sample_rate := int(payload.get("sample_rate", 24000))
	_update_voice_status("Received AI audio (%s @ %d Hz)." % [mime, sample_rate])
func _on_voice_input_buffer_ready(pcm: PackedByteArray, sample_rate: int, metadata: Dictionary):
	voice_capture_active = false
	var length_sec := float(metadata.get("length_seconds", float(pcm.size()) / max(sample_rate * 2, 1)))
	_update_voice_status("Captured microphone sample (%.2f s @ %d Hz)." % [length_sec, sample_rate])
	_sync_voice_ui_state()
func _on_voice_transcription_ready(transcript: String, metadata: Dictionary):
	voice_capture_active = false
	var direction: String = str(metadata.get("direction", "output"))
	var label := "AI transcription" if direction == "output" else "Input transcription"
	_update_voice_status("%s: %s" % [label, transcript])
	_sync_voice_ui_state()
func _on_voice_transcription_failed(reason: String):
	voice_capture_active = false
	_update_voice_status("Voice transcription failed: %s" % reason, true)
	_sync_voice_ui_state()
func _on_voice_enabled_toggled(button_pressed: bool):
	if button_pressed and not voice_supported:
		if _try_enable_gemini_native_audio_support():
			_update_voice_status("Native audio enabled.")
		else:
			_set_button_pressed_safely(voice_enabled_check, false)
			_update_voice_status("Current model does not support native audio.", true)
			return
	voice_enabled = button_pressed and voice_supported
	if not voice_enabled:
		voice_output_enabled = false
		voice_input_enabled = false
	voice_capture_active = false
	_apply_voice_preferences()
	_sync_voice_ui_state()
func _on_voice_output_toggled(button_pressed: bool):
	if not (voice_enabled and voice_supported):
		_set_button_pressed_safely(voice_output_check, false)
		_update_voice_status("Enable native voice first.", true)
		return
	voice_output_enabled = button_pressed
	_apply_voice_preferences()
	_sync_voice_ui_state()
func _on_voice_input_toggled(button_pressed: bool):
	if not (voice_enabled and voice_supported):
		_set_button_pressed_safely(voice_input_check, false)
		_update_voice_status("Enable native voice first.", true)
		return
	voice_input_enabled = button_pressed
	if not voice_input_enabled:
		voice_capture_active = false
		if AIManager:
			AIManager.cancel_voice_capture()
	_apply_voice_preferences()
	_sync_voice_ui_state()
func _on_voice_voice_option_selected(index: int):
	if voice_voice_option:
		voice_voice_name = voice_voice_option.get_item_text(index)
	_apply_voice_preferences()
func _on_voice_volume_changed(value: float):
	voice_volume = value
	_update_voice_volume_display()
	_apply_audio_settings()
func _on_voice_input_mode_selected(index: int):
	if not voice_input_mode_option: return
	var selected_id: int = voice_input_mode_option.get_item_id(index)
	if selected_id == -1:
		selected_id = voice_input_mode_option.selected
	voice_input_mode = selected_id
	_apply_voice_preferences()
func _on_voice_proactive_toggled(button_pressed: bool):
	voice_proactive_enabled = button_pressed
	_apply_voice_preferences()
func _on_voice_preview_button_pressed():
	if not (voice_enabled and voice_supported and voice_output_enabled):
		_update_voice_status("Enable native voice output to preview audio.", true)
		return
	if not AudioManager:
		_update_voice_status("AudioManager unavailable for preview.", true)
		return
	if not AIManager:
		_update_voice_status("AI Manager unavailable for preview.", true)
		return
	var snapshot: Dictionary = AIManager.get_state_snapshot()
	if not snapshot.is_empty() and not AIManager:
		_update_voice_status("No voice playback data available yet.", true)
		return
	if snapshot.has("stream") and snapshot["stream"]:
		AudioManager.play_voice_stream(snapshot["stream"])
		_update_voice_status("Replaying most recent AI voice output.")
		return
	var pcm: PackedByteArray = snapshot.get("pcm", PackedByteArray())
	if pcm.is_empty():
		_update_voice_status("No AI voice output captured yet.", true)
		return
	var sample_rate := int(snapshot.get("sample_rate", AudioManager.DEFAULT_VOICE_SAMPLE_RATE))
	AudioManager.play_voice_from_pcm(pcm, sample_rate)
	_update_voice_status("Replaying buffered AI voice sample.")
func _on_voice_capture_button_pressed():
	if voice_capture_active:
		if AIManager:
			AIManager.cancel_voice_capture()
		voice_capture_active = false
		_update_voice_status("Capture cancelled.")
		_sync_voice_ui_state()
		return
	if not (voice_enabled and voice_supported and voice_input_enabled):
		_update_voice_status("Enable native voice input to capture audio.", true)
		return
	if not AIManager:
		_update_voice_status("AI Manager unavailable for capture.", true)
		return
	voice_capture_active = true
	_update_voice_status("Listening for %.1f seconds..." % VOICE_CAPTURE_SECONDS)
	_sync_voice_ui_state()
	AIManager.request_voice_capture(VOICE_CAPTURE_SECONDS)
func _on_touch_controls_toggled(button_pressed: bool) -> void:
	touch_controls_enabled = button_pressed
	var touch_controls = get_tree().get_root().find_child("TouchControls", true, false)
	if touch_controls:
		touch_controls.visible = touch_controls_enabled
func _on_master_volume_changed(value: float):
	master_volume = value
	if master_volume_hbox.has_node("MasterVolumeValue"):
		master_volume_hbox.get_node("MasterVolumeValue").text = str(int(value)) + "%"
	_apply_audio_settings()
func _on_music_volume_changed(value: float):
	music_volume = value
	if music_volume_hbox.has_node("MusicVolumeValue"):
		music_volume_hbox.get_node("MusicVolumeValue").text = str(int(value)) + "%"
	_apply_audio_settings()
func _on_sfx_volume_changed(value: float):
	sfx_volume = value
	if sfx_volume_hbox.has_node("SFXVolumeValue"):
		sfx_volume_hbox.get_node("SFXVolumeValue").text = str(int(value)) + "%"
	_apply_audio_settings()
func _on_gloria_voice_toggled(button_pressed: bool):
	gloria_voice_enabled = button_pressed
	_apply_audio_settings()
func _on_mute_toggled(button_pressed: bool):
	is_muted = button_pressed
	_apply_audio_settings()
func _apply_audio_settings():
	if AudioManager:
		AudioManager.apply_volume_settings(
			{
				"master_volume": master_volume,
				"music_volume": music_volume,
				"sfx_volume": sfx_volume,
				"voice_volume": voice_volume,
				"gloria_voice_enabled": gloria_voice_enabled,
				"muted": is_muted,
			},
		)
	else:
		var master_bus_idx = AudioServer.get_bus_index("Master")
		var music_bus_idx = AudioServer.get_bus_index("Music")
		var sfx_bus_idx = AudioServer.get_bus_index("SFX")
		var voice_bus_idx = AudioServer.get_bus_index("Voice")
		if master_bus_idx != -1:
			AudioServer.set_bus_mute(master_bus_idx, is_muted)
			if not is_muted:
				var master_db = linear_to_db(master_volume / 100.0)
				var music_db = linear_to_db(music_volume / 100.0)
				var sfx_db = linear_to_db(sfx_volume / 100.0)
				var voice_db = linear_to_db(voice_volume / 100.0)
				AudioServer.set_bus_volume_db(master_bus_idx, master_db)
				if music_bus_idx != -1:
					AudioServer.set_bus_volume_db(music_bus_idx, music_db)
				if sfx_bus_idx != -1:
					AudioServer.set_bus_volume_db(sfx_bus_idx, sfx_db)
				if voice_bus_idx != -1:
					AudioServer.set_bus_volume_db(voice_bus_idx, voice_db)
func _coerce_vector2i(value: Variant, fallback: Vector2i) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		var vec: Vector2 = value
		return Vector2i(roundi(vec.x), roundi(vec.y))
	if value is Array:
		var arr: Array = value
		if arr.size() >= 2:
			return Vector2i(int(arr[0]), int(arr[1]))
	return fallback
func _get_closest_resolution_key(size: Vector2i) -> int:
	var best_key: int = 0
	var best_score: int = 2147483647
	for key_variant: Variant in resolutions.keys():
		var key: int = int(key_variant)
		var candidate_variant: Variant = resolutions.get(key, resolutions[0])
		var candidate: Vector2i = _coerce_vector2i(candidate_variant, resolutions[0])
		var score: int = int(abs(candidate.x - size.x) + abs(candidate.y - size.y))
		if score < best_score:
			best_score = score
			best_key = key
	return best_key
func _normalize_selected_resolution(fallback_size: Vector2i) -> void:
	var requested: Vector2i = selected_resolution
	if requested.x <= 0 or requested.y <= 0:
		requested = fallback_size
	var nearest_key: int = _get_closest_resolution_key(requested)
	var normalized_variant: Variant = resolutions.get(nearest_key, resolutions[0])
	selected_resolution = _coerce_vector2i(normalized_variant, resolutions[0])
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
	_populate_font_option(english_font_option, en_fonts)
	_populate_font_option(chinese_font_option, zh_fonts)
	if selected_english_font.is_empty():
		selected_english_font = en_fonts[0]
	if selected_chinese_font.is_empty():
		selected_chinese_font = zh_fonts[0]
	_sync_font_option_selection()
func _populate_font_option(option: OptionButton, items: Array) -> void:
	if option == null:
		return
	option.clear()
	for item in items:
		var font_name := String(item)
		option.add_item(font_name)
		option.set_item_metadata(option.item_count - 1, font_name)
func _sync_font_option_selection() -> void:
	_select_option_by_metadata(english_font_option, selected_english_font, _get_default_font("en"))
	_select_option_by_metadata(chinese_font_option, selected_chinese_font, _get_default_font("zh"))
func _select_option_by_metadata(option: OptionButton, target: String, fallback: String) -> void:
	if option == null:
		return
	var resolved := fallback
	var selected_idx := 0
	for i in range(option.item_count):
		var meta: Variant = option.get_item_metadata(i)
		var meta_str := ""
		if typeof(meta) == TYPE_STRING:
			meta_str = meta
		var text := option.get_item_text(i)
		if meta_str == target or text == target:
			selected_idx = i
			resolved = meta_str if not meta_str.is_empty() else text
			break
	option.select(selected_idx)
	var chosen := _get_option_metadata(option, selected_idx)
	if chosen.is_empty():
		chosen = resolved
	if option == english_font_option:
		selected_english_font = chosen
	elif option == chinese_font_option:
		selected_chinese_font = chosen
func _get_option_metadata(option: OptionButton, index: int) -> String:
	if option == null:
		return ""
	if index < 0 or index >= option.item_count:
		return ""
	var meta: Variant = option.get_item_metadata(index)
	if typeof(meta) == TYPE_STRING:
		var meta_str: String = meta
		if not meta_str.is_empty():
			return meta_str
	return option.get_item_text(index)
func _apply_selected_fonts_for_current_language() -> void:
	if not FontManager:
		return
	if FontManager.has_method("set_selected_font"):
		FontManager.set_selected_font("en", selected_english_font)
		FontManager.set_selected_font("zh", selected_chinese_font)
	if FontManager.has_method("apply_language_font"):
		FontManager.apply_language_font(selected_language)
func _sync_display_options_with_state() -> void:
	var resolution_key: int = _get_closest_resolution_key(selected_resolution)
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
	selected_resolution = _coerce_vector2i(selected_variant, resolutions[0])
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
	selected_english_font = _get_option_metadata(english_font_option, index)
	_report_info("English font changed to: %s" % selected_english_font)
	_apply_selected_fonts_for_current_language()
func _on_chinese_font_changed(index: int):
	selected_chinese_font = _get_option_metadata(chinese_font_option, index)
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
	var success := false
	var files_removed := 0
	var metadata_removed := 0
	if AudioManager:
		AudioManager.play_sfx("happy_click")
	var game_state := _get_game_state()
	if game_state and game_state.has_method("delete_local_logs"):
		var result: Dictionary = game_state.delete_local_logs()
		success = true
		files_removed = int(result.get("files_deleted", 0))
		var removed_array_variant: Variant = result.get("metadata_keys_removed", [])
		if removed_array_variant is Array:
			var removed_array: Array = removed_array_variant
			metadata_removed = removed_array.size()
		game_state.set_metadata("prayer_notice_acknowledged", false)
	else:
		success = false
	var message := ""
	if success:
		message = _tr("SETTINGS_LOGS_CLEARED") % [files_removed, metadata_removed]
	else:
		message = _tr("SETTINGS_LOGS_UNAVAILABLE")
	var notifier = ServiceLocator.get_notification_system() if ServiceLocator else null
	if notifier:
		if success:
			notifier.show_success(message)
		else:
			notifier.show_warning(message)
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
	if language == "zh":
		return FontManager.DEFAULT_ZH_FONT if FontManager else "Noto Sans SC"
	return FontManager.DEFAULT_EN_FONT if FontManager else "Trajan Pro"
func save_settings():
	var config = ConfigFile.new()
	config.set_value("display", "resolution", selected_resolution)
	config.set_value("display", "mode", selected_mode)
	config.set_value("display", "font_size", selected_font_size)
	config.set_value("display", "font_en", selected_english_font)
	config.set_value("display", "font_zh", selected_chinese_font)
	config.set_value("display", "high_contrast", high_contrast_mode)
	config.set_value("game", "language", selected_language)
	config.set_value("game", "text_speed", text_speed)
	config.set_value("game", "screen_shake", screen_shake_enabled)
	config.set_value("game", "max_rounds_per_mission", max_rounds_per_mission)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "gloria_voice_enabled", gloria_voice_enabled)
	config.set_value("audio", "muted", is_muted)
	config.set_value("voice", "enabled", voice_enabled)
	config.set_value("voice", "output_enabled", voice_output_enabled)
	config.set_value("voice", "input_enabled", voice_input_enabled)
	config.set_value("voice", "voice_volume", voice_volume)
	config.set_value("voice", "voice_name", voice_voice_name)
	config.set_value("voice", "voice_input_mode", voice_input_mode)
	config.set_value("voice", "proactive_enabled", voice_proactive_enabled)
	config.set_value("controls", "touch_controls_enabled", touch_controls_enabled)
	config.save("user://settings.cfg")
	var game_state := _get_game_state()
	if game_state:
		game_state.settings.text_speed = text_speed
		game_state.settings.screen_shake_enabled = screen_shake_enabled
		game_state.settings.high_contrast_mode = high_contrast_mode
		game_state.settings["max_rounds_per_mission"] = max_rounds_per_mission
func load_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	var fallback_window_size: Vector2i = Vector2i(DisplayServer.window_get_size())
	if err == OK:
		var stored_resolution: Variant = config.get_value("display", "resolution", fallback_window_size)
		selected_resolution = _coerce_vector2i(stored_resolution, fallback_window_size)
		_normalize_selected_resolution(fallback_window_size)
		selected_mode = clampi(int(config.get_value("display", "mode", 0)), 0, 2)
		selected_font_size = int(config.get_value("display", "font_size", 2))
		selected_english_font = String(config.get_value("display", "font_en", _get_default_font("en")))
		selected_chinese_font = String(config.get_value("display", "font_zh", _get_default_font("zh")))
		high_contrast_mode = bool(config.get_value("display", "high_contrast", false))
		selected_language = String(config.get_value("game", "language", "en"))
		text_speed = float(config.get_value("game", "text_speed", 1.0))
		screen_shake_enabled = bool(config.get_value("game", "screen_shake", true))
		max_rounds_per_mission = int(config.get_value("game", "max_rounds_per_mission", 0))
		master_volume = float(config.get_value("audio", "master_volume", 100.0))
		music_volume = float(config.get_value("audio", "music_volume", 100.0))
		sfx_volume = float(config.get_value("audio", "sfx_volume", 100.0))
		gloria_voice_enabled = bool(config.get_value("audio", "gloria_voice_enabled", true))
		is_muted = bool(config.get_value("audio", "muted", false))
		voice_enabled = bool(config.get_value("voice", "enabled", voice_enabled))
		voice_output_enabled = bool(config.get_value("voice", "output_enabled", voice_output_enabled))
		voice_input_enabled = bool(config.get_value("voice", "input_enabled", voice_input_enabled))
		voice_volume = float(config.get_value("voice", "voice_volume", voice_volume))
		voice_voice_name = String(config.get_value("voice", "voice_name", voice_voice_name))
		voice_input_mode = int(config.get_value("voice", "voice_input_mode", voice_input_mode))
		voice_proactive_enabled = bool(config.get_value("voice", "proactive_enabled", voice_proactive_enabled))
		touch_controls_enabled = bool(config.get_value("controls", "touch_controls_enabled", false))
		_apply_audio_settings()
		var game_state := _get_game_state()
		if game_state:
			game_state.settings.text_speed = text_speed
			game_state.settings.screen_shake_enabled = screen_shake_enabled
			game_state.settings.high_contrast_mode = high_contrast_mode
			game_state.settings["max_rounds_per_mission"] = max_rounds_per_mission
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
func _ensure_audio_label(hbox: Control, label_name: String) -> void:
	if not hbox: return
	if hbox.has_node(label_name): return
	var label = Label.new()
	label.name = label_name
	label.custom_minimum_size.x = 140
	hbox.add_child(label)
	hbox.move_child(label, 0)
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
