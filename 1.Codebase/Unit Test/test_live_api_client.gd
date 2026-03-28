extends Node
var test_client: LiveAPIClient = null
var tests_passed: int = 0
var tests_failed: int = 0
func _ready() -> void:
	print("\n" + "=".repeat(80))
	print("   TESTING LIVE API CLIENT")
	print("=".repeat(80) + "\n")
	await get_tree().process_frame
	await _test_client_initialization()
	await _test_connection_parameters()
	await _test_api_key_handling()
	await _test_session_configuration()
	await _test_message_formatting()
	await _test_connection_state_management()
	await _test_error_handling()
	await _test_signal_emissions()
	await _test_platform_specific_url()
	_print_summary()
	await get_tree().create_timer(0.5).timeout
	queue_free()
func _test_client_initialization() -> void:
	print("\n[Test] LiveAPIClient initialization...")
	var LiveAPIClientScript = load("res://1.Codebase/src/scripts/core/live_api_client.gd")
	test_client = LiveAPIClientScript.new()
	add_child(test_client)
	_assert(test_client != null, "LiveAPIClient should instantiate")
	_assert(test_client.websocket != null, "Should have WebSocketPeer instance")
	_assert(test_client.is_connected == false, "Should not be connected initially")
	_assert(test_client._is_session_setup == false, "Session should not be setup initially")
	print("    PASS: Client initialization")
func _test_connection_parameters() -> void:
	print("\n[Test] Connection parameters...")
	var test_model = "gemini-3.1-flash-live-preview"
	var test_api_key = "test_api_key_12345"
	var test_config = {"temperature": 0.8, "maxOutputTokens": 500}
	var test_session_handle = "session_abc123"
	var test_instruction = "You are a helpful assistant"
	var test_speech_config = {"voice": "Kore"}
	var test_transcription_config = {"input": true, "output": true}
	var test_realtime_input_config = {"turnCoverage": "TURN_INCLUDES_ONLY_ACTIVITY"}
	test_client._model_name = test_model
	test_client._api_key = test_api_key
	test_client._generation_config = test_config
	test_client._session_handle = test_session_handle
	test_client._system_instruction = test_instruction
	test_client._speech_config = test_speech_config
	test_client._transcription_config = test_transcription_config
	test_client._realtime_input_config = test_realtime_input_config
	_assert(test_client._model_name == test_model, "Model name should be stored")
	_assert(test_client._api_key == test_api_key, "API key should be stored")
	_assert(test_client._generation_config.has("temperature"), "Config should be stored")
	_assert(test_client._generation_config["temperature"] == 0.8, "Config values should match")
	_assert(test_client._session_handle == test_session_handle, "Session handle should be stored")
	_assert(test_client._system_instruction == test_instruction, "System instruction should be stored")
	_assert(test_client._speech_config.has("voice"), "Speech config should be stored")
	_assert(bool(test_client._transcription_config.get("input", false)), "Input transcription config should be stored")
	_assert(test_client._realtime_input_config.get("turnCoverage", "") == "TURN_INCLUDES_ONLY_ACTIVITY",
		"Realtime input config should be stored")
	print("    PASS: Connection parameters")
func _test_api_key_handling() -> void:
	print("\n[Test] API key handling...")
	test_client._api_key = ""
	_assert(test_client._api_key == "", "Should accept empty API key (for testing)")
	test_client._api_key = "AIza" + "SyDtXYZ123456789"
	_assert(test_client._api_key.length() > 10, "API key should have reasonable length")
	_assert(test_client._api_key.begins_with("AIza"), "Google API keys typically start with AIza")
	var key_with_spaces = "  test_key  "
	test_client._api_key = key_with_spaces
	_assert(test_client._api_key == key_with_spaces, "API key stored as-is (caller should strip)")
	print("    PASS: API key handling")
func _test_session_configuration() -> void:
	print("\n[Test] Session configuration...")
	var model_name = "gemini-3.1-flash-live-preview"
	var config = {"temperature": 0.9, "topP": 0.95}
	var session_handle = "session_xyz"
	var system_instruction = "Test instruction"
	var speech_config = {"voiceConfig": {"prebuiltVoiceConfig": {"voiceName": "Aoede"}}}
	test_client._model_name = model_name
	test_client._generation_config = config.duplicate()
	test_client._session_handle = session_handle
	test_client._system_instruction = system_instruction
	test_client._speech_config = speech_config.duplicate()
	_assert(test_client._model_name == model_name, "Model name should match")
	_assert(test_client._generation_config["temperature"] == 0.9, "Temperature should match")
	_assert(test_client._session_handle == session_handle, "Session handle should match")
	_assert(test_client._system_instruction == system_instruction, "System instruction should match")
	_assert(test_client._speech_config["voiceConfig"]["prebuiltVoiceConfig"]["voiceName"] == "Aoede", "Speech voice should match")
	test_client._session_handle = ""
	_assert(test_client._session_handle == "", "Should support empty session handle for new sessions")
	print("    PASS: Session configuration")
func _test_message_formatting() -> void:
	print("\n[Test] Message formatting...")
	var test_parts = [
		{"text": "Hello, how are you?"}
	]
	var expected_message = test_client._build_client_content_message([
		{"role": "user", "parts": test_parts},
	])
	_assert(expected_message.has("clientContent"), "Message should have clientContent")
	_assert(expected_message["clientContent"].has("turns"), "Should have turns array")
	_assert(expected_message["clientContent"]["turns"][0]["role"] == "user",
		"Turn should have user role")
	_assert(expected_message["clientContent"]["turns"][0]["parts"] == test_parts,
		"Turn should have correct parts")
	_assert(expected_message["clientContent"]["turnComplete"] == true,
		"Turn should be marked complete")
	var realtime_messages := test_client._build_realtime_input_messages([
		{"text": "Hello there"},
		{
			"inlineData": {
				"mimeType": "audio/pcm;rate=16000",
				"data": "QUJD",
			},
		},
	])
	_assert(realtime_messages.size() == 3, "Realtime input should emit text, audio, then audioStreamEnd")
	_assert(realtime_messages[0]["realtimeInput"]["text"] == "Hello there", "Realtime text should be preserved")
	_assert(realtime_messages[1]["realtimeInput"]["audio"]["mimeType"] == "audio/pcm;rate=16000", "Realtime audio mime type should be preserved")
	_assert(bool(realtime_messages[2]["realtimeInput"].get("audioStreamEnd", false)), "Realtime audio should end the stream for buffered microphone input")
	var setup_message := test_client._build_setup_message({
		"model": "models/gemini-3.1-flash-live-preview",
		"generationConfig": {
			"responseModalities": ["AUDIO"],
			"speechConfig": {
				"voiceConfig": {
					"prebuiltVoiceConfig": {
						"voiceName": "Aoede",
					},
				},
			},
		},
		"historyConfig": {
			"initialHistoryInClientContent": true,
		},
		"realtimeInputConfig": {
			"turnCoverage": "TURN_INCLUDES_ONLY_ACTIVITY",
		},
		"outputAudioTranscription": { },
	})
	_assert(setup_message.has("setup"), "Setup message should have setup payload")
	_assert(setup_message["setup"]["generationConfig"]["responseModalities"][0] == "AUDIO",
		"Setup should keep response modalities in generationConfig")
	_assert(bool(setup_message["setup"]["historyConfig"].get("initialHistoryInClientContent", false)),
		"Setup should enable initial history seeding when requested")
	_assert(setup_message["setup"]["realtimeInputConfig"]["turnCoverage"] == "TURN_INCLUDES_ONLY_ACTIVITY",
		"Setup should preserve explicit turn coverage for Gemini 3.1 Live")
	_assert(setup_message["setup"].has("outputAudioTranscription"),
		"Setup should keep output audio transcription at top level")
	print("    PASS: Message formatting")
func _test_connection_state_management() -> void:
	print("\n[Test] Connection state management...")
	_assert(test_client.is_connected == false, "Should start disconnected")
	_assert(test_client._is_session_setup == false, "Session should not be setup")
	test_client.is_connected = true
	test_client._is_setup_message_sent = true
	test_client._is_session_setup = true
	test_client.close_connection()
	_assert(test_client.is_connected == false, "Should be disconnected after close")
	_assert(test_client._is_setup_message_sent == false, "Setup message flag should reset after close")
	_assert(test_client._is_session_setup == false, "Session should be reset after close")
	_assert(WebSocketPeer.STATE_CLOSED == 3, "STATE_CLOSED should be 3")
	_assert(WebSocketPeer.STATE_OPEN == 1, "STATE_OPEN should be 1")
	_assert(WebSocketPeer.STATE_CONNECTING == 0, "STATE_CONNECTING should be 0")
	_assert(WebSocketPeer.STATE_CLOSING == 2, "STATE_CLOSING should be 2")
	print("    PASS: Connection state management")
func _test_error_handling() -> void:
	print("\n[Test] Error handling...")
	test_client.is_connected = false
	var test_error_code = 1006
	var test_error_reason = "Connection lost"
	test_client.is_connected = true
	test_client._on_connection_closed(test_error_code, test_error_reason)
	_assert(test_client.is_connected == false, "Should disconnect on error")
	_assert(test_client._is_session_setup == false, "Should reset session on error")
	print("    PASS: Error handling")
func _test_signal_emissions() -> void:
	print("\n[Test] Signal emissions...")
	var signal_list = test_client.get_signal_list()
	var signal_names = []
	for sig in signal_list:
		signal_names.append(sig["name"])
	_assert("connection_established" in signal_names, "Should have connection_established signal")
	_assert("connection_closed" in signal_names, "Should have connection_closed signal")
	_assert("connection_error" in signal_names, "Should have connection_error signal")
	_assert("setup_response_received" in signal_names, "Should have setup_response_received signal")
	_assert("server_message_received" in signal_names, "Should have server_message_received signal")
	_assert("error_received" in signal_names, "Should have error_received signal")
	_assert("session_updated" in signal_names, "Should have session_updated signal")
	print("    PASS: Signal emissions")
func _test_platform_specific_url() -> void:
	print("\n[Test] Platform-specific URL handling...")
	_assert(test_client.SERVICE_URL.begins_with("wss://"),
		"Service URL should use secure WebSocket")
	_assert(test_client.SERVICE_URL.contains("generativelanguage.googleapis.com"),
		"Service URL should point to Google's API")
	_assert(test_client.SERVICE_URL.contains("BidiGenerateContent"),
		"Service URL should target BidiGenerateContent endpoint")
	var current_platform = OS.get_name()
	_assert(current_platform != "", "Should detect platform")
	print("    PASS: Platform-specific URL handling")
func _assert(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("    FAIL: %s" % message)
func _print_summary() -> void:
	print("\n" + "=".repeat(80))
	print("  TEST SUMMARY: LiveAPIClient")
	print("=".repeat(80))
	print("  Total Tests:   %d" % (tests_passed + tests_failed))
	print("   Passed:     %d" % tests_passed)
	print("   Failed:     %d" % tests_failed)
	if tests_failed > 0:
		print("\n    Some tests failed!")
	else:
		print("\n   All tests passed!")
	print("=".repeat(80) + "\n")
	if test_client:
		test_client.queue_free()
		test_client = null
