extends Node
var _test_results = []
var _initial_state = { }
func _ready():
	print("\n" + "=".repeat(80))
	print(" GAMESTATE INTEGRATION TEST SUITE")
	print("=".repeat(80) + "\n")
	save_initial_state()
	await run_all_tests()
	print_summary()
	restore_initial_state()
	queue_free()
func save_initial_state():
	if GameState:
		_initial_state = {
			"reality_score": GameState.reality_score,
			"positive_energy": GameState.positive_energy,
			"entropy_level": GameState.entropy_level,
			"current_mission": GameState.current_mission,
		}
func restore_initial_state():
	if GameState and not _initial_state.is_empty():
		GameState.reality_score = _initial_state.get("reality_score", 50)
		GameState.positive_energy = _initial_state.get("positive_energy", 50)
		GameState.entropy_level = _initial_state.get("entropy_level", 0)
		GameState.current_mission = _initial_state.get("current_mission", 0)
		if GameState.has_method("clear_all_debuffs"):
			GameState.clear_all_debuffs()
		if GameState.has_method("clear_events"):
			GameState.clear_events()
		print("\n GameState restored to initial state")
func run_all_tests():
	await run_test("GameState Exists", test_gamestate_exists)
	await run_test("Subsystems Initialized", test_subsystems_initialized)
	await run_test("PlayerStats Property Accessors", test_player_stats_accessors)
	await run_test("EventLog Property Accessors", test_event_log_accessors)
	await run_test("Debuff Property Accessors", test_debuff_accessors)
	await run_test("Stat Modification Integration", test_stat_modification)
	await run_test("Event Recording Integration", test_event_recording)
	await run_test("Debuff Integration", test_debuff_integration)
	await run_test("Signal Propagation", test_signal_propagation)
	await run_test("Save/Load Round-trip", test_save_load_roundtrip)
	await run_test("New Game Reset", test_new_game_reset)
func run_test(test_name: String, test_func: Callable):
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
func assert_not_null(value, message: String = "") -> bool:
	if value == null:
		if message:
			print("      %s: got null" % message)
		return false
	return true
func test_gamestate_exists() -> bool:
	var success = true
	var game_state_service = ServiceLocator.get_game_state() if ServiceLocator and ServiceLocator.has_method("get_game_state") else null
	success = assert_true(game_state_service != null, "GameState autoload exists via ServiceLocator") and success
	success = assert_not_null(GameState, "GameState reference not null") and success
	return success
func test_subsystems_initialized() -> bool:
	var success = true
	if not GameState:
		return false
	success = assert_true(GameState.player_stats is Dictionary, "PlayerStats accessor available") and success
	success = assert_true(GameState.event_log is Array, "EventLog accessor available") and success
	success = assert_true(GameState.active_debuffs is Array, "Debuff accessor available") and success
	success = assert_true(GameState.has_method("get_save_data"), "Save system API available") and success
	success = assert_not_null(GameState.butterfly_tracker, "ButterflyTracker initialized") and success
	return success
func test_player_stats_accessors() -> bool:
	var success = true
	if not GameState:
		return false
	var original_reality = GameState.reality_score
	GameState.reality_score = 60
	success = assert_equal(GameState.reality_score, 60, "Reality score accessor set") and success
	success = assert_equal(GameState.reality_score, 60, "PlayerStats value updated via accessor") and success
	GameState.reality_score = original_reality
	var logic_skill = GameState.player_stats.get("logic", 0)
	success = assert_true(logic_skill > 0, "Skills accessible through property") and success
	return success
func test_event_log_accessors() -> bool:
	var success = true
	if not GameState:
		return false
	var initial_count = GameState.event_log.size()
	GameState.record_event("test_event", { "data": "test" })
	success = assert_equal(GameState.event_log.size(), initial_count + 1, "Event added to log") and success
	success = assert_true(GameState.recent_events.size() >= 1, "Recent events updated") and success
	return success
func test_debuff_accessors() -> bool:
	var success = true
	if not GameState:
		return false
	GameState.clear_all_debuffs()
	success = assert_equal(GameState.active_debuffs.size(), 0, "No debuffs initially") and success
	GameState.add_debuff(LocalizationManager.get_translation("TEST_DEBUFF_TEST_NAME", "zh") if LocalizationManager else "Test Debuff", 3, LocalizationManager.get_translation("TEST_DEBUFF_EFFECT", "zh") if LocalizationManager else "Test Effect")
	success = assert_equal(GameState.active_debuffs.size(), 1, "Debuff added") and success
	success = assert_true(GameState.active_debuffs[0] is Dictionary, "Debuff payload structure valid") and success
	GameState.clear_all_debuffs()
	return success
func test_stat_modification() -> bool:
	var success = true
	if not GameState:
		return false
	var original_reality = GameState.reality_score
	GameState.modify_reality_score(10, LocalizationManager.get_translation("TEST_STAT_MODIFIER", "zh") if LocalizationManager else "Test")
	success = assert_equal(GameState.reality_score, original_reality + 10, "Reality score modified") and success
	success = assert_equal(GameState.reality_score, original_reality + 10, "PlayerStats value matches") and success
	GameState.modify_reality_score(-(original_reality + 10 - _initial_state.get("reality_score", 50)))
	return success
func test_event_recording() -> bool:
	var success = true
	if not GameState:
		return false
	var initial_log_size = GameState.event_log.size()
	var initial_recent_size = GameState.recent_events.size()
	var event = GameState.record_event("integration_test", { "test": true })
	success = assert_true(event is Dictionary, "Event returned") and success
	success = assert_equal(event["type"], "integration_test", "Event type correct") and success
	success = assert_true(GameState.event_log.size() > initial_log_size, "Event added to log") and success
	return success
func test_debuff_integration() -> bool:
	var success = true
	if not GameState:
		return false
	GameState.clear_all_debuffs()
	GameState.add_debuff(LocalizationManager.get_translation("TEST_DEBUFF_INTEGRATION", "zh") if LocalizationManager else "Integration Test", 2, LocalizationManager.get_translation("TEST_DEBUFF_EFFECT", "zh") if LocalizationManager else "Test Effect")
	success = assert_equal(GameState.active_debuffs.size(), 1, "Debuff added") and success
	GameState.process_debuffs()
	var remaining_debuff = GameState.active_debuffs[0]
	success = assert_equal(remaining_debuff["duration"], 1, "Debuff duration decreased") and success
	GameState.process_debuffs()
	success = assert_equal(GameState.active_debuffs.size(), 0, "Debuff expired") and success
	return success
func test_signal_propagation() -> bool:
	var success = true
	if not GameState:
		return false
	var state = {"received": false, "value": 0}
	var connection = func(new_value):
		state["received"] = true
		state["value"] = new_value
	GameState.reality_score_changed.connect(connection)
	var original = GameState.reality_score
	GameState.modify_reality_score(5, LocalizationManager.get_translation("TEST_SIGNAL", "zh") if LocalizationManager else "Signal Test")
	await get_tree().process_frame
	success = assert_true(state["received"], "Signal received") and success
	success = assert_equal(state["value"], original + 5, "Signal value correct") and success
	GameState.reality_score_changed.disconnect(connection)
	GameState.modify_reality_score(-5)
	return success
func test_save_load_roundtrip() -> bool:
	var success = true
	if not GameState:
		return false
	GameState.reality_score = 77
	GameState.positive_energy = 33
	GameState.entropy_level = 15
	GameState.modify_stat("logic", 2)
	GameState.add_debuff(LocalizationManager.get_translation("TEST_DEBUFF_SAVE", "zh") if LocalizationManager else "Save Test", 3, LocalizationManager.get_translation("TEST_STAT_MODIFIER", "zh") if LocalizationManager else "Test")
	GameState.current_mission = 5
	var save_data = GameState.get_save_data()
	GameState.reality_score = 20
	GameState.positive_energy = 80
	GameState.current_mission = 10
	GameState.load_save_data(save_data)
	success = assert_equal(GameState.reality_score, 77, "Reality score restored") and success
	success = assert_equal(GameState.positive_energy, 33, "Positive energy restored") and success
	success = assert_equal(GameState.entropy_level, 15, "Entropy restored") and success
	success = assert_equal(GameState.get_stat("logic"), 7, "Logic skill restored") and success
	success = assert_equal(GameState.active_debuffs.size(), 1, "Debuffs restored") and success
	success = assert_equal(GameState.current_mission, 5, "Mission restored") and success
	return success
func test_new_game_reset() -> bool:
	var success = true
	if not GameState:
		return false
	GameState.reality_score = 20
	GameState.positive_energy = 80
	GameState.modify_stat("logic", 3)
	GameState.add_debuff(LocalizationManager.get_translation("TEST_DEBUFF_RESET", "zh") if LocalizationManager else "Reset Test", 5, LocalizationManager.get_translation("TEST_STAT_MODIFIER", "zh") if LocalizationManager else "Test")
	GameState.add_event(LocalizationManager.get_translation("TEST_EVENT_ZH", "en") if LocalizationManager else "Test Event", LocalizationManager.get_translation("TEST_EVENT_ZH", "zh") if LocalizationManager else "Test Event")
	GameState.current_mission = 10
	GameState.new_game()
	success = assert_equal(GameState.reality_score, 50, "Reality reset to 50") and success
	success = assert_equal(GameState.positive_energy, 50, "Positive energy reset to 50") and success
	success = assert_equal(GameState.entropy_level, 0, "Entropy reset to 0") and success
	success = assert_equal(GameState.get_stat("logic"), 5, "Logic reset to 5") and success
	success = assert_equal(GameState.active_debuffs.size(), 0, "Debuffs cleared") and success
	success = assert_equal(GameState.event_log.size(), 0, "Event log cleared") and success
	success = assert_equal(GameState.recent_events.size(), 0, "Recent events cleared") and success
	success = assert_equal(GameState.current_mission, 0, "Mission reset to 0") and success
	return success
func print_summary():
	print("\n" + "=".repeat(80))
	var passed = _test_results.filter(func(r): return r.passed).size()
	var total = _test_results.size()
	if passed == total:
		print(" ALL INTEGRATION TESTS PASSED (%d/%d)" % [passed, total])
		print("\n All systems integrate correctly in GameState!")
	else:
		print(" SOME INTEGRATION TESTS FAILED (%d/%d passed)" % [passed, total])
		print("\nFailed tests:")
		for result in _test_results:
			if not result.passed:
				print("  • %s" % result.name)
	print("=".repeat(80) + "\n")
