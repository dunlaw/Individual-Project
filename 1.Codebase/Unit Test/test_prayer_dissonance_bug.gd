extends Node
var tests_passed: int = 0
var tests_failed: int = 0
var prayer_system_script = load("res://1.Codebase/src/scripts/ui/prayer_system.gd")
func test_dissonance_ui_update() -> void:
	print("[Test] Starting Cognitive Dissonance UI Bug Regression Test")
	var game_state = GameState
	game_state.cognitive_dissonance_active = true
	game_state.current_language = "en"
	var ps = prayer_system_script.new()
	var prayer_input = TextEdit.new()
	prayer_input.text = "I hate this"
	ps.prayer_input = prayer_input
	print("[Test] Original Text: 'I hate this'")
	var prayer_text = prayer_input.text.strip_edges()
	var original_input = prayer_text
	if game_state.cognitive_dissonance_active:
		prayer_text = ps._inject_positive_words(prayer_text, "en")
		print("[Test] Injected Text: '%s'" % prayer_text)
	var sanitized_prayer = ps._sanitize_prayer_text(prayer_text)
	print("[Test] Sanitized Text: '%s'" % sanitized_prayer)
	if sanitized_prayer != original_input:
		print("[Test] Logic Branch: sanitized != original -> UPDATING UI")
		prayer_input.text = sanitized_prayer
	else:
		print("[Test] Logic Branch: sanitized == original -> NOT UPDATING UI")
	_assert(prayer_input.text != original_input, "Prayer text updates after cognitive dissonance injection")
	_assert(prayer_input.text == sanitized_prayer, "Prayer UI reflects sanitized prayer text")
	_assert(prayer_input.text.length() > original_input.length(), "Prayer text gains injected positive wording")
	ps.free()
	prayer_input.free()
func _ready() -> void:
	test_dissonance_ui_update()
	print("[PrayerDissonanceBugTest] Summary: %d passed, %d failed" % [tests_passed, tests_failed])
	queue_free()
func _assert(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
		print("    PASS  %s" % message)
	else:
		tests_failed += 1
		print("    FAIL  %s" % message)
