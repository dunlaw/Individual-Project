extends Control
signal close_requested
var ai_manager: Node
var current_language: String = "en"
var _overlay_mode: bool = false
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key)
	return key
func set_overlay_mode(enabled: bool) -> void:
	_overlay_mode = enabled
const VERBOSE_LOGS := GameConstants.Debug.ENABLE_VERBOSE_LOGS
const _ACTIVE_MODULATE := Color(1, 1, 1, 1)
const _INACTIVE_MODULATE := Color(0.6, 0.6, 0.6, 1)
const DEFAULT_OLLAMA_URL := "http://127.0.0.1:11434"
const GEMINI_MODEL_OPTIONS := [
	"★ gemini-3.1-flash-lite-preview",
	"gemini-3.1-pro-preview",
	"gemini-3-flash-preview",
	"gemini-2.5-flash-native-audio-preview-12-2025",
]
const OPENROUTER_MODEL_OPTIONS := [
	"openrouter/free",
	"openrouter/auto",
	"z-ai/glm-4.5-air:free",
	"stepfun/step-3.5-flash:free",
	"google/gemini-3-flash-preview",
	"deepseek/deepseek-r1-0528:free",
	"qwen/qwen3-coder:free",
	"moonshotai/kimi-k2:free",
	"openai/gpt-oss-120b:free",
	"openai/gpt-oss-20b:free",
	"mistralai/mistral-small-3.1-24b-instruct:free",
	"google/gemma-3-12b-it:free",
	"qwen/qwen3-4b:free",
	"nvidia/nemotron-nano-9b-v2:free",
]
@warning_ignore("shadowed_global_identifier")
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
@onready var main_vbox = $ScrollContainer/Panel/VBoxContainer
@onready var original_scroll = $ScrollContainer
@onready var panel = $ScrollContainer/Panel
@onready var buttons_container = $BottomControls
@onready var provider_option: OptionButton = $ScrollContainer/Panel/VBoxContainer/ProviderOption
@onready var provider_status_label: Label = $ScrollContainer/Panel/VBoxContainer/ProviderStatusLabel
@onready var test_button: Button = $ScrollContainer/Panel/VBoxContainer/TestButton
@onready var status_label: Label = $ScrollContainer/Panel/VBoxContainer/StatusLabel
@onready var provider_label: Label = $ScrollContainer/Panel/VBoxContainer/ProviderLabel
@onready var gemini_label: Label = $ScrollContainer/Panel/VBoxContainer/GeminiLabel
@onready var gemini_key_input: LineEdit = $ScrollContainer/Panel/VBoxContainer/GeminiKeyInput
@onready var gemini_hint_label: Label = $ScrollContainer/Panel/VBoxContainer/GeminiHintLabel
@onready var gemini_model_label: Label = $ScrollContainer/Panel/VBoxContainer/GeminiModelLabel
@onready var gemini_model_option: OptionButton = $ScrollContainer/Panel/VBoxContainer/GeminiModelOption
@onready var gemini_model_input: LineEdit = get_node_or_null("ScrollContainer/Panel/VBoxContainer/GeminiModelInput") as LineEdit
@onready var gemini_model_notice_label: Label = $ScrollContainer/Panel/VBoxContainer/GeminiModelNoticeLabel
@onready var gemini_disabled_label: Label = $ScrollContainer/Panel/VBoxContainer/GeminiDisabledLabel
@onready var openrouter_label: Label = $ScrollContainer/Panel/VBoxContainer/OpenRouterLabel
@onready var openrouter_key_input: LineEdit = $ScrollContainer/Panel/VBoxContainer/OpenRouterKeyInput
@onready var openrouter_hint_label: Label = $ScrollContainer/Panel/VBoxContainer/OpenRouterHintLabel
@onready var openrouter_model_label: Label = $ScrollContainer/Panel/VBoxContainer/ModelLabel
@onready var openrouter_model_option: OptionButton = $ScrollContainer/Panel/VBoxContainer/OpenRouterModelOption
@onready var openrouter_model_input: LineEdit = $ScrollContainer/Panel/VBoxContainer/ModelInput
@onready var openrouter_disabled_label: Label = $ScrollContainer/Panel/VBoxContainer/OpenRouterDisabledLabel
var openrouter_auto_router_check: CheckBox
var openrouter_auto_router_info_label: Label
var openrouter_auto_router_link_label: RichTextLabel
@onready var ollama_header_label: Label = $ScrollContainer/Panel/VBoxContainer/OllamaHeaderLabel
@onready var ollama_info_label: Label = $ScrollContainer/Panel/VBoxContainer/OllamaInfoLabel
@onready var ollama_host_label: Label = $ScrollContainer/Panel/VBoxContainer/OllamaHostLabel
@onready var ollama_host_input: LineEdit = $ScrollContainer/Panel/VBoxContainer/OllamaHostInput
@onready var ollama_port_label: Label = $ScrollContainer/Panel/VBoxContainer/OllamaPortLabel
@onready var ollama_port_spin: SpinBox = $ScrollContainer/Panel/VBoxContainer/OllamaPortSpin
@onready var ollama_model_label: Label = $ScrollContainer/Panel/VBoxContainer/OllamaModelLabel
@onready var ollama_model_input: LineEdit = $ScrollContainer/Panel/VBoxContainer/OllamaModelInput
@onready var ollama_use_chat_check: CheckBox = $ScrollContainer/Panel/VBoxContainer/OllamaUseChatCheck
@onready var ollama_options_label: Label = $ScrollContainer/Panel/VBoxContainer/OllamaOptionsLabel
@onready var ollama_options_input: TextEdit = $ScrollContainer/Panel/VBoxContainer/OllamaOptionsInput
@onready var ollama_hint_label: Label = $ScrollContainer/Panel/VBoxContainer/OllamaHintLabel
@onready var ollama_disabled_label: Label = $ScrollContainer/Panel/VBoxContainer/OllamaDisabledLabel
@onready var memory_settings_label: Label = $ScrollContainer/Panel/VBoxContainer/MemorySettingsLabel
@onready var memory_hint_label: Label = $ScrollContainer/Panel/VBoxContainer/MemoryHintLabel
@onready var memory_limit_container = $ScrollContainer/Panel/VBoxContainer/MemoryLimitContainer
@onready var memory_limit_label: Label = memory_limit_container.get_node("MemoryLimitLabel")
@onready var memory_limit_spin: SpinBox = memory_limit_container.get_node("MemoryLimitSpin")
@onready var memory_summary_container = $ScrollContainer/Panel/VBoxContainer/MemorySummaryContainer
@onready var memory_summary_label: Label = memory_summary_container.get_node("MemorySummaryLabel")
@onready var memory_summary_spin: SpinBox = memory_summary_container.get_node("MemorySummarySpin")
@onready var memory_full_container = $ScrollContainer/Panel/VBoxContainer/MemoryFullContainer
@onready var memory_full_label: Label = memory_full_container.get_node("MemoryFullLabel")
@onready var memory_full_spin: SpinBox = memory_full_container.get_node("MemoryFullSpin")
@onready var context_layers_label: Label = $ScrollContainer/Panel/VBoxContainer/ContextLayersLabel
@onready var context_panel = $ScrollContainer/Panel/VBoxContainer/ContextPanel
@onready var long_term_header: Label = context_panel.get_node("ContextVBox/LongTermHeader")
@onready var long_term_text: RichTextLabel = context_panel.get_node("ContextVBox/LongTermText")
@onready var notes_header: Label = context_panel.get_node("ContextVBox/NotesHeader")
@onready var notes_text: RichTextLabel = context_panel.get_node("ContextVBox/NotesText")
@onready var metrics_label: Label = $ScrollContainer/Panel/VBoxContainer/MetricsLabel
@onready var last_response_time_label: Label = $ScrollContainer/Panel/VBoxContainer/LastResponseTimeLabel
@onready var total_api_calls_label: Label = $ScrollContainer/Panel/VBoxContainer/TotalAPICallsLabel
@onready var total_tokens_used_label: Label = $ScrollContainer/Panel/VBoxContainer/TotalTokensUsedLabel
@onready var last_input_tokens_label: Label = $ScrollContainer/Panel/VBoxContainer/LastInputTokensLabel
@onready var last_output_tokens_label: Label = $ScrollContainer/Panel/VBoxContainer/LastOutputTokensLabel
@onready var metrics_chart_container: Panel = $ScrollContainer/Panel/VBoxContainer/MetricsChartContainer
@onready var ai_tone_style_label: Label = $ScrollContainer/Panel/VBoxContainer/AIToneStyleLabel
@onready var ai_tone_style_input: LineEdit = $ScrollContainer/Panel/VBoxContainer/AIToneStyleInput
@onready var save_button = $BottomControls/SaveButton
@onready var back_button = $BottomControls/BackButton
@onready var home_button = $BottomControls/HomeButton
var cumulative_header_label: Label = null
var cumulative_api_calls_label: Label = null
var cumulative_tokens_label: Label = null
var cumulative_avg_response_label: Label = null
var cumulative_first_request_label: Label = null
var max_tokens_container: HBoxContainer
var max_tokens_label: Label
var max_tokens_spin: SpinBox
var max_tokens_hint_label: Label
var tab_container: TabContainer
var tab_online_providers: VBoxContainer
var tab_gemini: VBoxContainer
var tab_openrouter: VBoxContainer
var tab_openai: VBoxContainer
var tab_claude: VBoxContainer
var tab_local_llm: VBoxContainer
var tab_ollama: VBoxContainer
var tab_lmstudio: VBoxContainer
var tab_ai_router: VBoxContainer
var tab_memory: VBoxContainer
var tab_metrics: VBoxContainer
var tab_behavior: VBoxContainer
var tab_safety: VBoxContainer
var tab_mock_mode: VBoxContainer
var safety_level_label: Label
var safety_level_option: OptionButton
var safety_hint_label: Label
var openai_label: Label
var openai_key_input: LineEdit
var openai_hint_label: Label
var openai_model_label: Label
var openai_model_input: LineEdit
var openai_disabled_label: Label
var claude_label: Label
var claude_key_input: LineEdit
var claude_hint_label: Label
var claude_model_label: Label
var claude_model_input: LineEdit
var claude_disabled_label: Label
var lmstudio_header_label: Label
var lmstudio_info_label: Label
var lmstudio_host_label: Label
var lmstudio_host_input: LineEdit
var lmstudio_port_label: Label
var lmstudio_port_spin: SpinBox
var lmstudio_model_label: Label
var lmstudio_model_input: LineEdit
var lmstudio_disabled_label: Label
var ai_router_header_label: Label
var ai_router_info_label: Label
var ai_router_host_label: Label
var ai_router_host_input: LineEdit
var ai_router_port_label: Label
var ai_router_port_spin: SpinBox
var ai_router_api_key_label: Label
var ai_router_api_key_input: LineEdit
var ai_router_model_label: Label
var ai_router_model_input: LineEdit
var ai_router_format_label: Label
var ai_router_format_option: OptionButton
var ai_router_endpoint_label: Label
var ai_router_endpoint_input: LineEdit
var ai_router_disabled_label: Label
var _mock_mode_status_label: Label = null
var _gemini_inputs: Array = []
var _gemini_visuals: Array = []
var _openrouter_inputs: Array = []
var _openrouter_visuals: Array = []
var _ollama_inputs: Array = []
var _ollama_visuals: Array = []
var _openai_inputs: Array = []
var _openai_visuals: Array = []
var _claude_inputs: Array = []
var _claude_visuals: Array = []
var _lmstudio_inputs: Array = []
var _lmstudio_visuals: Array = []
var _ai_router_inputs: Array = []
var _ai_router_visuals: Array = []
var ai_metrics_chart: Control = preload("res://1.Codebase/src/scripts/ui/ai_metrics_chart.gd").new()
var _builder: AISettingsMenuBuilder
var _provider_ui: AISettingsMenuProviderUI
var _settings_io: AISettingsMenuSettingsIO
var _handlers: AISettingsMenuHandlers
func _clamp_port(value: int) -> int:
	return clampi(value, 1, 65535)
func _build_ollama_url(host: String, port: int, scheme: String = "http") -> String:
	var clean_host := host.strip_edges()
	if clean_host.is_empty():
		clean_host = "127.0.0.1"
	var clean_scheme := scheme.strip_edges()
	if clean_scheme.is_empty():
		clean_scheme = "http"
	var effective_port := _clamp_port(port)
	if clean_host.begins_with("[") and clean_host.ends_with("]"):
		return "%s://%s:%d" % [clean_scheme, clean_host, effective_port]
	if clean_host.contains(":") and not clean_host.contains(".") and not clean_host.begins_with("["):
		return "%s://[%s]:%d" % [clean_scheme, clean_host, effective_port]
	return "%s://%s:%d" % [clean_scheme, clean_host, effective_port]
func _parse_ollama_url(raw: String, fallback_port: int) -> Dictionary:
	var text := raw.strip_edges()
	var scheme := "http"
	var fallback := _clamp_port(fallback_port)
	if text.is_empty():
		return {
			"ok": true,
			"host": "127.0.0.1",
			"port": fallback,
			"scheme": scheme,
			"url": DEFAULT_OLLAMA_URL,
			"explicit_port": false,
		}
	var working := text
	var lower := working.to_lower()
	if lower.begins_with("http://"):
		scheme = "http"
		working = working.substr(7)
	elif lower.begins_with("https://"):
		scheme = "https"
		working = working.substr(8)
	var slash_idx := working.find("/")
	if slash_idx != -1:
		working = working.substr(0, slash_idx)
	working = working.strip_edges()
	if working.is_empty():
		return {
			"ok": false,
			"error": "Ollama URL missing host.",
		}
	var host_part := working
	var port_value := fallback
	var explicit_port := false
	if host_part.begins_with("["):
		var close_idx := host_part.find("]")
		if close_idx == -1:
			return {
				"ok": false,
				"error": "Ollama URL has malformed IPv6 host.",
			}
		var remainder := host_part.substr(close_idx + 1).strip_edges()
		if remainder.begins_with(":"):
			var port_str := remainder.substr(1).strip_edges()
			if port_str.is_empty():
				return {
					"ok": false,
					"error": "Ollama URL missing port number.",
				}
			if not port_str.is_valid_int():
				return {
					"ok": false,
					"error": "Ollama URL has invalid port.",
				}
			port_value = _clamp_port(int(port_str))
			explicit_port = true
		elif not remainder.is_empty():
			return {
				"ok": false,
				"error": "Ollama URL has invalid format.",
			}
		host_part = host_part.substr(1, close_idx - 1)
	else:
		var colon_idx := host_part.rfind(":")
		if colon_idx != -1:
			var port_str := host_part.substr(colon_idx + 1).strip_edges()
			if port_str.is_empty():
				return {
					"ok": false,
					"error": "Ollama URL missing port number.",
				}
			if not port_str.is_valid_int():
				return {
					"ok": false,
					"error": "Ollama URL has invalid port.",
				}
			port_value = _clamp_port(int(port_str))
			explicit_port = true
			host_part = host_part.substr(0, colon_idx)
	host_part = host_part.strip_edges()
	if host_part.is_empty():
		return {
			"ok": false,
			"error": "Ollama URL missing host.",
		}
	var display_host := host_part
	if display_host.contains(":") and not display_host.begins_with("["):
		display_host = "[%s]" % display_host
	return {
		"ok": true,
		"host": host_part,
		"port": port_value,
		"scheme": scheme,
		"explicit_port": explicit_port,
		"url": _build_ollama_url(host_part, port_value, scheme),
	}
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	ai_manager = ServiceLocator.get_ai_manager() if ServiceLocator else AIManager
	current_language = GameState.current_language if GameState else "en"
	_builder = AISettingsMenuBuilder.new(self)
	_provider_ui = AISettingsMenuProviderUI.new(self)
	_settings_io = AISettingsMenuSettingsIO.new(self)
	_handlers = AISettingsMenuHandlers.new(self)
	_builder.rebuild_layout_into_tabs()
	_provider_ui.update_ui_labels()
	_provider_ui.configure_provider_widgets()
	if openrouter_model_option and not openrouter_model_option.item_selected.is_connected(_settings_io.on_openrouter_model_option_changed):
		openrouter_model_option.item_selected.connect(_settings_io.on_openrouter_model_option_changed)
	if gemini_model_option and not gemini_model_option.item_selected.is_connected(_settings_io.on_gemini_model_option_changed):
		gemini_model_option.item_selected.connect(_settings_io.on_gemini_model_option_changed)
	if metrics_chart_container:
		metrics_chart_container.add_child(ai_metrics_chart)
		ai_metrics_chart.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_provider_ui.update_metrics_display()
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_update_metrics_display)
	if ai_manager:
		ai_manager.ai_response_received.connect(_handlers.on_ai_test_success)
		ai_manager.ai_error.connect(_handlers.on_ai_test_error)
		if ai_manager.has_signal("ai_request_progress") and not ai_manager.ai_request_progress.is_connected(_handlers.on_ai_request_progress):
			ai_manager.ai_request_progress.connect(_handlers.on_ai_request_progress)
		_settings_io.load_current_settings()
	else:
		_provider_ui.update_provider_ui()
	_builder.apply_modern_styles()
	await get_tree().process_frame
	if save_button:
		save_button.grab_focus()
	if panel:
		UIStyleManager.fade_in(panel, 0.4)
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match (event as InputEventKey).keycode:
		KEY_ESCAPE:
			_on_back_button_pressed()
			get_viewport().set_input_as_handled()
func _exit_tree() -> void:
	if ai_manager:
		if ai_manager.ai_response_received.is_connected(_handlers.on_ai_test_success):
			ai_manager.ai_response_received.disconnect(_handlers.on_ai_test_success)
		if ai_manager.ai_error.is_connected(_handlers.on_ai_test_error):
			ai_manager.ai_error.disconnect(_handlers.on_ai_test_error)
		if ai_manager.has_signal("ai_request_progress") and ai_manager.ai_request_progress.is_connected(_handlers.on_ai_request_progress):
			ai_manager.ai_request_progress.disconnect(_handlers.on_ai_request_progress)
func update_provider_ui() -> void:
	_provider_ui.update_provider_ui()
func _update_mock_mode_status() -> void:
	_provider_ui.update_mock_mode_status()
func _configure_provider_widgets() -> void:
	_provider_ui.configure_provider_widgets()
func _get_provider_display_name(provider: int) -> String:
	return _provider_ui.get_provider_display_name(provider)
func _update_metrics_display() -> void:
	_provider_ui.update_metrics_display()
func _refresh_context_layers() -> void:
	_provider_ui.refresh_context_layers()
func _update_ui_labels() -> void:
	_provider_ui.update_ui_labels()
func load_current_settings() -> void:
	_settings_io.load_current_settings()
func save_ui_to_manager() -> bool:
	return _settings_io.save_ui_to_manager()
func _on_provider_changed(index: int) -> void:
	_handlers.on_provider_changed(index)
func _on_test_button_pressed() -> void:
	_handlers.on_test_button_pressed()
func _on_save_button_pressed() -> void:
	_handlers.on_save_button_pressed()
func _on_back_button_pressed() -> void:
	_handlers.on_back_button_pressed()
func _on_home_button_pressed() -> void:
	_handlers.on_home_button_pressed()
func _on_openrouter_auto_router_link_clicked(meta: Variant) -> void:
	_handlers.on_openrouter_auto_router_link_clicked(meta)
func _on_memory_limit_value_changed(value: float) -> void:
	_settings_io.on_memory_limit_value_changed(value)
func _on_memory_full_value_changed(value: float) -> void:
	_settings_io.on_memory_full_value_changed(value)
func update_status(message: String, is_error: bool = false, emit_notification: bool = false) -> void:
	if not status_label:
		return
	if not status_label.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART:
		status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var line_count := message.count("\n") + 1
	if line_count > 1:
		status_label.custom_minimum_size.y = max(60, line_count * 20)
	else:
		status_label.custom_minimum_size.y = 0
	status_label.text = message
	if is_error:
		if message.begins_with(""):
			status_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
		else:
			status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	else:
		if message.begins_with("✓"):
			status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		else:
			status_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	if emit_notification:
		_show_notification(message, is_error)
func _show_notification(message: String, is_error: bool) -> void:
	var notifier = ServiceLocator.get_notification_system() if ServiceLocator else null
	if notifier == null:
		return
	if is_error:
		notifier.show_error(message)
	else:
		notifier.show_success(message)
func _tr_local(key: String, fallback_en: String, fallback_zh: String) -> String:
	if LocalizationManager:
		var translated: String = LocalizationManager.get_translation(key, current_language)
		if not translated.is_empty() and translated != key:
			return translated
	return fallback_zh if current_language == "zh" else fallback_en
func _tr_localf(key: String, fallback_en: String, fallback_zh: String, args: Array = []) -> String:
	var template := _tr_local(key, fallback_en, fallback_zh)
	if args.is_empty():
		return template
	return template % args
func _debug_log(message: String) -> void:
	if VERBOSE_LOGS:
		ErrorReporterBridge.report_info("AISettingsMenu", message)
