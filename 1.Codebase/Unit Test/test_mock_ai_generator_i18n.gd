extends Node
var tests_passed: int = 0
var tests_failed: int = 0
const MockGen = preload("res://1.Codebase/src/scripts/core/mock_ai_generator.gd")
func _ready() -> void:
	print("[MockAIGeneratorI18nTest] Starting unit tests...")
	await get_tree().process_frame
	_test_resolve_language()
	_test_build_random_story_chinese()
	_test_build_random_story_english()
	_test_generate_consequence_chinese()
	_test_generate_prayer_chinese()
	_test_generate_interference_chinese()
	_test_generate_gloria_intervention_chinese()
	_test_scenario_memory_set_on_mission()
	_test_scenario_memory_consequence_coherence()
	_test_scenario_memory_followup_coherence()
	_test_scenario_memory_cleared_on_night_cycle()
	print("[MockAIGeneratorI18nTest] All tests completed.")
	queue_free()
func _test_resolve_language() -> void:
	print("[Test] Language resolution...")
	var context_zh = {"language": "zh"}
	var lang_zh = MockGen._resolve_language(context_zh)
	_assert(lang_zh == "zh", "Should resolve zh from context")
	var context_en = {"language": "en"}
	var lang_en = MockGen._resolve_language(context_en)
	_assert(lang_en == "en", "Should resolve en from context")
	var context_empty = {}
	var lang_default = MockGen._resolve_language(context_empty)
	_assert(lang_default in ["en", "zh"], "Should resolve to a valid language")
	print("[Test] Language resolution PASSED")
func _test_build_random_story_chinese() -> void:
	print("[Test] Build random story (Chinese)...")
	var context = {
		"language": "zh",
		"reality_score": 50,
		"positive_energy": 30,
		"entropy_level": 20
	}
	var story = MockGen._build_random_story(context)
	_assert(story.length() > 0, "Story should not be empty")
	_assert(_contains_chinese_chars(story), "Story should contain Chinese characters")
	_assert(LocalizationManager.get_translation("MOCK_STORY_CONTEXT_LABEL", "zh") in story or LocalizationManager.get_translation("MOCK_STORY_OBJECTIVE_LABEL", "zh") in story or LocalizationManager.get_translation("MOCK_STORY_COMPLICATION_LABEL", "zh") in story, "Should contain Chinese labels")
	print("[Test] Build random story (Chinese) PASSED")
func _test_build_random_story_english() -> void:
	print("[Test] Build random story (English)...")
	var context = {
		"language": "en",
		"reality_score": 50,
		"positive_energy": 30,
		"entropy_level": 20
	}
	var story = MockGen._build_random_story(context)
	_assert(story.length() > 0, "Story should not be empty")
	_assert("Context:" in story or "Objective:" in story or "Known complication:" in story, "Should contain English labels")
	print("[Test] Build random story (English) PASSED")
func _test_generate_consequence_chinese() -> void:
	print("[Test] Generate consequence (Chinese)...")
	var context = {
		"language": "zh",
		"choice_text": LocalizationManager.get_translation("TEST_CHOICE_ZH", "zh") if LocalizationManager else "Test Choice",
		"success": true
	}
	var json_result = MockGen._generate_consequence(context)
	var parsed = JSON.parse_string(json_result)
	_assert(parsed != null, "Should parse valid JSON")
	_assert(parsed.has("story_text"), "Should have story_text")
	_assert(_contains_chinese_chars(parsed["story_text"]), "Consequence should contain Chinese characters")
	print("[Test] Generate consequence (Chinese) PASSED")
func _test_generate_prayer_chinese() -> void:
	print("[Test] Generate prayer (Chinese)...")
	var context = {
		"language": "zh",
		"prayer_text": LocalizationManager.get_translation("TEST_PRAYER_ZH", "zh") if LocalizationManager else "World Peace",
		"reality_score": 50
	}
	var result = MockGen._generate_prayer(context)
	_assert(result.length() > 0, "Prayer result should not be empty")
	_assert(_contains_chinese_chars(result), "Prayer result should contain Chinese characters")
	_assert((LocalizationManager.get_translation("TEST_PRAYER_ZH", "zh") if LocalizationManager else "World Peace") in result, "Should include the prayer text")
	print("[Test] Generate prayer (Chinese) PASSED")
func _test_generate_interference_chinese() -> void:
	print("[Test] Generate interference (Chinese)...")
	var teammates = ["gloria", "donkey", "ark", "one"]
	for teammate in teammates:
		var context = {
			"language": "zh",
			"teammate_id": teammate,
			"action": LocalizationManager.get_translation("TEST_ACTION_ZH", "zh") if LocalizationManager else "Test Action"
		}
		var result = MockGen._generate_interference(context)
		_assert(result.length() > 0, "Interference result should not be empty for " + teammate)
		_assert(_contains_chinese_chars(result), "Interference should contain Chinese characters for " + teammate)
	print("[Test] Generate interference (Chinese) PASSED")
func _test_generate_gloria_intervention_chinese() -> void:
	print("[Test] Generate Gloria intervention (Chinese)...")
	var context = {
		"language": "zh",
		"choice": {
			"text": LocalizationManager.get_translation("TEST_DECISION_ZH", "zh") if LocalizationManager else "Test Decision"
		}
	}
	var json_result = MockGen._generate_gloria_intervention(context)
	var parsed = JSON.parse_string(json_result)
	_assert(parsed != null, "Should parse valid JSON")
	_assert(parsed.has("speech"), "Should have speech")
	_assert(_contains_chinese_chars(parsed["speech"]), "Gloria intervention should contain Chinese characters")
	print("[Test] Generate Gloria intervention (Chinese) PASSED")
func _test_scenario_memory_set_on_mission() -> void:
	print("[Test] Scenario memory set on mission generation...")
	const Library = preload("res://1.Codebase/src/scripts/core/mission_scenario_library.gd")
	Library.reset_scenario_tracking()
	MockGen._current_scenario = {}
	var context = {"purpose": "new_mission", "language": "en"}
	var result = MockGen._generate_mission(context)
	_assert(not MockGen._current_scenario.is_empty(), "Current scenario should be set after mission generation")
	_assert(MockGen._current_scenario.has("id"), "Current scenario should have an id")
	_assert(MockGen._current_scenario.get("id", "") == "neon_cacophony", "First scenario should be neon_cacophony")
	print("[Test] Scenario memory set on mission generation PASSED")
func _test_scenario_memory_consequence_coherence() -> void:
	print("[Test] Scenario memory consequence coherence...")
	const Library = preload("res://1.Codebase/src/scripts/core/mission_scenario_library.gd")
	Library.reset_scenario_tracking()
	MockGen._current_scenario = {}
	# Generate a mission first to set the scenario
	MockGen._generate_mission({"purpose": "new_mission", "language": "en"})
	var scenario_id = MockGen._current_scenario.get("id", "")
	_assert(not scenario_id.is_empty(), "Scenario should be set")
	# Generate consequence - should use scenario-specific text
	var consequence_json = MockGen._generate_consequence({"language": "en", "choice": {"text": "test choice"}, "success": true})
	var parsed = JSON.parse_string(consequence_json)
	_assert(parsed != null, "Consequence should parse as valid JSON")
	_assert(parsed.has("story_text"), "Consequence should have story_text")
	var story: String = parsed.get("story_text", "")
	# Scenario-specific consequences should NOT contain the generic opening format
	var fallback: Dictionary = MockGen._current_scenario.get("fallback", {})
	var expected_pool: Array = fallback.get("consequence_success", [])
	var found_scenario_text := false
	for entry in expected_pool:
		if str(entry) in story:
			found_scenario_text = true
			break
	_assert(found_scenario_text, "Consequence story should contain scenario-specific text (scenario: %s)" % scenario_id)
	print("[Test] Scenario memory consequence coherence PASSED")
func _test_scenario_memory_followup_coherence() -> void:
	print("[Test] Scenario memory followup coherence...")
	const Library = preload("res://1.Codebase/src/scripts/core/mission_scenario_library.gd")
	Library.reset_scenario_tracking()
	MockGen._current_scenario = {}
	# Generate a mission first to set the scenario
	MockGen._generate_mission({"purpose": "new_mission", "language": "en"})
	var scenario_id = MockGen._current_scenario.get("id", "")
	# Generate choice followup
	var followup_json = MockGen._generate_choice_followup({"language": "en"})
	var parsed = JSON.parse_string(followup_json)
	_assert(parsed != null, "Followup should parse as valid JSON")
	_assert(parsed.has("choices"), "Followup should have choices")
	var choices: Array = parsed.get("choices", [])
	_assert(choices.size() >= 5, "Should have at least 5 choices")
	# Check that choices come from scenario, not generic
	var fallback: Dictionary = MockGen._current_scenario.get("fallback", {})
	var expected_choices: Array = fallback.get("followup_choices", [])
	if expected_choices.size() >= 5:
		var first_expected: Dictionary = expected_choices[0] as Dictionary
		var first_actual: Dictionary = choices[0] as Dictionary
		_assert(first_actual.get("summary", "") == first_expected.get("summary", "NO_MATCH"), "First followup choice should match scenario-specific choice (scenario: %s)" % scenario_id)
	print("[Test] Scenario memory followup coherence PASSED")
func _test_scenario_memory_cleared_on_night_cycle() -> void:
	print("[Test] Scenario memory cleared on night cycle...")
	const Library = preload("res://1.Codebase/src/scripts/core/mission_scenario_library.gd")
	Library.reset_scenario_tracking()
	MockGen._current_scenario = {}
	# Generate a mission to set scenario
	MockGen._generate_mission({"purpose": "new_mission", "language": "en"})
	_assert(not MockGen._current_scenario.is_empty(), "Scenario should be set before night cycle")
	# Generate night cycle - should clear scenario
	MockGen._generate_night_cycle({"language": "en", "last_text": "test"})
	_assert(MockGen._current_scenario.is_empty(), "Scenario should be cleared after night cycle")
	print("[Test] Scenario memory cleared on night cycle PASSED")
func _contains_chinese_chars(text: String) -> bool:
	for i in range(text.length()):
		var char_code = text.unicode_at(i)
		if char_code >= 0x4E00 and char_code <= 0x9FFF:
			return true
	return false
func _assert(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
		print("    PASS  %s" % message)
	else:
		tests_failed += 1
		print("    FAIL  %s" % message)
