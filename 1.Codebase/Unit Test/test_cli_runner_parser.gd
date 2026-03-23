extends Node
var _passed: int = 0
var _failed: int = 0
var _cli_runner: Node = null
func _ready() -> void:
	print("\n[CLIRunnerParserTest] Starting parser unit tests...")
	await get_tree().process_frame
	_resolve_cli_runner()
	_test_command_aliases()
	_test_slot_option_parsing()
	_test_limit_option_parsing()
	_test_language_normalization()
	_test_provider_normalization()
	_test_api_key_provider_normalization()
	_test_scenario_lookup()
	print("[CLIRunnerParserTest] Completed. Passed=%d Failed=%d" % [_passed, _failed])
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
func _test_command_aliases() -> void:
	if _cli_runner == null:
		return
	_assert_test(
		String(_cli_runner.call("_canonical_command", "new")) == "new-game",
		"Alias 'new' resolves to new-game"
	)
	_assert_test(
		String(_cli_runner.call("_canonical_command", "lang")) == "set-language",
		"Alias 'lang' resolves to set-language"
	)
	_assert_test(
		String(_cli_runner.call("_canonical_command", "provider")) == "set-provider",
		"Alias 'provider' resolves to set-provider"
	)
	_assert_test(
		String(_cli_runner.call("_canonical_command", "providers")) == "ai-status",
		"Alias 'providers' resolves to ai-status"
	)
	_assert_test(
		String(_cli_runner.call("_canonical_command", "list-providers")) == "provider-list",
		"Alias 'list-providers' resolves to provider-list"
	)
	_assert_test(
		String(_cli_runner.call("_canonical_command", "STATUS")) == "status",
		"Command normalization lowercases command names"
	)
func _test_slot_option_parsing() -> void:
	if _cli_runner == null:
		return
	var args_slot_2: Array[String] = ["--slot=2"]
	var valid_result: Dictionary = _cli_runner.call("_resolve_slot_option", args_slot_2, "save", true, true)
	_assert_test(bool(valid_result.get("ok", false)), "Slot parser accepts valid slot")
	_assert_test(int(valid_result.get("slot", -1)) == 2, "Slot parser returns parsed slot value")
	var args_slot_invalid: Array[String] = ["--slot=abc"]
	var invalid_type: Dictionary = _cli_runner.call("_resolve_slot_option", args_slot_invalid, "save", true, true)
	_assert_test(not bool(invalid_type.get("ok", true)), "Slot parser rejects non-numeric slot")
	var args_slot_99: Array[String] = ["--slot=99"]
	var out_of_range: Dictionary = _cli_runner.call("_resolve_slot_option", args_slot_99, "save", true, true)
	_assert_test(not bool(out_of_range.get("ok", true)), "Slot parser rejects out-of-range slot")
	var empty_args: Array[String] = []
	var missing_optional: Dictionary = _cli_runner.call("_resolve_slot_option", empty_args, "save", true, true)
	_assert_test(bool(missing_optional.get("ok", false)), "Slot parser allows missing slot when optional")
	_assert_test(not bool(missing_optional.get("provided", true)), "Optional missing slot returns provided=false")
func _test_limit_option_parsing() -> void:
	if _cli_runner == null:
		return
	var empty_args: Array[String] = []
	var default_result: Dictionary = _cli_runner.call("_resolve_limit_option", empty_args, "events", true)
	_assert_test(bool(default_result.get("ok", false)), "Limit parser accepts missing limit")
	_assert_test(int(default_result.get("limit", -1)) == 6, "Limit parser applies default limit")
	var args_limit_0: Array[String] = ["--limit=0"]
	var lower_clamp: Dictionary = _cli_runner.call("_resolve_limit_option", args_limit_0, "events", true)
	_assert_test(int(lower_clamp.get("limit", 0)) == 1, "Limit parser clamps minimum to 1")
	var args_limit_999: Array[String] = ["--limit=999"]
	var upper_clamp: Dictionary = _cli_runner.call("_resolve_limit_option", args_limit_999, "events", true)
	_assert_test(int(upper_clamp.get("limit", 0)) == 100, "Limit parser clamps maximum to 100")
	var args_limit_bad: Array[String] = ["--limit=notanumber"]
	var invalid_limit: Dictionary = _cli_runner.call("_resolve_limit_option", args_limit_bad, "events", true)
	_assert_test(not bool(invalid_limit.get("ok", true)), "Limit parser rejects invalid input")
func _test_language_normalization() -> void:
	if _cli_runner == null:
		return
	_assert_test(
		String(_cli_runner.call("_normalize_language", "zh-tw")) == "zh",
		"Language parser normalizes zh variants"
	)
	_assert_test(
		String(_cli_runner.call("_normalize_language", "english")) == "en",
		"Language parser normalizes english alias"
	)
	_assert_test(
		String(_cli_runner.call("_normalize_language", "jp")) == "",
		"Language parser returns empty string for unsupported language"
	)
func _test_provider_normalization() -> void:
	if _cli_runner == null:
		return
	_assert_test(
		String(_cli_runner.call("_normalize_provider", "lm-studio")) == "lmstudio",
		"Provider parser normalizes lm-studio alias"
	)
	_assert_test(
		String(_cli_runner.call("_normalize_provider", "offline")) == "ollama",
		"Provider parser normalizes offline alias"
	)
	_assert_test(
		String(_cli_runner.call("_normalize_provider", "offline-mode")) == "mock",
		"Provider parser normalizes offline-mode alias"
	)
	_assert_test(
		String(_cli_runner.call("_normalize_provider", "offline mode")) == "mock",
		"Provider parser normalizes spaced offline mode alias"
	)
	_assert_test(
		String(_cli_runner.call("_normalize_provider", "mock-mode")) == "mock",
		"Provider parser normalizes mock-mode alias"
	)
	_assert_test(
		String(_cli_runner.call("_normalize_provider", "mock_mode")) == "mock",
		"Provider parser normalizes mock_mode alias"
	)
	_assert_test(
		String(_cli_runner.call("_normalize_provider", "unsupported")) == "",
		"Provider parser rejects unsupported providers"
	)
func _test_api_key_provider_normalization() -> void:
	if _cli_runner == null:
		return
	_assert_test(
		String(_cli_runner.call("_normalize_api_key_provider", "open-router")) == "openrouter",
		"API key provider parser normalizes open-router alias"
	)
	_assert_test(
		String(_cli_runner.call("_normalize_api_key_provider", "anthropic")) == "claude",
		"API key provider parser normalizes anthropic alias"
	)
	_assert_test(
		String(_cli_runner.call("_normalize_api_key_provider", "router")) == "ai-router",
		"API key provider parser normalizes router alias"
	)
	_assert_test(
		String(_cli_runner.call("_normalize_api_key_provider", "unsupported")) == "",
		"API key provider parser rejects unsupported provider"
	)
func _test_scenario_lookup() -> void:
	if _cli_runner == null:
		return
	var ids: Array = _cli_runner.call("_get_scenario_ids")
	_assert_test(ids.size() > 0, "Scenario list returns at least one id")
	_assert_test("ash_echo_relay" in ids, "Scenario list includes ash_echo_relay")
	var scenario: Dictionary = _cli_runner.call("_find_scenario_by_id", "ash_echo_relay")
	_assert_test(not scenario.is_empty(), "Scenario lookup returns data for valid id")
	_assert_test(String(scenario.get("id", "")) == "ash_echo_relay", "Scenario lookup returns matching id")
	var missing: Dictionary = _cli_runner.call("_find_scenario_by_id", "missing_id")
	_assert_test(missing.is_empty(), "Scenario lookup returns empty dictionary for missing id")
