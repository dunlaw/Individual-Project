extends Node
var tests_passed: int = 0
var tests_failed: int = 0
const TOL := 0.05
var initial_reality: int
var initial_positive: int
var initial_entropy: int
func _ready() -> void:
	print("[GameStateTest] Starting GameState unit tests...")
	await get_tree().process_frame
	_test_stat_modifications()
	await _test_save_load_system()
	await _test_event_logging()
	_test_skill_checks()
	_test_phase_management()
	print("[GameStateTest] All tests completed.")
	queue_free()
func _test_stat_modifications() -> void:
	print("[Test] Stat modifications...")
	initial_reality = GameState.reality_score
	initial_positive = GameState.positive_energy
	initial_entropy = GameState.entropy_level
	GameState.modify_reality_score(10, "Test increase")
	_assert(GameState.reality_score == initial_reality + 10, "Reality score should increase by 10")
	GameState.reality_score = 95
	GameState.modify_reality_score(10, "Test clamping")
	_assert(GameState.reality_score == 100, "Reality score should clamp at 100")
	GameState.reality_score = 5
	GameState.modify_reality_score(-10, "Test clamping min")
	_assert(GameState.reality_score == 0, "Reality score should clamp at 0")
	GameState.reality_score = initial_reality
	GameState.positive_energy = 50
	GameState.modify_positive_energy(20, "Test positive energy")
	_assert(GameState.positive_energy == 70, "Positive energy should be 70")
	var entropy_before = GameState.entropy_level
	GameState.positive_energy = 50
	GameState.modify_positive_energy(10, "Test entropy cascade")
	var entropy_after = GameState.entropy_level
	_assert(entropy_after > entropy_before, "Entropy should increase when positive energy increases")
	GameState.reality_score = initial_reality
	GameState.positive_energy = initial_positive
	GameState.entropy_level = initial_entropy
	print("[Test] Stat modifications PASSED")
func _test_save_load_system() -> void:
	print("[Test] Save/Load system...")
	GameState.reality_score = 42
	GameState.positive_energy = 67
	GameState.entropy_level = 15
	GameState.current_mission = 3
	GameState.missions_completed = 2
	GameState.game_phase = GameConstants.GamePhase.CRISIS
	GameState.player_stats["logic"] = 7
	GameState.player_stats["perception"] = 6
	GameState.add_event("Test event EN", LocalizationManager.get_translation("TEST_EVENT_ZH", "zh") + " ZH" if LocalizationManager else "Test event ZH")
	var test_slot = 4
	var original_save_slot = GameState.current_save_slot
	var save_success = GameState.save_game_to_slot(test_slot)
	_assert(save_success, "Save should succeed")
	await get_tree().create_timer(0.1).timeout
	GameState.current_save_slot = original_save_slot
	GameState.reality_score = 99
	GameState.positive_energy = 11
	GameState.entropy_level = 999
	GameState.current_mission = 0
	GameState.missions_completed = 0
	GameState.game_phase = GameConstants.GamePhase.HONEYMOON
	GameState.player_stats["logic"] = 1
	GameState.player_stats["perception"] = 1
	GameState.recent_events.clear()
	var load_success = GameState.load_game_from_slot(test_slot)
	_assert(load_success, "Load should succeed")
	await get_tree().create_timer(0.1).timeout
	_assert(GameState.reality_score == 42, "Reality score should be restored to 42")
	_assert(GameState.positive_energy == 67, "Positive energy should be restored to 67")
	_assert(GameState.entropy_level == 15, "Entropy level should be restored to 15")
	_assert(GameState.current_mission == 3, "Current mission should be restored to 3")
	_assert(GameState.missions_completed == 2, "Missions completed should be restored to 2")
	_assert(GameState.game_phase == GameConstants.GamePhase.CRISIS, "Game phase should be restored to crisis")
	_assert(GameState.player_stats["logic"] == 7, "Logic stat should be restored to 7")
	_assert(GameState.player_stats["perception"] == 6, "Perception stat should be restored to 6")
	_assert(GameState.recent_events.size() > 0, "Events should be restored")
	var slot_info = GameState.get_save_slot_info(test_slot)
	_assert(slot_info.get("exists", false), "Slot info should show slot exists")
	_assert(slot_info.get("reality_score", -1) == 42, "Slot info should show correct reality score")
	GameState.delete_save_slot(test_slot)
	GameState.current_save_slot = original_save_slot
	print("[Test] Save/Load system PASSED")
func _test_event_logging() -> void:
	print("[Test] Event logging...")
	GameState.clear_events()
	_assert(GameState.recent_events.is_empty(), "Events should be cleared")
	for i in range(5):
		GameState.add_event("Event %d EN" % i, (LocalizationManager.get_translation("TEST_EVENT_N_ZH", "zh") if LocalizationManager else "Event %d ZH") % i)
	_assert(GameState.recent_events.size() == 5, "Should have 5 events")
	for i in range(20):
		GameState.add_event("Overflow event %d" % i, (LocalizationManager.get_translation("TEST_OVERFLOW_EVENT_ZH", "zh") if LocalizationManager else "Overflow Event") + " %d" % i)
	_assert(GameState.recent_events.size() <= GameState.MAX_EVENTS, "Events should be capped at MAX_EVENTS")
	GameState.clear_event_log()
	var entry = GameState.record_event("test_event", { "detail": "test_value" })
	_assert(entry.has("type"), "Event should have type")
	_assert(entry.has("timestamp"), "Event should have timestamp")
	_assert(GameState.event_log.size() == 1, "Event log should have 1 entry")
	for i in range(3):
		GameState.record_event("event_%d" % i, { "index": i })
	var recent = GameState.get_recent_records(2)
	_assert(recent.size() == 2, "Should return 2 most recent events")
	print("[Test] Event logging PASSED")
func _test_skill_checks() -> void:
	print("[Test] Skill checks...")
	GameState.player_stats["logic"] = 5
	var successes = 0
	var failures = 0
	for i in range(20):
		var result = GameState.skill_check("logic", 10)
		if result["success"]:
			successes += 1
		else:
			failures += 1
		_assert(result.has("success"), "Result should have success flag")
		_assert(result.has("roll"), "Result should have roll value")
		_assert(result.has("skill_value"), "Result should have skill_value")
		_assert(result.has("total"), "Result should have total")
		_assert(result.has("difficulty"), "Result should have difficulty")
	_assert(successes > 0, "Should have at least some successes in 20 rolls")
	_assert(failures > 0, "Should have at least some failures in 20 rolls")
	GameState.player_stats["perception"] = 10
	var easy_result = GameState.skill_check("perception", 5)
	_assert(easy_result["total"] >= 10, "With perception=10, total should be at least 10")
	print("[Test] Skill checks PASSED")
func _test_phase_management() -> void:
	print("[Test] Phase management...")
	GameState.set_game_phase(GameConstants.GamePhase.HONEYMOON)
	_assert(GameState.game_phase == GameConstants.GamePhase.HONEYMOON, "Phase should be honeymoon")
	GameState.set_game_phase(GameConstants.GamePhase.NORMAL)
	_assert(GameState.game_phase == GameConstants.GamePhase.NORMAL, "Phase should be normal")
	GameState.set_game_phase(GameConstants.GamePhase.CRISIS)
	_assert(GameState.game_phase == GameConstants.GamePhase.CRISIS, "Phase should be crisis")
	GameState.enter_honeymoon_phase()
	_assert(GameState.game_phase == GameConstants.GamePhase.HONEYMOON, "Should enter honeymoon phase")
	_assert(GameState.honeymoon_charges == 5, "Honeymoon charges should be 5")
	GameState.consume_honeymoon_charge("Test reason")
	_assert(GameState.honeymoon_charges == 4, "Honeymoon charges should decrease to 4")
	for i in range(4):
		GameState.consume_honeymoon_charge("Test %d" % i)
	_assert(GameState.honeymoon_charges == 0, "Honeymoon charges should be 0")
	_assert(GameState.game_phase == GameConstants.GamePhase.NORMAL, "Phase should transition to normal when charges depleted")
	GameState.positive_energy = 100
	GameState.reality_score = 0
	var high_entropy = GameState.calculate_void_entropy()
	_assert(high_entropy > 0.5, "High positive energy + low reality should give high entropy")
	GameState.positive_energy = 0
	GameState.reality_score = 100
	var low_entropy = GameState.calculate_void_entropy()
	_assert(low_entropy < 0.5, "Low positive energy + high reality should give low entropy")
	GameState.reality_score = initial_reality
	GameState.positive_energy = initial_positive
	GameState.game_phase = GameConstants.GamePhase.NORMAL
	print("[Test] Phase management PASSED")
func _assert(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
		print("    PASS  %s" % message)
	else:
		tests_failed += 1
		print("    FAIL  %s" % message)
