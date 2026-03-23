class_name CLIAICommands
extends RefCounted
var _parser: CLICommandParser
func _init(parser: CLICommandParser) -> void:
	_parser = parser
func handle_ai_status(_args: Array[String], json_output: bool) -> int:
	var ai_manager := _parser.get_ai_manager()
	if ai_manager == null:
		_parser.output_payload(
			{
				"ok": false,
				"command": "ai-status",
				"error": "AIManager service unavailable",
			},
			json_output,
		)
		return 1
	var current_provider := _parser.get_current_provider(ai_manager)
	var providers: Array[Dictionary] = []
	for provider in _parser.get_supported_providers():
		var provider_value := int(CLICommandParser.PROVIDER_ENUMS.get(provider, -1))
		var entry := {
			"provider": provider,
			"is_current": provider == current_provider,
			"configured": _parser.is_provider_configured(ai_manager, provider_value, provider),
		}
		var model_property := String(CLICommandParser.PROVIDER_MODEL_PROPERTIES.get(provider, ""))
		if not model_property.is_empty() and ai_manager.has_method("get"):
			entry["model"] = String(ai_manager.get(model_property))
		if CLICommandParser.API_KEY_PROVIDER_PROPERTIES.has(provider):
			var api_key := _parser.get_provider_api_key(ai_manager, provider, provider_value)
			entry["key_configured"] = not api_key.is_empty()
			entry["key_masked"] = _parser.mask_secret(api_key)
		providers.append(entry)
	_parser.output_payload(
		{
			"ok": true,
			"command": "ai-status",
			"current_provider": current_provider,
			"providers": providers,
		},
		json_output,
	)
	return 0
func handle_provider_list(json_output: bool) -> int:
	var providers: Array[Dictionary] = []
	for provider in _parser.get_supported_providers():
		providers.append(
			{
				"provider": provider,
				"value": int(CLICommandParser.PROVIDER_ENUMS.get(provider, -1)),
				"requires_api_key": CLICommandParser.API_KEY_PROVIDER_PROPERTIES.has(provider),
				"has_model_setting": CLICommandParser.PROVIDER_MODEL_PROPERTIES.has(provider),
			}
		)
	_parser.output_payload(
		{
			"ok": true,
			"command": "provider-list",
			"count": providers.size(),
			"providers": providers,
			"api_key_providers": _parser.get_api_key_supported_providers(),
		},
		json_output,
	)
	return 0
func handle_set_provider(args: Array[String], json_output: bool) -> int:
	var ai_manager := _parser.get_ai_manager()
	if ai_manager == null:
		_parser.output_payload(
			{
				"ok": false,
				"command": "set-provider",
				"error": "AIManager service unavailable",
			},
			json_output,
		)
		return 1
	var raw_provider := _parser.get_option(args, "--provider").strip_edges()
	if raw_provider.is_empty():
		raw_provider = _parser.get_option(args, "--to").strip_edges()
	if raw_provider.is_empty():
		raw_provider = _parser.get_first_non_command_positional(args)
	var target_provider := _parser.normalize_provider(raw_provider)
	if target_provider.is_empty():
		_parser.output_payload(
			{
				"ok": false,
				"command": "set-provider",
				"error": "Missing or unsupported provider",
				"supported_providers": _parser.get_supported_providers(),
			},
			json_output,
		)
		return 2
	var provider_value := int(CLICommandParser.PROVIDER_ENUMS.get(target_provider, -1))
	if provider_value < 0:
		_parser.output_payload(
			{
				"ok": false,
				"command": "set-provider",
				"provider": target_provider,
				"error": "Provider enum mapping unavailable",
			},
			json_output,
		)
		return 2
	var previous_provider := _parser.get_current_provider(ai_manager)
	ai_manager.set("current_provider", provider_value)
	if ai_manager.has_method("save_ai_settings"):
		ai_manager.save_ai_settings()
	if ai_manager.has_method("load_ai_settings"):
		ai_manager.load_ai_settings()
	var current_provider := _parser.get_current_provider(ai_manager)
	var applied_ok := current_provider == target_provider
	_parser.output_payload(
		{
			"ok": applied_ok,
			"command": "set-provider",
			"previous_provider": previous_provider,
			"provider": current_provider,
		},
		json_output,
	)
	return 0 if applied_ok else 1
func handle_set_api_key(args: Array[String], json_output: bool) -> int:
	var ai_manager := _parser.get_ai_manager()
	if ai_manager == null:
		_parser.output_payload(
			{
				"ok": false,
				"command": "set-api-key",
				"error": "AIManager service unavailable",
			},
			json_output,
		)
		return 1
	var provider_raw := _parser.get_option(args, "--provider").strip_edges()
	if provider_raw.is_empty():
		provider_raw = _parser.get_option(args, "--for").strip_edges()
	var provider_option_provided := not provider_raw.is_empty()
	var provider := _parser.normalize_api_key_provider(provider_raw)
	if provider_option_provided and provider.is_empty():
		_parser.output_payload(
			{
				"ok": false,
				"command": "set-api-key",
				"error": "Unsupported provider: %s" % provider_raw,
				"supported_providers": _parser.get_api_key_supported_providers(),
			},
			json_output,
		)
		return 2
	if provider.is_empty():
		provider = _parser.get_current_api_key_provider(ai_manager)
	if provider.is_empty():
		_parser.output_payload(
			{
				"ok": false,
				"command": "set-api-key",
				"error": "Missing or unsupported provider. Use --provider=gemini|openrouter|openai|claude|ai-router",
				"supported_providers": _parser.get_api_key_supported_providers(),
			},
			json_output,
		)
		return 2
	var clear_mode := _parser.has_flag(args, "--clear-key") or _parser.has_flag(args, "--clear")
	var raw_key_direct := _parser.get_option(args, "--api-key")
	if raw_key_direct.is_empty():
		raw_key_direct = _parser.get_option(args, "--key")
	var api_key_env_name := _parser.get_option(args, "--api-key-env").strip_edges()
	var api_key_file_path := _parser.get_option(args, "--api-key-file").strip_edges()
	var key_source_count := 0
	if not raw_key_direct.strip_edges().is_empty():
		key_source_count += 1
	if not api_key_env_name.is_empty():
		key_source_count += 1
	if not api_key_file_path.is_empty():
		key_source_count += 1
	if key_source_count > 1:
		_parser.output_payload(
			{
				"ok": false,
				"command": "set-api-key",
				"provider": provider,
				"error": "Use only one key source: --api-key | --api-key-env | --api-key-file",
			},
			json_output,
		)
		return 2
	if clear_mode and key_source_count > 0:
		_parser.output_payload(
			{
				"ok": false,
				"command": "set-api-key",
				"provider": provider,
				"error": "Do not combine --clear-key with key value options",
			},
			json_output,
		)
		return 2
	var key_source := "direct"
	var api_key := raw_key_direct.strip_edges()
	if not api_key_env_name.is_empty():
		key_source = "env"
		api_key = OS.get_environment(api_key_env_name).strip_edges()
		if api_key.is_empty():
			_parser.output_payload(
				{
					"ok": false,
					"command": "set-api-key",
					"provider": provider,
					"error": "Environment variable is missing or empty: %s" % api_key_env_name,
				},
				json_output,
			)
			return 2
	elif not api_key_file_path.is_empty():
		key_source = "file"
		var file_result := _parser.read_secret_from_file(api_key_file_path)
		if not bool(file_result.get("ok", false)):
			_parser.output_payload(
				{
					"ok": false,
					"command": "set-api-key",
					"provider": provider,
					"error": String(file_result.get("error", "Unable to read API key file")),
				},
				json_output,
			)
			return 2
		api_key = String(file_result.get("value", "")).strip_edges()
	if not clear_mode and api_key.is_empty():
		_parser.output_payload(
			{
				"ok": false,
				"command": "set-api-key",
				"provider": provider,
				"error": "Missing required option: --api-key=<value> (or --api-key-env / --api-key-file)",
			},
			json_output,
		)
		return 2
	if clear_mode:
		key_source = "clear"
	var property_name := String(CLICommandParser.API_KEY_PROVIDER_PROPERTIES.get(provider, ""))
	if property_name.is_empty():
		_parser.output_payload(
			{
				"ok": false,
				"command": "set-api-key",
				"provider": provider,
				"error": "Provider is not configurable for API key",
			},
			json_output,
		)
		return 2
	var provider_value := int(CLICommandParser.API_KEY_PROVIDER_ENUMS.get(provider, -1))
	if provider_value < 0:
		_parser.output_payload(
			{
				"ok": false,
				"command": "set-api-key",
				"provider": provider,
				"error": "Provider enum mapping unavailable",
			},
			json_output,
		)
		return 2
	var target_key := "" if clear_mode else api_key
	var key_apply_ok := true
	if ai_manager.has_method("set_provider_api_key"):
		key_apply_ok = bool(ai_manager.call("set_provider_api_key", provider_value, target_key))
	else:
		ai_manager.set(property_name, target_key)
	if not key_apply_ok:
		_parser.output_payload(
			{
				"ok": false,
				"command": "set-api-key",
				"provider": provider,
				"error": "Failed to apply API key",
			},
			json_output,
		)
		return 1
	if _parser.has_flag(args, "--set-current"):
		ai_manager.set("current_provider", provider_value)
	if ai_manager.has_method("save_ai_settings"):
		ai_manager.save_ai_settings()
	if ai_manager.has_method("load_ai_settings"):
		ai_manager.load_ai_settings()
	var effective_key := ""
	if ai_manager.has_method("get_provider_api_key"):
		effective_key = String(ai_manager.call("get_provider_api_key", provider_value))
	else:
		effective_key = String(ai_manager.get(property_name))
	var applied_ok := (clear_mode and effective_key.is_empty()) or (not clear_mode and not effective_key.is_empty())
	_parser.output_payload(
		{
			"ok": applied_ok,
			"command": "set-api-key",
			"provider": provider,
			"cleared": clear_mode,
			"configured": not effective_key.is_empty(),
			"source": key_source,
			"key_masked": _parser.mask_secret(effective_key),
		},
		json_output,
	)
	return 0 if applied_ok else 1
func handle_ai_usage(args: Array[String], json_output: bool) -> int:
	var ai_manager := _parser.get_ai_manager()
	if ai_manager == null:
		_parser.output_payload(
			{
				"ok": false,
				"command": "ai-usage",
				"error": "AIManager service unavailable",
			},
			json_output,
		)
		return 1
	var detailed := _parser.has_flag(args, "--detailed") or _parser.has_flag(args, "--verbose")
	var request_manager: Node = null
	if ai_manager.has_method("get"):
		request_manager = ai_manager.get("_request_manager")
	if request_manager == null:
		_parser.output_payload(
			{
				"ok": false,
				"command": "ai-usage",
				"error": "AI Request Manager unavailable",
			},
			json_output,
		)
		return 1
	var cumulative_tokens := 0
	var cumulative_input_tokens := 0
	var cumulative_output_tokens := 0
	var cumulative_calls := 0
	var last_input_tokens := 0
	var last_output_tokens := 0
	var last_response_time := 0.0
	var first_request_timestamp := ""
	if request_manager.has_method("get"):
		cumulative_tokens = int(request_manager.get("_cumulative_tokens_consumed"))
		cumulative_input_tokens = int(request_manager.get("_cumulative_input_tokens"))
		cumulative_output_tokens = int(request_manager.get("_cumulative_output_tokens"))
		cumulative_calls = int(request_manager.get("_cumulative_api_calls"))
		last_input_tokens = int(request_manager.get("_last_input_tokens"))
		last_output_tokens = int(request_manager.get("_last_output_tokens"))
		first_request_timestamp = String(request_manager.get("_first_request_timestamp"))
		var response_history: Array = request_manager.get("_response_time_history")
		if response_history.size() > 0:
			last_response_time = float(response_history[response_history.size() - 1])
	var payload := {
		"ok": true,
		"command": "ai-usage",
		"total_api_calls": cumulative_calls,
		"total_tokens": cumulative_tokens,
		"total_input_tokens": cumulative_input_tokens,
		"total_output_tokens": cumulative_output_tokens,
		"last_request": {
			"input_tokens": last_input_tokens,
			"output_tokens": last_output_tokens,
			"total_tokens": last_input_tokens + last_output_tokens,
			"response_time_seconds": last_response_time,
		},
	}
	if not first_request_timestamp.is_empty():
		payload["first_request_timestamp"] = first_request_timestamp
	if detailed and request_manager.has_method("get"):
		var token_history: Array = request_manager.get("_token_usage_history")
		var response_history: Array = request_manager.get("_response_time_history")
		payload["token_usage_history"] = token_history
		payload["response_time_history"] = response_history
		if token_history.size() > 0:
			var avg_tokens := 0.0
			for tokens in token_history:
				avg_tokens += float(tokens)
			avg_tokens /= float(token_history.size())
			payload["average_tokens_per_request"] = avg_tokens
		if response_history.size() > 0:
			var avg_time := 0.0
			for time in response_history:
				avg_time += float(time)
			avg_time /= float(response_history.size())
			payload["average_response_time_seconds"] = avg_time
	_parser.output_payload(payload, json_output)
	return 0
