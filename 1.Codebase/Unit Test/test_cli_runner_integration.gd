extends Node
var _passed: int = 0
var _failed: int = 0
var _cli_runner: Node = null
func _ready() -> void:
	print("\n[CLIRunnerIntegrationTest] Starting command integration tests...")
	await get_tree().process_frame
	_resolve_cli_runner()
	_test_command_execution_paths()
	_test_provider_commands()
	_test_set_api_key_command()
	_test_silent_mode_behavior()
	print("[CLIRunnerIntegrationTest] Completed. Passed=%d Failed=%d" % [_passed, _failed])
	queue_free()
func _assert_test(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		print("   PASS: %s" % label)
	else:
		_failed += 1
		print("   FAIL: %s" % label)
func _resolve_cli_runner() -> void:
	if ServiceLocator != null and ServiceLocator.has_method("get_cli_runner"):
		_cli_runner = ServiceLocator.get_cli_runner()
	_assert_test(_cli_runner != null, "ServiceLocator resolves CLIRunner")
func _test_command_execution_paths() -> void:
	if _cli_runner == null:
		return
	var empty_args: Array[String] = []
	var unknown_code: int = int(_cli_runner.call("_execute_command", "unknown_command_xyz", empty_args, true))
	_assert_test(unknown_code == 2, "Unknown command returns exit code 2")
	var scenario_list_code: int = int(_cli_runner.call("_execute_command", "scenario-list", empty_args, true))
	_assert_test(scenario_list_code == 0, "scenario-list returns success exit code")
	var provider_list_code: int = int(_cli_runner.call("_execute_command", "provider-list", empty_args, true))
	_assert_test(provider_list_code == 0, "provider-list returns success exit code")
	var args_slot_99: Array[String] = ["--slot=99"]
	var invalid_slot_code: int = int(_cli_runner.call("_execute_command", "load", args_slot_99, true))
	_assert_test(invalid_slot_code == 2, "load with invalid slot returns exit code 2")
	var missing_target_code: int = int(_cli_runner.call("_execute_command", "delete-save", empty_args, true))
	_assert_test(missing_target_code == 2, "delete-save without target returns exit code 2")
	var args_limit_bad: Array[String] = ["--limit=oops"]
	var invalid_limit_code: int = int(_cli_runner.call("_execute_command", "events", args_limit_bad, true))
	_assert_test(invalid_limit_code == 2, "events with invalid limit returns exit code 2")
func _test_provider_commands() -> void:
	if _cli_runner == null:
		return
	var ai_manager: Node = null
	if ServiceLocator != null and ServiceLocator.has_method("get_ai_manager"):
		ai_manager = ServiceLocator.get_ai_manager()
	_assert_test(ai_manager != null, "ServiceLocator resolves AIManager for provider command tests")
	if ai_manager == null:
		return
	var original_provider := int(ai_manager.get("current_provider"))
	var empty_args: Array[String] = []
	var ai_status_code: int = int(_cli_runner.call("_execute_command", "ai-status", empty_args, true))
	_assert_test(ai_status_code == 0, "ai-status returns success exit code")
	var args_invalid_provider: Array[String] = ["--provider=not-a-provider"]
	var invalid_provider_code: int = int(_cli_runner.call("_execute_command", "set-provider", args_invalid_provider, true))
	_assert_test(invalid_provider_code == 2, "set-provider rejects unsupported provider")
	var args_set_provider: Array[String] = ["--provider=ollama"]
	var set_provider_code: int = int(_cli_runner.call("_execute_command", "set-provider", args_set_provider, true))
	_assert_test(set_provider_code == 0, "set-provider accepts valid provider")
	_assert_test(
		String(_cli_runner.call("_get_current_provider", ai_manager)) == "ollama",
		"set-provider updates current provider"
	)
	var args_set_provider_positional: Array[String] = ["mock"]
	var positional_provider_code: int = int(_cli_runner.call("_execute_command", "set-provider", args_set_provider_positional, true))
	_assert_test(positional_provider_code == 0, "set-provider accepts positional provider format")
	_assert_test(
		String(_cli_runner.call("_get_current_provider", ai_manager)) == "mock",
		"set-provider positional provider switches to mock mode"
	)
	var args_set_provider_offline_mode: Array[String] = ["--provider=offline-mode"]
	var offline_mode_code: int = int(_cli_runner.call("_execute_command", "set-provider", args_set_provider_offline_mode, true))
	_assert_test(offline_mode_code == 0, "set-provider accepts offline-mode alias")
	_assert_test(
		String(_cli_runner.call("_get_current_provider", ai_manager)) == "mock",
		"set-provider offline-mode maps to mock mode"
	)
	ai_manager.set("current_provider", original_provider)
	if ai_manager.has_method("save_ai_settings"):
		ai_manager.save_ai_settings()
	if ai_manager.has_method("load_ai_settings"):
		ai_manager.load_ai_settings()
func _test_set_api_key_command() -> void:
	if _cli_runner == null:
		return
	var ai_manager: Node = null
	if ServiceLocator != null and ServiceLocator.has_method("get_ai_manager"):
		ai_manager = ServiceLocator.get_ai_manager()
	_assert_test(ai_manager != null, "ServiceLocator resolves AIManager for API key command test")
	if ai_manager == null:
		return
	var original_key := String(ai_manager.get("openrouter_api_key"))
	var original_provider := int(ai_manager.get("current_provider"))
	var sentinel_key := "cli_test_openrouter_key_1234"
	var env_var_name := "CLI_TEST_OPENROUTER_KEY"
	var env_key := "cli_test_env_openrouter_5678"
	var file_key := "cli_test_file_openrouter_9012"
	var key_file_path := "user://cli_test_openrouter_key.txt"
	var args_invalid_provider: Array[String] = ["--provider=unknown", "--api-key=test123"]
	var invalid_provider_code: int = int(_cli_runner.call("_execute_command", "set-api-key", args_invalid_provider, true))
	_assert_test(invalid_provider_code == 2, "set-api-key rejects unknown provider")
	var args_missing_key: Array[String] = ["--provider=openrouter"]
	var missing_key_code: int = int(_cli_runner.call("_execute_command", "set-api-key", args_missing_key, true))
	_assert_test(missing_key_code == 2, "set-api-key requires --api-key when not clearing")
	var args_set_key: Array[String] = ["--provider=openrouter", "--api-key=" + sentinel_key, "--set-current"]
	var set_key_code: int = int(_cli_runner.call("_execute_command", "set-api-key", args_set_key, true))
	_assert_test(set_key_code == 0, "set-api-key succeeds for OpenRouter provider")
	_assert_test(String(ai_manager.get("openrouter_api_key")) == sentinel_key, "set-api-key updates OpenRouter key in AIManager")
	var args_conflicting_sources: Array[String] = ["--provider=openrouter", "--api-key=direct_value", "--api-key-env=" + env_var_name]
	var conflicting_sources_code: int = int(_cli_runner.call("_execute_command", "set-api-key", args_conflicting_sources, true))
	_assert_test(conflicting_sources_code == 2, "set-api-key rejects multiple key sources")
	OS.set_environment(env_var_name, env_key)
	var args_env_key: Array[String] = ["--provider=openrouter", "--api-key-env=" + env_var_name]
	var set_env_key_code: int = int(_cli_runner.call("_execute_command", "set-api-key", args_env_key, true))
	_assert_test(set_env_key_code == 0, "set-api-key supports --api-key-env")
	_assert_test(String(ai_manager.get("openrouter_api_key")) == env_key, "set-api-key env source updates OpenRouter key")
	var key_file := FileAccess.open(key_file_path, FileAccess.WRITE)
	if key_file != null:
		key_file.store_string(file_key + "\n")
		key_file.close()
	var args_file_key: Array[String] = ["--provider=openrouter", "--api-key-file=" + key_file_path]
	var set_file_key_code: int = int(_cli_runner.call("_execute_command", "set-api-key", args_file_key, true))
	_assert_test(set_file_key_code == 0, "set-api-key supports --api-key-file")
	_assert_test(String(ai_manager.get("openrouter_api_key")) == file_key, "set-api-key file source updates OpenRouter key")
	var args_missing_env: Array[String] = ["--provider=openrouter", "--api-key-env=CLI_MISSING_ENV_FOR_TEST"]
	var missing_env_code: int = int(_cli_runner.call("_execute_command", "set-api-key", args_missing_env, true))
	_assert_test(missing_env_code == 2, "set-api-key rejects missing env variable")
	var args_clear_key: Array[String] = ["--provider=openrouter", "--clear-key"]
	var clear_key_code: int = int(_cli_runner.call("_execute_command", "set-api-key", args_clear_key, true))
	_assert_test(clear_key_code == 0, "set-api-key supports --clear-key")
	_assert_test(String(ai_manager.get("openrouter_api_key")) == "", "set-api-key clear removes OpenRouter key")
	OS.set_environment(env_var_name, "")
	var absolute_key_file_path := ProjectSettings.globalize_path(key_file_path)
	if FileAccess.file_exists(key_file_path) or FileAccess.file_exists(absolute_key_file_path):
		DirAccess.remove_absolute(absolute_key_file_path)
	ai_manager.set("openrouter_api_key", original_key)
	ai_manager.set("current_provider", original_provider)
	if ai_manager.has_method("save_ai_settings"):
		ai_manager.save_ai_settings()
	if ai_manager.has_method("load_ai_settings"):
		ai_manager.load_ai_settings()
func _test_silent_mode_behavior() -> void:
	if _cli_runner == null:
		return
	var previous_engine_errors := Engine.print_error_messages
	var previous_console_logs := true
	var previous_notifications := true
	if ErrorReporter != null:
		previous_console_logs = bool(ErrorReporter.enable_console_logs)
		previous_notifications = bool(ErrorReporter.enable_user_notifications)
	_cli_runner.call("_apply_silent_mode")
	_assert_test(Engine.print_error_messages == false, "Silent mode disables engine error printing")
	if ErrorReporter != null:
		_assert_test(ErrorReporter.enable_console_logs == false, "Silent mode disables ErrorReporter console logs")
		_assert_test(ErrorReporter.enable_user_notifications == false, "Silent mode disables ErrorReporter notifications")
	Engine.print_error_messages = previous_engine_errors
	if ErrorReporter != null:
		ErrorReporter.enable_console_logs = previous_console_logs
		ErrorReporter.enable_user_notifications = previous_notifications
