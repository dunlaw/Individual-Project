extends Node
var tests_passed: int = 0
var tests_failed: int = 0
const IntroStoryScript = preload("res://1.Codebase/src/scripts/ui/intro_story.gd")
const IntroStoryData = preload("res://1.Codebase/src/scripts/ui/intro_story_data.gd")
func _ready() -> void:
	print("[IntroStoryLoadingTest] Starting intro story loading tests...")
	await get_tree().process_frame
	_test_bundled_story_pages_complete()
	_test_csv_story_pages_complete()
	_test_german_story_text_escape_sequences_are_decoded()
	print("[IntroStoryLoadingTest] All tests completed.")
	queue_free()
func _test_bundled_story_pages_complete() -> void:
	var pages := IntroStoryData.get_story_pages()
	_assert(pages.size() >= IntroStoryScript.TOTAL_PAGES, "Bundled intro story data should include all intro pages")
	for i in range(IntroStoryScript.TOTAL_PAGES):
		var page_data: Dictionary = pages[i]
		var text_zh := String(page_data.get("text_zh", "")).strip_edges()
		var text_en := String(page_data.get("text_en", "")).strip_edges()
		_assert(not text_zh.is_empty(), "Bundled zh story text should not be empty on page %d" % (i + 1))
		_assert(not text_en.is_empty(), "Bundled en story text should not be empty on page %d" % (i + 1))
		_assert(not text_zh.contains(LocalizationManager.get_translation("TEST_INTRO_PLACEHOLDER_ZH", "zh") if LocalizationManager else "placeholder"), "Bundled zh story text should not be placeholder on page %d" % (i + 1))
		_assert(not text_en.contains("Placeholder"), "Bundled en story text should not be placeholder on page %d" % (i + 1))
	print("[Test] Bundled intro story pages completeness PASSED")
func _test_csv_story_pages_complete() -> void:
	var file := FileAccess.open(IntroStoryScript.STORY_CSV_PATH, FileAccess.READ)
	_assert(file != null, "Intro story CSV should be loadable in source tree")
	if file == null:
		return
	var row_index := 0
	var valid_rows := 0
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.is_empty():
			continue
		if row_index == 0:
			row_index += 1
			continue
		row_index += 1
		if row.size() < 9:
			continue
		var title_zh := String(row[4]).strip_edges()
		var title_en := String(row[5]).strip_edges()
		var text_zh := String(row[6]).strip_edges()
		var text_en := String(row[7]).strip_edges()
		if title_zh.is_empty() or title_en.is_empty() or text_zh.is_empty() or text_en.is_empty():
			continue
		valid_rows += 1
	file.close()
	_assert(valid_rows >= IntroStoryScript.TOTAL_PAGES, "CSV intro story should provide complete data for all intro pages")
	print("[Test] Intro story CSV completeness PASSED")
func _test_german_story_text_escape_sequences_are_decoded() -> void:
	var intro_story := IntroStoryScript.new()
	var loaded_from_csv := intro_story._try_load_story_pages_from_csv()
	_assert(loaded_from_csv, "Intro story CSV should load through IntroStory parser")
	if not loaded_from_csv:
		return
	_assert(intro_story.story_pages.size() >= 6, "Intro story CSV should include page 6 for German text validation")
	if intro_story.story_pages.size() < 6:
		return
	var page_six: Dictionary = intro_story.story_pages[5]
	var german_text := String(page_six.get("text_de", ""))
	_assert(german_text.contains("\n"), "German story page 6 should contain actual line breaks")
	_assert(not german_text.contains("\\n"), "German story page 6 should not keep escaped newline markers")
	_assert(not german_text.contains("\\\""), "German story page 6 should not keep escaped quote markers")
	print("[Test] German intro story text escape decoding PASSED")
func _assert(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
		print("    PASS  %s" % message)
	else:
		tests_failed += 1
		print("    FAIL  %s" % message)
