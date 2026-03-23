extends Node
var tests_passed: int = 0
var tests_failed: int = 0
var tracker: ButterflyEffectTracker
var signal_choice_recorded: bool = false
var signal_consequence_triggered: bool = false
var signal_butterfly_revealed: bool = false
var last_choice_id: String = ""
func _ready() -> void:
	print("[ButterflyEffectTrackerTest] Starting ButterflyEffectTracker unit tests...")
	await get_tree().process_frame
	tracker = ButterflyEffectTracker.new()
	add_child(tracker)
	await get_tree().process_frame
	tracker.choice_recorded.connect(_on_choice_recorded)
	tracker.consequence_triggered.connect(_on_consequence_triggered)
	tracker.butterfly_effect_revealed.connect(_on_butterfly_revealed)
	_test_initialization()
	_test_record_simple_choice()
	_test_record_choice_from_dictionary()
	_test_scene_advancement()
	_test_consequence_triggering()
	_test_manual_consequence_trigger()
	_test_get_choice_by_id()
	_test_get_choices_by_tag()
	_test_get_recent_choices()
	_test_get_pending_consequences()
	_test_ai_context_generation()
	_test_butterfly_effect_summary()
	_test_eligible_for_ripple()
	_test_suggest_choice_callback()
	_test_save_load_functionality()
	_test_max_choices_limit()
	_test_choice_type_validation()
	await _test_signal_emission()
	_test_clear_functionality()
	tracker.queue_free()
	print("[ButterflyEffectTrackerTest] All tests completed.")
	queue_free()
func _on_choice_recorded(choice_id: String) -> void:
	signal_choice_recorded = true
	last_choice_id = choice_id
func _on_consequence_triggered(_choice_id: String, _consequence: Dictionary) -> void:
	signal_consequence_triggered = true
func _on_butterfly_revealed(_choice_id: String, _scenes_later: int) -> void:
	signal_butterfly_revealed = true
func _test_initialization() -> void:
	print("[Test] Initialization...")
	_assert(tracker != null, "Tracker should be created")
	_assert(tracker.recorded_choices is Array, "recorded_choices should be Array")
	_assert(tracker.current_scene_number == 0, "Should start at scene 0")
	_assert(tracker.next_choice_id == 1, "Should start with choice ID 1")
	_assert(tracker.MAX_STORED_CHOICES == 100, "Should have max choices limit")
	_assert(tracker.CONSEQUENCE_LOOKBACK_SCENES == 20, "Should have lookback limit")
	print("[Test] Initialization PASSED ")
func _test_record_simple_choice() -> void:
	print("[Test] Record simple choice...")
	tracker.clear_all()
	var choice_id = tracker.record_choice("I decided to trust the mysterious stranger")
	_assert(choice_id.length() > 0, "Should return choice ID")
	_assert(choice_id.begins_with("choice_"), "Choice ID should have correct format")
	_assert(tracker.recorded_choices.size() == 1, "Should have 1 recorded choice")
	var choice = tracker.recorded_choices[0]
	_assert(choice["id"] == choice_id, "Choice should have correct ID")
	_assert(choice["choice_text"] == "I decided to trust the mysterious stranger", "Should store choice text")
	_assert(choice["choice_type"] == "major", "Should default to major type")
	_assert(choice["scene_number"] == 0, "Should record scene number")
	_assert(choice.has("timestamp"), "Should have timestamp")
	_assert(choice.has("stats_at_time"), "Should capture stats")
	print("[Test] Record simple choice PASSED ")
func _test_record_choice_from_dictionary() -> void:
	print("[Test] Record choice from dictionary...")
	tracker.clear_all()
	var choice_dict = {
		"text": "Expose Gloria's manipulation",
		"choice_type": "critical",
		"tags": ["gloria", "confrontation"],
		"predicted_consequences": [
			{
				"scene_number": 5,
				"description": "Gloria remembers your defiance",
				"severity": "high",
				"triggered": false
			}
		]
	}
	var choice_id = tracker.record_choice(choice_dict)
	_assert(tracker.recorded_choices.size() == 1, "Should have 1 choice")
	var choice = tracker.recorded_choices[0]
	_assert(choice["choice_text"] == "Expose Gloria's manipulation", "Should extract text from dict")
	_assert(choice["choice_type"] == "critical", "Should use dict choice_type")
	_assert(choice["tags"].size() == 2, "Should have 2 tags")
	_assert("gloria" in choice["tags"], "Should include gloria tag")
	_assert("confrontation" in choice["tags"], "Should include confrontation tag")
	_assert(choice["consequences"].size() == 1, "Should have 1 predicted consequence")
	_assert(choice["consequences_total"] == 1, "Should track total consequences")
	print("[Test] Record choice from dictionary PASSED ")
func _test_scene_advancement() -> void:
	print("[Test] Scene advancement...")
	tracker.clear_all()
	_assert(tracker.current_scene_number == 0, "Should start at scene 0")
	tracker.advance_scene()
	_assert(tracker.current_scene_number == 1, "Should advance to scene 1")
	tracker.advance_scene()
	_assert(tracker.current_scene_number == 2, "Should advance to scene 2")
	print("[Test] Scene advancement PASSED ")
func _test_consequence_triggering() -> void:
	print("[Test] Consequence triggering...")
	tracker.clear_all()
	var choice_dict = {
		"text": "Test choice",
		"consequences": [
			{
				"scene_number": 3,
				"description": "Your choice comes back to haunt you",
				"triggered": false,
				"severity": "medium"
			}
		]
	}
	tracker.record_choice(choice_dict)
	tracker.advance_scene()
	tracker.advance_scene()
	var choice = tracker.recorded_choices[0]
	_assert(choice["consequences"][0]["triggered"] == false, "Consequence should not trigger yet")
	tracker.advance_scene()
	choice = tracker.recorded_choices[0]
	_assert(choice["consequences"][0]["triggered"] == true, "Consequence should be triggered")
	_assert(choice["consequences_triggered"] == 1, "Should track triggered count")
	print("[Test] Consequence triggering PASSED ")
func _test_manual_consequence_trigger() -> void:
	print("[Test] Manual consequence trigger...")
	tracker.clear_all()
	var choice_id = tracker.record_choice("Manual trigger test choice")
	var success = tracker.trigger_consequence_for_choice(
		choice_id,
		"AI-generated consequence",
		"high"
	)
	_assert(success, "Manual trigger should succeed")
	var choice = tracker.get_choice_by_id(choice_id)
	_assert(choice["consequences"].size() == 1, "Should have added consequence")
	_assert(choice["consequences"][0]["triggered"] == true, "Consequence should be marked triggered")
	_assert(choice["consequences"][0]["description"] == "AI-generated consequence", "Should have correct description")
	_assert(choice["consequences_triggered"] == 1, "Should update triggered count")
	var fail = tracker.trigger_consequence_for_choice("invalid_id", "Test", "low")
	_assert(not fail, "Should fail for invalid choice ID")
	print("[Test] Manual consequence trigger PASSED ")
func _test_get_choice_by_id() -> void:
	print("[Test] Get choice by ID...")
	tracker.clear_all()
	var id1 = tracker.record_choice("First choice")
	var id2 = tracker.record_choice("Second choice")
	var choice1 = tracker.get_choice_by_id(id1)
	_assert(not choice1.is_empty(), "Should find first choice")
	_assert(choice1["id"] == id1, "Should return correct choice")
	_assert(choice1["choice_text"] == "First choice", "Should have correct text")
	var choice2 = tracker.get_choice_by_id(id2)
	_assert(choice2["choice_text"] == "Second choice", "Should find second choice")
	var invalid = tracker.get_choice_by_id("nonexistent_choice")
	_assert(invalid.is_empty(), "Should return empty dict for invalid ID")
	print("[Test] Get choice by ID PASSED ")
func _test_get_choices_by_tag() -> void:
	print("[Test] Get choices by tag...")
	tracker.clear_all()
	tracker.record_choice({"text": "Choice 1", "tags": ["gloria", "moral"]})
	tracker.record_choice({"text": "Choice 2", "tags": ["combat", "risky"]})
	tracker.record_choice({"text": "Choice 3", "tags": ["gloria", "strategic"]})
	var gloria_choices = tracker.get_choices_by_tag("gloria")
	_assert(gloria_choices.size() == 2, "Should find 2 choices with gloria tag")
	for choice in gloria_choices:
		_assert("gloria" in choice["tags"], "All results should have gloria tag")
	var combat_choices = tracker.get_choices_by_tag("combat")
	_assert(combat_choices.size() == 1, "Should find 1 choice with combat tag")
	var none = tracker.get_choices_by_tag("nonexistent")
	_assert(none.size() == 0, "Should return empty array for non-existent tag")
	print("[Test] Get choices by tag PASSED ")
func _test_get_recent_choices() -> void:
	print("[Test] Get recent choices...")
	tracker.clear_all()
	tracker.record_choice("Scene 0 choice")
	tracker.advance_scene()
	tracker.record_choice("Scene 1 choice")
	tracker.advance_scene()
	tracker.advance_scene()
	tracker.record_choice("Scene 3 choice")
	tracker.advance_scene()
	tracker.advance_scene()
	tracker.advance_scene()
	tracker.record_choice("Scene 6 choice")
	var recent = tracker.get_recent_choices(3)
	_assert(recent.size() == 1, "Should get choices from last 3 scenes (only scene 6)")
	recent = tracker.get_recent_choices(10)
	_assert(recent.size() >= 2, "Should get more choices with larger window")
	print("[Test] Get recent choices PASSED ")
func _test_get_pending_consequences() -> void:
	print("[Test] Get pending consequences...")
	tracker.clear_all()
	tracker.record_choice("No consequence choice")
	tracker.record_choice({
		"text": "Pending choice",
		"consequences": [
			{"scene_number": 10, "description": "Future consequence", "triggered": false}
		]
	})
	tracker.record_choice({
		"text": "Triggered choice",
		"consequences": [
			{"scene_number": 0, "description": "Past consequence", "triggered": true}
		]
	})
	var pending = tracker.get_choices_with_pending_consequences()
	_assert(pending.size() == 1, "Should find 1 choice with pending consequences")
	_assert(pending[0]["choice_text"] == "Pending choice", "Should be the right choice")
	print("[Test] Get pending consequences PASSED ")
func _test_ai_context_generation() -> void:
	print("[Test] AI context generation...")
	tracker.clear_all()
	tracker.record_choice({
		"text": "Made a risky decision",
		"consequences": [
			{"scene_number": 10, "description": "Risk consequence", "triggered": false}
		]
	})
	tracker.advance_scene()
	tracker.record_choice("Another choice")
	var context_en = tracker.get_context_for_ai("en")
	_assert(context_en is String, "Should return string")
	_assert(context_en.length() > 0, "Should not be empty")
	_assert("Recent player choices" in context_en, "Should have English header")
	_assert("Made a risky decision" in context_en, "Should include choice text")
	var context_zh = tracker.get_context_for_ai("zh")
	_assert((LocalizationManager.get_translation("TEST_BUTTERFLY_CONTEXT_HEADER_ZH", "zh") if LocalizationManager else "") in context_zh, "Should have Chinese header")
	tracker.clear_all()
	var empty_context = tracker.get_context_for_ai("en")
	_assert(empty_context == "", "Should return empty string with no choices")
	print("[Test] AI context generation PASSED ")
func _test_butterfly_effect_summary() -> void:
	print("[Test] Butterfly effect summary...")
	tracker.clear_all()
	var choice_id = tracker.record_choice({
		"text": "Early choice",
		"choice_type": "critical",
		"consequences": [
			{"scene_number": 2, "description": "Consequence 1", "triggered": false}
		]
	})
	tracker.advance_scene()
	tracker.advance_scene()
	var summary = tracker.get_butterfly_effect_summary()
	_assert(summary is Array, "Should return array")
	tracker.advance_scene()
	summary = tracker.get_butterfly_effect_summary()
	if summary.size() > 0:
		var entry = summary[0]
		_assert(entry.has("choice_id"), "Summary should have choice_id")
		_assert(entry.has("choice_text"), "Summary should have choice_text")
		_assert(entry.has("scenes_ago"), "Summary should have scenes_ago")
		_assert(entry.has("consequences_triggered"), "Summary should have triggered count")
		_assert(entry.has("choice_type"), "Summary should have choice_type")
	print("[Test] Butterfly effect summary PASSED ")
func _test_eligible_for_ripple() -> void:
	print("[Test] Eligible for ripple...")
	tracker.clear_all()
	tracker.current_scene_number = 10
	tracker.recorded_choices.append({
		"id": "recent",
		"scene_number": 9,
		"choice_text": "Too recent",
		"choice_type": "major",
		"consequences_triggered": 0,
		"consequences_total": 0,
		"consequences": [],
		"tags": [],
		"stats_at_time": {}
	})
	tracker.recorded_choices.append({
		"id": "eligible",
		"scene_number": 5,
		"choice_text": "Eligible choice",
		"choice_type": "major",
		"consequences_triggered": 0,
		"consequences_total": 0,
		"consequences": [],
		"tags": [],
		"stats_at_time": {}
	})
	tracker.recorded_choices.append({
		"id": "old",
		"scene_number": -15,
		"choice_text": "Too old",
		"choice_type": "major",
		"consequences_triggered": 0,
		"consequences_total": 0,
		"consequences": [],
		"tags": [],
		"stats_at_time": {}
	})
	var eligible = tracker.get_eligible_for_ripple()
	_assert(eligible.size() == 1, "Should find 1 eligible choice")
	_assert(eligible[0]["id"] == "eligible", "Should be the eligible choice")
	print("[Test] Eligible for ripple PASSED ")
func _test_suggest_choice_callback() -> void:
	print("[Test] Suggest choice callback...")
	tracker.clear_all()
	tracker.current_scene_number = 10
	tracker.recorded_choices.append({
		"id": "gloria_choice",
		"scene_number": 5,
		"choice_text": "Gloria choice",
		"choice_type": "major",
		"tags": ["gloria"],
		"consequences_triggered": 0,
		"consequences_total": 0,
		"consequences": [],
		"stats_at_time": {}
	})
	tracker.recorded_choices.append({
		"id": "combat_choice",
		"scene_number": 6,
		"choice_text": "Combat choice",
		"choice_type": "major",
		"tags": ["combat"],
		"consequences_triggered": 0,
		"consequences_total": 0,
		"consequences": [],
		"stats_at_time": {}
	})
	var suggested = tracker.suggest_choice_for_callback(["gloria"], 3)
	if not suggested.is_empty():
		_assert(suggested["id"] == "gloria_choice", "Should suggest gloria choice")
		_assert("gloria" in suggested["tags"], "Should have gloria tag")
	var any_suggested = tracker.suggest_choice_for_callback([], 3)
	_assert(not any_suggested.is_empty(), "Should suggest a choice")
	print("[Test] Suggest choice callback PASSED ")
func _test_save_load_functionality() -> void:
	print("[Test] Save/load functionality...")
	tracker.clear_all()
	tracker.record_choice("Save test choice 1")
	tracker.record_choice("Save test choice 2")
	tracker.advance_scene()
	tracker.advance_scene()
	var save_data = tracker.get_save_data()
	_assert(save_data.has("recorded_choices"), "Save data should have choices")
	_assert(save_data.has("current_scene_number"), "Save data should have scene number")
	_assert(save_data.has("next_choice_id"), "Save data should have next ID")
	_assert(save_data["current_scene_number"] == 2, "Should save scene number")
	tracker.clear_all()
	_assert(tracker.recorded_choices.size() == 0, "Should be cleared")
	_assert(tracker.current_scene_number == 0, "Scene should be reset")
	tracker.load_save_data(save_data)
	_assert(tracker.recorded_choices.size() == 2, "Should restore choices")
	_assert(tracker.current_scene_number == 2, "Should restore scene number")
	_assert(tracker.recorded_choices[0]["choice_text"] == "Save test choice 1", "Should restore choice data")
	print("[Test] Save/load functionality PASSED ")
func _test_max_choices_limit() -> void:
	print("[Test] Max choices limit...")
	tracker.clear_all()
	for i in range(105):
		tracker.record_choice("Choice %d" % i)
	_assert(tracker.recorded_choices.size() == 100, "Should limit to MAX_STORED_CHOICES")
	var first_choice = tracker.recorded_choices[0]
	_assert("Choice 5" in first_choice["choice_text"], "Oldest choices should be removed")
	print("[Test] Max choices limit PASSED ")
func _test_choice_type_validation() -> void:
	print("[Test] Choice type validation...")
	tracker.clear_all()
	var critical_id = tracker.record_choice({"text": "Critical", "choice_type": "critical"})
	var major_id = tracker.record_choice({"text": "Major", "choice_type": "major"})
	var minor_id = tracker.record_choice({"text": "Minor", "choice_type": "minor"})
	_assert(tracker.get_choice_by_id(critical_id)["choice_type"] == "critical", "Should accept critical")
	_assert(tracker.get_choice_by_id(major_id)["choice_type"] == "major", "Should accept major")
	_assert(tracker.get_choice_by_id(minor_id)["choice_type"] == "minor", "Should accept minor")
	var invalid_id = tracker.record_choice({"text": "Invalid", "choice_type": "invalid_type"}, "major")
	_assert(tracker.get_choice_by_id(invalid_id)["choice_type"] == "major", "Should use default for invalid type")
	print("[Test] Choice type validation PASSED ")
func _test_signal_emission() -> void:
	print("[Test] Signal emission...")
	tracker.clear_all()
	signal_choice_recorded = false
	signal_consequence_triggered = false
	signal_butterfly_revealed = false
	tracker.record_choice("Signal test choice")
	await get_tree().create_timer(0.05).timeout
	_assert(signal_choice_recorded, "choice_recorded signal should be emitted")
	tracker.clear_all()
	signal_consequence_triggered = false
	signal_butterfly_revealed = false
	var choice_id = tracker.record_choice({
		"text": "Consequence test",
		"consequences": [
			{"scene_number": 1, "description": "Test consequence", "triggered": false}
		]
	})
	tracker.advance_scene()
	await get_tree().create_timer(0.05).timeout
	_assert(signal_consequence_triggered, "consequence_triggered signal should be emitted")
	_assert(signal_butterfly_revealed, "butterfly_effect_revealed signal should be emitted")
	print("[Test] Signal emission PASSED ")
func _test_clear_functionality() -> void:
	print("[Test] Clear functionality...")
	tracker.clear_all()
	tracker.record_choice("Choice 1")
	tracker.record_choice("Choice 2")
	tracker.advance_scene()
	tracker.advance_scene()
	_assert(tracker.recorded_choices.size() > 0, "Should have choices before clear")
	_assert(tracker.current_scene_number > 0, "Should have advanced scenes")
	tracker.clear_all()
	_assert(tracker.recorded_choices.size() == 0, "Choices should be cleared")
	_assert(tracker.current_scene_number == 0, "Scene should be reset to 0")
	_assert(tracker.next_choice_id == 1, "Choice ID should be reset to 1")
	print("[Test] Clear functionality PASSED ")
func _assert(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
		print("    PASS  %s" % message)
	else:
		tests_failed += 1
		print("    FAIL  %s" % message)
