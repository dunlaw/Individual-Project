extends Node
var tests_passed: int = 0
var tests_failed: int = 0
class MockLiveClient:
	extends Node
	signal connection_established()
	signal connection_closed(code, reason)
	signal connection_error()
	signal setup_response_received(response)
	signal server_message_received(message)
	signal error_received(error_message)
	signal session_updated(session_handle)
	var connect_calls: Array = []
	var seeded_history: Array = []
	var close_calls: Array = []
	func connect_to_server(
			model_name: String,
			api_key: String,
			config: Dictionary,
			session_handle: String = "",
			system_instruction: String = "",
			speech_config: Dictionary = { },
			transcription_config: Dictionary = { },
			realtime_input_config: Dictionary = { },
	) -> void:
		connect_calls.append({
			"model_name": model_name,
			"api_key": api_key,
			"config": config.duplicate(true),
			"session_handle": session_handle,
			"system_instruction": system_instruction,
			"speech_config": speech_config.duplicate(true),
			"transcription_config": transcription_config.duplicate(true),
			"realtime_input_config": realtime_input_config.duplicate(true),
		})
	func seed_initial_history(turns: Array) -> void:
		seeded_history = turns.duplicate(true)
	func close_connection(code: int = 1000, reason: String = "Client requested disconnect") -> void:
		close_calls.append({
			"code": code,
			"reason": reason,
		})
class MockVoiceSession:
	extends Node
	func prefers_native_audio() -> bool:
		return true
	func wants_voice_output() -> bool:
		return true
	func wants_voice_input() -> bool:
		return false
	func get_preferred_voice_name() -> String:
		return "Kore"
	func process_transcription_entry(_entry: Variant, _direction: String) -> void:
		pass
func _ready() -> void:
	print("\n" + "=".repeat(80))
	print("   TESTING AI PROVIDERS")
	print("=".repeat(80) + "\n")
	await get_tree().process_frame
	await _test_provider_base_interface()
	await _test_gemini_provider_structure()
	await _test_provider_configuration()
	await _test_gemini_live_request_configuration()
	await _test_gemini_live_transcription_fallback()
	await _test_gemini_live_expected_close()
	await _test_provider_signals()
	await _test_error_handling()
	_print_summary()
	await get_tree().create_timer(0.5).timeout
	queue_free()
func _test_provider_base_interface() -> void:
	print("\n[Test] AIProviderBase interface...")
	var AIProviderBaseScript = load("res://1.Codebase/src/scripts/core/ai/ai_provider_base.gd")
	var base_provider = AIProviderBaseScript.new()
	_assert(base_provider != null, "AIProviderBase should instantiate")
	_assert(base_provider.provider_name == "BaseProvider", "Default provider name should be BaseProvider")
	_assert(base_provider.is_requesting == false, "Should not be requesting initially")
	_assert(base_provider.has_method("send_request"), "Should have send_request method")
	_assert(base_provider.has_method("cancel_request"), "Should have cancel_request method")
	_assert(base_provider.has_method("is_configured"), "Should have is_configured method")
	_assert(base_provider.has_method("get_configuration"), "Should have get_configuration method")
	_assert(base_provider.has_method("apply_configuration"), "Should have apply_configuration method")
	_assert(base_provider.has_method("_emit_error"), "Should have _emit_error helper")
	_assert(base_provider.has_method("_emit_progress"), "Should have _emit_progress helper")
	print("    PASS: AIProviderBase interface")
func _test_gemini_provider_structure() -> void:
	print("\n[Test] GeminiProvider structure...")
	var GeminiProviderScript = load("res://1.Codebase/src/scripts/core/ai/gemini_provider.gd")
	var gemini = GeminiProviderScript.new()
	_assert(gemini != null, "GeminiProvider should instantiate")
	_assert(gemini.provider_name == "Gemini", "Provider name should be Gemini")
	_assert(gemini.GEMINI_ENDPOINT_BASE.begins_with("https://"),
		"Endpoint should use HTTPS")
	_assert(gemini.GEMINI_ENDPOINT_BASE.contains("generativelanguage.googleapis.com"),
		"Endpoint should point to Google API")
	_assert(gemini.GEMINI_DEFAULT_MODEL == "gemini-3.1-flash-lite-preview",
		"Default model should be gemini-3.1-flash-lite-preview")
	_assert(gemini.DEFAULT_OUTPUT_SAMPLE_RATE == 24000,
		"Default sample rate should be 24000")
	_assert(gemini.GEMINI_NATIVE_AUDIO_MODELS is Array,
		"GEMINI_NATIVE_AUDIO_MODELS should be Array")
	_assert(gemini.GEMINI_NATIVE_AUDIO_MODELS.size() > 0,
		"Should have at least one native audio model")
	_assert(gemini.LEGACY_REQUIRED_CHARACTERS is Array,
		"LEGACY_REQUIRED_CHARACTERS should be Array")
	_assert("protagonist" in gemini.LEGACY_REQUIRED_CHARACTERS,
		"Should include protagonist in required characters")
	_assert("gloria" in gemini.LEGACY_REQUIRED_CHARACTERS,
		"Should include gloria in required characters")
	_assert(gemini.LEGACY_BACKGROUND_IDS is Array,
		"LEGACY_BACKGROUND_IDS should be Array")
	_assert(gemini.LEGACY_BACKGROUND_IDS.size() > 10,
		"Should have multiple background IDs")
	_assert(gemini.LEGACY_EXPRESSIONS is Array,
		"LEGACY_EXPRESSIONS should be Array")
	_assert("neutral" in gemini.LEGACY_EXPRESSIONS,
		"Should include neutral expression")
	print("    PASS: GeminiProvider structure")
func _test_provider_configuration() -> void:
	print("\n[Test] Provider configuration...")
	var GeminiProviderScript = load("res://1.Codebase/src/scripts/core/ai/gemini_provider.gd")
	var gemini = GeminiProviderScript.new()
	_assert(gemini.api_key == "", "API key should be empty initially")
	_assert(gemini.model == gemini.GEMINI_DEFAULT_MODEL, "Should use default model")
	_assert(gemini.is_configured() == false, "Should not be configured without API key")
	gemini.api_key = "test_key_123"
	gemini.model = "gemini-pro"
	gemini.project_id = "test-project"
	gemini.location = "us-central1"
	_assert(gemini.api_key == "test_key_123", "API key should be set")
	_assert(gemini.model == "gemini-pro", "Model should be set")
	_assert(gemini.project_id == "test-project", "Project ID should be set")
	_assert(gemini.location == "us-central1", "Location should be set")
	_assert(gemini.is_configured() == true, "Should be configured with API key")
	var config = gemini.get_configuration()
	_assert(config.has("api_key"), "Config should have api_key")
	_assert(config.has("model"), "Config should have model")
	_assert(config.has("project_id"), "Config should have project_id")
	_assert(config.has("location"), "Config should have location")
	_assert(config["api_key"] == "test_key_123", "Config should return correct API key")
	_assert(config["model"] == "gemini-pro", "Config should return correct model")
	print("    PASS: Provider configuration")
func _test_gemini_live_request_configuration() -> void:
	print("\n[Test] Gemini Live request configuration...")
	var GeminiProviderScript = load("res://1.Codebase/src/scripts/core/ai/gemini_provider.gd")
	var gemini = GeminiProviderScript.new()
	var mock_http := HTTPRequest.new()
	var mock_live := MockLiveClient.new()
	var mock_voice := MockVoiceSession.new()
	add_child(mock_http)
	add_child(mock_live)
	add_child(mock_voice)
	gemini.api_key = "test_key_123"
	gemini.model = "gemini-3.1-flash-live-preview"
	gemini.setup(mock_http, mock_live, mock_voice)
	gemini._send_live_request([
		{ "role": "system", "content": "Speak naturally." },
		{ "role": "assistant", "content": "Previous reply." },
		{ "role": "user", "parts": [{ "text": "Tell me a story." }] },
	])
	_assert(mock_live.connect_calls.size() == 1, "Live request should open exactly one WebSocket session")
	if mock_live.connect_calls.size() > 0:
		var connect_call: Dictionary = mock_live.connect_calls[0]
		_assert(connect_call["config"].has("thinkingConfig"),
			"Gemini 3.1 Live should use thinkingConfig in generation config")
		_assert(connect_call["config"]["thinkingConfig"].get("thinkingLevel", "") == "minimal",
			"Gemini 3.1 Live should default to minimal thinking level")
		_assert(connect_call["realtime_input_config"].get("turnCoverage", "") == "TURN_INCLUDES_ONLY_ACTIVITY",
			"Gemini 3.1 Live should pin turn coverage to activity-only behavior")
		_assert(bool(connect_call["transcription_config"].get("output", false)),
			"Gemini 3.1 Live should enable output transcription for voice responses")
	_assert(mock_live.seeded_history.size() == 1, "Assistant history should be seeded via clientContent before live turn")
	mock_http.queue_free()
	mock_live.queue_free()
	mock_voice.queue_free()
	print("    PASS: Gemini Live request configuration")
func _test_gemini_live_transcription_fallback() -> void:
	print("\n[Test] Gemini Live transcription fallback...")
	var GeminiProviderScript = load("res://1.Codebase/src/scripts/core/ai/gemini_provider.gd")
	var gemini = GeminiProviderScript.new()
	var response_holder := { "data": { } }
	gemini.pending_callback = func(response): response_holder["data"] = response
	gemini.is_requesting = true
	gemini._extract_live_response_chunks({
		"serverContent": {
			"outputTranscription": { "text": "Hello" },
		},
	})
	gemini._extract_live_response_chunks({
		"serverContent": {
			"outputTranscription": { "text": "Hello there" },
		},
	})
	_assert(gemini._live_output_transcription_text == "Hello there",
		"Gemini Live should keep the latest cumulative output transcription")
	gemini._on_live_api_server_message({
		"serverContent": {
			"turnComplete": true,
		},
	})
	var captured_response: Dictionary = response_holder.get("data", {})
	_assert(captured_response.get("content", "") == "Hello there",
		"Gemini Live should fall back to output transcription when no text parts arrive")
	print("    PASS: Gemini Live transcription fallback")
func _test_gemini_live_expected_close() -> void:
	print("\n[Test] Gemini Live expected close handling...")
	var GeminiProviderScript = load("res://1.Codebase/src/scripts/core/ai/gemini_provider.gd")
	var gemini = GeminiProviderScript.new()
	var mock_http := HTTPRequest.new()
	var mock_live := MockLiveClient.new()
	add_child(mock_http)
	add_child(mock_live)
	gemini.setup(mock_http, mock_live, null)
	gemini.pending_callback = func(_response): pass
	gemini.is_requesting = true
	gemini._extract_live_response_chunks({
		"serverContent": {
			"modelTurn": {
				"parts": [
					{ "text": "Done." },
				],
			},
		},
	})
	gemini._on_live_api_server_message({
		"serverContent": {
			"turnComplete": true,
		},
	})
	_assert(mock_live.close_calls.size() == 1,
		"Gemini Live should close the websocket after a completed turn")
	gemini._on_live_api_connection_closed(1000, "Live turn completed")
	_assert(gemini.is_requesting == false,
		"Expected websocket close after completion should not reopen request state")
	mock_http.queue_free()
	mock_live.queue_free()
	print("    PASS: Gemini Live expected close handling")
func _test_provider_signals() -> void:
	print("\n[Test] Provider signals...")
	var AIProviderBaseScript = load("res://1.Codebase/src/scripts/core/ai/ai_provider_base.gd")
	var provider = AIProviderBaseScript.new()
	var signal_list = provider.get_signal_list()
	var signal_names = []
	for sig in signal_list:
		signal_names.append(sig["name"])
	_assert("request_started" in signal_names, "Should have request_started signal")
	_assert("request_completed" in signal_names, "Should have request_completed signal")
	_assert("request_progress" in signal_names, "Should have request_progress signal")
	_assert("request_error" in signal_names, "Should have request_error signal")
	var error_state := {
		"emitted": false,
		"message": "",
	}
	provider.request_error.connect(func(msg):
		error_state["emitted"] = true
		error_state["message"] = msg
	)
	provider._emit_error("Test error")
	_assert(bool(error_state.get("emitted", false)), "Should emit error signal")
	_assert(String(error_state.get("message", "")) == "Test error", "Should pass error message")
	var progress_state := {
		"emitted": false,
		"data": { },
	}
	provider.request_progress.connect(func(data):
		progress_state["emitted"] = true
		progress_state["data"] = data
	)
	provider._emit_progress({"chunk": "test", "tokens": 10})
	_assert(bool(progress_state.get("emitted", false)), "Should emit progress signal")
	var progress_data: Dictionary = progress_state.get("data", {})
	_assert(progress_data.has("provider"), "Progress should include provider name")
	_assert(progress_data.has("chunk"), "Progress should include original data")
	_assert(progress_data["provider"] == "BaseProvider", "Provider name should match")
	print("    PASS: Provider signals")
func _test_error_handling() -> void:
	print("\n[Test] Error handling...")
	var AIProviderBaseScript = load("res://1.Codebase/src/scripts/core/ai/ai_provider_base.gd")
	var provider = AIProviderBaseScript.new()
	var previous_console_logs := true
	if ErrorReporter != null:
		previous_console_logs = ErrorReporter.enable_console_logs
		ErrorReporter.enable_console_logs = false
	provider.send_request([], Callable())
	_assert(true, "send_request should not crash when not implemented")
	provider.cancel_request()
	_assert(true, "cancel_request should not crash when not implemented")
	var configured = provider.is_configured()
	if ErrorReporter != null:
		ErrorReporter.enable_console_logs = previous_console_logs
	_assert(configured == false, "Base is_configured should return false")
	var config = provider.get_configuration()
	_assert(config is Dictionary, "get_configuration should return Dictionary")
	_assert(config.is_empty(), "Base get_configuration should return empty dict")
	provider.apply_configuration({"test": "value"})
	_assert(true, "apply_configuration should not crash")
	print("    PASS: Error handling")
func _assert(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("    FAIL: %s" % message)
func _print_summary() -> void:
	print("\n" + "=".repeat(80))
	print("  TEST SUMMARY: AI Providers")
	print("=".repeat(80))
	print("  Total Tests:   %d" % (tests_passed + tests_failed))
	print("   Passed:     %d" % tests_passed)
	print("   Failed:     %d" % tests_failed)
	if tests_failed > 0:
		print("\n    Some tests failed!")
	else:
		print("\n   All tests passed!")
	print("=".repeat(80) + "\n")
