extends Node
const StoryChoiceController = preload("res://1.Codebase/src/scripts/ui/story_choice_controller.gd")
const StoryStateController = preload("res://1.Codebase/src/scripts/ui/story_state_controller.gd")
var tests_passed: int = 0
var tests_failed: int = 0
func _assert_test(condition: bool, label: String, details: String = "") -> void:
	if condition:
		tests_passed += 1
		print("    PASS  %s" % label)
		return
	tests_failed += 1
	print("    FAIL  %s%s" % [label, (": %s" % details) if not details.is_empty() else ""])
func _create_state_controller() -> Dictionary:
	var mock_story_scene := Control.new()
	add_child(mock_story_scene)
	var state_controller := StoryStateController.new(mock_story_scene)
	return {
		"scene": mock_story_scene,
		"state_controller": state_controller,
	}
func test_choice_controller_sets_context_correctly() -> void:
	print("[Test] Testing prayer context from choice selection")
	var setup := _create_state_controller()
	var mock_story_scene: Control = setup["scene"]
	var state_controller: StoryStateController = setup["state_controller"]
	var choice_controller = StoryChoiceController.new(mock_story_scene)
	var initial_context = state_controller.get_prayer_context()
	print("[Test] Initial prayer context: %s" % initial_context)
	_assert_test(initial_context == "mission", "Initial prayer context is mission")
	state_controller.set_prayer_context(choice_controller.PRAYER_CONTEXT_MISSION)
	var context_after_choice = state_controller.get_prayer_context()
	print("[Test] Prayer context after choice selection: %s" % context_after_choice)
	_assert_test(context_after_choice == "mission", "Choice flow keeps mission context")
	mock_story_scene.queue_free()
func test_night_overlay_sets_context_correctly() -> void:
	print("[Test] Testing prayer context from night overlay")
	var setup := _create_state_controller()
	var mock_story_scene: Control = setup["scene"]
	var state_controller: StoryStateController = setup["state_controller"]
	var initial_context = state_controller.get_prayer_context()
	print("[Test] Initial prayer context: %s" % initial_context)
	_assert_test(initial_context == "mission", "Night flow starts from mission context")
	state_controller.set_prayer_context(StoryStateController.PRAYER_CONTEXT_NIGHT)
	var context_after_night = state_controller.get_prayer_context()
	print("[Test] Prayer context after night overlay request: %s" % context_after_night)
	_assert_test(context_after_night == "night", "Night flow switches to night context")
	mock_story_scene.queue_free()
func test_context_consistency() -> void:
	print("[Test] Testing context consistency between different entry points")
	var setup := _create_state_controller()
	var mock_story_scene: Control = setup["scene"]
	var state_controller: StoryStateController = setup["state_controller"]
	state_controller.set_prayer_context("mission")
	_assert_test(state_controller.get_prayer_context() == "mission", "Mission context is accepted")
	state_controller.set_prayer_context("night")
	_assert_test(state_controller.get_prayer_context() == "night", "Night context is accepted")
	state_controller.set_prayer_context("mission")
	_assert_test(state_controller.get_prayer_context() == "mission", "Context can switch back to mission")
	mock_story_scene.queue_free()
func _ready() -> void:
	print("===== Prayer Context Fix Test Suite =====")
	test_choice_controller_sets_context_correctly()
	print("")
	test_night_overlay_sets_context_correctly()
	print("")
	test_context_consistency()
	print("")
	print("===== Prayer Context Fix Summary: %d passed, %d failed =====" % [tests_passed, tests_failed])
	queue_free()
