extends Node

const NarrativeResponseParser = preload("res://1.Codebase/src/scripts/core/ai/narrative_response_parser.gd")

var tests_passed: int = 0
var tests_failed: int = 0

func _ready() -> void:
	print("[NarrativeResponseParserTest] Starting tests...")
	await get_tree().process_frame
	_test_choice_validation_accepts_longer_zh_summaries()
	_test_choice_validation_accepts_longer_non_zh_summaries()
	_test_parse_response_extracts_choices_from_json()
	print("[NarrativeResponseParserTest] Completed. Passed=%d Failed=%d" % [tests_passed, tests_failed])
	queue_free()

func _test_choice_validation_accepts_longer_zh_summaries() -> void:
	var payload: Array[Dictionary] = [
		{"archetype": "cautious", "summary": "先穩住場面再排查封印裂痕，避免團隊再次被情緒勒索"},
		{"archetype": "balanced", "summary": "分工修復祭壇並監控熵值，降低下一輪失控風險"},
		{"archetype": "reckless", "summary": "直接強攻核心想快速收尾，極可能引爆更大反噬"},
		{"archetype": "positive", "summary": "盲目讚美現狀並配合話術，短暫平靜但熵值繼續上升"},
		{"archetype": "complain", "summary": "公開質疑流程與責任歸屬，雖揭露問題卻惡化團隊對立"},
	]
	var report := NarrativeResponseParser.get_ai_choice_validation_report(payload, "zh")
	_assert(bool(report.get("valid", false)), "ZH summaries longer than 20 chars should still be accepted")

func _test_choice_validation_accepts_longer_non_zh_summaries() -> void:
	var payload: Array[Dictionary] = [
		{"archetype": "cautious", "summary": "Stabilize the altar seals first, then inspect hidden fractures before anyone triggers another avoidable collapse."},
		{"archetype": "balanced", "summary": "Coordinate ARK diagnostics with controlled repairs, buying time while containing entropy growth across the chamber."},
		{"archetype": "reckless", "summary": "Push full output through the unstable core immediately, gambling on speed and inviting catastrophic backlash."},
		{"archetype": "positive", "summary": "Echo Gloria's optimism, celebrate progress, and quietly feed the same instability that caused the crisis."},
		{"archetype": "complain", "summary": "Call out the broken process publicly, expose the blame cycle, and risk team cooperation breaking apart."},
	]
	var report := NarrativeResponseParser.get_ai_choice_validation_report(payload, "en")
	_assert(bool(report.get("valid", false)), "Non-ZH summaries above 20 words should still be accepted")

func _test_parse_response_extracts_choices_from_json() -> void:
	var response := {
		"success": true,
		"content": JSON.stringify({
			"story_text": "The chamber quiets, but the seal remains unstable.",
			"scene": {"background": "temple", "atmosphere": "tense", "lighting": "dim"},
			"characters": {
				"protagonist": {"expression": "thinking"},
				"gloria": {"expression": "happy"},
				"donkey": {"expression": "happy"},
				"ark": {"expression": "thinking"},
				"one": {"expression": "neutral"},
			},
			"choices": [
				{"archetype": "cautious", "summary": "Check the seal before anyone celebrates."},
				{"archetype": "balanced", "summary": "Split tasks and monitor the entropy gauges."},
				{"archetype": "reckless", "summary": "Break the seal now and end this quickly."},
			],
		}),
	}
	var parsed := NarrativeResponseParser.parse_mission_response(response, null)
	_assert(bool(parsed.get("success", false)), "Parser should accept JSON payload responses")
	_assert(String(parsed.get("story_text", "")).find("chamber") != -1, "Parser should preserve story_text")
	var choices: Array[Dictionary] = parsed.get("choices", [])
	_assert(choices.size() == 3, "Parser should extract choices array from JSON payload")

func _assert(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
		print("    PASS  %s" % message)
	else:
		tests_failed += 1
		print("    FAIL  %s" % message)
