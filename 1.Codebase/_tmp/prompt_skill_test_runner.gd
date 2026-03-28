extends Node

const TEST_SCRIPT = preload("res://1.Codebase/Unit Test/test_narrative_prompt_skill_loading.gd")

var _test_node: Node = null

func _ready() -> void:
	print("[PromptSkillTestRunner] Boot")
	_test_node = TEST_SCRIPT.new()
	add_child(_test_node)

func _process(_delta: float) -> void:
	if _test_node != null and not is_instance_valid(_test_node):
		print("[PromptSkillTestRunner] Test node finished; quitting.")
		get_tree().quit(0)
