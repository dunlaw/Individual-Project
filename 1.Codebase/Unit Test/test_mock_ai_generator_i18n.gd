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
