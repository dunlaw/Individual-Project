extends Node
const TrolleyProblemOverlay = preload("res://1.Codebase/src/scenes/ui/trolley_problem_overlay.tscn")
const PrayerSystemMain = preload("res://1.Codebase/src/scenes/ui/prayer_system.tscn")
const GloriaInterventionOverlay = preload("res://1.Codebase/src/scenes/ui/gloria_intervention_overlay.tscn")
var tests_passed: int = 0
var tests_failed: int = 0
var _previous_provider: int = -1
var _previous_mock_override: bool = false
var _previous_prayer_notice_acknowledged: bool = false
var _mock_state_prepared: bool = false
func _ready() -> void:
	print("[TestMockModeInteractions] Starting tests...")
	await get_tree().process_frame
	_prepare_mock_environment()
	await _test_trolley_mock_mode()
	await _test_prayer_mock_mode()
	await _test_fsm_debug()
	await _test_gloria_mock_mode()
	_restore_mock_environment()
	print("[TestMockModeInteractions] Summary: %d passed, %d failed" % [tests_passed, tests_failed])
	queue_free()
func _assert_test(condition: bool, label: String, details: String = "") -> void:
	if condition:
		tests_passed += 1
		print("    PASS  %s" % label)
		return
	tests_failed += 1
	print("    FAIL  %s%s" % [label, (": %s" % details) if not details.is_empty() else ""])
func _wait_for_flag(flag: Dictionary, timeout_sec: float = 5.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while Time.get_ticks_msec() <= deadline:
		if bool(flag.get("value", false)):
			return true
		await get_tree().process_frame
	return bool(flag.get("value", false))
func _prepare_mock_environment() -> void:
	if _mock_state_prepared:
		return
	if AIManager:
		_previous_provider = int(AIManager.current_provider)
		_previous_mock_override = AIManager.is_mock_override_enabled() if AIManager.has_method("is_mock_override_enabled") else false
		AIManager.current_provider = AIManager.AIProvider.MOCK_MODE
		if AIManager.has_method("set_mock_override"):
			AIManager.set_mock_override(true, "test_mock_mode_interactions")
	if GameState:
		_previous_prayer_notice_acknowledged = bool(GameState.get_metadata("prayer_notice_acknowledged", false))
		GameState.set_metadata("prayer_notice_acknowledged", false)
	_mock_state_prepared = true
func _restore_mock_environment() -> void:
	if not _mock_state_prepared:
		return
	if GameState:
		GameState.set_metadata("prayer_notice_acknowledged", _previous_prayer_notice_acknowledged)
	if AIManager:
		if AIManager.has_method("set_mock_override"):
			AIManager.set_mock_override(_previous_mock_override)
		if _previous_provider >= 0:
			AIManager.current_provider = _previous_provider
	_mock_state_prepared = false
func _test_trolley_mock_mode() -> void:
	print("[Test] Trolley problem in mock mode...")
	var trolley = TrolleyProblemOverlay.instantiate()
	add_child(trolley)
	await get_tree().process_frame
	var dummy_data = {
		"scenario": "Test Mock Scenario",
		"template_type": "classic",
		"choices": [
			{
				"id": "c1",
				"text": "Choice 1 Mock",
				"framing": "honest",
				"immediate_consequence": "None",
				"long_term_consequence": "None",
				"stat_changes": {}
			}
		],
		"thematic_point": "Mocking is cool"
	}
	trolley.setup(dummy_data)
	_assert_test(trolley.dilemma_data.scenario == "Test Mock Scenario", "Trolley setup stores scenario")
	_assert_test(trolley._choices_data.size() == 1, "Trolley setup stores one choice")
	var emitted := {"value": false}
	trolley.choice_selected.connect(
		func(choice_id: String):
			emitted["value"] = (choice_id == "c1"),
		CONNECT_ONE_SHOT
	)
	trolley._try_keyboard_choice(0)
	var resolved := await _wait_for_flag(emitted, 8.0)
	_assert_test(resolved, "Trolley mock mode emits selected choice")
	if is_instance_valid(trolley):
		trolley.queue_free()
func _test_prayer_mock_mode() -> void:
	print("[Test] Prayer in mock mode...")
	if GameState:
		GameState.set_metadata("prayer_notice_acknowledged", false)
	var prayer = PrayerSystemMain.instantiate()
	add_child(prayer)
	await get_tree().process_frame
	var is_mock = prayer._is_offline_or_mock_mode()
	_assert_test(
		is_mock == true,
		"Prayer scene reports mock mode in tests",
		"provider=%s override=%s" % [
			str(AIManager.current_provider) if AIManager else "no_ai_manager",
			str(AIManager.is_mock_override_enabled()) if AIManager and AIManager.has_method("is_mock_override_enabled") else "n/a"
		]
	)
	prayer._maybe_show_data_notice()
	_assert_test(
		prayer._input_locked_by_notice == false,
		"Prayer mock mode bypasses notice lock",
		"notice_overlay=%s" % str(is_instance_valid(prayer._notice_overlay))
	)
	if is_instance_valid(prayer):
		prayer.queue_free()
func _test_fsm_debug() -> void:
	print("[Test] FSM debug features...")
	var FSMChallengeModule = preload("res://1.Codebase/src/scripts/core/fsm_challenge_module.gd")
	var fsm = FSMChallengeModule.new()
	fsm.start_challenge()
	_assert_test(fsm.is_challenge_active == true, "FSM challenge starts active")
	_assert_test(fsm.current_day == 1, "FSM challenge starts on day 1")
	fsm.current_day = 8
	_assert_test(fsm.current_day == 8, "FSM debug test can jump current day")
func _test_gloria_mock_mode() -> void:
	print("[Test] Gloria in mock mode...")
	var gloria = GloriaInterventionOverlay.instantiate()
	add_child(gloria)
	await get_tree().process_frame
	_assert_test(gloria.visible == true, "Gloria overlay becomes visible in mock mode")
	var emitted := {"value": false}
	gloria.continue_requested.connect(
		func():
			emitted["value"] = true,
		CONNECT_ONE_SHOT
	)
	gloria._on_continue_pressed()
	var continued := await _wait_for_flag(emitted, 1.0)
	_assert_test(continued, "Gloria mock mode emits continue_requested")
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(gloria):
		gloria.queue_free()
