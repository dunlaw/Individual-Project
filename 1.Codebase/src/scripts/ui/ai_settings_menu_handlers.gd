class_name AISettingsMenuHandlers
extends RefCounted
var _menu: Control
func _init(menu: Control) -> void:
	_menu = menu
func on_provider_changed(index: int) -> void:
	_menu.update_provider_ui()
	_menu._update_mock_mode_status()
	var ai_manager = _menu.ai_manager
	if ai_manager:
		ai_manager.current_provider = index
		_menu.update_status(_menu._tr("AI_SETTINGS_STATUS_PROVIDER_CHANGED"))
func on_test_button_pressed() -> void:
	var ai_manager = _menu.ai_manager
	if not ai_manager:
		_menu.update_status(_menu._tr("AI_SETTINGS_ERROR_MANAGER_NOT_FOUND"), true)
		return
	if not _menu.save_ui_to_manager():
		return
	var use_mock := false
	var status_message := ""
	var validation_error := ""
	match ai_manager.current_provider:
		AIManager.AIProvider.GEMINI:
			var api_key: String = str(ai_manager.gemini_api_key).strip_edges()
			var model: String = str(ai_manager.gemini_model).strip_edges()
			if api_key.is_empty():
				validation_error = _menu._tr("AI_SETTINGS_VALIDATION_GEMINI_MISSING_KEY")
				use_mock = true
			elif api_key.begins_with("http"):
				validation_error = _menu._tr("AI_SETTINGS_VALIDATION_GEMINI_INVALID_KEY")
				use_mock = true
			else:
				if model.is_empty():
					validation_error = _menu._tr("AI_SETTINGS_VALIDATION_GEMINI_MISSING_MODEL")
					use_mock = true
				else:
					status_message = _menu._tr("AI_SETTINGS_STATUS_TESTING_GEMINI") % [model]
		AIManager.AIProvider.OPENROUTER:
			var api_key: String = str(ai_manager.openrouter_api_key).strip_edges()
			var model: String = str(ai_manager.openrouter_model).strip_edges()
			if api_key.is_empty():
				validation_error = _menu._tr("AI_SETTINGS_VALIDATION_OPENROUTER_MISSING_KEY")
				use_mock = true
			else:
				if model.is_empty():
					validation_error = _menu._tr("AI_SETTINGS_VALIDATION_OPENROUTER_MISSING_MODEL")
					use_mock = true
				else:
					status_message = _menu._tr("AI_SETTINGS_STATUS_TESTING_OPENROUTER") % [model]
		AIManager.AIProvider.OLLAMA:
			var host: String = str(ai_manager.ollama_host).strip_edges()
			var port: int = int(ai_manager.ollama_port)
			var model: String = str(ai_manager.ollama_model).strip_edges()
			if host.is_empty():
				validation_error = _menu._tr("AI_SETTINGS_VALIDATION_OLLAMA_MISSING_HOST")
				use_mock = true
			elif model.is_empty():
				validation_error = _menu._tr("AI_SETTINGS_VALIDATION_OLLAMA_MISSING_MODEL")
				use_mock = true
			else:
				status_message = _menu._tr("AI_SETTINGS_STATUS_CHECKING_OLLAMA") % [host, port]
				_menu.update_status(status_message, false)
				if not OllamaClient.health_check(2.0, true):
					validation_error = _menu._tr("AI_SETTINGS_VALIDATION_OLLAMA_UNREACHABLE") % [host, port]
					use_mock = true
				else:
					var tags_result: Dictionary = OllamaClient.fetch_tags(3.0, true)
					if not tags_result.get("ok", false):
						var tags_error: String = str(tags_result.get("error", "Unable to query models."))
						validation_error = _menu._tr("AI_SETTINGS_VALIDATION_OLLAMA_LIST_MODELS_FAILED") % [tags_error]
						use_mock = true
					else:
						var models: Array = tags_result.get("models", [])
						var model_found := false
						var available_models: Array = []
						for entry in models:
							var model_name: String = ""
							if entry is Dictionary:
								model_name = str(entry.get("name", entry.get("model", ""))).strip_edges()
							else:
								model_name = str(entry).strip_edges()
							available_models.append(model_name)
							if model_name == model:
								model_found = true
						if not model_found:
							var models_list: String = ", ".join(available_models.slice(0, 5))
							if available_models.size() > 5:
								models_list += "..."
							validation_error = _menu._tr("AI_SETTINGS_VALIDATION_OLLAMA_MODEL_NOT_FOUND") % [model, models_list, model]
							use_mock = true
						else:
							status_message = _menu._tr("AI_SETTINGS_STATUS_TESTING_OLLAMA") % [host, port, model]
		AIManager.AIProvider.OPENAI:
			var api_key: String = str(ai_manager.openai_api_key).strip_edges()
			var model: String = str(ai_manager.openai_model).strip_edges()
			if api_key.is_empty():
				validation_error = _menu._tr("AI_SETTINGS_VALIDATION_OPENAI_MISSING_KEY")
				use_mock = true
			elif not api_key.begins_with("sk-"):
				validation_error = _menu._tr("AI_SETTINGS_VALIDATION_OPENAI_INVALID_KEY")
				use_mock = true
			else:
				if model.is_empty():
					model = "gpt-5.2"
				status_message = _menu._tr("AI_SETTINGS_STATUS_TESTING_OPENAI") % [model]
		AIManager.AIProvider.CLAUDE:
			var api_key: String = str(ai_manager.claude_api_key).strip_edges()
			var model: String = str(ai_manager.claude_model).strip_edges()
			if api_key.is_empty():
				validation_error = _menu._tr("AI_SETTINGS_VALIDATION_CLAUDE_MISSING_KEY")
				use_mock = true
			elif not api_key.begins_with("sk-ant-"):
				validation_error = _menu._tr("AI_SETTINGS_VALIDATION_CLAUDE_INVALID_KEY")
				use_mock = true
			else:
				if model.is_empty():
					model = "claude-sonnet-4-5-20250929"
				status_message = _menu._tr("AI_SETTINGS_STATUS_TESTING_CLAUDE") % [model]
		AIManager.AIProvider.LMSTUDIO:
			var host: String = str(ai_manager.lmstudio_host).strip_edges()
			var port: int = int(ai_manager.lmstudio_port)
			var model: String = str(ai_manager.lmstudio_model).strip_edges()
			var model_label: String = model
			if host.is_empty():
				host = "127.0.0.1"
			if model_label.is_empty():
				model_label = _menu._tr("AI_SETTINGS_AUTO_DETECT")
			status_message = _menu._tr("AI_SETTINGS_STATUS_TESTING_LMSTUDIO") % [host, port, model_label]
			var test_url: String = "http://%s:%d/v1/models" % [host, port]
			status_message += _menu._tr("AI_SETTINGS_STATUS_CHECKING_URL") % [test_url]
		AIManager.AIProvider.AI_ROUTER:
			var host: String = str(ai_manager.ai_router_host).strip_edges()
			var port: int = int(ai_manager.ai_router_port)
			var model: String = str(ai_manager.ai_router_model).strip_edges()
			var api_format: int = int(ai_manager.ai_router_api_format)
			var format_name: String = "OpenAI"
			match api_format:
				1: format_name = "Claude"
				2: format_name = "Gemini"
			if host.is_empty():
				validation_error = _menu._tr("AI_SETTINGS_VALIDATION_ROUTER_MISSING_HOST")
				use_mock = true
			elif model.is_empty():
				validation_error = _menu._tr("AI_SETTINGS_VALIDATION_ROUTER_MISSING_MODEL")
				use_mock = true
			else:
				status_message = _menu._tr("AI_SETTINGS_STATUS_TESTING_ROUTER") % [host, port, model, format_name]
		AIManager.AIProvider.MOCK_MODE:
			status_message = _menu._tr("AI_SETTINGS_STATUS_TESTING_MOCK")
			use_mock = true
		_:
			validation_error = _menu._tr("AI_SETTINGS_VALIDATION_UNKNOWN_PROVIDER")
			use_mock = true
	if not validation_error.is_empty():
		_menu.update_status(_menu._tr("AI_SETTINGS_STATUS_CONFIG_ISSUE") + validation_error, true)
		if not use_mock:
			return
		status_message = _menu._tr("AI_SETTINGS_STATUS_FALLBACK_TO_MOCK")
	_menu.update_status(status_message if not status_message.is_empty() else _menu._tr("AI_SETTINGS_STATUS_TESTING_CONNECTION"), false)
	if _menu.test_button:
		_menu.test_button.disabled = true
		_menu.test_button.text = _menu._tr("AI_SETTINGS_BUTTON_TESTING")
	var test_prompt = _menu._tr("AI_SETTINGS_TEST_PROMPT")
	ai_manager.generate_story(test_prompt, { "purpose": "test", "force_mock": use_mock })
func on_ai_test_success(response: Variant) -> void:
	if _menu.test_button:
		_menu.test_button.disabled = false
		_menu.test_button.text = _menu._tr("AI_SETTINGS_BUTTON_TEST_CONNECTION")
	var display_text = ""
	var ai_manager = _menu.ai_manager
	var provider_name := _menu._get_provider_display_name(ai_manager.current_provider) if ai_manager else _menu._tr("AI_SETTINGS_PROVIDER_UNKNOWN")
	if typeof(response) == TYPE_DICTIONARY:
		if response.has("content"):
			display_text = str(response["content"])
		elif response.has("error"):
			var error_text: String = str(response.get("error", ""))
			_menu.update_status(_menu._tr("AI_SETTINGS_STATUS_PROVIDER_ERROR") % [provider_name, error_text], true)
			return
	elif typeof(response) == TYPE_STRING:
		display_text = response
	if display_text.length() > 100:
		display_text = display_text.substr(0, 100) + "..."
	_menu.update_status(
		_menu._tr("AI_SETTINGS_STATUS_TEST_SUCCESS") % [provider_name, display_text],
		false,
	)
	_menu._debug_log("[AI Settings] Test Response from %s: %s" % [provider_name, display_text])
func on_ai_test_error(error_message: String) -> void:
	if _menu.test_button:
		_menu.test_button.disabled = false
		_menu.test_button.text = _menu._tr("AI_SETTINGS_BUTTON_TEST_CONNECTION")
	var ai_manager = _menu.ai_manager
	var provider_name := _menu._get_provider_display_name(ai_manager.current_provider) if ai_manager else _menu._tr("AI_SETTINGS_PROVIDER_UNKNOWN")
	var helpful_message := error_message
	var error_lower := error_message.to_lower()
	if "401" in error_message or "unauthorized" in error_lower or "invalid api key" in error_lower:
		helpful_message = _menu._tr("AI_SETTINGS_ERROR_AUTH_FAILED")
	elif "403" in error_message or "forbidden" in error_lower:
		helpful_message = _menu._tr("AI_SETTINGS_ERROR_FORBIDDEN")
	elif "404" in error_message or "not found" in error_lower:
		helpful_message = _menu._tr("AI_SETTINGS_ERROR_NOT_FOUND")
	elif "429" in error_message or "rate limit" in error_lower or "too many" in error_lower:
		helpful_message = _menu._tr("AI_SETTINGS_ERROR_RATE_LIMIT")
	elif "500" in error_message or "internal server" in error_lower:
		helpful_message = _menu._tr("AI_SETTINGS_ERROR_SERVER")
	elif "502" in error_message or "bad gateway" in error_lower:
		helpful_message = _menu._tr("AI_SETTINGS_ERROR_BAD_GATEWAY")
	elif "503" in error_message or "service unavailable" in error_lower:
		helpful_message = _menu._tr("AI_SETTINGS_ERROR_SERVICE_UNAVAILABLE")
	elif "timeout" in error_lower or "timed out" in error_lower:
		helpful_message = _menu._tr("AI_SETTINGS_ERROR_TIMEOUT")
	elif "connection refused" in error_lower or "econnrefused" in error_lower:
		helpful_message = _menu._tr("AI_SETTINGS_ERROR_CONNECTION_REFUSED")
	elif "network" in error_lower or "dns" in error_lower or "resolve" in error_lower:
		helpful_message = _menu._tr("AI_SETTINGS_ERROR_NETWORK")
	_menu.update_status(_menu._tr("AI_SETTINGS_STATUS_PROVIDER_ERROR") % [provider_name, helpful_message], true)
func on_ai_request_progress(update: Dictionary) -> void:
	var ai_manager = _menu.ai_manager
	if not ai_manager:
		return
	var provider: int = int(update.get("provider", ai_manager.current_provider))
	var provider_name := _menu._get_provider_display_name(provider)
	var status: String = str(update.get("status", ""))
	var elapsed: float = float(update.get("elapsed_sec", 0.0))
	var tokens: int = 0
	if update.has("partial_tokens"):
		tokens = int(update["partial_tokens"])
	elif update.has("response_tokens"):
		tokens = int(update["response_tokens"])
	var is_error := false
	var message := ""
	if provider == AIManager.AIProvider.OLLAMA:
		var model: String = str(update.get("model", ai_manager.ollama_model))
		var host: String = str(update.get("host", ai_manager.ollama_host))
		var port: int = int(update.get("port", ai_manager.ollama_port))
		match status:
			"queued":
				message = _menu._tr("AI_SETTINGS_PROGRESS_OLLAMA_QUEUED") % [model, host, port]
			"started":
				message = _menu._tr("AI_SETTINGS_PROGRESS_OLLAMA_STARTED") % [host, port]
			"stream":
				message = _menu._tr("AI_SETTINGS_PROGRESS_OLLAMA_STREAM") % [tokens, elapsed]
				var chunk_preview: String = str(update.get("last_chunk", "")).strip_edges()
				if chunk_preview.length() > 0:
					if chunk_preview.length() > 50:
						chunk_preview = chunk_preview.substr(0, 50) + "..."
					message += "\n\"%s\"" % chunk_preview
			"timeout":
				var attempt := int(update.get("attempt", 1))
				message = _menu._tr("AI_SETTINGS_PROGRESS_OLLAMA_TIMEOUT") % [elapsed, attempt]
				is_error = true
			"error":
				var reason: String = str(update.get("reason", _menu._tr("AI_SETTINGS_UNKNOWN_ERROR")))
				message = _menu._tr("AI_SETTINGS_PROGRESS_OLLAMA_ERROR") % [reason]
				is_error = true
			"completed":
				message = _menu._tr("AI_SETTINGS_PROGRESS_OLLAMA_COMPLETED") % [elapsed, tokens]
			_:
				return
	else:
		match status:
			"queued", "started":
				message = _menu._tr("AI_SETTINGS_PROGRESS_GENERIC_SENDING") % [provider_name]
			"stream":
				message = _menu._tr("AI_SETTINGS_PROGRESS_GENERIC_STREAM") % [provider_name, tokens, elapsed]
			"timeout":
				var attempt := int(update.get("attempt", 1))
				message = _menu._tr("AI_SETTINGS_PROGRESS_GENERIC_TIMEOUT") % [provider_name, elapsed, attempt]
				is_error = true
			"error":
				var reason: String = str(update.get("reason", _menu._tr("AI_SETTINGS_UNKNOWN_ERROR")))
				message = _menu._tr("AI_SETTINGS_PROGRESS_GENERIC_ERROR") % [provider_name, reason]
				is_error = true
			"completed":
				message = _menu._tr("AI_SETTINGS_PROGRESS_GENERIC_COMPLETED") % [provider_name, elapsed]
			_:
				return
	_menu.update_status(message, is_error)
func on_save_button_pressed() -> void:
	var ai_manager = _menu.ai_manager
	if not ai_manager:
		_menu.update_status(_menu._tr("AI_SETTINGS_ERROR_MANAGER_NOT_FOUND_SHORT"), true, true)
		return
	if not _menu.save_ui_to_manager():
		return
	if ai_manager.has_method("_sync_gemini_provider"):
		ai_manager._sync_gemini_provider()
	if ai_manager.has_method("_sync_openrouter_provider"):
		ai_manager._sync_openrouter_provider()
	if ai_manager.has_method("_sync_ollama_provider"):
		ai_manager._sync_ollama_provider()
	ai_manager.save_ai_settings()
	_menu.update_status(_menu._tr("AI_SETTINGS_STATUS_SETTINGS_SAVED"), false, true)
	await _menu.get_tree().create_timer(1.0).timeout
	on_back_button_pressed()
func on_back_button_pressed() -> void:
	var tree := _menu.get_tree()
	if not tree:
		return
	if _menu._overlay_mode:
		_menu.close_requested.emit()
		_menu.queue_free()
		return
	tree.paused = false
	tree.change_scene_to_file("res://1.Codebase/src/scenes/ui/settings_menu.tscn")
func on_home_button_pressed() -> void:
	var tree := _menu.get_tree()
	if not tree:
		return
	tree.paused = false
	tree.change_scene_to_file("res://1.Codebase/menu_main.tscn")
func on_openrouter_auto_router_link_clicked(_meta: Variant) -> void:
	OS.shell_open("https://openrouter.ai/docs/features/auto-router")
