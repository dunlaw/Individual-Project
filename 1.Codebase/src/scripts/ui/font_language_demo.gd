extends Control
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
const ERROR_CONTEXT := "FontLanguageDemo"
var current_language: String = "en"
var _game_state: Node = null
var _font_manager: Node = null
var _ai_manager: Node = null
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key, current_language)
	return key
func _ready():
	_resolve_services()
	_load_language_from_state()
	_apply_font_sizes()
	update_ui_text()
	_connect_font_signal()
	_connect_buttons()
func _exit_tree() -> void:
	_disconnect_font_signal()
func _resolve_services() -> void:
	if not ServiceLocator:
		_report_warning("ServiceLocator unavailable; using defaults")
		return
	_game_state = ServiceLocator.get_game_state()
	_font_manager = ServiceLocator.get_font_manager()
	_ai_manager = ServiceLocator.get_ai_manager()
func _load_language_from_state() -> void:
	current_language = _game_state.current_language if _game_state else "en"
func _connect_font_signal() -> void:
	if not is_instance_valid(_font_manager):
		return
	var font_signal: Signal = _font_manager.font_size_changed
	if not font_signal.is_connected(_on_font_size_changed):
		font_signal.connect(_on_font_size_changed)
func _disconnect_font_signal() -> void:
	if not is_instance_valid(_font_manager):
		return
	var font_signal: Signal = _font_manager.font_size_changed
	if font_signal.is_connected(_on_font_size_changed):
		font_signal.disconnect(_on_font_size_changed)
func _connect_buttons() -> void:
	$Panel/VBox/LanguageButton.pressed.connect(_toggle_language)
	$Panel/VBox/FontSizeButton.pressed.connect(_cycle_font_size)
	$Panel/VBox/TestAIButton.pressed.connect(_test_ai_output)
func _apply_font_sizes():
	if not is_instance_valid(_font_manager):
		_report_warning("FontManager not available; skipping font setup")
		return
	_font_manager.apply_to_label($Panel/VBox/TitleLabel, 36)
	_font_manager.apply_to_label($Panel/VBox/DescriptionLabel, 18)
	_font_manager.apply_to_button($Panel/VBox/LanguageButton, 20)
	_font_manager.apply_to_button($Panel/VBox/FontSizeButton, 20)
	_font_manager.apply_to_button($Panel/VBox/TestAIButton, 20)
	_font_manager.apply_to_label($Panel/VBox/StatusLabel, 16)
func _on_font_size_changed(multiplier: float):
	_report_info("Font size changed to: %sx" % multiplier)
	_apply_font_sizes()
func update_ui_text():
	$Panel/VBox/TitleLabel.text = _tr("FONT_DEMO_TITLE")
	$Panel/VBox/DescriptionLabel.text = _tr("FONT_DEMO_DESCRIPTION")
	$Panel/VBox/LanguageButton.text = _tr("FONT_DEMO_SWITCH_LANG")
	$Panel/VBox/FontSizeButton.text = _tr("FONT_DEMO_CHANGE_SIZE")
	$Panel/VBox/TestAIButton.text = _tr("FONT_DEMO_TEST_AI")
	_update_status()
func _update_status():
	var font_name := _get_font_size_name()
	var multiplier: float = float(_font_manager.get_multiplier()) if _font_manager else 1.0
	$Panel/VBox/StatusLabel.text = _tr("FONT_DEMO_STATUS") % [font_name, multiplier * 100]
func _get_font_size_name() -> String:
	if not _font_manager:
		return _tr("FONT_SIZE_STANDARD")
	match _font_manager.get_font_size():
		0: return _tr("FONT_SIZE_XSMALL")
		1: return _tr("FONT_SIZE_SMALL")
		2: return _tr("FONT_SIZE_STANDARD")
		3: return _tr("FONT_SIZE_LARGE")
		4: return _tr("FONT_SIZE_XLARGE")
		_: return _tr("FONT_SIZE_UNKNOWN")
func _toggle_language():
	current_language = "en" if current_language == "zh" else "zh"
	if _game_state:
		_game_state.current_language = current_language
	update_ui_text()
	_report_info("Language changed to: %s" % current_language)
func _cycle_font_size():
	if not is_instance_valid(_font_manager):
		_report_warning("FontManager not available; cannot change font size")
		return
	var current = _font_manager.get_font_size()
	var next_size = (current + 1) % 5
	_font_manager.set_font_size(next_size)
	update_ui_text()
func _test_ai_output():
	if not is_instance_valid(_ai_manager):
		_report_warning("AIManager not available; cannot generate test output")
		$Panel/VBox/StatusLabel.text = _tr("FONT_DEMO_AI_UNAVAILABLE")
		return
	$Panel/VBox/StatusLabel.text = _tr("FONT_DEMO_GENERATING_AI_RESPONSE")
	var prompt = _tr("FONT_DEMO_DESCRIBE_A_BEAUTIFUL_SUNSET_IN")
	_ai_manager.generate_story(
		prompt,
		{ },
		func(response):
			if response.success:
				var result = _tr("FONT_DEMO_AI_RESPONSE") % response.content
				_report_info(result)
				$Panel/VBox/StatusLabel.text = _tr("FONT_DEMO_AI_RESPONSE_RECEIVED_CHECK_CONSOLE")
			else:
				$Panel/VBox/StatusLabel.text = _tr("FONT_DEMO_AI_ERROR") % response.error
	)
func _report_info(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, message, details)
func _report_warning(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, message, details)
func _report_error(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, -1, false, details)
