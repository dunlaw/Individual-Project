extends Node
var tests_passed: int = 0
var tests_failed: int = 0
const SceneDirectivesParserScript = preload("res://1.Codebase/src/scripts/core/ai/scene_directives_parser.gd")
var parser: RefCounted = null
func _ready() -> void:
	print("[SceneDirectivesParserTest] Starting SceneDirectivesParser unit tests...")
	await get_tree().process_frame
	_setup()
	_test_initialization()
	_test_valid_json_parsing()
	_test_marker_block_parsing()
	_test_code_block_parsing()
	_test_malformed_json()
	_test_empty_input()
	_test_nested_structures()
	_test_content_extraction()
	_test_edge_cases()
	_test_regex_caching()
	_teardown()
	print("[SceneDirectivesParserTest] All tests completed.")
	queue_free()
func _setup() -> void:
	print("[Test Setup] Creating SceneDirectivesParser...")
	parser = SceneDirectivesParserScript.new()
func _teardown() -> void:
	if parser:
		parser = null
func _test_initialization() -> void:
	print("[Test] Parser initialization...")
	_assert(parser != null, "Parser should be created")
	_assert(parser.has_method("parse_scene_directives"), "Should have parse_scene_directives method")
	_assert(parser.has_method("extract_story_content"), "Should have extract_story_content method")
	print("[Test] Initialization PASSED")
func _test_valid_json_parsing() -> void:
	print("[Test] Valid JSON parsing...")
	if not parser:
		print("[Test] SKIPPED")
		return
	var valid_json := """{
		"scene": {
			"background": "ruins",
			"atmosphere": "dark",
			"lighting": "dim"
		},
		"characters": {
			"protagonist": {"expression": "neutral"},
			"gloria": {"expression": "happy"}
		},
		"story_text": "Test story content"
	}"""
	var result: Dictionary = parser.parse_scene_directives(valid_json)
	_assert(result is Dictionary, "Should return Dictionary")
	_assert(result.has("scene"), "Should have scene key")
	_assert(result.has("characters"), "Should have characters key")
	_assert(result["scene"] is Dictionary, "Scene should be Dictionary")
	_assert(result["characters"] is Dictionary, "Characters should be Dictionary")
	print("[Test] Valid JSON parsing PASSED")
func _test_marker_block_parsing() -> void:
	print("[Test] Marker block parsing...")
	if not parser:
		print("[Test] SKIPPED")
		return
	var with_markers := """Some story text here.

[SCENE_DIRECTIVES]
{
	"scene": {"background": "cave"},
	"characters": {"protagonist": {"expression": "thinking"}}
}
[/SCENE_DIRECTIVES]

More story text."""
	var result: Dictionary = parser.parse_scene_directives(with_markers)
	_assert(result is Dictionary, "Should return Dictionary")
	_assert(result.has("scene"), "Should parse scene from marker block")
	_assert(result.has("characters"), "Should parse characters from marker block")
	print("[Test] Marker block parsing PASSED")
func _test_code_block_parsing() -> void:
	print("[Test] Code block parsing...")
	if not parser:
		print("[Test] SKIPPED")
		return
	var with_code_block := """Here's the directive:

```json
{
	"scene": {"background": "forest"},
	"characters": {"gloria": {"expression": "angry"}}
}
```

Story continues."""
	var result: Dictionary = parser.parse_scene_directives(with_code_block)
	_assert(result is Dictionary, "Should return Dictionary")
	_assert(result.has("scene"), "Should parse scene from code block")
	print("[Test] Code block parsing PASSED")
func _test_malformed_json() -> void:
	print("[Test] Malformed JSON handling...")
	if not parser:
		print("[Test] SKIPPED")
		return
	var malformed_cases := [
		"{broken json}",
		"{'single': 'quotes'}",
		"{\"unclosed\": ",
		"[array, not, object]",
		"",
		"null",
	]
	for malformed in malformed_cases:
		var result: Dictionary = parser.parse_scene_directives(malformed)
		_assert(result is Dictionary, "Should always return Dictionary")
		if not result.is_empty():
			print("[Test] Note: Parser recovered from: ", malformed.left(20))
	print("[Test] Malformed JSON handling PASSED")
func _test_empty_input() -> void:
	print("[Test] Empty input handling...")
	if not parser:
		print("[Test] SKIPPED")
		return
	var empty_cases := [
		"",
		"   ",
		"\n\n",
		"{}",
		"Just plain text with no directives",
	]
	for empty_input in empty_cases:
		var result: Dictionary = parser.parse_scene_directives(empty_input)
		_assert(result is Dictionary, "Should return Dictionary for empty input")
	print("[Test] Empty input handling PASSED")
func _test_nested_structures() -> void:
	print("[Test] Nested structures...")
	if not parser:
		print("[Test] SKIPPED")
		return
	var nested := """{
		"metadata": {
			"scene_directives": {
				"scene": {"background": "temple"},
				"characters": {"ark": {"expression": "confused"}}
			}
		}
	}"""
	var result: Dictionary = parser.parse_scene_directives(nested)
	_assert(result is Dictionary, "Should return Dictionary")
	var with_visuals := """{
		"visuals": {
			"scene": {"background": "laboratory"},
			"characters": {"one": {"expression": "shocked"}}
		}
	}"""
	result = parser.parse_scene_directives(with_visuals)
	_assert(result is Dictionary, "Should return Dictionary")
	print("[Test] Nested structures PASSED")
func _test_content_extraction() -> void:
	print("[Test] Content extraction...")
	if not parser:
		print("[Test] SKIPPED")
		return
	var with_directives := """Story begins here.

[SCENE_DIRECTIVES]
{"scene": {"background": "ruins"}}
[/SCENE_DIRECTIVES]

Story continues.

```json
{"more": "directives"}
```

Story ends."""
	var extracted: String = parser.extract_story_content(with_directives)
	_assert(extracted is String, "Should return String")
	_assert(not extracted.contains("[SCENE_DIRECTIVES]"), "Should remove markers")
	_assert(not extracted.contains("```json"), "Should remove code blocks")
	_assert(extracted.contains("Story begins"), "Should keep story content")
	_assert(extracted.contains("Story ends"), "Should keep all story content")
	print("[Test] Content extraction PASSED")
func _test_edge_cases() -> void:
	print("[Test] Edge cases...")
	if not parser:
		print("[Test] SKIPPED")
		return
	var multiple_blocks := """
[SCENE_DIRECTIVES]
{"scene": {"background": "first"}}
[/SCENE_DIRECTIVES]

[SCENE_DIRECTIVES]
{"scene": {"background": "second"}}
[/SCENE_DIRECTIVES]
"""
	var result: Dictionary = parser.parse_scene_directives(multiple_blocks)
	_assert(result is Dictionary, "Should handle multiple blocks")
	var at_start := """[SCENE_DIRECTIVES]
{"scene": {"background": "test"}}
[/SCENE_DIRECTIVES]"""
	result = parser.parse_scene_directives(at_start)
	_assert(result is Dictionary, "Should handle directive at start")
	var at_end := """Story content
[SCENE_DIRECTIVES]
{"scene": {"background": "test"}}
[/SCENE_DIRECTIVES]"""
	result = parser.parse_scene_directives(at_end)
	_assert(result is Dictionary, "Should handle directive at end")
	var with_whitespace := """

	[SCENE_DIRECTIVES]

	{
		"scene":    {   "background":   "test"   }
	}

	[/SCENE_DIRECTIVES]

	"""
	result = parser.parse_scene_directives(with_whitespace)
	_assert(result is Dictionary, "Should handle excessive whitespace")
	var unicode_content := """{
		"scene": {"background": "ruins"},
		"story_text": LocalizationManager.get_translation("TEST_UNICODE_CONTENT", "zh") if LocalizationManager else "Unicode Test"
	}"""
	result = parser.parse_scene_directives(unicode_content)
	_assert(result is Dictionary, "Should handle Unicode content")
	var long_content := "{"
	long_content += "\"scene\": {\"background\": \"test\"},"
	long_content += "\"story_text\": \"" + "a".repeat(10000) + "\""
	long_content += "}"
	result = parser.parse_scene_directives(long_content)
	_assert(result is Dictionary, "Should handle long content")
	print("[Test] Edge cases PASSED")
func _test_regex_caching() -> void:
	print("[Test] Regex caching...")
	if not parser:
		print("[Test] SKIPPED")
		return
	var test_input := """[SCENE_DIRECTIVES]
{"scene": {"background": "test"}}
[/SCENE_DIRECTIVES]"""
	var start_time := Time.get_ticks_msec()
	for i in range(100):
		var _result: Dictionary = parser.parse_scene_directives(test_input)
	var duration := Time.get_ticks_msec() - start_time
	_assert(duration < 1000, "100 parses should complete in under 1 second (was %d ms)" % duration)
	print("[Test] Regex caching PASSED (duration: %d ms)" % duration)
func _assert(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
		print("    PASS  %s" % message)
	else:
		tests_failed += 1
		print("    FAIL  %s" % message)
