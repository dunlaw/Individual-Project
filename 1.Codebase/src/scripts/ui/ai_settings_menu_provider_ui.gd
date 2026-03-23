# Manages provider UI state, label updates, and metrics display for AISettingsMenu.
class_name AISettingsMenuProviderUI
extends RefCounted

var _menu: Control

func _init(menu: Control) -> void:
	_menu = menu

func configure_provider_widgets() -> void:
	if not _menu._gemini_inputs.is_empty():
		return
	_menu._gemini_inputs = [_menu.gemini_key_input, _menu.gemini_model_option, _menu.gemini_model_input]
	_menu._gemini_visuals = [
		_menu.gemini_label,
		_menu.gemini_key_input,
		_menu.gemini_hint_label,
		_menu.gemini_model_label,
		_menu.gemini_model_option,
		_menu.gemini_model_notice_label,
	]
	_menu._openrouter_inputs = [_menu.openrouter_key_input, _menu.openrouter_model_option, _menu.openrouter_model_input]
	if _menu.openrouter_auto_router_check:
		_menu._openrouter_inputs.append(_menu.openrouter_auto_router_check)
	_menu._openrouter_visuals = [_menu.openrouter_label, _menu.openrouter_key_input, _menu.openrouter_hint_label, _menu.openrouter_model_label, _menu.openrouter_model_option, _menu.openrouter_model_input]
	if _menu.openrouter_auto_router_check:
		_menu._openrouter_visuals.append(_menu.openrouter_auto_router_check)
	if _menu.openrouter_auto_router_info_label:
		_menu._openrouter_visuals.append(_menu.openrouter_auto_router_info_label)
	if _menu.openrouter_auto_router_link_label:
		_menu._openrouter_visuals.append(_menu.openrouter_auto_router_link_label)
	_menu._ollama_inputs = [_menu.ollama_host_input, _menu.ollama_port_spin, _menu.ollama_model_input, _menu.ollama_use_chat_check, _menu.ollama_options_input]
	_menu._ollama_visuals = [
		_menu.ollama_header_label,
		_menu.ollama_info_label,
		_menu.ollama_host_label,
		_menu.ollama_host_input,
		_menu.ollama_port_label,
		_menu.ollama_port_spin,
		_menu.ollama_model_label,
		_menu.ollama_model_input,
		_menu.ollama_use_chat_check,
		_menu.ollama_options_label,
		_menu.ollama_options_input,
		_menu.ollama_hint_label,
	]
	_menu._openai_inputs = [_menu.openai_key_input, _menu.openai_model_input]
	_menu._openai_visuals = [_menu.openai_label, _menu.openai_key_input, _menu.openai_hint_label, _menu.openai_model_label, _menu.openai_model_input]
	_menu._claude_inputs = [_menu.claude_key_input, _menu.claude_model_input]
	_menu._claude_visuals = [_menu.claude_label, _menu.claude_key_input, _menu.claude_hint_label, _menu.claude_model_label, _menu.claude_model_input]
	_menu._lmstudio_inputs = [_menu.lmstudio_host_input, _menu.lmstudio_port_spin, _menu.lmstudio_model_input]
	_menu._lmstudio_visuals = [
		_menu.lmstudio_header_label,
		_menu.lmstudio_info_label,
		_menu.lmstudio_host_label,
		_menu.lmstudio_host_input,
		_menu.lmstudio_port_label,
		_menu.lmstudio_port_spin,
		_menu.lmstudio_model_label,
		_menu.lmstudio_model_input,
	]
	_menu._ai_router_inputs = [_menu.ai_router_host_input, _menu.ai_router_port_spin, _menu.ai_router_api_key_input, _menu.ai_router_model_input, _menu.ai_router_format_option, _menu.ai_router_endpoint_input]
	_menu._ai_router_visuals = [
		_menu.ai_router_header_label,
		_menu.ai_router_info_label,
		_menu.ai_router_host_label,
		_menu.ai_router_host_input,
		_menu.ai_router_port_label,
		_menu.ai_router_port_spin,
		_menu.ai_router_api_key_label,
		_menu.ai_router_api_key_input,
		_menu.ai_router_format_label,
		_menu.ai_router_format_option,
		_menu.ai_router_model_label,
		_menu.ai_router_model_input,
		_menu.ai_router_endpoint_label,
		_menu.ai_router_endpoint_input,
	]

func set_provider_section_state(inputs: Array, visuals: Array, disabled_label: Label, is_active: bool) -> void:
	for control in inputs:
		if control is LineEdit:
			(control as LineEdit).editable = is_active
		elif control is TextEdit:
			(control as TextEdit).editable = is_active
		elif control is SpinBox:
			(control as SpinBox).editable = is_active
		elif control is OptionButton:
			(control as OptionButton).disabled = not is_active
		elif control is CheckBox:
			(control as CheckBox).disabled = not is_active
		if control is Control:
			var ctrl := control as Control
			ctrl.mouse_filter = Control.MOUSE_FILTER_STOP if is_active else Control.MOUSE_FILTER_IGNORE
			if not is_active and ctrl.is_inside_tree():
				ctrl.release_focus()
	for item in visuals:
		if item is CanvasItem:
			(item as CanvasItem).modulate = _menu._ACTIVE_MODULATE if is_active else _menu._INACTIVE_MODULATE
	if is_active:
		disabled_label.text = ""
		disabled_label.visible = false
	else:
		disabled_label.text = _menu._tr("AI_SETTINGS_PROVIDER_DISABLED_MESSAGE")
		disabled_label.visible = true

func get_provider_display_name(provider: int) -> String:
	match provider:
		AIManager.AIProvider.GEMINI:
			return "Google Gemini"
		AIManager.AIProvider.OPENROUTER:
			return "OpenRouter"
		AIManager.AIProvider.OLLAMA:
			return "Ollama (Local)"
		AIManager.AIProvider.OPENAI:
			return "OpenAI"
		AIManager.AIProvider.CLAUDE:
			return "Claude (Anthropic)"
		AIManager.AIProvider.LMSTUDIO:
			return "LMStudio (Local)"
		AIManager.AIProvider.AI_ROUTER:
			return "AI Router (Local Proxy)"
		AIManager.AIProvider.MOCK_MODE:
			return _menu._tr("AI_SETTINGS_PROVIDER_MOCK_MODE")
	return _menu._tr("AI_SETTINGS_PROVIDER_UNKNOWN")

func update_provider_ui() -> void:
	configure_provider_widgets()
	var selected := _menu.provider_option.selected
	set_provider_section_state(_menu._gemini_inputs, _menu._gemini_visuals, _menu.gemini_disabled_label, true)
	set_provider_section_state(_menu._openrouter_inputs, _menu._openrouter_visuals, _menu.openrouter_disabled_label, true)
	set_provider_section_state(_menu._ollama_inputs, _menu._ollama_visuals, _menu.ollama_disabled_label, true)
	if _menu.openai_disabled_label:
		set_provider_section_state(_menu._openai_inputs, _menu._openai_visuals, _menu.openai_disabled_label, true)
	if _menu.claude_disabled_label:
		set_provider_section_state(_menu._claude_inputs, _menu._claude_visuals, _menu.claude_disabled_label, true)
	if _menu.lmstudio_disabled_label:
		set_provider_section_state(_menu._lmstudio_inputs, _menu._lmstudio_visuals, _menu.lmstudio_disabled_label, true)
	if _menu.ai_router_disabled_label:
		set_provider_section_state(_menu._ai_router_inputs, _menu._ai_router_visuals, _menu.ai_router_disabled_label, true)
	_menu.gemini_disabled_label.visible = false
	_menu.openrouter_disabled_label.visible = false
	_menu.ollama_disabled_label.visible = false
	if _menu.openai_disabled_label:
		_menu.openai_disabled_label.visible = false
	if _menu.claude_disabled_label:
		_menu.claude_disabled_label.visible = false
	if _menu.lmstudio_disabled_label:
		_menu.lmstudio_disabled_label.visible = false
	if _menu.ai_router_disabled_label:
		_menu.ai_router_disabled_label.visible = false
	var provider_name := get_provider_display_name(selected)
	if selected == AIManager.AIProvider.OLLAMA:
		provider_name = _decorate_ollama_provider_label(provider_name)
	_menu.provider_status_label.text = _menu._tr("AI_SETTINGS_STATUS_CURRENT_PROVIDER") % [provider_name]
	update_mock_mode_status()

func update_mock_mode_status() -> void:
	if not _menu._mock_mode_status_label:
		return
	var selected := _menu.provider_option.selected if _menu.provider_option else -1
	if selected == AIManager.AIProvider.MOCK_MODE:
		_menu._mock_mode_status_label.text = _menu._tr("AI_SETTINGS_MOCK_STATUS_ACTIVE")
		_menu._mock_mode_status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	else:
		var provider_name := get_provider_display_name(selected)
		_menu._mock_mode_status_label.text = _menu._tr("AI_SETTINGS_MOCK_STATUS_INACTIVE") % [provider_name]
		_menu._mock_mode_status_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

func _decorate_ollama_provider_label(base_label: String) -> String:
	var model_text := _menu.ollama_model_input.text.strip_edges()
	var fallback_port := _menu._clamp_port(int(_menu.ollama_port_spin.value))
	var parsed := _menu._parse_ollama_url(_menu.ollama_host_input.text, fallback_port)
	if not parsed.get("ok", false):
		_menu.ollama_disabled_label.visible = true
		_menu.ollama_disabled_label.text = parsed.get(
			"error",
			_menu._tr("AI_SETTINGS_OLLAMA_SETUP_REQUIRED"),
		)
		return base_label + _menu._tr("AI_SETTINGS_OLLAMA_SETUP_SUFFIX")
	var host_text := String(parsed.get("host", ""))
	var port_value := int(parsed.get("port", fallback_port))
	if host_text.is_empty() or model_text.is_empty() or port_value <= 0:
		_menu.ollama_disabled_label.visible = true
		_menu.ollama_disabled_label.text = _menu._tr("AI_SETTINGS_OLLAMA_SETUP_REQUIRED")
		return base_label + _menu._tr("AI_SETTINGS_OLLAMA_SETUP_SUFFIX")
	var ai_manager = _menu.ai_manager
	if not ai_manager:
		_menu.ollama_disabled_label.visible = false
		_menu.ollama_disabled_label.text = ""
		return base_label
	var is_ready: bool = ai_manager.is_ollama_ready()
	if is_ready:
		_menu.ollama_disabled_label.visible = false
		_menu.ollama_disabled_label.text = ""
		return base_label + _menu._tr("AI_SETTINGS_OLLAMA_READY_SUFFIX")
	var host_display: String = ai_manager.ollama_host.strip_edges()
	if host_display.is_empty():
		host_display = host_text
	var port_display: int = ai_manager.ollama_port
	if port_display <= 0:
		port_display = port_value
	_menu.ollama_disabled_label.visible = true
	_menu.ollama_disabled_label.text = _menu._tr("AI_SETTINGS_OLLAMA_OFFLINE_TEMPLATE") % [host_display, port_display]
	return base_label + _menu._tr("AI_SETTINGS_OLLAMA_OFFLINE_SUFFIX")

func update_ui_labels() -> void:
	var tab_container = _menu.tab_container
	if tab_container:
		tab_container.set_tab_title(0, _menu._tr("AI_SETTINGS_ONLINE_PROVIDERS"))
		tab_container.set_tab_title(1, _menu._tr("AI_SETTINGS_LOCAL_LLM"))
		tab_container.set_tab_title(2, _menu._tr("AI_SETTINGS_SAFETY"))
		tab_container.set_tab_title(3, _menu._tr("AI_SETTINGS_MEMORY"))
		tab_container.set_tab_title(4, _menu._tr("AI_SETTINGS_BEHAVIOR"))
		tab_container.set_tab_title(5, _menu._tr("AI_SETTINGS_METRICS"))
		tab_container.set_tab_title(6, _menu._tr("AI_SETTINGS_TAB_MOCK_MODE"))
	if _menu.safety_level_label: _menu.safety_level_label.text = _menu._tr("AI_SETTINGS_SAFETY_FILTER_LABEL")
	if _menu.safety_hint_label: _menu.safety_hint_label.text = _menu._tr("AI_SETTINGS_SAFETY_FILTER_HINT")
	if _menu.safety_level_option:
		_menu.safety_level_option.set_item_text(0, _menu._tr("AI_SETTINGS_SAFETY_GAME_MODE"))
		_menu.safety_level_option.set_item_text(1, _menu._tr("AI_SETTINGS_SAFETY_LOW_BLOCKING"))
		_menu.safety_level_option.set_item_text(2, _menu._tr("AI_SETTINGS_SAFETY_STANDARD"))
		_menu.safety_level_option.set_item_text(3, _menu._tr("AI_SETTINGS_SAFETY_STRICT"))
	_menu.ollama_header_label.text = "Configure Ollama"
	_menu.ollama_info_label.text = "Provide the local Ollama service URL and model tag. Default URL: http://127.0.0.1:11434"
	_menu.ollama_host_label.text = "Ollama URL:"
	_menu.ollama_port_label.text = "Ollama Port:"
	_menu.ollama_model_label.text = "Ollama Model Tag:"
	_menu.ollama_use_chat_check.text = "Use /api/chat streaming endpoint"
	if _menu.ollama_host_input:
		_menu.ollama_host_input.placeholder_text = _menu.DEFAULT_OLLAMA_URL
	_menu.ollama_hint_label.text = "Edit advanced sampling options in the JSON block below (temperature, top_p, num_predict, context, etc.)."
	_menu.ollama_options_label.text = "Ollama Options (JSON):"
	_menu.memory_settings_label.text = _menu._tr("AI_SETTINGS_MEMORY_SETTINGS")
	_menu.memory_hint_label.text = _menu._tr("AI_SETTINGS_MEMORY_HINT")
	_menu.memory_limit_label.text = _menu._tr("AI_SETTINGS_MEMORY_LIMIT")
	_menu.memory_summary_label.text = _menu._tr("AI_SETTINGS_MEMORY_SUMMARY_THRESHOLD")
	_menu.memory_full_label.text = _menu._tr("AI_SETTINGS_MEMORY_FULL_RETENTION")
	_menu.context_layers_label.text = _menu._tr("AI_SETTINGS_CONTEXT_LAYERS")
	_menu.long_term_header.text = _menu._tr("AI_SETTINGS_LONG_TERM_SUMMARIES")
	_menu.notes_header.text = _menu._tr("AI_SETTINGS_TRACKED_NOTES")
	if _menu.provider_label: _menu.provider_label.text = _menu._tr("AI_SETTINGS_PROVIDER_LABEL")
	_menu.gemini_label.text = _menu._tr("AI_SETTINGS_GEMINI_KEY_LABEL")
	_menu.gemini_hint_label.text = _menu._tr("AI_SETTINGS_GEMINI_KEY_HINT")
	_menu.gemini_model_label.text = _menu._tr("AI_SETTINGS_GEMINI_MODEL_LABEL")
	_menu.openrouter_label.text = _menu._tr("AI_SETTINGS_OPENROUTER_KEY_LABEL")
	_menu.openrouter_hint_label.text = _menu._tr("AI_SETTINGS_OPENROUTER_KEY_HINT")
	_menu.openrouter_model_label.text = _menu._tr("AI_SETTINGS_OPENROUTER_MODEL_LABEL")
	_menu.test_button.text = _menu._tr("AI_SETTINGS_BUTTON_TEST_CONNECTION")
	_menu.save_button.text = _menu._tr("AI_SETTINGS_BUTTON_SAVE")
	_menu.back_button.text = _menu._tr("AI_SETTINGS_BUTTON_BACK")
	_menu.home_button.text = _menu._tr("AI_SETTINGS_BUTTON_HOME")
	_menu.memory_limit_spin.suffix = _menu._tr("AI_SETTINGS_MEMORY_SUFFIX")
	_menu.memory_summary_spin.suffix = _menu._tr("AI_SETTINGS_MEMORY_SUFFIX")
	_menu.memory_full_spin.suffix = _menu._tr("AI_SETTINGS_MEMORY_SUFFIX")
	_menu.metrics_label.text = _menu.tr("METRICS_CURRENT_SESSION")
	_menu.last_response_time_label.text = _menu._tr("AI_SETTINGS_LAST_RESPONSE_TIME")
	_menu.total_api_calls_label.text = _menu.tr("METRICS_SESSION_API_CALLS")
	_menu.total_tokens_used_label.text = _menu.tr("METRICS_SESSION_TOKENS")
	_menu.last_input_tokens_label.text = _menu._tr("AI_SETTINGS_LAST_INPUT_TOKENS")
	_menu.last_output_tokens_label.text = _menu._tr("AI_SETTINGS_LAST_OUTPUT_TOKENS")
	_menu.ai_tone_style_label.text = _menu._tr("AI_SETTINGS_AI_TONE_STYLE")
	_menu.ai_tone_style_input.placeholder_text = _menu._tr("AI_SETTINGS_AI_TONE_PLACEHOLDER")
	refresh_context_layers()

func update_metrics_display() -> void:
	var ai_manager = _menu.ai_manager
	if ai_manager:
		var metrics = ai_manager.get_ai_metrics()
		var last_metrics = ai_manager.get_prompt_metrics()
		_menu.last_response_time_label.text = ("%s %.2f s" % [_menu.tr("Last Response Time:"), metrics.get("last_response_time", 0.0)])
		_menu.total_api_calls_label.text = ("%s %d" % [_menu.tr("Total API Calls:"), metrics.get("total_requests", 0)])
		_menu.total_tokens_used_label.text = ("%s %d" % [_menu.tr("Total Tokens Used:"), metrics.get("total_tokens", 0)])
		var input_tokens = int(metrics.get("last_input_tokens", 0))
		var output_tokens = int(metrics.get("last_output_tokens", 0))
		var tps = float(last_metrics.get("tps", 0.0))
		_menu.last_input_tokens_label.text = ("%s %d" % [_menu.tr("Last Input Tokens:"), input_tokens])
		_menu.last_output_tokens_label.text = ("%s %d" % [_menu.tr("Last Output Tokens:"), output_tokens])
		if tps > 0:
			_menu.last_output_tokens_label.text += " (%.1f T/s)" % tps
		_update_cumulative_stats_display(metrics)
	if _menu.ai_metrics_chart:
		_menu.ai_metrics_chart.set_data(ai_manager.get_response_time_history(), ai_manager.get_token_usage_history())
	if _menu.max_tokens_label and _menu.max_tokens_spin:
		if _menu.current_language == "en":
			_menu.max_tokens_label.text = "Max AI Reply Tokens (Per Request):"
			_menu.max_tokens_spin.suffix = " tokens"
			if _menu.max_tokens_hint_label:
				_menu.max_tokens_hint_label.text = "Limits one AI response length (output only). Not full-playthrough total, and not input token limit."
		else:
			_menu.max_tokens_label.text = "Max Tokens:"
			_menu.max_tokens_spin.suffix = " token"
			if _menu.max_tokens_hint_label:
				_menu.max_tokens_hint_label.text = "Per-request AI output limit; not total game tokens and not input limit."
	if _menu.gemini_model_input and _menu.current_language == "en":
		_menu.gemini_model_input.placeholder_text = "Enter custom model name when Custom is selected"
	refresh_context_layers()

func _update_cumulative_stats_display(metrics: Dictionary) -> void:
	if not _menu.cumulative_header_label:
		return
	var cumulative_calls := int(metrics.get("cumulative_api_calls", 0))
	var cumulative_tokens := int(metrics.get("cumulative_tokens", 0))
	var cumulative_input := int(metrics.get("cumulative_input_tokens", 0))
	var cumulative_output := int(metrics.get("cumulative_output_tokens", 0))
	var avg_response := float(metrics.get("average_response_time", 0.0))
	var first_request := str(metrics.get("first_request_timestamp", ""))
	_menu.cumulative_header_label.text = _menu.tr("METRICS_CUMULATIVE_HEADER")
	_menu.cumulative_api_calls_label.text = "%s %d" % [_menu.tr("METRICS_CUMULATIVE_API_CALLS"), cumulative_calls]
	_menu.cumulative_tokens_label.text = "%s %d (In: %d / Out: %d)" % [_menu.tr("METRICS_CUMULATIVE_TOKENS"), cumulative_tokens, cumulative_input, cumulative_output]
	_menu.cumulative_avg_response_label.text = "%s %.2f s" % [_menu.tr("METRICS_AVG_RESPONSE_TIME"), avg_response]
	if first_request.is_empty():
		_menu.cumulative_first_request_label.text = _menu.tr("METRICS_FIRST_REQUEST_NA")
	else:
		_menu.cumulative_first_request_label.text = "%s %s" % [_menu.tr("METRICS_FIRST_REQUEST"), first_request]

func refresh_context_layers() -> void:
	var language = _menu.current_language
	var summary_count = 0
	var notes_count = 0
	var summary_lines: Array = []
	var note_lines: Array = []
	var ai_manager = _menu.ai_manager
	if ai_manager:
		summary_count = ai_manager.get_long_term_summary_count()
		notes_count = ai_manager.get_note_count()
		summary_lines = ai_manager.get_long_term_lines(language, 12)
		note_lines = ai_manager.get_notes_lines(language, 12)
	_menu.long_term_header.text = _menu._tr("AI_SETTINGS_LONG_TERM_SUMMARIES_COUNT") % summary_count
	_menu.notes_header.text = _menu._tr("AI_SETTINGS_TRACKED_NOTES_COUNT") % notes_count
	if summary_lines.is_empty():
		_menu.long_term_text.text = "[i]%s[/i]" % (_menu._tr("AI_SETTINGS_NO_SUMMARIES_CAPTURED_YET"))
	else:
		var builder := ""
		for i in range(summary_lines.size()):
			builder += "%d. %s\n" % [i + 1, summary_lines[i]]
		_menu.long_term_text.text = builder.strip_edges()
	if note_lines.is_empty():
		_menu.notes_text.text = "[i]%s[/i]" % (_menu._tr("AI_SETTINGS_NO_NOTES_RECORDED"))
	else:
		var note_builder := ""
		for line in note_lines:
			note_builder += "- %s\n" % line
		_menu.notes_text.text = note_builder.strip_edges()
	update_provider_ui()
