extends Node
var _test_results = []
var _game_state = null
var _save_system = null
func _ready():
	print("\n" + "=".repeat(80))
	print(" JOURNAL/DIARY SAVE/LOAD TEST SUITE (" + (LocalizationManager.get_translation("TEST_JOURNAL_SAVE_TITLE_ZH", "zh") if LocalizationManager else "Journal Save Test") + ")")
	print("=".repeat(80) + "\n")
	await run_all_tests()
	print_summary()
	cleanup_test_files()
	queue_free()
func run_all_tests():
	await run_test("GameState and SaveLoadSystem initialization", test_initialization)
	await run_test("Journal entries save to metadata", test_journal_entries_in_metadata)
	await run_test("Player preset entry persistence", test_preset_entry_save_load)
	await run_test("Player custom entry persistence", test_custom_entry_save_load)
	await run_test("AI summary persistence", test_ai_summary_persistence)
	await run_test("Multiple journal entries save/load", test_multiple_entries)
	await run_test("Empty AI summary handling", test_empty_summary_handling)
	await run_test("AI summary pending flag persistence", test_pending_flag_persistence)
	await run_test("Journal entry structure completeness", test_entry_structure)
	await run_test("Full save/load cycle integration", test_full_save_load_cycle)
func run_test(test_name: String, test_func: Callable):
	setup_test_environment()
	var result = await test_func.call()
	_test_results.append({"name": test_name, "passed": result})
	if result:
		print("   ✓ %s" % test_name)
	else:
		print("   ✗ %s FAILED" % test_name)
	teardown_test_environment()
func setup_test_environment():
	_game_state = get_node_or_null("/root/GameState")
	_save_system = get_node_or_null("/root/SaveLoadSystem")
	if not _save_system and _game_state and _game_state.has_method("get_save_load_system"):
		_save_system = _game_state.get_save_load_system()
	if not _game_state:
		print("      WARNING: GameState autoload not available")
	if not _save_system:
		print("      WARNING: SaveLoadSystem autoload not available")
func teardown_test_environment():
	if _game_state:
		_game_state.set_journal_entries([])
func test_initialization() -> bool:
	var success = true
	success = assert_not_null(_game_state, "GameState autoload exists") and success
	success = assert_not_null(_save_system, "SaveLoadSystem autoload exists") and success
	if _game_state:
		var entries = _game_state.get_journal_entries()
		success = assert_true(entries is Array, "Journal entries returns Array") and success
	return success
func test_journal_entries_in_metadata() -> bool:
	var success = true
	if not _game_state:
		print("      SKIP: GameState not available")
		return true
	var test_entry = {
		"id": "test_123",
		"timestamp": "2026-03-12 10:00:00",
		"icon_path": "res://1.Codebase/src/assets/ui/icons/journal_frustrated.png",
		"text": "Test entry text",
		"type": "frustrated",
		"source": "preset",
		"reality_gain": 2,
		"ai_summary": "Test summary",
		"ai_summary_pending": false
	}
	_game_state.set_journal_entries([test_entry])
	var save_data = _game_state.get_save_data()
	success = assert_true(save_data.has("metadata"), "Save data has metadata") and success
	if save_data.has("metadata"):
		var metadata = save_data["metadata"]
		success = assert_true(metadata is Dictionary, "Metadata is Dictionary") and success
		success = assert_true(metadata.has("journal_entries"), "Metadata has journal_entries") and success
		if metadata.has("journal_entries"):
			var entries = metadata["journal_entries"]
			success = assert_true(entries is Array, "Journal entries is Array") and success
			success = assert_equal(entries.size(), 1, "Has 1 journal entry") and success
			if entries.size() > 0:
				var loaded_entry = entries[0]
				success = assert_equal(loaded_entry.get("id"), "test_123", "Entry ID matches") and success
				success = assert_equal(loaded_entry.get("text"), "Test entry text", "Entry text matches") and success
				success = assert_equal(loaded_entry.get("ai_summary"), "Test summary", "AI summary matches") and success
	return success
func test_preset_entry_save_load() -> bool:
	var success = true
	if not _game_state or not _save_system:
		print("      SKIP: Required systems not available")
		return true
	var preset_entry = {
		"id": "preset_456",
		"timestamp": "2026-03-12 11:00:00",
		"icon_path": "res://1.Codebase/src/assets/ui/icons/journal_frustrated.png",
		"text": "I feel so overwhelmed by everything...",
		"type": "frustrated",
		"source": "preset",
		"reality_gain": 2,
		"ai_summary": "",
		"ai_summary_pending": true
	}
	_game_state.set_journal_entries([preset_entry])
	var save_result = _save_system.save_to_slot(1)
	success = assert_true(save_result, "Save to slot succeeded") and success
	_game_state.set_journal_entries([])
	var cleared = _game_state.get_journal_entries()
	success = assert_equal(cleared.size(), 0, "Entries cleared") and success
	var load_result = _save_system.load_from_slot(1)
	success = assert_true(load_result, "Load from slot succeeded") and success
	var loaded_entries = _game_state.get_journal_entries()
	success = assert_equal(loaded_entries.size(), 1, "Loaded 1 entry") and success
	if loaded_entries.size() > 0:
		var entry = loaded_entries[0]
		success = assert_equal(entry.get("id"), "preset_456", "Preset ID persisted") and success
		success = assert_equal(entry.get("text"), "I feel so overwhelmed by everything...", "Preset text persisted") and success
		success = assert_equal(entry.get("type"), "frustrated", "Preset type persisted") and success
		success = assert_equal(entry.get("source"), "preset", "Source is preset") and success
		success = assert_equal(entry.get("reality_gain"), 2, "Reality gain persisted") and success
	return success
func test_custom_entry_save_load() -> bool:
	var success = true
	if not _game_state or not _save_system:
		print("      SKIP: Required systems not available")
		return true
	var custom_entry = {
		"id": "custom_789",
		"timestamp": "2026-03-12 12:00:00",
		"icon_path": "res://1.Codebase/src/assets/ui/icons/journal_custom.png",
		"text": LocalizationManager.get_translation("TEST_JOURNAL_TEXT_1", "zh") if LocalizationManager else "I learned a lot today.",  
		"type": "custom",
		"source": "custom",
		"reality_gain": 5,
		"ai_summary": "",
		"ai_summary_pending": true
	}
	_game_state.set_journal_entries([custom_entry])
	_save_system.save_to_slot(2)
	_game_state.set_journal_entries([])
	_save_system.load_from_slot(2)
	var loaded_entries = _game_state.get_journal_entries()
	success = assert_equal(loaded_entries.size(), 1, "Loaded 1 custom entry") and success
	if loaded_entries.size() > 0:
		var entry = loaded_entries[0]
		success = assert_equal(entry.get("id"), "custom_789", "Custom ID persisted") and success
		success = assert_equal(entry.get("text"), (LocalizationManager.get_translation("TEST_JOURNAL_TEXT_1", "zh") if LocalizationManager else "I learned a lot today."), "Chinese text persisted") and success
		success = assert_equal(entry.get("type"), "custom", "Custom type persisted") and success
		success = assert_equal(entry.get("source"), "custom", "Source is custom") and success
		success = assert_equal(entry.get("reality_gain"), 5, "Custom reality gain persisted") and success
	return success
func test_ai_summary_persistence() -> bool:
	var success = true
	if not _game_state or not _save_system:
		print("      SKIP: Required systems not available")
		return true
	var entry_with_summary = {
		"id": "summary_111",
		"timestamp": "2026-03-12 13:00:00",
		"icon_path": "res://1.Codebase/src/assets/ui/icons/journal_hopeless.png",
		"text": "Everything feels pointless and I can't find motivation to do anything.",
		"type": "hopeless",
		"source": "preset",
		"reality_gain": 3,
		"ai_summary": "The player is experiencing a lack of motivation and feelings of futility, which may indicate low morale or depression.",
		"ai_summary_pending": false,
		"ai_summary_timestamp": "2026-03-12 13:01:00"
	}
	_game_state.set_journal_entries([entry_with_summary])
	_save_system.save_to_slot(3)
	_game_state.set_journal_entries([])
	_save_system.load_from_slot(3)
	var loaded_entries = _game_state.get_journal_entries()
	success = assert_equal(loaded_entries.size(), 1, "Loaded entry with summary") and success
	if loaded_entries.size() > 0:
		var entry = loaded_entries[0]
		success = assert_equal(entry.get("ai_summary"), "The player is experiencing a lack of motivation and feelings of futility, which may indicate low morale or depression.", "AI summary persisted") and success
		success = assert_equal(entry.get("ai_summary_pending"), false, "Pending flag is false") and success
		success = assert_true(entry.has("ai_summary_timestamp"), "Has summary timestamp") and success
	return success
func test_multiple_entries() -> bool:
	var success = true
	if not _game_state or not _save_system:
		print("      SKIP: Required systems not available")
		return true
	var entries = [
		{
			"id": "multi_1",
			"timestamp": "2026-03-12 14:00:00",
			"icon_path": "res://1.Codebase/src/assets/ui/icons/journal_frustrated.png",
			"text": "First entry",
			"type": "frustrated",
			"source": "preset",
			"reality_gain": 2,
			"ai_summary": "Summary 1",
			"ai_summary_pending": false
		},
		{
			"id": "multi_2",
			"timestamp": "2026-03-12 14:05:00",
			"icon_path": "res://1.Codebase/src/assets/ui/icons/journal_angry.png",
			"text": "Second entry",
			"type": "angry",
			"source": "preset",
			"reality_gain": 3,
			"ai_summary": "Summary 2",
			"ai_summary_pending": false
		},
		{
			"id": "multi_3",
			"timestamp": "2026-03-12 14:10:00",
			"icon_path": "res://1.Codebase/src/assets/ui/icons/journal_custom.png",
			"text": "Third custom entry",
			"type": "custom",
			"source": "custom",
			"reality_gain": 5,
			"ai_summary": "Summary 3",
			"ai_summary_pending": false
		}
	]
	_game_state.set_journal_entries(entries)
	_save_system.save_to_slot(4)
	_game_state.set_journal_entries([])
	_save_system.load_from_slot(4)
	var loaded_entries = _game_state.get_journal_entries()
	success = assert_equal(loaded_entries.size(), 3, "All 3 entries persisted") and success
	if loaded_entries.size() == 3:
		for i in range(3):
			var entry = loaded_entries[i]
			var expected_id = "multi_%d" % (i + 1)
			success = assert_equal(entry.get("id"), expected_id, "Entry %d ID correct" % (i + 1)) and success
	return success
func test_empty_summary_handling() -> bool:
	var success = true
	if not _game_state or not _save_system:
		print("      SKIP: Required systems not available")
		return true
	var entry_no_summary = {
		"id": "empty_222",
		"timestamp": "2026-03-12 15:00:00",
		"icon_path": "res://1.Codebase/src/assets/ui/icons/journal_confused.png",
		"text": "I don't know what to think anymore.",
		"type": "confused",
		"source": "preset",
		"reality_gain": 2,
		"ai_summary": "",
		"ai_summary_pending": true
	}
	_game_state.set_journal_entries([entry_no_summary])
	_save_system.save_to_slot(5)
	_game_state.set_journal_entries([])
	_save_system.load_from_slot(5)
	var loaded_entries = _game_state.get_journal_entries()
	success = assert_equal(loaded_entries.size(), 1, "Entry loaded") and success
	if loaded_entries.size() > 0:
		var entry = loaded_entries[0]
		success = assert_equal(entry.get("ai_summary"), "", "Empty summary persisted") and success
		success = assert_equal(entry.get("ai_summary_pending"), true, "Pending flag true") and success
	return success
func test_pending_flag_persistence() -> bool:
	var success = true
	if not _game_state or not _save_system:
		print("      SKIP: Required systems not available")
		return true
	var entries = [
		{
			"id": "pending_1",
			"timestamp": "2026-03-12 16:00:00",
			"text": "Pending entry",
			"ai_summary": "",
			"ai_summary_pending": true
		},
		{
			"id": "pending_2",
			"timestamp": "2026-03-12 16:05:00",
			"text": "Complete entry",
			"ai_summary": "Complete summary",
			"ai_summary_pending": false
		}
	]
	_game_state.set_journal_entries(entries)
	_save_system.autosave()
	_game_state.set_journal_entries([])
	var load_result = _save_system.load_from_autosave()
	success = assert_true(load_result, "Autosave loaded") and success
	var loaded = _game_state.get_journal_entries()
	if loaded.size() == 2:
		success = assert_equal(loaded[0].get("ai_summary_pending"), true, "Pending flag true persisted") and success
		success = assert_equal(loaded[1].get("ai_summary_pending"), false, "Pending flag false persisted") and success
	return success
func test_entry_structure() -> bool:
	var success = true
	if not _game_state or not _save_system:
		print("      SKIP: Required systems not available")
		return true
	var complete_entry = {
		"id": "complete_333",
		"timestamp": "2026-03-12 17:00:00",
		"icon_path": "res://1.Codebase/src/assets/ui/icons/journal_tired.png",
		"text": "I'm exhausted from all the mental strain.",
		"type": "tired",
		"source": "preset",
		"reality_gain": 4,
		"ai_summary": "Player shows signs of mental fatigue and burnout.",
		"ai_summary_pending": false,
		"ai_summary_timestamp": "2026-03-12 17:01:00"
	}
	_game_state.set_journal_entries([complete_entry])
	_save_system.save_to_slot(1)
	_game_state.set_journal_entries([])
	_save_system.load_from_slot(1)
	var loaded = _game_state.get_journal_entries()
	if loaded.size() > 0:
		var entry = loaded[0]
		success = assert_true(entry.has("id"), "Has id field") and success
		success = assert_true(entry.has("timestamp"), "Has timestamp field") and success
		success = assert_true(entry.has("icon_path"), "Has icon_path field") and success
		success = assert_true(entry.has("text"), "Has text field") and success
		success = assert_true(entry.has("type"), "Has type field") and success
		success = assert_true(entry.has("source"), "Has source field") and success
		success = assert_true(entry.has("reality_gain"), "Has reality_gain field") and success
		success = assert_true(entry.has("ai_summary"), "Has ai_summary field") and success
		success = assert_true(entry.has("ai_summary_pending"), "Has ai_summary_pending field") and success
	return success
func test_full_save_load_cycle() -> bool:
	var success = true
	if not _game_state or not _save_system:
		print("      SKIP: Required systems not available")
		return true
	var realistic_entries = [
		{
			"id": "cycle_1_1710244800000",
			"timestamp": "2026-03-12 08:00:00",
			"icon_path": "res://1.Codebase/src/assets/ui/icons/journal_frustrated.png",
			"text": "Started the day feeling overwhelmed by tasks.",
			"type": "frustrated",
			"source": "preset",
			"reality_gain": 2,
			"ai_summary": "Player begins with stress about workload.",
			"ai_summary_pending": false,
			"ai_summary_timestamp": "2026-03-12 08:00:30"
		},
		{
			"id": "cycle_2_1710248400000",
			"timestamp": "2026-03-12 09:00:00",
			"icon_path": "res://1.Codebase/src/assets/ui/icons/journal_custom.png",
			"text": LocalizationManager.get_translation("TEST_JOURNAL_TEXT_2", "zh") if LocalizationManager else "Tried mindfulness meditation.",
			"type": "custom",
			"source": "custom",
			"reality_gain": 5,
			"ai_summary": "Player is trying mindfulness meditation to manage stress, with some positive results.",
			"ai_summary_pending": false,
			"ai_summary_timestamp": "2026-03-12 09:01:00"
		},
		{
			"id": "cycle_3_1710252000000",
			"timestamp": "2026-03-12 10:00:00",
			"icon_path": "res://1.Codebase/src/assets/ui/icons/journal_hopeless.png",
			"text": "Nothing seems to be working out today...",
			"type": "hopeless",
			"source": "preset",
			"reality_gain": 3,
			"ai_summary": "",
			"ai_summary_pending": true
		}
	]
	_game_state.set_journal_entries(realistic_entries)
	var autosave_result = _save_system.autosave()
	success = assert_true(autosave_result, "Autosave succeeded") and success
	_game_state.set_journal_entries([])
	var load_result = _save_system.load_from_autosave()
	success = assert_true(load_result, "Load from autosave succeeded") and success
	var loaded = _game_state.get_journal_entries()
	success = assert_equal(loaded.size(), 3, "All 3 realistic entries loaded") and success
	if loaded.size() == 3:
		var entry1 = loaded[0]
		success = assert_equal(entry1.get("ai_summary_pending"), false, "Entry 1 summary complete") and success
		success = assert_true(entry1.get("ai_summary").length() > 0, "Entry 1 has summary") and success
		var entry2 = loaded[1]
		success = assert_true(entry2.get("text") == (LocalizationManager.get_translation("TEST_JOURNAL_TEXT_2", "zh") if LocalizationManager else "Tried mindfulness meditation."), "Entry 2 Chinese text persisted") and success
		success = assert_equal(entry2.get("source"), "custom", "Entry 2 is custom") and success
		var entry3 = loaded[2]
		success = assert_equal(entry3.get("ai_summary_pending"), true, "Entry 3 summary pending") and success
		success = assert_equal(entry3.get("ai_summary"), "", "Entry 3 summary empty") and success
	return success
func assert_true(condition: bool, message: String = "") -> bool:
	if not condition:
		if message:
			print("      ✗ %s" % message)
		return false
	return true
func assert_equal(actual, expected, message: String = "") -> bool:
	if actual != expected:
		if message:
			print("      ✗ %s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true
func assert_not_null(value, message: String = "") -> bool:
	if value == null:
		if message:
			print("      ✗ %s is null" % message)
		return false
	return true
func cleanup_test_files():
	if not _save_system:
		return
	for slot in range(1, 6):
		_save_system.delete_save_slot(slot)
	_save_system.delete_autosave()
	print("\n Test files cleaned up")
func print_summary():
	print("\n" + "=".repeat(80))
	var passed = _test_results.filter(func(r): return r.passed).size()
	var total = _test_results.size()
	if passed == total:
		print(" ✓ ALL TESTS PASSED (%d/%d)" % [passed, total])
		print("\n CONCLUSION: Journal/diary save and load functionality is working correctly.")
		print("   Player input (preset and custom) persists ✓")
		print("   AI summaries persist ✓")
		print("   AI summary pending flags persist ✓")
		print("   Chinese text persists ✓")
		print("   Multiple entries persist ✓")
	else:
		print(" ✗ SOME TESTS FAILED (%d/%d passed)" % [passed, total])
		print("\nFailed tests:")
		for result in _test_results:
			if not result.passed:
				print("  • %s" % result.name)
	print("=".repeat(80) + "\n")
