extends Node
const NarrativePromptBuilder = preload("res://1.Codebase/src/scripts/core/ai/narrative_prompt_builder.gd")
const TrolleyGeneratorScript = preload("res://1.Codebase/src/scripts/core/trolley_problem_generator.gd")
var tests_passed: int = 0
var tests_failed: int = 0
class MockGameState:
	extends RefCounted
	var current_language: String = "en"
	var reality_score: int = 42
	var positive_energy: int = 77
	var entropy_level: int = 13
	var _honeymoon: bool = false
	func is_in_honeymoon() -> bool:
		return _honeymoon
func _ready() -> void:
	print("[NarrativePromptSkillLoadingTest] Starting...")
	await get_tree().process_frame
	var skill_mgr := _get_skill_manager()
	_assert(skill_mgr != null, "SkillManager should be available")
	if skill_mgr == null:
		_finish()
		return
	if not skill_mgr.is_initialized():
		skill_mgr.reload_skills()
		await get_tree().process_frame
	_test_required_skills_exist(skill_mgr)
	_test_mission_prompt_uses_skill()
	_test_consequence_prompt_uses_skill()
	_test_interference_prompt_uses_skill_and_replaces_tokens()
	_test_gloria_prompt_uses_skill_and_replaces_tokens()
	_test_choice_followup_prompt_uses_skill_and_replaces_tokens()
	_test_trolley_prompt_uses_skill()
	_finish()
func _finish() -> void:
	print("[NarrativePromptSkillLoadingTest] Completed. passed=%d failed=%d" % [tests_passed, tests_failed])
	queue_free()
func _get_skill_manager() -> Node:
	var tree := get_tree()
	if tree and tree.root:
		var service_locator := tree.root.get_node_or_null("ServiceLocator")
		if service_locator and service_locator.has_method("get_skill_manager"):
			var skill_mgr: Variant = service_locator.call("get_skill_manager")
			if skill_mgr != null:
				return skill_mgr
		return tree.root.get_node_or_null("SkillManager")
	return null
func _test_required_skills_exist(skill_mgr: Node) -> void:
	var names: Array = skill_mgr.get_all_skill_names()
	_assert("mission-generation" in names, "mission-generation skill exists")
	_assert("consequence-generation" in names, "consequence-generation skill exists")
	_assert("teammate-interference" in names, "teammate-interference skill exists")
	_assert("gloria-intervention" in names, "gloria-intervention skill exists")
	_assert("choice-followup" in names, "choice-followup skill exists")
	_assert("trolley-problem" in names, "trolley-problem skill exists")
func _test_mission_prompt_uses_skill() -> void:
	var gs := MockGameState.new()
	var prompt: String = NarrativePromptBuilder.build_mission_prompt(gs, [], null)
	_assert(prompt.contains("Mission Generation Rules"), "Mission prompt should include mission-generation skill body")
func _test_consequence_prompt_uses_skill() -> void:
	var prompt: String = NarrativePromptBuilder.build_consequence_prompt(
		{"text": "Take the risky shortcut"},
		true,
		"en",
		false
	)
	_assert(prompt.contains("Consequence Generation Rules"), "Consequence prompt should include consequence-generation skill body")
func _test_interference_prompt_uses_skill_and_replaces_tokens() -> void:
	var prompt: String = NarrativePromptBuilder.build_interference_prompt(
		"donkey",
		"Open the vault",
		"en",
		false
	)
	_assert(prompt.contains("Teammate Interference Rules"), "Interference prompt should include teammate-interference skill body")
	_assert(not prompt.contains("{name}"), "Interference prompt should replace {name}")
	_assert(not prompt.contains("{action}"), "Interference prompt should replace {action}")
	_assert(prompt.contains("Donkey"), "Interference prompt should contain teammate display name")
	_assert(prompt.contains("Open the vault"), "Interference prompt should contain action text")
func _test_gloria_prompt_uses_skill_and_replaces_tokens() -> void:
	var prompt: String = NarrativePromptBuilder.build_gloria_prompt(
		{"text": "Refuse to smile on command"},
		"en"
	)
	_assert(prompt.contains("Gloria's Positive Energy Bombardment"), "Gloria prompt should include gloria-intervention skill body")
	_assert(not prompt.contains("{choice_text}"), "Gloria prompt should replace {choice_text}")
	_assert(prompt.contains("Refuse to smile on command"), "Gloria prompt should include choice text")
func _test_choice_followup_prompt_uses_skill_and_replaces_tokens() -> void:
	var excerpt := "The team entered the silent archive and the lights went out."
	var prompt: String = NarrativePromptBuilder.build_choice_followup_prompt(excerpt, "en")
	_assert(prompt.contains("Choice Summary Follow-up"), "Choice follow-up prompt should include choice-followup skill body")
	_assert(not prompt.contains("{story_excerpt}"), "Choice follow-up prompt should replace {story_excerpt}")
	_assert(prompt.contains(excerpt), "Choice follow-up prompt should include excerpt text")
func _test_trolley_prompt_uses_skill() -> void:
	var generator = TrolleyGeneratorScript.new()
	add_child(generator)
	var template := {
		"setup": "A runaway trolley problem with a GDA twist",
		"choice_count": 2,
	}
	var prompt: String = generator._build_dilemma_prompt_from_skill(
		"classic",
		template,
		"en",
		50,
		60,
		"A fragile public hearing is about to collapse.",
		[]
	)
	_assert(prompt.contains("Trolley Problem Generation Rules"), "Trolley prompt should include trolley-problem skill body")
	_assert(prompt.contains("Required choice count: 2"), "Trolley prompt should include context header")
	generator.queue_free()
func _assert(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
		print("    PASS  %s" % message)
	else:
		tests_failed += 1
		print("    FAIL  %s" % message)
