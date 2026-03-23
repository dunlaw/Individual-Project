extends Node
var tests_passed: int = 0
var tests_failed: int = 0
const TrolleyGeneratorScript = preload("res://1.Codebase/src/scripts/core/trolley_problem_generator.gd")
var generator: Node
var mock_teammate_system: MockTeammateSystem
var mock_achievement_system: MockAchievementSystem
func _ready() -> void:
	print("[TrolleyProblemGeneratorTest] Starting unit tests...")
	await get_tree().process_frame
	_setup()
	_test_initialization()
	_test_json_parsing_valid()
	_test_json_parsing_markdown()
	_test_json_parsing_invalid()
	_test_dilemma_resolution()
	_test_preset_generation()
	_teardown()
	print("[TrolleyProblemGeneratorTest] All tests completed.")
	queue_free()
func _setup() -> void:
	print("[Test Setup] Creating TrolleyProblemGenerator...")
	generator = TrolleyGeneratorScript.new()
	add_child(generator)
	mock_teammate_system = MockTeammateSystem.new()
	mock_achievement_system = MockAchievementSystem.new()
	if ServiceLocator:
		ServiceLocator.register_service("TeammateSystem", mock_teammate_system)
		ServiceLocator.register_service("AchievementSystem", mock_achievement_system)
func _teardown() -> void:
	if generator:
		generator.queue_free()
		generator = null
	if ServiceLocator:
		ServiceLocator.unregister_service("TeammateSystem")
		ServiceLocator.unregister_service("AchievementSystem")
func _test_initialization() -> void:
	print("[Test] Initialization...")
	_assert(generator != null, "Generator should be created")
	_assert(generator.has_signal("dilemma_generated"), "Should have signal dilemma_generated")
	_assert(generator.has_signal("dilemma_resolved"), "Should have signal dilemma_resolved")
	print("[Test] Initialization PASSED")
func _test_json_parsing_valid() -> void:
	print("[Test] Valid JSON parsing...")
	var valid_json = """
	{
		"scenario": "Test scenario",
		"choices": [
			{
				"id": "c1",
				"text": "Choice 1",
				"framing": "honest",
				"immediate_consequence": "Bad things",
				"long_term_consequence": "Worse things",
				"stat_changes": {"reality": -5},
				"relationship_changes": [{"target": "gloria", "value": -10}]
			},
			{
				"id": "c2",
				"text": "Choice 2",
				"framing": "positive",
				"immediate_consequence": "Good things?",
				"long_term_consequence": "No.",
				"stat_changes": {"reality": 5}
			}
		],
		"thematic_point": "Life is hard"
	}
	"""
	var data = generator._parse_dilemma_json(valid_json)
	_assert(data.has("scenario"), "Should parse scenario")
	_assert(data.scenario == "Test scenario", "Scenario text match")
	_assert(data.choices.size() == 2, "Should parse 2 choices")
	_assert(data.choices[0].id == "c1", "Choice 1 ID match")
	_assert(data.choices[0].relationship_changes[0].target == "gloria", "Relationship target match")
	_assert(data.thematic_point == "Life is hard", "Theme match")
	print("[Test] Valid JSON parsing PASSED")
func _test_json_parsing_markdown() -> void:
	print("[Test] Markdown JSON parsing...")
	var markdown_json = """
	Here is the dilemma:
	```json
	{
		"scenario": "Markdown scenario",
		"choices": [
			{
				"id": "m1",
				"text": "Markdown Choice",
				"framing": "neutral",
				"immediate_consequence": "Markdown",
				"long_term_consequence": "Markdown",
				"stat_changes": {}
			},
            {
				"id": "m2",
				"text": "Markdown Choice 2",
				"framing": "neutral",
				"immediate_consequence": "Markdown",
				"long_term_consequence": "Markdown",
				"stat_changes": {}
			}
		],
		"thematic_point": "Code blocks work"
	}
	```
	End of text.
	"""
	var data = generator._parse_dilemma_json(markdown_json)
	_assert(not data.is_empty(), "Should parse from markdown")
	_assert(data.scenario == "Markdown scenario", "Scenario match")
	_assert(data.choices.size() == 2, "Choices count match")
	print("[Test] Markdown JSON parsing PASSED")
func _test_json_parsing_invalid() -> void:
	print("[Test] Invalid JSON parsing...")
	var previous_console_logs := true
	if ErrorReporter != null:
		previous_console_logs = ErrorReporter.enable_console_logs
		ErrorReporter.enable_console_logs = false
	var invalid_json = "{ broken json }"
	var data = generator._parse_dilemma_json(invalid_json)
	_assert(data.is_empty(), "Should return empty dict for invalid JSON")
	var empty_str = ""
	data = generator._parse_dilemma_json(empty_str)
	if ErrorReporter != null:
		ErrorReporter.enable_console_logs = previous_console_logs
	_assert(data.is_empty(), "Should return empty dict for empty string")
	print("[Test] Invalid JSON parsing PASSED")
func _test_dilemma_resolution() -> void:
	print("[Test] Dilemma resolution...")
	var dilemma = {
		"template_type": "test",
		"scenario": "Test",
		"choices": [
			{
				"id": "resolve_test",
				"text": "Resolve Me",
				"framing": "test",
				"immediate_consequence": "Done",
				"long_term_consequence": "Really done",
				"stat_changes": {"reality": -10},
				"relationship_changes": [
					{"target": "mock_char", "value": 5, "status": "Happy"}
				]
			}
		],
		"thematic_point": "Testing"
	}
	generator.current_dilemma = dilemma
	var resolve_state := { "emitted": false }
	var _on_resolved = func(id, res):
		resolve_state["emitted"] = true
		_assert(id == "resolve_test", "Signal ID match")
	generator.dilemma_resolved.connect(_on_resolved)
	var result = generator.resolve_dilemma("resolve_test")
	_assert(not result.is_empty(), "Should return resolution result")
	_assert(result.choice_id == "resolve_test", "Result ID match")
	_assert(bool(resolve_state.get("emitted", false)), "Signal should be emitted")
	_assert(mock_teammate_system.last_update.source == "mock_char", "Teammate system source should be relationship target")
	_assert(mock_teammate_system.last_update.target == "player", "Teammate system target should be player")
	_assert(mock_achievement_system.dilemma_resolved_called, "Achievement system called")
	var history = generator.get_dilemma_history()
	_assert(history.size() > 0, "History updated")
	_assert(history[0].choice_id == "resolve_test", "History content match")
	_assert(generator.current_dilemma.is_empty(), "Current dilemma cleared")
	print("[Test] Dilemma resolution PASSED")
func _test_preset_generation() -> void:
	print("[Test] Preset generation...")
	var preset_state := { "generated": false }
	var _on_generated = func(dilemma):
		preset_state["generated"] = true
		_assert(dilemma.has("preset"), "Should be marked as preset")
	generator.dilemma_generated.connect(_on_generated)
	generator._generate_preset_dilemma("positive_energy_trap")
	_assert(bool(preset_state.get("generated", false)), "Should generate preset")
	_assert(not generator.current_dilemma.is_empty(), "Current dilemma populated")
	_assert(generator.current_dilemma.template_type == "positive_energy_trap", "Template type match")
	print("[Test] Preset generation PASSED")
class MockTeammateSystem extends RefCounted:
	var last_update = {}
	func update_relationship(source, target, status, value):
		last_update = {"source": source, "target": target, "status": status, "value": value}
class MockAchievementSystem extends RefCounted:
	var dilemma_resolved_called = false
	func check_dilemma_resolved():
		dilemma_resolved_called = true
func _assert(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
		print("    PASS  %s" % message)
	else:
		tests_failed += 1
		print("    FAIL  %s" % message)
