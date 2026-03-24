class_name AISettingsMenuSettingsIO
extends RefCounted
var _menu: Control
func _init(menu: Control) -> void:
	_menu = menu
func load_current_settings() -> void:
	var ai_manager = _menu.ai_manager
	if not ai_manager:
		return
	_menu.provider_option.selected = ai_manager.current_provider
	_menu.gemini_key_input.text = ai_manager.gemini_api_key
	_menu.openrouter_key_input.text = ai_manager.openrouter_api_key
	var option = _menu.gemini_model_option
	if option:
		option.clear()
		for model_name in _menu.GEMINI_MODEL_OPTIONS:
			option.add_item(model_name)
		option.add_item("Custom")
	sync_gemini_model_selection(ai_manager.gemini_model)
	if _menu.max_tokens_spin:
		_menu.max_tokens_spin.value = ai_manager.max_tokens
	if _menu.safety_level_option:
		var current_safety = ai_manager.gemini_safety_settings
		match current_safety:
			"BLOCK_NONE": _menu.safety_level_option.selected = 0
			"BLOCK_ONLY_HIGH": _menu.safety_level_option.selected = 1
			"BLOCK_MEDIUM_AND_ABOVE": _menu.safety_level_option.selected = 2
			"BLOCK_LOW_AND_ABOVE": _menu.safety_level_option.selected = 3
			_: _menu.safety_level_option.selected = 0
	_menu.openrouter_model_input.text = ai_manager.openrouter_model
	sync_openrouter_model_selection(ai_manager.openrouter_model)
	if _menu.openrouter_auto_router_check:
		_menu.openrouter_auto_router_check.button_pressed = ai_manager.openrouter_use_auto_router
	var parsed_url: Dictionary = _menu._parse_ollama_url(ai_manager.ollama_host, ai_manager.ollama_port)
	if parsed_url.get("ok", false):
		_menu.ollama_host_input.text = String(parsed_url.get("url", _menu.DEFAULT_OLLAMA_URL))
		_menu.ollama_port_spin.value = int(parsed_url.get("port", ai_manager.ollama_port))
	else:
		_menu.ollama_host_input.text = _menu._build_ollama_url(ai_manager.ollama_host, ai_manager.ollama_port)
		_menu.ollama_port_spin.value = ai_manager.ollama_port
	_menu.ollama_model_input.text = ai_manager.ollama_model
	_menu.ollama_use_chat_check.button_pressed = ai_manager.ollama_use_chat
	var options_json := JSON.stringify(ai_manager.ollama_options, "  ")
	_menu.ollama_options_input.text = options_json
	if _menu.openai_key_input:
		_menu.openai_key_input.text = ai_manager.openai_api_key
	if _menu.openai_model_input:
		_menu.openai_model_input.text = ai_manager.openai_model
	if _menu.claude_key_input:
		_menu.claude_key_input.text = ai_manager.claude_api_key
	if _menu.claude_model_input:
		_menu.claude_model_input.text = ai_manager.claude_model
	if _menu.lmstudio_host_input:
		_menu.lmstudio_host_input.text = ai_manager.lmstudio_host
	if _menu.lmstudio_port_spin:
		_menu.lmstudio_port_spin.value = ai_manager.lmstudio_port
	if _menu.lmstudio_model_input:
		_menu.lmstudio_model_input.text = ai_manager.lmstudio_model
	if _menu.ai_router_host_input:
		_menu.ai_router_host_input.text = ai_manager.ai_router_host
	if _menu.ai_router_port_spin:
		_menu.ai_router_port_spin.value = ai_manager.ai_router_port
	if _menu.ai_router_api_key_input:
		_menu.ai_router_api_key_input.text = ai_manager.ai_router_api_key
	if _menu.ai_router_model_input:
		_menu.ai_router_model_input.text = ai_manager.ai_router_model
	if _menu.ai_router_format_option:
		_menu.ai_router_format_option.selected = ai_manager.ai_router_api_format
	if _menu.ai_router_endpoint_input:
		_menu.ai_router_endpoint_input.text = ai_manager.ai_router_custom_endpoint
	_menu.ai_tone_style_input.text = ai_manager.custom_ai_tone_style
	if ai_manager.memory_store:
		_menu.memory_limit_spin.value = ai_manager.memory_store.max_memory_items
		_menu.memory_summary_spin.value = ai_manager.memory_store.memory_summary_threshold
		_menu.memory_full_spin.value = ai_manager.memory_store.memory_full_entries
	else:
		_menu.memory_limit_spin.value = _menu.memory_limit_spin.min_value
		_menu.memory_summary_spin.value = _menu.memory_summary_spin.min_value
		_menu.memory_full_spin.value = _menu.memory_full_spin.min_value
	sync_memory_spinners()
	_menu.update_provider_ui()
func save_ui_to_manager() -> bool:
	var ai_manager = _menu.ai_manager
	if not ai_manager:
		_menu.update_status(_menu._tr("AI_SETTINGS_ERROR_MANAGER_NOT_FOUND_SHORT"), true, true)
		return false
	sync_memory_spinners()
	ai_manager.current_provider = _menu.provider_option.selected
	if _menu.max_tokens_spin:
		if ai_manager.has_method("set_max_tokens"):
			ai_manager.set_max_tokens(int(_menu.max_tokens_spin.value))
		else:
			ai_manager.max_tokens = int(_menu.max_tokens_spin.value)
	var gemini_key_value: String = _menu.gemini_key_input.text.strip_edges()
	if not gemini_key_value.is_empty():
		if gemini_key_value.begins_with("http://") or gemini_key_value.begins_with("https://"):
			_menu.update_status(
				_menu._tr("AI_SETTINGS_VALIDATION_GEMINI_URL"),
				true,
				true,
			)
			return false
	ai_manager.gemini_api_key = gemini_key_value
	var gemini_values = [
		"gemini-3.1-flash-lite-preview",
		"gemini-3.1-pro-preview",
		"gemini-3-flash-preview",
		"gemini-2.5-flash-native-audio-preview-12-2025",
	]
	var gemini_selected = _menu.gemini_model_option.selected
	if gemini_selected >= 0 and gemini_selected < gemini_values.size():
		ai_manager.gemini_model = gemini_values[gemini_selected]
	elif _menu.gemini_model_input:
		var custom_gemini_model: String = _menu.gemini_model_input.text.strip_edges()
		if not custom_gemini_model.is_empty():
			ai_manager.gemini_model = custom_gemini_model
	if _menu.safety_level_option:
		match _menu.safety_level_option.selected:
			0: ai_manager.gemini_safety_settings = "BLOCK_NONE"
			1: ai_manager.gemini_safety_settings = "BLOCK_ONLY_HIGH"
			2: ai_manager.gemini_safety_settings = "BLOCK_MEDIUM_AND_ABOVE"
			3: ai_manager.gemini_safety_settings = "BLOCK_LOW_AND_ABOVE"
			_: ai_manager.gemini_safety_settings = "BLOCK_NONE"
	ai_manager.openrouter_api_key = _menu.openrouter_key_input.text
	var openrouter_selected: int = _menu.openrouter_model_option.selected if _menu.openrouter_model_option else -1
	if openrouter_selected >= 0 and openrouter_selected < _menu.OPENROUTER_MODEL_OPTIONS.size():
		ai_manager.openrouter_model = _menu.OPENROUTER_MODEL_OPTIONS[openrouter_selected]
	else:
		ai_manager.openrouter_model = _menu.openrouter_model_input.text.strip_edges()
	if _menu.openrouter_auto_router_check:
		ai_manager.openrouter_use_auto_router = _menu.openrouter_auto_router_check.button_pressed
	var fallback_port: int = _menu._clamp_port(int(_menu.ollama_port_spin.value))
	var parsed_url: Dictionary = _menu._parse_ollama_url(_menu.ollama_host_input.text, fallback_port)
	if not parsed_url.get("ok", false):
		_menu.update_status(str(parsed_url.get("error", _menu._tr("AI_SETTINGS_VALIDATION_OLLAMA_URL_INVALID"))), true, true)
		return false
	var host_text: String = String(parsed_url.get("host", "127.0.0.1"))
	var scheme: String = String(parsed_url.get("scheme", "http"))
	var use_port: int = fallback_port
	if parsed_url.get("explicit_port", false):
		use_port = int(parsed_url.get("port", fallback_port))
	var normalized_url: String = _menu._build_ollama_url(host_text, use_port, scheme)
	_menu.ollama_host_input.text = normalized_url
	_menu.ollama_port_spin.value = use_port
	ai_manager.ollama_host = host_text
	ai_manager.ollama_port = use_port
	var model_text: String = _menu.ollama_model_input.text.strip_edges()
	if model_text.is_empty():
		model_text = ai_manager.ollama_model
		_menu.ollama_model_input.text = model_text
	ai_manager.ollama_model = model_text
	var options_text: String = _menu.ollama_options_input.text.strip_edges()
	if not options_text.is_empty():
		var json := JSON.new()
		var parse_err := json.parse(options_text)
		if parse_err != OK:
			_menu.update_status(
				_menu._tr("AI_SETTINGS_VALIDATION_OLLAMA_JSON_INVALID") % [parse_err],
				true,
				true,
			)
			return false
		if not (json.data is Dictionary):
			_menu.update_status(_menu._tr("AI_SETTINGS_VALIDATION_OLLAMA_JSON_OBJECT"), true, true)
			return false
		ai_manager.ollama_options = (json.data as Dictionary).duplicate(true)
	ai_manager.ollama_use_chat = _menu.ollama_use_chat_check.button_pressed
	if ai_manager.has_method("_apply_ollama_configuration"):
		ai_manager._apply_ollama_configuration()
	if _menu.openai_key_input:
		ai_manager.openai_api_key = _menu.openai_key_input.text.strip_edges()
	if _menu.openai_model_input:
		ai_manager.openai_model = _menu.openai_model_input.text.strip_edges()
	if _menu.claude_key_input:
		ai_manager.claude_api_key = _menu.claude_key_input.text.strip_edges()
	if _menu.claude_model_input:
		ai_manager.claude_model = _menu.claude_model_input.text.strip_edges()
	if _menu.lmstudio_host_input:
		ai_manager.lmstudio_host = _menu.lmstudio_host_input.text.strip_edges()
	if _menu.lmstudio_port_spin:
		ai_manager.lmstudio_port = int(_menu.lmstudio_port_spin.value)
	if _menu.lmstudio_model_input:
		ai_manager.lmstudio_model = _menu.lmstudio_model_input.text.strip_edges()
	if _menu.ai_router_host_input:
		ai_manager.ai_router_host = _menu.ai_router_host_input.text.strip_edges()
	if _menu.ai_router_port_spin:
		ai_manager.ai_router_port = int(_menu.ai_router_port_spin.value)
	if _menu.ai_router_api_key_input:
		ai_manager.ai_router_api_key = _menu.ai_router_api_key_input.text.strip_edges()
	if _menu.ai_router_model_input:
		ai_manager.ai_router_model = _menu.ai_router_model_input.text.strip_edges()
	if _menu.ai_router_format_option:
		ai_manager.ai_router_api_format = _menu.ai_router_format_option.selected
	if _menu.ai_router_endpoint_input:
		ai_manager.ai_router_custom_endpoint = _menu.ai_router_endpoint_input.text.strip_edges()
	ai_manager.custom_ai_tone_style = _menu.ai_tone_style_input.text
	if ai_manager.memory_store:
		ai_manager.memory_store.max_memory_items = int(_menu.memory_limit_spin.value)
		ai_manager.memory_store.memory_summary_threshold = int(_menu.memory_summary_spin.value)
		ai_manager.memory_store.memory_full_entries = int(_menu.memory_full_spin.value)
		ai_manager.apply_memory_settings()
	_menu.update_provider_ui()
	return true
func sync_memory_spinners() -> void:
	_menu.memory_limit_spin.step = 10
	_menu.memory_summary_spin.max_value = _menu.memory_limit_spin.value
	_menu.memory_full_spin.max_value = _menu.memory_limit_spin.value
	if _menu.memory_full_spin.value > _menu.memory_limit_spin.value:
		_menu.memory_full_spin.value = _menu.memory_limit_spin.value
	if _menu.memory_summary_spin.value > _menu.memory_limit_spin.value:
		_menu.memory_summary_spin.value = _menu.memory_limit_spin.value
	if _menu.memory_summary_spin.value < _menu.memory_full_spin.value:
		_menu.memory_summary_spin.value = _menu.memory_full_spin.value
	_menu.memory_summary_spin.min_value = _menu.memory_full_spin.value
func on_memory_limit_value_changed(_value: float) -> void:
	sync_memory_spinners()
func on_memory_full_value_changed(value: float) -> void:
	if _menu.memory_summary_spin.value < value:
		_menu.memory_summary_spin.value = value
	sync_memory_spinners()
func sync_gemini_model_selection(model: String) -> void:
	if not _menu.gemini_model_option:
		return
	var model_lower := model.strip_edges().to_lower()
	var found_index := -1
	for i in range(_menu.GEMINI_MODEL_OPTIONS.size()):
		if _menu.GEMINI_MODEL_OPTIONS[i].to_lower() == model_lower:
			found_index = i
			break
	if found_index >= 0:
		_menu.gemini_model_option.selected = found_index
		if _menu.gemini_model_input:
			_menu.gemini_model_input.text = _menu.GEMINI_MODEL_OPTIONS[found_index]
			_menu.gemini_model_input.editable = false
			_menu.gemini_model_input.modulate = Color(0.7, 0.7, 0.7, 1)
	else:
		_menu.gemini_model_option.selected = _menu.GEMINI_MODEL_OPTIONS.size()
		if _menu.gemini_model_input:
			_menu.gemini_model_input.text = model
			_menu.gemini_model_input.editable = true
			_menu.gemini_model_input.modulate = Color(1, 1, 1, 1)
func on_gemini_model_option_changed(index: int) -> void:
	if not _menu.gemini_model_input:
		return
	if index < _menu.GEMINI_MODEL_OPTIONS.size():
		_menu.gemini_model_input.text = _menu.GEMINI_MODEL_OPTIONS[index]
		_menu.gemini_model_input.editable = false
		_menu.gemini_model_input.modulate = Color(0.7, 0.7, 0.7, 1)
	else:
		_menu.gemini_model_input.editable = true
		_menu.gemini_model_input.modulate = Color(1, 1, 1, 1)
		if _menu.gemini_model_input.text in _menu.GEMINI_MODEL_OPTIONS:
			_menu.gemini_model_input.text = ""
		_menu.gemini_model_input.grab_focus()
func sync_openrouter_model_selection(model: String) -> void:
	if not _menu.openrouter_model_option:
		return
	var model_lower := model.strip_edges().to_lower()
	var found_index := -1
	for i in range(_menu.OPENROUTER_MODEL_OPTIONS.size()):
		if _menu.OPENROUTER_MODEL_OPTIONS[i].to_lower() == model_lower:
			found_index = i
			break
	if found_index >= 0:
		_menu.openrouter_model_option.selected = found_index
		_menu.openrouter_model_input.text = _menu.OPENROUTER_MODEL_OPTIONS[found_index]
		_menu.openrouter_model_input.editable = false
		_menu.openrouter_model_input.modulate = Color(0.7, 0.7, 0.7, 1)
	else:
		_menu.openrouter_model_option.selected = _menu.OPENROUTER_MODEL_OPTIONS.size()
		_menu.openrouter_model_input.text = model
		_menu.openrouter_model_input.editable = true
		_menu.openrouter_model_input.modulate = Color(1, 1, 1, 1)
func on_openrouter_model_option_changed(index: int) -> void:
	if index < _menu.OPENROUTER_MODEL_OPTIONS.size():
		_menu.openrouter_model_input.text = _menu.OPENROUTER_MODEL_OPTIONS[index]
		_menu.openrouter_model_input.editable = false
		_menu.openrouter_model_input.modulate = Color(0.7, 0.7, 0.7, 1)
	else:
		_menu.openrouter_model_input.editable = true
		_menu.openrouter_model_input.modulate = Color(1, 1, 1, 1)
		if _menu.openrouter_model_input.text in _menu.OPENROUTER_MODEL_OPTIONS:
			_menu.openrouter_model_input.text = ""
		_menu.openrouter_model_input.grab_focus()
