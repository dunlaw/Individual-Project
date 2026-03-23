extends Node
var tests_passed: int = 0
var tests_failed: int = 0
var initial_completed: Dictionary = {}
var initial_enabled: bool = true
var initial_game_started: bool = false
var initial_startup_grace_elapsed: bool = false
func _ready() -> void:
	print("[TutorialSystemTest] Starting TutorialSystem unit tests...")
	await get_tree().process_frame
	if not TutorialSystem:
		_assert_test(false, "TutorialSystem autoload exists")
		print("[TutorialSystemTest] Summary: %d passed, %d failed" % [tests_passed, tests_failed])
		queue_free()
		return
	initial_completed = TutorialSystem.completed_tutorials.duplicate(true)
	initial_enabled = TutorialSystem.tutorial_enabled
	initial_game_started = TutorialSystem.game_started
	initial_startup_grace_elapsed = TutorialSystem._startup_grace_elapsed
	_test_initialization()
	_test_tutorial_steps_definition()
	_test_tutorial_enabled_toggle()
	await _test_check_tutorial_trigger()
	_test_is_tutorial_completed()
	_test_get_tutorial_progress()
	_test_get_all_tutorial_steps()
	_test_get_completed_tutorials()
	await _test_signal_emission()
	await _test_save_load_persistence()
	_test_reset_tutorials()
	await _test_all_tutorials_complete_check()
	TutorialSystem.completed_tutorials = initial_completed.duplicate(true)
	TutorialSystem.tutorial_enabled = initial_enabled
	TutorialSystem.game_started = initial_game_started
	TutorialSystem._startup_grace_elapsed = initial_startup_grace_elapsed
	TutorialSystem.save_tutorial_progress()
	_cleanup_popup()
	print("[TutorialSystemTest] Summary: %d passed, %d failed" % [tests_passed, tests_failed])
	queue_free()
func _assert_test(condition: bool, label: String, details: String = "") -> void:
	if condition:
		tests_passed += 1
		print("    PASS  %s" % label)
		return
	tests_failed += 1
	print("    FAIL  %s%s" % [label, (": %s" % details) if not details.is_empty() else ""])
func _cleanup_popup() -> void:
	if TutorialSystem.current_tutorial_popup and is_instance_valid(TutorialSystem.current_tutorial_popup):
		TutorialSystem.current_tutorial_popup.queue_free()
	TutorialSystem.current_tutorial_popup = null
func _prepare_triggerable_state() -> void:
	_cleanup_popup()
	TutorialSystem.reset_tutorials()
	TutorialSystem.set_tutorial_enabled(true)
	TutorialSystem.game_started = true
	TutorialSystem._startup_grace_elapsed = true
func _test_initialization() -> void:
	print("[Test] Initialization...")
	_assert_test(TutorialSystem != null, "TutorialSystem autoload exists")
	_assert_test(TutorialSystem.tutorial_steps is Array, "tutorial_steps is an Array")
	_assert_test(TutorialSystem.completed_tutorials is Dictionary, "completed_tutorials is a Dictionary")
	_assert_test(TutorialSystem.tutorial_enabled is bool, "tutorial_enabled is a bool")
	_assert_test(TutorialSystem.tutorial_steps.size() > 0, "Tutorial steps are defined")
func _test_tutorial_steps_definition() -> void:
	print("[Test] Tutorial steps definition...")
	for step in TutorialSystem.tutorial_steps:
		_assert_test(step.has("id"), "Tutorial step has id")
		_assert_test(step.has("trigger"), "Tutorial step has trigger")
		_assert_test(step.has("priority"), "Tutorial step has priority")
		_assert_test(step["id"] is String, "Tutorial id is String")
		_assert_test(step["trigger"] is String, "Tutorial trigger is String")
		_assert_test(step["priority"] is int, "Tutorial priority is int")
	var tutorial_ids: Array = []
	for step in TutorialSystem.tutorial_steps:
		tutorial_ids.append(step["id"])
	_assert_test("first_choice" in tutorial_ids, "Tutorial list includes first_choice")
	_assert_test("first_stat_change" in tutorial_ids, "Tutorial list includes first_stat_change")
func _test_tutorial_enabled_toggle() -> void:
	print("[Test] Tutorial enabled toggle...")
	TutorialSystem.set_tutorial_enabled(true)
	_assert_test(TutorialSystem.tutorial_enabled == true, "Tutorials can be enabled")
	TutorialSystem.set_tutorial_enabled(false)
	_assert_test(TutorialSystem.tutorial_enabled == false, "Tutorials can be disabled")
	TutorialSystem.set_tutorial_enabled(true)
func _test_check_tutorial_trigger() -> void:
	print("[Test] Check tutorial trigger...")
	_prepare_triggerable_state()
	TutorialSystem.check_tutorial_trigger("first_choice")
	await get_tree().create_timer(0.1).timeout
	_assert_test(TutorialSystem.is_tutorial_completed("first_choice"), "first_choice trigger marks tutorial completed")
	TutorialSystem.check_tutorial_trigger("first_choice")
	await get_tree().create_timer(0.05).timeout
	_assert_test(TutorialSystem.completed_tutorials["first_choice"] == true, "Tutorial trigger does not duplicate completion")
	_cleanup_popup()
func _test_is_tutorial_completed() -> void:
	print("[Test] Is tutorial completed...")
	TutorialSystem.reset_tutorials()
	_assert_test(not TutorialSystem.is_tutorial_completed("first_choice"), "first_choice starts incomplete")
	_assert_test(not TutorialSystem.is_tutorial_completed("first_stat_change"), "first_stat_change starts incomplete")
	TutorialSystem.completed_tutorials["first_choice"] = true
	_assert_test(TutorialSystem.is_tutorial_completed("first_choice"), "Completed tutorial returns true")
	_assert_test(not TutorialSystem.is_tutorial_completed("first_stat_change"), "Other tutorials remain incomplete")
	_assert_test(not TutorialSystem.is_tutorial_completed("nonexistent_tutorial"), "Unknown tutorial returns false")
func _test_get_tutorial_progress() -> void:
	print("[Test] Get tutorial progress...")
	TutorialSystem.reset_tutorials()
	var progress_0 = TutorialSystem.get_tutorial_progress()
	_assert_test(progress_0 == 0.0, "Progress starts at 0 percent")
	var total_tutorials = TutorialSystem.tutorial_steps.size()
	if total_tutorials > 0:
		TutorialSystem.completed_tutorials["first_choice"] = true
		var progress_1 = TutorialSystem.get_tutorial_progress()
		var expected = (1.0 / total_tutorials) * 100.0
		_assert_test(abs(progress_1 - expected) < 0.1, "Progress reflects one completed tutorial")
	for step in TutorialSystem.tutorial_steps:
		TutorialSystem.completed_tutorials[step["id"]] = true
	var progress_100 = TutorialSystem.get_tutorial_progress()
	_assert_test(abs(progress_100 - 100.0) < 0.1, "Progress reaches 100 percent")
func _test_get_all_tutorial_steps() -> void:
	print("[Test] Get all tutorial steps...")
	var steps = TutorialSystem.get_all_tutorial_steps()
	_assert_test(steps is Array, "get_all_tutorial_steps returns Array")
	_assert_test(steps.size() == TutorialSystem.tutorial_steps.size(), "get_all_tutorial_steps returns all steps")
	if steps.size() > 0:
		var original_id = TutorialSystem.tutorial_steps[0]["id"]
		steps[0]["id"] = "modified_id_test"
		_assert_test(TutorialSystem.tutorial_steps[0]["id"] == original_id, "Tutorial steps are returned as a copy")
func _test_get_completed_tutorials() -> void:
	print("[Test] Get completed tutorials...")
	TutorialSystem.reset_tutorials()
	TutorialSystem.completed_tutorials["first_choice"] = true
	TutorialSystem.completed_tutorials["first_stat_change"] = true
	var completed = TutorialSystem.get_completed_tutorials()
	_assert_test(completed is Array, "get_completed_tutorials returns Array")
	_assert_test(completed.size() == 2, "get_completed_tutorials returns both completed ids")
	_assert_test("first_choice" in completed, "Completed list includes first_choice")
	_assert_test("first_stat_change" in completed, "Completed list includes first_stat_change")
	TutorialSystem.reset_tutorials()
	completed = TutorialSystem.get_completed_tutorials()
	_assert_test(completed.size() == 0, "Completed list resets to empty")
func _test_signal_emission() -> void:
	print("[Test] Signal emission...")
	var tutorial_triggered_state := {"called": false, "step": {}}
	var tutorial_completed_state := {"called": false, "id": ""}
	var trigger_handler = func(step: Dictionary):
		tutorial_triggered_state["called"] = true
		tutorial_triggered_state["step"] = step.duplicate(true)
	var complete_handler = func(step_id: String):
		tutorial_completed_state["called"] = true
		tutorial_completed_state["id"] = step_id
	TutorialSystem.tutorial_triggered.connect(trigger_handler)
	TutorialSystem.tutorial_completed.connect(complete_handler)
	_prepare_triggerable_state()
	TutorialSystem.check_tutorial_trigger("first_prayer")
	await get_tree().create_timer(0.1).timeout
	_assert_test(bool(tutorial_triggered_state["called"]), "tutorial_triggered signal is emitted")
	_assert_test(bool(tutorial_completed_state["called"]), "tutorial_completed signal is emitted")
	_assert_test(String(tutorial_completed_state["id"]) == "first_prayer", "tutorial_completed emits the right id")
	TutorialSystem.tutorial_triggered.disconnect(trigger_handler)
	TutorialSystem.tutorial_completed.disconnect(complete_handler)
	_cleanup_popup()
func _test_save_load_persistence() -> void:
	print("[Test] Save/load persistence...")
	TutorialSystem.reset_tutorials()
	TutorialSystem.completed_tutorials["first_choice"] = true
	TutorialSystem.completed_tutorials["first_mission"] = true
	TutorialSystem.save_tutorial_progress()
	await get_tree().create_timer(0.1).timeout
	var saved_completed = TutorialSystem.completed_tutorials.duplicate(true)
	TutorialSystem.completed_tutorials.clear()
	_assert_test(TutorialSystem.completed_tutorials.size() == 0, "Tutorial progress can be cleared in memory")
	TutorialSystem.load_tutorial_progress()
	await get_tree().create_timer(0.1).timeout
	_assert_test(TutorialSystem.is_tutorial_completed("first_choice"), "Saved tutorial progress restores first_choice")
	_assert_test(TutorialSystem.is_tutorial_completed("first_mission"), "Saved tutorial progress restores first_mission")
	_assert_test(TutorialSystem.completed_tutorials == saved_completed, "Loaded tutorial progress matches saved snapshot")
func _test_reset_tutorials() -> void:
	print("[Test] Reset tutorials...")
	TutorialSystem.completed_tutorials["first_choice"] = true
	TutorialSystem.completed_tutorials["first_stat_change"] = true
	TutorialSystem.completed_tutorials["first_prayer"] = true
	_assert_test(TutorialSystem.completed_tutorials.size() > 0, "Reset test begins with completed tutorials")
	TutorialSystem.reset_tutorials()
	_assert_test(TutorialSystem.completed_tutorials.size() == 0, "reset_tutorials clears completed tutorials")
	_assert_test(not TutorialSystem.is_tutorial_completed("first_choice"), "first_choice is cleared by reset")
	_assert_test(not TutorialSystem.is_tutorial_completed("first_stat_change"), "first_stat_change is cleared by reset")
func _test_all_tutorials_complete_check() -> void:
	print("[Test] All tutorials complete check...")
	var all_complete_state := {"called": false}
	var complete_handler = func():
		all_complete_state["called"] = true
	TutorialSystem.all_tutorials_completed.connect(complete_handler)
	TutorialSystem.reset_tutorials()
	for step in TutorialSystem.tutorial_steps:
		TutorialSystem.completed_tutorials[step["id"]] = false
	for i in range(TutorialSystem.tutorial_steps.size() - 1):
		TutorialSystem.completed_tutorials[TutorialSystem.tutorial_steps[i]["id"]] = true
	TutorialSystem.check_all_tutorials_complete()
	await get_tree().create_timer(0.05).timeout
	_assert_test(not bool(all_complete_state["called"]), "all_tutorials_completed stays silent when one tutorial is missing")
	var last_step = TutorialSystem.tutorial_steps[TutorialSystem.tutorial_steps.size() - 1]
	TutorialSystem.completed_tutorials[last_step["id"]] = true
	TutorialSystem.check_all_tutorials_complete()
	await get_tree().create_timer(0.05).timeout
	_assert_test(bool(all_complete_state["called"]), "all_tutorials_completed emits after final tutorial")
	TutorialSystem.all_tutorials_completed.disconnect(complete_handler)
