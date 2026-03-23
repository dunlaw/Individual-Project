extends Node
var EventLogSystemScript = preload("res://1.Codebase/src/scripts/core/event_log_system.gd")
var _event_system = null
var _test_results = []
func _ready():
	print("\n" + "=".repeat(80))
	print(" EVENT LOG SYSTEM TEST SUITE")
	print("=".repeat(80) + "\n")
	await run_all_tests()
	print_summary()
	queue_free()
func run_all_tests():
	await run_test("Initialization", test_initialization)
	await run_test("Adding Text Events", test_add_text_events)
	await run_test("Text Event Limits", test_text_event_limits)
	await run_test("Recording Structured Events", test_record_structured_events)
	await run_test("Structured Event Limits", test_structured_event_limits)
	await run_test("Event Log Queries", test_event_queries)
	await run_test("Event Clearing", test_clear_events)
	await run_test("Save/Load Functionality", test_save_load)
	await run_test("Reset Functionality", test_reset)
	await run_test("Signal Emissions", test_signal_emissions)
func run_test(test_name: String, test_func: Callable):
	_event_system = EventLogSystemScript.new()
	var result = await test_func.call()
	_test_results.append({ "name": test_name, "passed": result })
	if result:
		print("   %s" % test_name)
	else:
		print("   %s FAILED" % test_name)
func assert_equal(actual, expected, message: String = "") -> bool:
	if actual != expected:
		if message:
			print("      %s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true
func assert_true(condition: bool, message: String = "") -> bool:
	if not condition:
		if message:
			print("      %s" % message)
		return false
	return true
func test_initialization() -> bool:
	var success = true
	success = assert_equal(_event_system.event_log.size(), 0, "No initial events") and success
	success = assert_equal(_event_system.recent_events.size(), 0, "No initial text events") and success
	success = assert_equal(_event_system.current_language, "en", "Default language is en") and success
	return success
func test_add_text_events() -> bool:
	var success = true
	_event_system.add_event("Player completed quest", LocalizationManager.get_translation("TEST_EVENT_ZH", "zh") + " quest" if LocalizationManager else "Player completed quest ZH")
	success = assert_equal(_event_system.recent_events.size(), 1, "One event added") and success
	success = assert_equal(_event_system.recent_events[0], "Player completed quest", "English event stored") and success
	_event_system.current_language = "zh"
	_event_system.add_event("Found secret item", LocalizationManager.get_translation("TEST_EVENT_ZH", "zh") + " item" if LocalizationManager else "Found secret item ZH")
	success = assert_equal(_event_system.recent_events.size(), 2, "Two events added") and success
	success = assert_equal(_event_system.recent_events[1], (LocalizationManager.get_translation("TEST_EVENT_ZH", "zh") + " item") if LocalizationManager else "Found secret item ZH", "Chinese event stored") and success
	_event_system.current_language = "en"
	_event_system.add_event("English only", "")
	success = assert_equal(_event_system.recent_events[2], "English only", "Fallback to English") and success
	return success
func test_text_event_limits() -> bool:
	var success = true
	for i in range(_event_system.MAX_EVENTS):
		_event_system.add_event("Event %d" % i, (LocalizationManager.get_translation("TEST_OVERFLOW_EVENT_ZH", "zh") if LocalizationManager else "Event") + " %d" % i)
	success = assert_equal(_event_system.recent_events.size(), 10, "Exactly 10 events") and success
	success = assert_equal(_event_system.recent_events[0], "Event 0", "First event is Event 0") and success
	_event_system.add_event("Event 10", (LocalizationManager.get_translation("TEST_OVERFLOW_EVENT_ZH", "zh") if LocalizationManager else "Event") + " 10")
	success = assert_equal(_event_system.recent_events.size(), 10, "Still 10 events") and success
	success = assert_equal(_event_system.recent_events[0], "Event 1", "Oldest removed, first is now Event 1") and success
	success = assert_equal(_event_system.recent_events[9], "Event 10", "Newest is Event 10") and success
	return success
func test_record_structured_events() -> bool:
	var success = true
	var event1 = _event_system.record_event("test_event", { "detail": "value1" })
	success = assert_true(event1 is Dictionary, "Returns dictionary") and success
	success = assert_equal(event1["type"], "test_event", "Event type stored") and success
	success = assert_true(event1.has("timestamp"), "Event has timestamp") and success
	success = assert_equal(_event_system.event_log.size(), 1, "Event added to log") and success
	var event2 = _event_system.record_event("another_event", { "value": 42 })
	success = assert_equal(_event_system.event_log.size(), 2, "Two events in log") and success
	success = assert_equal(_event_system.event_log[1]["details"]["value"], 42, "Event details stored") and success
	return success
func test_structured_event_limits() -> bool:
	var success = true
	for i in range(_event_system.MAX_EVENT_LOG_SIZE):
		_event_system.record_event("event_%d" % i, { "index": i })
	success = assert_equal(_event_system.event_log.size(), 200, "Exactly 200 events") and success
	success = assert_equal(_event_system.event_log[0]["type"], "event_0", "First event is event_0") and success
	_event_system.record_event("event_200", { "index": 200 })
	success = assert_equal(_event_system.event_log.size(), 200, "Still 200 events") and success
	success = assert_equal(_event_system.event_log[0]["type"], "event_1", "Oldest removed") and success
	success = assert_equal(_event_system.event_log[199]["type"], "event_200", "Newest is event_200") and success
	return success
func test_event_queries() -> bool:
	var success = true
	for i in range(15):
		_event_system.record_event("event_%d" % i, { "index": i })
	var recent = _event_system.get_recent_records()
	success = assert_equal(recent.size(), 10, "Default limit is 10") and success
	success = assert_equal(recent[0]["type"], "event_5", "First of recent is event_5") and success
	success = assert_equal(recent[9]["type"], "event_14", "Last of recent is event_14") and success
	var recent_5 = _event_system.get_recent_records(5)
	success = assert_equal(recent_5.size(), 5, "Custom limit 5") and success
	success = assert_equal(recent_5[0]["type"], "event_10", "First of recent_5 is event_10") and success
	_event_system.recent_events.clear()
	_event_system.add_event("Event A", (LocalizationManager.get_translation("TEST_OVERFLOW_EVENT_ZH", "zh") if LocalizationManager else "Event") + " A")
	_event_system.add_event("Event B", (LocalizationManager.get_translation("TEST_OVERFLOW_EVENT_ZH", "zh") if LocalizationManager else "Event") + " B")
	var summary = _event_system.get_events_summary()
	success = assert_true(summary.contains("Event A"), "Summary contains Event A") and success
	success = assert_true(summary.contains("Event B"), "Summary contains Event B") and success
	return success
func test_clear_events() -> bool:
	var success = true
	_event_system.add_event("Text event", LocalizationManager.get_translation("TEST_EVENT_ZH", "zh") if LocalizationManager else "Text Event ZH")
	_event_system.record_event("structured_event", { "key": "value" })
	_event_system.clear_event_log()
	success = assert_equal(_event_system.event_log.size(), 0, "Event log cleared") and success
	success = assert_equal(_event_system.recent_events.size(), 1, "Text events not affected") and success
	_event_system.record_event("another_event", { })
	_event_system.recent_events.clear()
	_event_system.event_log.clear()
	success = assert_equal(_event_system.event_log.size(), 0, "All events cleared") and success
	success = assert_equal(_event_system.recent_events.size(), 0, "All text events cleared") and success
	return success
func test_save_load() -> bool:
	var success = true
	_event_system.add_event("Event 1", (LocalizationManager.get_translation("TEST_OVERFLOW_EVENT_ZH", "zh") if LocalizationManager else "Event") + " 1")
	_event_system.add_event("Event 2", (LocalizationManager.get_translation("TEST_OVERFLOW_EVENT_ZH", "zh") if LocalizationManager else "Event") + " 2")
	_event_system.record_event("event_type_1", { "data": "value1" })
	_event_system.record_event("event_type_2", { "data": "value2" })
	var save_data = _event_system.get_save_data()
	success = assert_true(save_data.has("event_log"), "Save has event_log") and success
	success = assert_true(save_data.has("recent_events"), "Save has recent_events") and success
	success = assert_equal(save_data["event_log"].size(), 2, "Saved 2 structured events") and success
	success = assert_equal(save_data["recent_events"].size(), 2, "Saved 2 text events") and success
	var new_system = EventLogSystemScript.new()
	new_system.load_save_data(save_data)
	success = assert_equal(new_system.event_log.size(), 2, "Loaded 2 structured events") and success
	success = assert_equal(new_system.recent_events.size(), 2, "Loaded 2 text events") and success
	success = assert_equal(new_system.recent_events[0], "Event 1", "Loaded Event 1") and success
	success = assert_equal(new_system.event_log[0]["type"], "event_type_1", "Loaded event_type_1") and success
	success = assert_equal(new_system.event_log[1]["details"]["data"], "value2", "Loaded event details") and success
	var empty_system = EventLogSystemScript.new()
	empty_system.load_save_data({})
	success = assert_equal(empty_system.event_log.size(), 0, "Loaded empty event_log gracefully") and success
	success = assert_equal(empty_system.recent_events.size(), 0, "Loaded empty recent_events gracefully") and success
	var invalid_data_system = EventLogSystemScript.new()
	invalid_data_system.load_save_data({
		"event_log": "not_an_array",
		"recent_events": 12345
	})
	success = assert_equal(invalid_data_system.event_log.size(), 0, "Handled non-array event_log gracefully") and success
	success = assert_equal(invalid_data_system.recent_events.size(), 0, "Handled non-array recent_events gracefully") and success
	var mod_system = EventLogSystemScript.new()
	mod_system.load_save_data(save_data)
	mod_system.recent_events.append("New Event")
	mod_system.event_log.append({"type": "new_type"})
	mod_system.event_log[0]["details"]["data"] = "modified_value"
	success = assert_equal(save_data["recent_events"].size(), 2, "Original recent_events data should not be modified") and success
	success = assert_equal(save_data["event_log"].size(), 2, "Original event_log data should not be modified") and success
	success = assert_equal(save_data["event_log"][0]["details"]["data"], "value1", "Original event_log nested dictionaries should not be modified") and success
	var save_data_mod = _event_system.get_save_data()
	save_data_mod["recent_events"].append("Modified")
	save_data_mod["event_log"].append({"type": "mod"})
	save_data_mod["event_log"][1]["details"]["data"] = "another_modified_value"
	success = assert_equal(_event_system.recent_events.size(), 2, "System recent_events not modified via get_save_data return value") and success
	success = assert_equal(_event_system.event_log.size(), 2, "System event_log not modified via get_save_data return value") and success
	success = assert_equal(_event_system.event_log[1]["details"]["data"], "value2", "System event_log nested dictionaries not modified via get_save_data return value") and success
	return success
func test_reset() -> bool:
	var success = true
	_event_system.add_event("Text event", LocalizationManager.get_translation("TEST_EVENT_ZH", "zh") if LocalizationManager else "Text Event ZH")
	_event_system.record_event("structured_event", { "key": "value" })
	_event_system.reset()
	success = assert_equal(_event_system.event_log.size(), 0, "Event log reset") and success
	success = assert_equal(_event_system.recent_events.size(), 0, "Text events reset") and success
	return success
func test_signal_emissions() -> bool:
	var success = true
	var state = {"count": 0, "last_event": null}
	var handler = func(event):
		state["count"] += 1
		state["last_event"] = event
	_event_system.event_logged.connect(handler)
	_event_system.record_event("test_signal", { "data": 123 })
	await get_tree().process_frame
	success = assert_equal(state["count"], 1, "Signal emitted once") and success
	success = assert_true(state["last_event"] != null, "Event data received") and success
	if state["last_event"] != null:
		success = assert_equal(state["last_event"]["type"], "test_signal", "Correct event type in signal") and success
		success = assert_equal(state["last_event"]["details"]["data"], 123, "Correct event details in signal") and success
	return success
func print_summary():
	print("\n" + "=".repeat(80))
	var passed = _test_results.filter(func(r): return r.passed).size()
	var total = _test_results.size()
	if passed == total:
		print(" ALL TESTS PASSED (%d/%d)" % [passed, total])
	else:
		print(" SOME TESTS FAILED (%d/%d passed)" % [passed, total])
		print("\nFailed tests:")
		for result in _test_results:
			if not result.passed:
				print("  • %s" % result.name)
	print("=".repeat(80) + "\n")
