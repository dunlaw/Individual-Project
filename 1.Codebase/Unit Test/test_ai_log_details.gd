extends SceneTree


class _StubDebugProvider:
	extends RefCounted

	func get_debug_snapshot() -> Dictionary:
		return {
			"request": {
				"protocol": "openai",
				"endpoint": "http://127.0.0.1:8046/v1/chat/completions",
				"body": "{\"messages\":[{\"role\":\"user\",\"content\":\"hello\"}],\"model\":\"stub-model\"}",
			},
			"response": {
				"status_code": 200,
				"body": "{\"choices\":[{\"message\":{\"role\":\"assistant\",\"content\":\"world\"}}]}",
			},
		}


class _StubDebugProviderManager:
	extends RefCounted

	var provider := _StubDebugProvider.new()

	func get_current_provider_name() -> String:
		return "AI_ROUTER"

	func get_current_provider() -> RefCounted:
		return provider


var _failed: bool = false


func _initialize() -> void:
	print("[AILogDetailsTest] Starting targeted AI log detail checks...")
	_run_capture_toggle_test()
	_run_renderer_format_test()
	if _failed:
		print("[AILogDetailsTest] FAILED")
		quit(1)
		return
	print("[AILogDetailsTest] PASSED")
	quit()


func _assert_test(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: %s" % label)
		return
	_failed = true
	print("  FAIL: %s" % label)


func _run_capture_toggle_test() -> void:
	var manager_script: GDScript = load("res://1.Codebase/src/scripts/core/ai/managers/ai_request_manager.gd")
	var config_script: GDScript = load("res://1.Codebase/src/scripts/core/ai/managers/ai_config_manager.gd")
	_assert_test(manager_script != null, "AIRequestManager script loads")
	_assert_test(config_script != null, "AIConfigManager script loads")
	if manager_script == null or config_script == null:
		return
	var manager = manager_script.new()
	var config = config_script.new()
	_assert_test(manager != null, "AIRequestManager instantiates")
	_assert_test(config != null, "AIConfigManager instantiates")
	if manager == null or config == null:
		return
	manager.set_config_manager(config)
	manager.set_provider_manager(_StubDebugProviderManager.new())
	config.current_provider = config_script.AIProvider.AI_ROUTER
	config.ai_router_model = "stub-model"
	manager._active_request_payload = {
		"context": {"purpose": "new_mission"},
	}
	config.save_detailed_ai_call_logs = true
	manager.clear_call_log()
	manager._record_call_log(true, "live", 200, 10, 12, 1.25)
	var detailed_entry: Dictionary = manager.get_call_log().back()
	_assert_test(bool(detailed_entry.get("detail_available", false)), "Detailed log entry is stored when toggle is on")
	_assert_test(str(detailed_entry.get("request_body", "")).find("\"messages\"") != -1, "Request JSON body is captured")
	_assert_test(str(detailed_entry.get("response_body", "")).find("\"choices\"") != -1, "Response JSON body is captured")
	config.save_detailed_ai_call_logs = false
	manager.clear_call_log()
	manager._record_call_log(true, "live", 200, 10, 12, 1.25)
	var summary_entry: Dictionary = manager.get_call_log().back()
	_assert_test(not bool(summary_entry.get("detail_available", false)), "Detailed bodies are omitted when toggle is off")


func _run_renderer_format_test() -> void:
	var renderer_script: GDScript = load("res://1.Codebase/src/scripts/ui/settings_menu_ai_log_renderer.gd")
	_assert_test(renderer_script != null, "Renderer script loads")
	if renderer_script == null:
		return
	var detail_text: String = str(renderer_script.format_detail_text(
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
		func(_key: String, fallback: String) -> String:
			return fallback
	))
	_assert_test(detail_text.find("Request Time") != -1, "Detail view includes request timestamp heading")
	_assert_test(detail_text.find("Request (Request)") != -1, "Detail view includes request payload section")
	_assert_test(detail_text.find("Response (Response)") != -1, "Detail view includes response payload section")
	_assert_test(detail_text.find("\"messages\"") != -1, "Detail view contains request JSON")
	_assert_test(detail_text.find("\"choices\"") != -1, "Detail view contains response JSON")
