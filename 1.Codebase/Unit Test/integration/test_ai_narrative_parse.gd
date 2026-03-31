extends Node
var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0
func _ready() -> void:
	print("\n[AINarrativeParseIntegration] Starting AI narrative parse integration tests...")
	await get_tree().process_frame
	_test_full_json_mission_response_parsing()
	_test_mixed_text_and_json_response()
	_test_scene_directives_normalization()
	_test_character_directives_normalization()
	_test_choice_extraction_from_json()
	_test_choice_validation_rules()
	_test_choice_extraction_from_text_labels()
	_test_night_cycle_response_parsing()
	_test_gloria_speech_extraction()
	_test_malformed_json_recovery()
	_test_empty_response_handling()
	_test_incomplete_json_detection()
	_test_end_to_end_mission_parse_to_display()
	print("\n[AINarrativeParseIntegration] Results: %d/%d passed (%d failed)" % [
		passed_tests, total_tests, failed_tests])
	queue_free()
func assert_test(condition: bool, test_name: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("    PASS: %s" % test_name)
	else:
		failed_tests += 1
		print("    FAIL: %s" % test_name)
func _test_full_json_mission_response_parsing() -> void:
	print("[Test] Full JSON mission response parsing...")
	var raw_response = {
		"success": true,
		"content": '{"mission_title": "The Noodle Incident", "scene": {"background": "default", "atmosphere": "tense", "lighting": "dim"}, "characters": {"protagonist": {"expression": "worried"}, "gloria": {"expression": "smiling"}}, "story_text": "You stand before the noodle factory.", "choices": [{"archetype": "cautious", "summary": "Inspect the noodles carefully"}, {"archetype": "reckless", "summary": "Eat the noodles immediately"}]}'
	}
	var result = NarrativeResponseParser.parse_mission_response(raw_response, null)
	assert_test(result["success"] == true,
		"Successful response parsed correctly")
	assert_test(result["mission_title"] == "The Noodle Incident",
		"Mission title extracted")
	assert_test(not result["story_text"].is_empty(),
		"Story text extracted from JSON")
	assert_test(result["choices"].size() == 2,
		"Two choices extracted from JSON")
	assert_test(result["directives"].has("scene"),
		"Scene directives extracted")
func _test_mixed_text_and_json_response() -> void:
	print("[Test] Mixed text and JSON response...")
	var mixed_content = """Here is your story:
{"mission_title": "Dark Waters", "scene": {"background": "water", "atmosphere": "eerie"}, "story_text": "The river flows backward.", "choices": [{"archetype": "balanced", "summary": "Follow the current"}]}
Hope you enjoy!"""
	var response = { "success": true, "content": mixed_content }
	var result = NarrativeResponseParser.parse_mission_response(response, null)
	assert_test(result["success"] == true,
		"Mixed text/JSON response parsed successfully")
	assert_test(result["mission_title"] == "Dark Waters",
		"Title extracted from mixed content")
func _test_scene_directives_normalization() -> void:
	print("[Test] Scene directives normalization...")
	var scene = NarrativeResponseParser.normalize_scene_directives({
		"background": "  Forest  ",
		"atmosphere": "Misty",
		"lighting": "DIM",
	})
	assert_test(scene["background"] == "forest" or scene["background"] == "default",
		"Background normalized to lowercase")
	assert_test(scene["atmosphere"] == "Misty",
		"Atmosphere preserved after strip")
	assert_test(scene["lighting"] == "DIM",
		"Lighting preserved after strip")
	var empty_scene = NarrativeResponseParser.normalize_scene_directives({})
	assert_test(empty_scene["background"] == "default",
		"Empty background defaults to 'default'")
	var invalid = NarrativeResponseParser.normalize_scene_directives("not a dict")
	assert_test(invalid.is_empty(),
		"Non-dictionary input returns empty dict")
func _test_character_directives_normalization() -> void:
	print("[Test] Character directives normalization...")
	var chars = NarrativeResponseParser.normalize_character_directives({
		"protagonist": { "expression": "Angry" },
		"gloria": { "expression": "unknown_expression_xyz" },
	})
	assert_test(chars.has("protagonist"),
		"Protagonist preserved in output")
	assert_test(chars["protagonist"]["expression"] == "angry" or chars["protagonist"]["expression"] == "neutral",
		"Expression normalized to lowercase")
	assert_test(chars.has("donkey"),
		"Missing required character 'donkey' auto-filled")
	assert_test(chars.has("ark"),
		"Missing required character 'ark' auto-filled")
	assert_test(chars.has("one"),
		"Missing required character 'one' auto-filled")
	assert_test(chars["donkey"]["expression"] == "neutral",
		"Auto-filled character defaults to neutral expression")
func _test_choice_extraction_from_json() -> void:
	print("[Test] Choice extraction from JSON payload...")
	var choices_payload = [
		{"archetype": "cautious", "summary": "Think it through"},
		{"archetype": "balanced", "summary": "Consider both sides"},
		{"archetype": "reckless", "summary": "Rush in headfirst"},
		{"archetype": "positive", "summary": "Smile and nod"},
		{"archetype": "complain", "summary": "Whine about it"},
	]
	var normalized = NarrativeResponseParser.normalize_ai_choice_payload(choices_payload)
	assert_test(normalized.size() == 5,
		"All 5 archetype choices normalized")
	assert_test(normalized[0]["archetype"] == "cautious",
		"First choice archetype correct")
	assert_test(normalized[4]["summary"] == "Whine about it",
		"Last choice summary preserved")
	var bad_payload = [
		{"archetype": "", "summary": "No archetype"},
		{"archetype": "cautious", "summary": ""},
		"not a dict",
	]
	var filtered = NarrativeResponseParser.normalize_ai_choice_payload(bad_payload)
	assert_test(filtered.size() == 0,
		"Invalid choices filtered out completely")
func _test_choice_validation_rules() -> void:
	print("[Test] Choice validation rules...")
	var valid_de = [
		{"archetype": "cautious", "summary": "Study the brittle mechanism carefully before moving, even if Gloria keeps calling caution a trust issue"},
		{"archetype": "balanced", "summary": "Negotiate a compromise with the altar while ARK quietly arms safeguards behind Gloria's radiant sermon"},
		{"archetype": "reckless", "summary": "Kick the glowing console immediately and pretend the explosion was always part of the strategic vision"},
	]
	assert_test(
		NarrativeResponseParser.are_ai_choices_valid(valid_de, "de"),
		"German-style 10-20 word summaries validate successfully")
	var valid_zh = [
		{"archetype": "cautious", "summary": "先幫ARK抽乾怪物能量避免它立刻當場爆炸"},
		{"archetype": "balanced", "summary": "說服Gloria安撫怪物同時暗中部署後備炸彈"},
		{"archetype": "reckless", "summary": "直接把怨靈拖走當隊伍吉祥物完全不管風險"},
	]
	assert_test(
		NarrativeResponseParser.are_ai_choices_valid(valid_zh, "zh"),
		"Chinese 10-20 character summaries validate successfully")
	var duplicate_archetypes = [
		{"archetype": "cautious", "summary": "Study the brittle mechanism carefully before moving, even if Gloria keeps calling caution a trust issue"},
		{"archetype": "cautious", "summary": "Wait beside the altar and let the fumes judge everyone in patient administrative silence"},
		{"archetype": "reckless", "summary": "Kick the glowing console immediately and pretend the explosion was always part of the strategic vision"},
	]
	assert_test(
		not NarrativeResponseParser.are_ai_choices_valid(duplicate_archetypes, "de"),
		"Duplicate archetypes fail validation")
	var long_zh = [
		{"archetype": "cautious", "summary": "秘密協助ARK抽乾怪物的能量並且順便記錄所有異常指標避免它爆炸"},
		{"archetype": "balanced", "summary": "說服Gloria讓怪物在這裡靜修同時安排遠端引爆作為保險"},
		{"archetype": "reckless", "summary": "採納Donkey建議把這隻隨時會爆掉的怪物當寵物帶回營地"},
	]
	assert_test(
		NarrativeResponseParser.are_ai_choices_valid(long_zh, "zh"),
		"Chinese summaries of 28-31 characters validate successfully within 100-char limit")
	var wrong_count = [
		{"archetype": "cautious", "summary": "Study the brittle mechanism carefully before moving, even if Gloria keeps calling caution a trust issue"},
		{"archetype": "balanced", "summary": "Negotiate a compromise with the altar while ARK quietly arms safeguards behind Gloria's radiant sermon"},
	]
	assert_test(
		not NarrativeResponseParser.are_ai_choices_valid(wrong_count, "de"),
		"Fewer than 3 choices fail validation")
func _test_choice_extraction_from_text_labels() -> void:
	print("[Test] Choice extraction from text labels...")
	var story_text = """The path splits before you.

[Cautious] Examine the map carefully before proceeding
[Balanced] Take the middle road
[Reckless] Sprint down the dark tunnel
[Positive] Smile at the darkness
[Complain] Mutter about the poor lighting"""
	var choices = NarrativeResponseParser.extract_archetype_choices_from_text(story_text, "en")
	assert_test(choices.size() == 5,
		"All 5 choices extracted from text labels")
	var found_cautious = false
	var found_reckless = false
	for choice in choices:
		if choice["archetype"] == "cautious":
			found_cautious = true
			assert_test(choice["summary"].find("map") != -1,
				"Cautious summary contains expected content")
		if choice["archetype"] == "reckless":
			found_reckless = true
	assert_test(found_cautious, "Cautious archetype found in text")
	assert_test(found_reckless, "Reckless archetype found in text")
func _test_night_cycle_response_parsing() -> void:
	print("[Test] Night cycle response parsing...")
	var response = {
		"success": true,
		"content": '{"reflection_text": "You reflect on today.", "teacher_chan_text": "Miss Chan sings softly.", "song_title": "Noodle Lullaby", "honeymoon_text": "Sweet dreams.", "prayer_prompt": "Pray to the FSM."}'
	}
	var result = NarrativeResponseParser.parse_night_cycle_response(response)
	assert_test(result["success"] == true,
		"Night cycle response parsed successfully")
	assert_test(result["payload"].has("reflection_text"),
		"Reflection text present in payload")
	assert_test(result["payload"]["song_title"] == "Noodle Lullaby",
		"Song title extracted correctly")
	var failed_response = { "success": false, "content": "" }
	var failed_result = NarrativeResponseParser.parse_night_cycle_response(failed_response)
	assert_test(failed_result["success"] == false,
		"Failed response correctly marked as unsuccessful")
func _test_gloria_speech_extraction() -> void:
	print("[Test] Gloria speech extraction...")
	var plain = NarrativeResponseParser.extract_gloria_speech(
		"Gloria whispers: You cannot escape.", null)
	assert_test(plain.find("cannot escape") != -1,
		"Plain text Gloria speech extracted")
	var json_speech = NarrativeResponseParser.extract_gloria_speech(
		'{"speech": "You are weak.", "tone": "menacing"}', null)
	assert_test(json_speech == "You are weak.",
		"JSON-wrapped Gloria speech extracted from 'speech' key")
	var fallback = NarrativeResponseParser.extract_gloria_speech("", null)
	assert_test(not fallback.is_empty(),
		"Empty content produces fallback Gloria speech")
func _test_malformed_json_recovery() -> void:
	print("[Test] Malformed JSON recovery...")
	var truncated = '{"mission_title": "Test", "story_text": "Hello", "choices": [{"archety'
	var extracted = NarrativeResponseParser.extract_primary_json_block(truncated)
	assert_test(extracted.is_empty(),
		"Truncated JSON returns empty extraction")
	var extra_text = 'Sure! Here is your mission: {"mission_title": "Test", "story_text": "A story"} I hope you like it!'
	var clean = NarrativeResponseParser.extract_primary_json_block(extra_text)
	assert_test(not clean.is_empty(),
		"JSON block extracted from surrounding text")
	var json = JSON.new()
	if not clean.is_empty():
		assert_test(json.parse(clean) == OK,
			"Extracted JSON block is valid JSON")
func _test_empty_response_handling() -> void:
	print("[Test] Empty response handling...")
	var empty_response = { "success": true, "content": "" }
	var result = NarrativeResponseParser.parse_mission_response(empty_response, null)
	assert_test(result["success"] == false,
		"Empty content results in failure")
	assert_test(not result["error"].is_empty(),
		"Error message provided for empty content")
	var no_success = { "content": "Some text" }
	var result2 = NarrativeResponseParser.parse_mission_response(no_success, null)
	assert_test(result2["success"] == false,
		"Missing success flag results in failure")
func _test_incomplete_json_detection() -> void:
	print("[Test] Incomplete JSON detection...")
	var complete = '{"key": "value"}'
	assert_test(
		not NarrativeResponseParser._looks_like_incomplete_json(complete),
		"Complete JSON not flagged as incomplete")
	var incomplete = '{"key": "value", "nested": {'
	assert_test(
		NarrativeResponseParser._looks_like_incomplete_json(incomplete),
		"Unbalanced JSON flagged as incomplete")
	assert_test(
		not NarrativeResponseParser._looks_like_incomplete_json("Just plain text"),
		"Plain text not flagged as incomplete JSON")
func _test_end_to_end_mission_parse_to_display() -> void:
	print("[Test] End-to-end: AI response → parsed result → display-ready data...")
	var ai_response = {
		"success": true,
		"content": '{"mission_title": "The Factory of Smiles", "scene": {"background": "factory", "atmosphere": "oppressive", "lighting": "fluorescent"}, "characters": {"protagonist": {"expression": "nervous", "visible": true}, "gloria": {"expression": "smiling", "visible": true}, "donkey": {"expression": "sad", "visible": true}, "ark": {"expression": "neutral", "visible": false}, "one": {"expression": "neutral", "visible": false}}, "story_text": "The conveyor belt hums with forced positivity. Gloria stands at the end of the line, clipboard in hand, marking down each smile.", "choices": [{"archetype": "cautious", "summary": "Observe the production line from a distance"}, {"archetype": "balanced", "summary": "Join the line but keep your expression neutral"}, {"archetype": "reckless", "summary": "Smash the smile-measuring device"}, {"archetype": "positive", "summary": "Flash your brightest smile"}, {"archetype": "complain", "summary": "File a formal complaint about working conditions"}]}'
	}
	var result = NarrativeResponseParser.parse_mission_response(ai_response, null)
	assert_test(result["success"] == true,
		"[E2E] Parse succeeds")
	assert_test(result["mission_title"] == "The Factory of Smiles",
		"[E2E] Mission title ready for display")
	assert_test(result["story_text"].find("conveyor belt") != -1,
		"[E2E] Story text contains narrative content")
	assert_test(result["choices"].size() == 5,
		"[E2E] All 5 archetype choices available")
	var directives = result["directives"]
	assert_test(directives.has("scene") and directives["scene"].has("background"),
		"[E2E] Scene directives have background")
	assert_test(directives.has("characters"),
		"[E2E] Character directives present")
	var chars = directives.get("characters", {})
	for required_id in ["protagonist", "gloria", "donkey", "ark", "one"]:
		assert_test(chars.has(required_id),
			"[E2E] Required character '%s' present" % required_id)
	for choice in result["choices"]:
		assert_test(choice.has("archetype") and choice.has("summary"),
			"[E2E] Choice has archetype and summary keys")
		assert_test(not choice["archetype"].is_empty() and not choice["summary"].is_empty(),
			"[E2E] Choice fields are non-empty")
