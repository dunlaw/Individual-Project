extends Node
const TEST_AI_PROMPT_BUILDER = preload("res://1.Codebase/Unit Test/test_ai_prompt_builder.gd")
const TEST_ASSET_REGISTRY = preload("res://1.Codebase/Unit Test/test_asset_registry.gd")
const TEST_NARRATIVE_PROMPT_SKILL_LOADING = preload("res://1.Codebase/Unit Test/test_narrative_prompt_skill_loading.gd")
func _ready() -> void:
	print("=".repeat(60))
	print("PROMPT TESTS")
	print("=".repeat(60))
	await get_tree().process_frame
	await _run_test("AIPromptBuilder", TEST_AI_PROMPT_BUILDER)
	await _run_test("AssetRegistry", TEST_ASSET_REGISTRY)
	await _run_test("NarrativePromptSkillLoading", TEST_NARRATIVE_PROMPT_SKILL_LOADING)
	print("=".repeat(60))
	print("PROMPT TESTS COMPLETED")
	print("=".repeat(60))
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()
func _run_test(test_name: String, test_script: GDScript) -> void:
	print("\n--- Running %s Tests ---" % test_name)
	var test_instance = test_script.new()
	add_child(test_instance)
	while is_instance_valid(test_instance):
		await get_tree().process_frame
	print("--- %s Tests Completed ---\n" % test_name)
