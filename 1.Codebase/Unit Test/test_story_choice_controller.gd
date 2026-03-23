extends Node
var tests_passed: int = 0
var tests_failed: int = 0
const StoryChoiceControllerScript = preload("res://1.Codebase/src/scripts/ui/story_choice_controller.gd")
var controller
var mock_scene
func _ready() -> void:
	print("Starting StoryChoiceController Tests")
	mock_scene = Control.new()
	var mock_script = GDScript.new()
	mock_script.source_code = """
extends Control
var in_night_cycle: bool = false
var awaiting_ai_response: bool = false
var ui_controller = null
var narrative_controller = null
var overlay_controller = null
var ui = null
"""
	mock_script.reload()
	mock_scene.set_script(mock_script)
	add_child(mock_scene)
	var choices_area = Control.new()
	choices_area.name = "ChoicesArea"
	mock_scene.add_child(choices_area)
	var choices_container = VBoxContainer.new()
	choices_container.name = "ChoicesContainer"
	choices_area.add_child(choices_container)
	for i in range(1, 4):
		var btn = Button.new()
		btn.name = "Choice%d" % i
		choices_container.add_child(btn)
	var show_btn = Button.new()
	show_btn.name = "ShowOptionsBtn"
	choices_area.add_child(show_btn)
	controller = StoryChoiceControllerScript.new(mock_scene)
	_record_result(controller != null, "StoryChoiceController instantiated")
	await _test_choice_generation()
	await _test_choice_processing()
	mock_scene.queue_free()
	print("[StoryChoiceControllerTest] Summary: %d passed, %d failed" % [tests_passed, tests_failed])
	queue_free()
func _test_choice_generation() -> void:
	print("Testing Choice Generation...")
	if GameState:
		var old_stats = GameState.player_stats
		GameState.player_stats = {"logic": 5, "perception": 1, "composure": 1, "empathy": 1}
		controller.generate_choices()
		var choices = controller.current_choices
		_record_result(choices.size() > 0, "Choices generated")
		if choices.size() > 0:
			var types = []
			for c in choices:
				types.append(c["type"])
			_record_result("logic" in types, "Logic skill choice generated")
			_record_result("positive" in types and "complain" in types, "Default choices present")
		GameState.player_stats = old_stats
	await get_tree().process_frame
func _test_choice_processing() -> void:
	print("Testing Choice Processing...")
	var mock_ui = Node.new()
	var ui_script = GDScript.new()
	ui_script.source_code = """
extends Node
func set_status_text(txt): pass
func display_story(txt): pass
"""
	ui_script.reload()
	mock_ui.set_script(ui_script)
	mock_scene.ui_controller = mock_ui
	mock_scene.add_child(mock_ui)
	if controller.current_choices.size() > 0:
		var choice = controller.current_choices[0]
		controller.process_choice(choice)
		_record_result(true, "process_choice executed without error")
	else:
		_record_result(false, "process_choice executed without error")
	await get_tree().process_frame
func _record_result(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
		print("PASS: %s" % message)
	else:
		tests_failed += 1
		print("FAIL: %s" % message)
