extends Node
var tests_passed: int = 0
var tests_failed: int = 0
const Library = preload("res://1.Codebase/src/scripts/core/mission_scenario_library.gd")
func _ready() -> void:
	print("[MissionScenarioLibraryTest] Starting unit tests...")
	await get_tree().process_frame
	_test_has_scenarios()
	_test_get_random_scenario()
	_test_scenario_structure()
	_test_scenario_consequence_and_followup_data()
	_test_helper_functions()
	print("[MissionScenarioLibraryTest] All tests completed.")
	queue_free()
func _test_has_scenarios() -> void:
	print("[Test] Has scenarios...")
	_assert(Library.has_scenarios(), "Library should have scenarios")
	print("[Test] Has scenarios PASSED")
func _test_get_random_scenario() -> void:
	print("[Test] Get random scenario...")
	for i in range(10):
		var scenario = Library.get_random_scenario()
		_assert(not scenario.is_empty(), "Should return a non-empty scenario")
		_assert(scenario.has("id"), "Scenario should have ID")
		_assert(scenario.has("assets"), "Scenario should have assets")
		_assert(scenario.has("fallback"), "Scenario should have fallback data")
	print("[Test] Get random scenario PASSED")
func _test_scenario_structure() -> void:
	print("[Test] Scenario structure validation...")
	for scenario in Library.SCENARIOS:
		_assert(scenario.has("id") and scenario.id is String, "ID validation")
		_assert(scenario.has("assets") and scenario.assets is Array, "Assets validation")
		_assert(scenario.has("translation_keys") and scenario.translation_keys is Dictionary, "Translation keys validation")
		var fallback = scenario.get("fallback", {})
		_assert(not fallback.is_empty(), "Fallback validation")
		_assert(fallback.has("title"), "Fallback title")
		_assert(fallback.has("description"), "Fallback description")
		_assert(fallback.has("choices") and fallback.choices is Array, "Fallback choices")
		_assert(fallback.choices.size() >= 2, "Should have at least 2 choices")
	print("[Test] Scenario structure validation PASSED")
func _test_scenario_consequence_and_followup_data() -> void:
	print("[Test] Scenario consequence and followup data...")
	for scenario in Library.SCENARIOS:
		var fallback = scenario.get("fallback", {})
		var sid = scenario.get("id", "unknown")
		_assert(fallback.has("consequence_success"), "%s should have consequence_success" % sid)
		_assert(fallback.has("consequence_fail"), "%s should have consequence_fail" % sid)
		_assert(fallback.has("followup_choices"), "%s should have followup_choices" % sid)
		var cs = fallback.get("consequence_success", [])
		var cf = fallback.get("consequence_fail", [])
		var fc = fallback.get("followup_choices", [])
		_assert(cs is Array and cs.size() >= 3, "%s consequence_success should have >= 3 entries" % sid)
		_assert(cf is Array and cf.size() >= 3, "%s consequence_fail should have >= 3 entries" % sid)
		_assert(fc is Array and fc.size() >= 5, "%s followup_choices should have >= 5 entries" % sid)
		for entry in fc:
			_assert(entry is Dictionary, "%s followup_choices entries should be dictionaries" % sid)
			if entry is Dictionary:
				_assert(entry.has("archetype"), "%s followup choice should have archetype" % sid)
				_assert(entry.has("summary"), "%s followup choice should have summary" % sid)
	print("[Test] Scenario consequence and followup data PASSED")
func _test_helper_functions() -> void:
	print("[Test] Helper functions...")
	var context_en = {"language": "en"}
	var lang_en = Library._resolve_language(context_en)
	_assert(lang_en == "en", "Should resolve en")
	var context_zh = {"language": "zh"}
	var lang_zh = Library._resolve_language(context_zh)
	_assert(lang_zh == "zh", "Should resolve zh")
	var context_empty = {}
	var lang_default = Library._resolve_language(context_empty)
	_assert(lang_default == "en", "Should default to en")
	print("[Test] Helper functions PASSED")
func _assert(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
		print("    PASS  %s" % message)
	else:
		tests_failed += 1
		print("    FAIL  %s" % message)
