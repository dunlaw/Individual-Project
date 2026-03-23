extends Node
var tests_passed: int = 0
var tests_failed: int = 0
func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("SCENE DIRECTIVES SYSTEM TEST")
	print("=".repeat(60) + "\n")
	await get_tree().process_frame
	_record_test(test_character_expression_loader(), "Character Expression Loader")
	_record_test(test_background_loader(), "Background Loader")
	_record_test(test_ai_directive_parsing(), "AI Directive Parsing")
	_record_test(test_scene_directive_application(), "Scene Directive Application")
	_record_test(test_bbcode_balancing(), "BBCode Tag Balancing")
	_record_test(test_fuzzy_asset_matching(), "Fuzzy Asset Matching")
	print("\n" + "=".repeat(60))
	print("SUMMARY: %d passed, %d failed" % [tests_passed, tests_failed])
	print("=".repeat(60) + "\n")
	queue_free()
func _record_test(passed: bool, test_name: String) -> void:
	if passed:
		tests_passed += 1
		print("PASS: %s" % test_name)
	else:
		tests_failed += 1
		print("FAIL: %s" % test_name)
func test_character_expression_loader() -> bool:
	print("\n--- Test 1: Character Expression Loader ---")
	if not CharacterExpressionLoader:
		print("FAIL: CharacterExpressionLoader not available")
		return false
	var characters := CharacterExpressionLoader.get_all_characters()
	print("Found %d characters: %s" % [characters.size(), ", ".join(characters)])
	if characters.is_empty():
		print("FAIL: No characters were reported")
		return false
	for char_id in characters:
		var char_name: String = CharacterExpressionLoader.get_character_name(char_id)
		print("Testing character: %s (%s)" % [char_name, char_id])
		var texture: Texture2D = CharacterExpressionLoader.get_character_texture(char_id, "neutral")
		if texture == null:
			print("WARN: No neutral expression for %s" % char_id)
		var expressions := CharacterExpressionLoader.get_available_expressions(char_id)
		print("Available expressions: %s" % ", ".join(expressions))
	return true
func test_background_loader() -> bool:
	print("\n--- Test 2: Background Loader ---")
	if not BackgroundLoader:
		print("FAIL: BackgroundLoader not available")
		return false
	var bg_ids := BackgroundLoader.get_all_background_ids()
	print("Found %d backgrounds" % bg_ids.size())
	if bg_ids.is_empty():
		print("FAIL: No backgrounds were reported")
		return false
	var test_backgrounds := ["default", "forest", "cave", "temple", "safe_zone"]
	for bg_id in test_backgrounds:
		var texture: Texture2D = BackgroundLoader.get_background_texture(bg_id)
		var bg_info: Dictionary = BackgroundLoader.get_background_info(bg_id)
		if texture == null:
			print("WARN: Failed to load '%s'" % bg_id)
			continue
		var is_placeholder: bool = bg_info.get("is_placeholder", false)
		var status := "placeholder" if is_placeholder else "proper texture"
		print("Loaded '%s' (%s)" % [bg_id, status])
	var ai_prompt: String = BackgroundLoader.get_backgrounds_for_ai_prompt()
	if ai_prompt.is_empty():
		print("FAIL: Failed to generate AI prompt")
		return false
	print("Generated AI prompt with %d characters" % ai_prompt.length())
	return true
func test_ai_directive_parsing() -> bool:
	print("\n--- Test 3: AI Directive Parsing ---")
	if not AIManager:
		print("FAIL: AIManager not available")
		return false
	var test_response_1 := """
Here's the story content...

[SCENE_DIRECTIVES]
{
  "scene": {
	"background": "forest",
	"atmosphere": "mysterious",
	"lighting": "dim"
  },
  "characters": {
	"protagonist": {"expression": "confused", "visible": true},
	"gloria": {"expression": "angry", "visible": true}
  },
  "assets": [
	{"id": "Generic_Lever", "contextual_name": "Ancient Control Lever", "description": "A mysterious lever"}
  ]
}
[/SCENE_DIRECTIVES]
"""
	var directives_1: Dictionary = AIManager.parse_scene_directives(test_response_1)
	if not directives_1.has("scene") or not directives_1.has("characters"):
		print("FAIL: Failed to parse valid scene directives")
		return false
	var story_content: String = AIManager.extract_story_content(test_response_1)
	if "[SCENE_DIRECTIVES]" in story_content:
		print("FAIL: Scene directives were not removed from story content")
		return false
	var test_response_2 := "Just a regular story without directives"
	var directives_2: Dictionary = AIManager.parse_scene_directives(test_response_2)
	if not directives_2.is_empty():
		print("FAIL: Non-directive content was parsed unexpectedly")
		return false
	return true
func test_scene_directive_application() -> bool:
	print("\n--- Test 4: Scene Directive Application ---")
	var story_scene_script: GDScript = load("res://1.Codebase/src/scripts/ui/story_scene.gd")
	var directive_applier_script: GDScript = load("res://1.Codebase/src/scripts/ui/story_scene_directive_applier.gd")
	if story_scene_script == null:
		print("FAIL: Failed to load story scene script")
		return false
	if directive_applier_script == null:
		print("FAIL: Failed to load directive applier script")
		return false
	var story_scene = story_scene_script.new()
	var directive_applier = directive_applier_script.new()
	var required_methods := [
		"apply_scene_directives",
	]
	for method_name in required_methods:
		if not story_scene.has_method(method_name):
			print("FAIL: Missing function: %s" % method_name)
			return false
		print("Found StoryScene function: %s" % method_name)
	var applier_methods := [
		"apply_scene_directives",
		"_apply_scene_settings",
		"_apply_character_directives",
		"_apply_asset_directives",
	]
	for method_name in applier_methods:
		if not directive_applier.has_method(method_name):
			print("FAIL: Missing directive applier function: %s" % method_name)
			return false
		print("Found DirectiveApplier function: %s" % method_name)
	return true
func test_bbcode_balancing() -> bool:
	print("\n--- Test 5: BBCode Tag Balancing ---")
	var StoryUIHelper: GDScript = load("res://1.Codebase/src/scripts/ui/story_ui_helper.gd")
	if StoryUIHelper == null:
		print("FAIL: StoryUIHelper not available")
		return false
	var test_1 := "This is [b]bold text without closing"
	var result_1: String = StoryUIHelper.sanitize_story_text(test_1)
	if result_1.count("[b]") != result_1.count("[/b]"):
		print("FAIL: Did not auto-close [b] tag")
		return false
	var test_2 := "[b]Bold [i]italic [u]underline"
	var result_2: String = StoryUIHelper.sanitize_story_text(test_2)
	if result_2.count("[b]") != result_2.count("[/b]"):
		print("FAIL: Did not balance [b] tag")
		return false
	if result_2.count("[i]") != result_2.count("[/i]"):
		print("FAIL: Did not balance [i] tag")
		return false
	if result_2.count("[u]") != result_2.count("[/u]"):
		print("FAIL: Did not balance [u] tag")
		return false
	var test_3 := "**Bold text** and *italic text*"
	var result_3: String = StoryUIHelper.sanitize_story_text(test_3)
	if result_3.count("[b]") != result_3.count("[/b]"):
		print("FAIL: Markdown bold conversion was unbalanced")
		return false
	if result_3.count("[i]") != result_3.count("[/i]"):
		print("FAIL: Markdown italic conversion was unbalanced")
		return false
	return true
func test_fuzzy_asset_matching() -> bool:
	print("\n--- Test 6: Fuzzy Asset Matching ---")
	if not AIManager:
		print("FAIL: AIManager not available")
		return false
	var test_response_1 := """
[SCENE_DIRECTIVES]
{
  "scene": {"background": "forest"},
  "assets": [
	{"id": "Generic Lever", "contextual_name": "Old Lever"},
	{"id": "generic lever", "contextual_name": "Rusty Lever"}
  ]
}
[/SCENE_DIRECTIVES]
"""
	var directives_1: Dictionary = AIManager.parse_scene_directives(test_response_1)
	if not directives_1.has("assets") or directives_1["assets"].is_empty():
		print("FAIL: Failed to parse asset directives")
		return false
	var first_asset: Dictionary = directives_1["assets"][0]
	var first_asset_id: String = first_asset.get("id", "")
	if first_asset_id != "Generic_Lever" and AssetRegistry.get_asset(first_asset_id).is_empty():
		print("FAIL: Asset ID '%s' was not normalized to a known asset" % first_asset_id)
		return false
	var test_response_2 := """
[SCENE_DIRECTIVES]
{
  "assets": [
	{"id": "GENERIC_MONSTER", "contextual_name": "Scary Beast"}
  ]
}
[/SCENE_DIRECTIVES]
"""
	var directives_2: Dictionary = AIManager.parse_scene_directives(test_response_2)
	if not directives_2.has("assets") or directives_2["assets"].is_empty():
		print("FAIL: Failed to parse case-insensitive asset directives")
		return false
	var second_asset_id: String = directives_2["assets"][0].get("id", "")
	if AssetRegistry.get_asset(second_asset_id).is_empty():
		print("FAIL: Asset ID '%s' does not resolve in AssetRegistry" % second_asset_id)
		return false
	var test_response_3 := """
[SCENE_DIRECTIVES]
{
  "scene": {"background": "Crystal Cavern"},
  "characters": {"protagonist": {"expression": "shocked"}}
}
[/SCENE_DIRECTIVES]
"""
	var directives_3: Dictionary = AIManager.parse_scene_directives(test_response_3)
	if not directives_3.has("scene") or not directives_3["scene"].has("background"):
		print("FAIL: Failed to parse background directive")
		return false
	var bg_id: String = directives_3["scene"]["background"]
	if BackgroundLoader.get_background_texture(bg_id) == null:
		print("FAIL: Background '%s' does not resolve to a texture" % bg_id)
		return false
	var test_response_4 := """
The team enters a dark chamber...

[SCENE_DIRECTIVES]
{
  "scene": {"background": "dungeon", "atmosphere": "dark", "lighting": "dim"},
  "characters": {
	"protagonist": {"expression": "confused", "visible": true},
	"gloria": {"expression": "happy", "visible": true}
  },
  "assets": [
	{"id": "ancient statue", "contextual_name": "Crumbling Statue"},
	{"id": "Generic_Chest", "contextual_name": "Locked Chest"}
  ]
}
[/SCENE_DIRECTIVES]
"""
	var directives_4: Dictionary = AIManager.parse_scene_directives(test_response_4)
	var story_4: String = AIManager.extract_story_content(test_response_4)
	if not directives_4.has("scene") or not directives_4.has("characters") or not directives_4.has("assets"):
		print("FAIL: Full integration payload did not parse completely")
		return false
	if "[SCENE_DIRECTIVES]" in story_4:
		print("FAIL: Story content still contains directive markup")
		return false
	return true
