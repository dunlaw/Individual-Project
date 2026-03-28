extends Node
var _passed: int = 0
var _failed: int = 0
func _ready() -> void:
	print("\n[PolishRegressionTest] Starting polish regression checks...")
	await get_tree().process_frame
	_test_service_locator_getters()
	_test_game_state_public_api()
	await _test_scene_smoke()
	_test_ai_request_manager_api()
	_test_ai_settings_persistence_roundtrip()
	_test_ai_detailed_log_settings_roundtrip()
	_test_ai_request_manager_fallback_behavior()
	_test_ai_call_log_detail_capture_toggle()
	_test_ai_log_detail_renderer_format()
	_test_mock_generator_story_purpose_coverage()
	_test_mock_request_short_circuit_path()
	_test_mock_mode_allows_long_prompts()
	_test_ai_rate_limit_metadata_context()
	_test_journal_state_roundtrip()
	await _test_journal_open_does_not_auto_request_ai()
	print("[PolishRegressionTest] Completed. Passed=%d Failed=%d" % [_passed, _failed])
	queue_free()
func _assert_test(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		print("   PASS: %s" % label)
	else:
		_failed += 1
		print("   FAIL: %s" % label)
func _test_service_locator_getters() -> void:
	_assert_test(ServiceLocator != null, "ServiceLocator autoload exists")
	_assert_test(ServiceLocator.has_method("get_skill_manager"), "ServiceLocator exposes get_skill_manager")
	_assert_test(ServiceLocator.has_method("get_game_agent_server"), "ServiceLocator exposes get_game_agent_server")
	_assert_test(ServiceLocator.has_method("get_cli_runner"), "ServiceLocator exposes get_cli_runner")
	var skill_manager = ServiceLocator.get_skill_manager() if ServiceLocator else null
	_assert_test(skill_manager != null, "ServiceLocator can resolve SkillManager")
	var agent_server = ServiceLocator.get_game_agent_server() if ServiceLocator else null
	_assert_test(agent_server != null, "ServiceLocator can resolve GameAgentServer")
	var cli_runner = ServiceLocator.get_cli_runner() if ServiceLocator else null
	_assert_test(cli_runner != null, "ServiceLocator can resolve CLIRunner")
func _test_game_state_public_api() -> void:
	_assert_test(GameState != null, "GameState autoload exists")
	_assert_test(GameState.has_method("clear_all_debuffs"), "GameState exposes clear_all_debuffs()")
	var clear_result: Variant = GameState.clear_all_debuffs()
	_assert_test(clear_result is bool, "clear_all_debuffs() returns bool")
	_assert_test(GameState.player_stats is Dictionary, "GameState.player_stats is Dictionary")
	_assert_test(GameState.player_skills is Dictionary, "GameState.player_skills compatibility alias works")
func _test_scene_smoke() -> void:
	var scene_paths := [
		"res://1.Codebase/src/scenes/ui/settings_menu.tscn",
		"res://1.Codebase/src/scenes/ui/ai_settings_menu.tscn",
		"res://1.Codebase/src/scenes/ui/journal_system.tscn",
		"res://1.Codebase/src/scenes/ui/gameplay_stats_viewer.tscn",
	]
	for path in scene_paths:
		var packed: PackedScene = load(path)
		_assert_test(packed != null, "Scene loads: %s" % path.get_file())
		if packed == null:
			continue
		var instance: Node = packed.instantiate()
		_assert_test(instance != null, "Scene instantiates: %s" % path.get_file())
		if instance == null:
			continue
		add_child(instance)
		await get_tree().process_frame
		instance.queue_free()
		await get_tree().process_frame
func _test_ai_request_manager_api() -> void:
	var script: GDScript = load("res://1.Codebase/src/scripts/core/ai/managers/ai_request_manager.gd")
	_assert_test(script != null, "AIRequestManager script loads")
	if script == null:
		return
	var manager = script.new()
	_assert_test(manager != null, "AIRequestManager can instantiate")
	if manager == null:
		return
	_assert_test(manager.has_method("request_ai"), "AIRequestManager exposes request_ai()")
	_assert_test(manager.has_method("set_mock_override"), "AIRequestManager exposes set_mock_override()")
	_assert_test(manager.has_method("reset_cumulative_stats"), "AIRequestManager exposes reset_cumulative_stats()")
func _test_ai_settings_persistence_roundtrip() -> void:
	_assert_test(AIManager != null, "AIManager autoload exists")
	if AIManager == null:
		return
	var original_model := String(AIManager.gemini_model)
	var original_tone := String(AIManager.custom_ai_tone_style)
	var sentinel_model := "gemini-3-flash-preview"
	var sentinel_tone := "polish_regression_settings_persist"
	AIManager.gemini_model = sentinel_model
	AIManager.custom_ai_tone_style = sentinel_tone
	AIManager.save_ai_settings()
	AIManager.gemini_model = "gemini-3.1-flash-lite-preview"
	AIManager.custom_ai_tone_style = "temporary_override_for_test"
	AIManager.load_ai_settings()
	_assert_test(String(AIManager.gemini_model) == sentinel_model, "AI settings persist: gemini_model roundtrip")
	_assert_test(String(AIManager.custom_ai_tone_style) == sentinel_tone, "AI settings persist: tone style roundtrip")
	AIManager.gemini_model = original_model
	AIManager.custom_ai_tone_style = original_tone
	AIManager.save_ai_settings()
func _test_ai_detailed_log_settings_roundtrip() -> void:
	_assert_test(AIManager != null, "AI detailed log setting: AIManager autoload exists")
	if AIManager == null:
		return
	var original_enabled := bool(AIManager.save_detailed_ai_call_logs)
	AIManager.save_detailed_ai_call_logs = false
	AIManager.save_ai_settings()
	AIManager.save_detailed_ai_call_logs = true
	AIManager.load_ai_settings()
	_assert_test(
		not bool(AIManager.save_detailed_ai_call_logs),
		"AI detailed log setting persists across save/load",
	)
	AIManager.save_detailed_ai_call_logs = original_enabled
	AIManager.save_ai_settings()
class _StubDebugProvider:
	extends RefCounted
	func get_debug_snapshot() -> Dictionary:
		return {
			"request": {
				"protocol": "openai",
				"endpoint": "http://127.0.0.1:8046/v1/chat/completions",
				"body": "{\"max_tokens\":128,\"messages\":[{\"role\":\"user\",\"content\":\"hello\"}],\"model\":\"stub-model\"}",
			},
			"response": {
				"status_code": 200,
				"body": "{\"id\":\"resp_1\",\"choices\":[{\"message\":{\"role\":\"assistant\",\"content\":\"world\"}}]}",
			},
		}
class _StubDebugProviderManager:
	extends RefCounted
	var provider := _StubDebugProvider.new()
	func get_current_provider_name() -> String:
		return "AI_ROUTER"
	func get_current_provider() -> RefCounted:
		return provider
func _test_ai_request_manager_fallback_behavior() -> void:
	var manager_script: GDScript = load("res://1.Codebase/src/scripts/core/ai/managers/ai_request_manager.gd")
	var config_script: GDScript = load("res://1.Codebase/src/scripts/core/ai/managers/ai_config_manager.gd")
	_assert_test(manager_script != null, "AIRequestManager script loads for fallback test")
	_assert_test(config_script != null, "AIConfigManager script loads for fallback test")
	if manager_script == null or config_script == null:
		return
	var manager = manager_script.new()
	var config = config_script.new()
	if manager == null or config == null:
		_assert_test(false, "Fallback test setup can instantiate manager/config")
		return
	manager.set_config_manager(config)
	config.current_provider = 0
	config.gemini_api_key = ""
	config.openrouter_api_key = ""
	_assert_test(manager._should_use_mock(false), "Fallback: uses mock when API keys are missing")
	config.gemini_api_key = "test_key"
	_assert_test(not manager._should_use_mock(false), "Fallback: uses live mode when provider key exists")
	manager.set_mock_override(true, "regression_test")
	_assert_test(manager._should_use_mock(false), "Fallback: mock override forces mock mode")
	manager.set_mock_override(false)
	config.current_provider = config_script.AIProvider.MOCK_MODE
	_assert_test(manager._should_use_mock(false), "Fallback: explicit Mock provider always stays in mock mode")
	config.current_provider = config_script.AIProvider.OLLAMA
	config.gemini_api_key = ""
	config.openrouter_api_key = ""
	_assert_test(not manager._should_use_mock(false), "Fallback: Ollama provider does not depend on cloud API keys")
	config.current_provider = config_script.AIProvider.OPENAI
	config.openai_api_key = ""
	_assert_test(manager._should_use_mock(false), "Fallback: OpenAI provider uses mock when API key is missing")
	config.openai_api_key = "test_openai_key"
	_assert_test(not manager._should_use_mock(false), "Fallback: OpenAI provider uses live mode when key exists")
	manager._active_request_payload = { "prompt": "test prompt", "force_mock": false }
	_assert_test(
		manager._should_trigger_fallback("network error", { "status_code": 503 }),
		"Fallback: recoverable provider failures trigger mock fallback",
	)
	manager._active_request_payload = { "prompt": "test prompt", "force_mock": true }
	_assert_test(
		not manager._should_trigger_fallback("network error", { "status_code": 503 }),
		"Fallback: force_mock requests skip emergency fallback",
	)
func _test_ai_call_log_detail_capture_toggle() -> void:
	var manager_script: GDScript = load("res://1.Codebase/src/scripts/core/ai/managers/ai_request_manager.gd")
	var config_script: GDScript = load("res://1.Codebase/src/scripts/core/ai/managers/ai_config_manager.gd")
	_assert_test(manager_script != null, "AI detailed log capture: request manager script loads")
	_assert_test(config_script != null, "AI detailed log capture: config manager script loads")
	if manager_script == null or config_script == null:
		return
	var manager = manager_script.new()
	var config = config_script.new()
	if manager == null or config == null:
		_assert_test(false, "AI detailed log capture: test setup can instantiate manager/config")
		return
	manager.set_config_manager(config)
	manager.set_provider_manager(_StubDebugProviderManager.new())
	config.current_provider = config_script.AIProvider.AI_ROUTER
	config.ai_router_model = "stub-model"
	manager._active_request_payload = {
		"context": { "purpose": "new_mission" },
	}
	config.save_detailed_ai_call_logs = true
	manager.clear_call_log()
	manager._record_call_log(true, "live", 200, 10, 12, 1.25)
	var detailed_entry: Dictionary = manager.get_call_log().back()
	_assert_test(
		bool(detailed_entry.get("detail_available", false)),
		"AI detailed log capture stores request/response bodies when enabled",
	)
	_assert_test(
		str(detailed_entry.get("request_body", "")).find("\"messages\"") != -1,
		"AI detailed log capture stores request payload text",
	)
	config.save_detailed_ai_call_logs = false
	manager.clear_call_log()
	manager._record_call_log(true, "live", 200, 10, 12, 1.25)
	var summary_entry: Dictionary = manager.get_call_log().back()
	_assert_test(
		not bool(summary_entry.get("detail_available", false)),
		"AI detailed log capture omits request/response bodies when disabled",
	)
func _test_ai_log_detail_renderer_format() -> void:
	var renderer_script: GDScript = load("res://1.Codebase/src/scripts/ui/settings_menu_ai_log_renderer.gd")
	_assert_test(renderer_script != null, "AI log detail renderer: script loads")
	if renderer_script == null:
		return
	var detail_text := renderer_script.format_detail_text(
		{
			"request_timestamp": "2026-03-28T20:00:40",
			"duration_msec": 18028,
			"input_tokens": 8599,
			"output_tokens": 588,
			"protocol": "openai",
			"request_endpoint": "http://127.0.0.1:8046/v1/chat/completions",
			"provider": "AI_ROUTER",
			"model": "gemini-3-flash-agent",
			"account": "tester@example.com",
			"purpose": "choice_followup",
			"request_body": "{\"messages\":[{\"role\":\"user\",\"content\":\"hello\"}]}",
			"response_body": "{\"choices\":[{\"message\":{\"role\":\"assistant\",\"content\":\"world\"}}]}",
		},
		func(key: String, fallback: String) -> String:
			return fallback
	)
	_assert_test(
		detail_text.find("Request Time") != -1 and detail_text.find("Response (Response)") != -1,
		"AI log detail renderer includes high-level request/response sections",
	)
	_assert_test(
		detail_text.find("\"messages\"") != -1 and detail_text.find("\"choices\"") != -1,
		"AI log detail renderer includes formatted request and response JSON bodies",
	)
func _test_mock_generator_story_purpose_coverage() -> void:
	var mock_script: GDScript = load("res://1.Codebase/src/scripts/core/mock_ai_generator.gd")
	_assert_test(mock_script != null, "Mock generator script loads for purpose coverage test")
	if mock_script == null:
		return
	var mission_raw: String = String(mock_script.generate_response("Mission", { "purpose": "new_mission", "language": "en" }))
	var mission_parser := JSON.new()
	var mission_ok := mission_parser.parse(mission_raw) == OK and mission_parser.data is Dictionary
	var mission_data: Dictionary = mission_parser.data if mission_ok and mission_parser.data is Dictionary else {}
	_assert_test(mission_ok, "Mock generator: new_mission returns valid JSON")
	_assert_test(
		mission_data.has("story_text") and mission_data.has("choices"),
		"Mock generator: new_mission payload includes story_text and choices",
	)
	var intro_raw: String = String(mock_script.generate_response("Intro", { "purpose": "intro_story", "language": "en" }))
	var intro_parser := JSON.new()
	var intro_ok := intro_parser.parse(intro_raw) == OK and intro_parser.data is Dictionary
	_assert_test(intro_ok, "Mock generator: intro_story returns mission-compatible JSON")
	var followup_raw: String = String(mock_script.generate_response("Followup", { "purpose": "choice_followup", "language": "en" }))
	var followup_parser := JSON.new()
	var followup_ok := followup_parser.parse(followup_raw) == OK and followup_parser.data is Dictionary
	var followup_data: Dictionary = followup_parser.data if followup_ok and followup_parser.data is Dictionary else {}
	_assert_test(followup_ok, "Mock generator: choice_followup returns valid JSON")
	_assert_test(
		followup_data.has("choices"),
		"Mock generator: choice_followup payload includes choices array",
	)
	var night_raw: String = String(mock_script.generate_response("Night", { "purpose": "night_cycle", "language": "en" }))
	var night_parser := JSON.new()
	var night_ok := night_parser.parse(night_raw) == OK and night_parser.data is Dictionary
	var night_data: Dictionary = night_parser.data if night_ok and night_parser.data is Dictionary else {}
	_assert_test(night_ok, "Mock generator: night_cycle returns valid JSON")
	_assert_test(
		night_data.has("concert_lyrics") and night_data.has("prayer_prompt"),
		"Mock generator: night_cycle payload includes expected keys",
	)
class _TrackingContextManager:
	extends AIContextManager
	var build_calls: int = 0
	var add_calls: int = 0
	func _init() -> void:
		var memory_script: GDScript = load("res://1.Codebase/src/scripts/core/ai_memory_store.gd")
		if memory_script != null:
			memory_store = memory_script.new()
	func build_request_messages(prompt: String, _context: Dictionary) -> Array[Dictionary]:
		build_calls += 1
		return [{ "role": "user", "content": prompt }]
	func add_to_memory(role: String, content: String, _extra_data: Dictionary = {}) -> void:
		add_calls += 1
		if memory_store and memory_store.story_memory is Array:
			memory_store.story_memory.append({ "role": role, "content": content })
func _test_mock_request_short_circuit_path() -> void:
	var manager_script: GDScript = load("res://1.Codebase/src/scripts/core/ai/managers/ai_request_manager.gd")
	var config_script: GDScript = load("res://1.Codebase/src/scripts/core/ai/managers/ai_config_manager.gd")
	_assert_test(manager_script != null, "Mock short-circuit: AIRequestManager script loads")
	_assert_test(config_script != null, "Mock short-circuit: AIConfigManager script loads")
	if manager_script == null or config_script == null:
		return
	var manager = manager_script.new()
	var config = config_script.new()
	if manager == null or config == null:
		_assert_test(false, "Mock short-circuit: test setup can instantiate manager/config")
		return
	config.current_provider = config_script.AIProvider.MOCK_MODE
	manager.set_config_manager(config)
	var mock_context := _TrackingContextManager.new()
	manager.set_context_manager(mock_context)
	var captured_responses: Array = []
	manager.response_received.connect(func(response: Dictionary): captured_responses.append(response))
	manager.request_ai("offline short circuit check", Callable(), { "purpose": "new_mission" })
	_assert_test(
		mock_context.build_calls == 0,
		"Mock short-circuit: request avoids full context builder in mock mode",
	)
	_assert_test(
		mock_context.add_calls >= 2,
		"Mock short-circuit: user + assistant messages still recorded to memory",
	)
	_assert_test(
		captured_responses.size() > 0 and bool((captured_responses[0] as Dictionary).get("success", false)),
		"Mock short-circuit: request still returns successful offline response",
	)
func _test_mock_mode_allows_long_prompts() -> void:
	var manager_script: GDScript = load("res://1.Codebase/src/scripts/core/ai/managers/ai_request_manager.gd")
	var config_script: GDScript = load("res://1.Codebase/src/scripts/core/ai/managers/ai_config_manager.gd")
	_assert_test(manager_script != null, "Mock long prompt: AIRequestManager script loads")
	_assert_test(config_script != null, "Mock long prompt: AIConfigManager script loads")
	if manager_script == null or config_script == null:
		return
	var manager = manager_script.new()
	var config = config_script.new()
	if manager == null or config == null:
		_assert_test(false, "Mock long prompt: test setup can instantiate manager/config")
		return
	config.current_provider = config_script.AIProvider.MOCK_MODE
	manager.set_config_manager(config)
	var response_events: Array[Dictionary] = []
	var error_events: Array[String] = []
	manager.response_received.connect(func(response: Dictionary): response_events.append(response))
	manager.request_error.connect(func(message: String): error_events.append(message))
	var long_prompt := "x".repeat(GameConstants.AI.PROMPT_MAX_LENGTH + 200)
	manager.request_ai(long_prompt, Callable(), { "purpose": "new_mission" })
	_assert_test(error_events.is_empty(), "Mock long prompt: no invalid prompt error emitted")
	_assert_test(response_events.size() > 0, "Mock long prompt: request succeeds with mock response")
class _MockRateLimiter:
	extends RefCounted
	func attempt() -> Dictionary:
		return {
			"allowed": false,
			"retry_after_msec": 1200,
		}
func _test_ai_rate_limit_metadata_context() -> void:
	var manager_script: GDScript = load("res://1.Codebase/src/scripts/core/ai/managers/ai_request_manager.gd")
	_assert_test(manager_script != null, "Rate-limit metadata: AIRequestManager script loads")
	if manager_script == null:
		return
	var manager = manager_script.new()
	if manager == null:
		_assert_test(false, "Rate-limit metadata: test setup can instantiate manager")
		return
	_rate_limit_signal_fired = false
	_rate_limit_captured_purpose = ""
	manager._active_request_payload = {
		"prompt": "rate-limit metadata test",
		"context": { "purpose": "journal_prompt" },
		"force_mock": false,
	}
	manager._rate_limiter = _MockRateLimiter.new()
	manager.request_error.connect(_on_rate_limit_test_error.bind(manager))
	manager._handle_rate_limit_with_callback(Callable())
	_assert_test(_rate_limit_signal_fired, "Rate-limit metadata: request_error signal emitted")
	_assert_test(
		_rate_limit_captured_purpose == "journal_prompt",
		"Rate-limit metadata: purpose preserved for event filtering",
	)
var _rate_limit_signal_fired: bool = false
var _rate_limit_captured_purpose: String = ""
func _on_rate_limit_test_error(_message: String, manager) -> void:
	_rate_limit_signal_fired = true
	var metadata: Dictionary = manager.get_active_request_metadata()
	_rate_limit_captured_purpose = String(metadata.get("purpose", ""))
func _test_journal_state_roundtrip() -> void:
	_assert_test(GameState != null, "GameState autoload exists for journal roundtrip")
	if GameState == null:
		return
	var original_snapshot: Dictionary = GameState.get_save_data()
	var sentinel_entry := {
		"id": "polish_journal_entry_1",
		"timestamp": "2026-02-20 00:00:00",
		"text": "Regression sentinel entry",
		"type": "custom",
		"source": "test",
		"reality_gain": 1,
		"ai_summary": "summary",
		"ai_summary_pending": false,
	}
	GameState.set_journal_entries([sentinel_entry])
	GameState.set_latest_story_summary("polish_journal_summary_sentinel")
	var mutated_snapshot: Dictionary = GameState.get_save_data()
	GameState.set_journal_entries([])
	GameState.set_latest_story_summary("")
	GameState.load_save_data(mutated_snapshot)
	var loaded_entries: Array = GameState.get_journal_entries()
	var loaded_summary: String = GameState.get_latest_story_summary("")
	var first_entry: Dictionary = loaded_entries[0] if loaded_entries.size() > 0 and loaded_entries[0] is Dictionary else { }
	var entry_roundtrip_ok := loaded_entries.size() == 1 and str(first_entry.get("id", "")) == "polish_journal_entry_1"
	_assert_test(entry_roundtrip_ok, "Journal roundtrip: entry payload restored from save snapshot")
	_assert_test(loaded_summary == "polish_journal_summary_sentinel", "Journal roundtrip: latest story summary restored")
	GameState.load_save_data(original_snapshot)
func _test_journal_open_does_not_auto_request_ai() -> void:
	var journal_scene: PackedScene = load("res://1.Codebase/src/scenes/ui/journal_system.tscn")
	_assert_test(journal_scene != null, "Journal open: scene loads for AI request regression check")
	if journal_scene == null:
		return
	var journal_instance: Node = journal_scene.instantiate()
	_assert_test(journal_instance != null, "Journal open: scene instantiates for AI request regression check")
	if journal_instance == null:
		return
	add_child(journal_instance)
	await get_tree().process_frame
	var suggestion_in_flight := bool(journal_instance.get("_suggestion_in_flight"))
	var story_summary_in_flight := bool(journal_instance.get("_story_summary_in_flight"))
	_assert_test(
		not suggestion_in_flight,
		"Journal open: suggestions should not auto trigger AI request",
	)
	_assert_test(
		not story_summary_in_flight,
		"Journal open: story summary should not auto trigger AI request",
	)
	journal_instance.queue_free()
	await get_tree().process_frame
