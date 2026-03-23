extends Node
const PrayerSystemScript = preload("res://1.Codebase/src/scripts/ui/prayer_system.gd")
var tests_passed: int = 0
var tests_failed: int = 0
func _ready() -> void:
	print("Running PrayerSystem Sanitization Logic Test")
	print("------------------------------------------")
	_test_whitespace_collapse()
	_test_length_cap()
	print("Prayer sanitization summary: %d passed, %d failed" % [tests_passed, tests_failed])
	queue_free()
func _assert_test(condition: bool, test_name: String, details: String = "") -> void:
	if condition:
		tests_passed += 1
		print("PASS: %s" % test_name)
		return
	tests_failed += 1
	print("FAIL: %s" % test_name)
	if not details.is_empty():
		print(details)
func _new_prayer_system():
	return PrayerSystemScript.new()
func _test_whitespace_collapse() -> void:
	var prayer_system = _new_prayer_system()
	var raw_text := "  hello   world  \t\n  test  "
	var sanitized: String = prayer_system._sanitize_prayer_text(raw_text)
	_assert_test(
		sanitized == "hello world test",
		"Prayer text collapses whitespace safely",
		"Expected 'hello world test', got '%s'" % sanitized,
	)
	prayer_system.free()
func _test_length_cap() -> void:
	var prayer_system = _new_prayer_system()
	var over_limit := "x".repeat(GameConstants.Prayer.MAX_SANITIZED_INPUT_LENGTH + 25)
	var sanitized: String = prayer_system._sanitize_prayer_text(over_limit)
	_assert_test(
		sanitized.length() == GameConstants.Prayer.MAX_SANITIZED_INPUT_LENGTH,
		"Prayer text respects MAX_SANITIZED_INPUT_LENGTH",
		"Expected length %d, got %d" % [
			GameConstants.Prayer.MAX_SANITIZED_INPUT_LENGTH,
			sanitized.length(),
		],
	)
	prayer_system.free()
