extends Node
const GeminiProviderScript = preload("res://1.Codebase/src/scripts/core/ai/gemini_provider.gd")
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
func _ready() -> void:
	print("Running Gemini Session Resumption Test...")
	await get_tree().process_frame
	_test_session_handle_updates_from_signal()
	print("Gemini session resumption summary: %d passed, %d failed" % [tests_passed, tests_failed])
	queue_free()
func _assert_test(condition: bool, test_name: String, details: String = "") -> void:
	if condition:
		tests_passed += 1
		print("PASS: %s" % test_name)
		return
	tests_failed += 1
	print("FAIL: %s" % test_name)
	if not details.is_empty():
		print(details)
func _test_session_handle_updates_from_signal() -> void:
	var provider = GeminiProviderScript.new()
	var mock_client = MockLiveClient.new()
	var mock_http = HTTPRequest.new()
	provider.setup(mock_http, mock_client, null)
	var first_handle := "test_handle_12345"
	mock_client.session_updated.emit(first_handle)
	_assert_test(
		provider.live_api_session_handle == first_handle,
		"GeminiProvider stores the latest Live API session handle",
		"Expected '%s', got '%s'" % [first_handle, provider.live_api_session_handle],
	)
	var second_handle := "replacement_handle_98765"
	mock_client.session_updated.emit(second_handle)
	_assert_test(
		provider.live_api_session_handle == second_handle,
		"GeminiProvider replaces the previous Live API session handle on resume",
		"Expected '%s', got '%s'" % [second_handle, provider.live_api_session_handle],
	)
	mock_http.free()
	mock_client.free()
