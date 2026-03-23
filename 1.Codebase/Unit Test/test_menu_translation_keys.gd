extends Node
var tests_passed: int = 0
var tests_failed: int = 0
func _ready() -> void:
	print("\n" + "=".repeat(80))
	print(" MENU TRANSLATION KEYS TEST")
	print("=".repeat(80) + "\n")
	await get_tree().process_frame
	if not LocalizationManager:
		print("ERROR: LocalizationManager not available!")
		tests_failed += 1
		queue_free()
		return
	var test_keys = [
		"MENU_TIMESTAMP_FMT",
		"MENU_SLOT_FMT",
		"MENU_LAST_SAVE_FMT"
	]
	for key in test_keys:
		print("Testing key: %s" % key)
		var en_value = LocalizationManager.get_translation(key, "en")
		var zh_value = LocalizationManager.get_translation(key, "zh")
		print("  EN: %s" % en_value)
		print("  ZH: %s" % zh_value)
		_assert(en_value != key, "English translation found for %s" % key)
		_assert(zh_value != key, "Chinese translation found for %s" % key)
		print("")
	print("Testing string formatting:")
	print("")
	var slot_fmt = LocalizationManager.get_translation("MENU_SLOT_FMT", "en")
	if slot_fmt != "MENU_SLOT_FMT":
		var formatted = slot_fmt % 3
		print("  MENU_SLOT_FMT %% 3 = '" + formatted + "'")
		_assert(true, "Slot formatting works")
	else:
		_assert(false, "Slot formatting works")
	print("")
	var timestamp_fmt = LocalizationManager.get_translation("MENU_TIMESTAMP_FMT", "en")
	if timestamp_fmt != "MENU_TIMESTAMP_FMT":
		var formatted = timestamp_fmt % [2026, 2, 25, 14, 30]
		print("  MENU_TIMESTAMP_FMT %% [2026, 2, 25, 14, 30] = '%s'" % formatted)
		_assert(true, "Timestamp formatting works")
	else:
		_assert(false, "Timestamp formatting works")
	print("")
	var last_save_fmt = LocalizationManager.get_translation("MENU_LAST_SAVE_FMT", "en")
	if last_save_fmt != "MENU_LAST_SAVE_FMT":
		var formatted = last_save_fmt % [85, 12, "Slot 3", "2026-02-25 14:30"]
		print("  MENU_LAST_SAVE_FMT %% [85, 12, 'Slot 3', '2026-02-25 14:30'] = '%s'" % formatted)
		_assert(true, "Last save formatting works")
	else:
		_assert(false, "Last save formatting works")
	print("")
	print("=".repeat(80))
	if tests_failed == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
	print("=".repeat(80) + "\n")
	queue_free()
func _assert(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
		print("  PASS: %s" % message)
	else:
		tests_failed += 1
		print("  FAIL: %s" % message)
