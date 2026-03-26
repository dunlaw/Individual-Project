extends Node

const TrolleyProblemOverlay = preload("res://1.Codebase/src/scenes/ui/trolley_problem_overlay.tscn")
const PrayerSystem = preload("res://1.Codebase/src/scenes/ui/prayer_notice.tscn")
const PrayerSystemMain = preload("res://1.Codebase/src/scenes/ui/prayer_system.tscn")
const GloriaInterventionOverlay = preload("res://1.Codebase/src/scenes/ui/gloria_intervention_overlay.tscn")

func _ready() -> void:
	print("[TestMockModeInteractions] Starting tests...")
	await get_tree().process_frame

	await _test_trolley_mock_mode()
	await _test_prayer_mock_mode()
	_test_fsm_debug()
	await _test_gloria_mock_mode()

	print("[TestMockModeInteractions] All tests completed.")
	queue_free()

func _test_trolley_mock_mode() -> void:
	print("[Test] Trolley problem in mock mode...")
	var trolley = TrolleyProblemOverlay.instantiate()
	add_child(trolley)
	await get_tree().process_frame # Let _ready() run

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
	assert(trolley.dilemma_data.scenario == "Test Mock Scenario", "Should have set data")
	assert(trolley._choices_data.size() == 1, "Should have 1 choice")

	var emitted = false
	trolley.choice_selected.connect(func(id): emitted = (id == "c1"))

	# Simulate choosing
	trolley._try_keyboard_choice(0)

	# wait for tween
	await get_tree().create_timer(1.0).timeout
	assert(emitted == true, "Should have resolved choice and emitted signal")

	trolley.queue_free()
	print("[Test] Trolley problem mock mode passed")

func _test_prayer_mock_mode() -> void:
	print("[Test] Prayer in mock mode...")
	var prayer = PrayerSystemMain.instantiate()
	add_child(prayer)
	await get_tree().process_frame

	var is_mock = prayer._is_offline_or_mock_mode()
	assert(is_mock == true, "Should return true in unit test")

	prayer._maybe_show_data_notice()
	assert(prayer._input_locked_by_notice == false, "Should bypass notice in mock mode")

	prayer.queue_free()
	print("[Test] Prayer mock mode passed")

func _test_fsm_debug() -> void:
	print("[Test] FSM debug features...")
	var FSMChallengeModule = preload("res://1.Codebase/src/scripts/core/fsm_challenge_module.gd")
	var fsm = FSMChallengeModule.new()
	fsm.start_challenge()
	assert(fsm.is_challenge_active == true, "Should be active")
	assert(fsm.current_day == 1, "Should start at day 1")
	fsm.current_day = 8 # simulate jumping
	assert(fsm.current_day == 8, "Should update current day")
	print("[Test] FSM debug features passed")

func _test_gloria_mock_mode() -> void:
	print("[Test] Gloria in mock mode...")
	var gloria = GloriaInterventionOverlay.instantiate()
	add_child(gloria)
	await get_tree().process_frame

	# Gloria requests AI guilt trip which uses mock AI generator if AIManager is offline or missing.
	assert(gloria.visible == true, "Gloria should be visible and not crash when AI is mocked")

	var emitted = false
	gloria.continue_requested.connect(func(): emitted = true)

	# Simulate accepting
	gloria._on_continue_pressed()
	assert(emitted == true, "Should have emitted continue_requested")

	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(gloria):
		gloria.queue_free()

	print("[Test] Gloria mock mode passed")
