extends Node
var tests_passed: int = 0
var tests_failed: int = 0
func _ready() -> void:
	print("[AssetRegistryTest] Starting AssetRegistry unit tests...")
	await get_tree().process_frame
	if not AssetRegistry:
		print("[AssetRegistryTest]  FAIL: AssetRegistry autoload not found")
		queue_free()
		return
	_test_system_initialization()
	_test_asset_lookup()
	_test_invalid_asset_lookup()
	_test_get_asset_ids()
	_test_tag_filtering()
	_test_multiple_tag_filtering()
	_test_context_cycles()
	_test_context_type_normalization()
	_test_context_with_explicit_ids()
	_test_context_with_tags()
	_test_default_cycle_fallback()
	_test_prompt_formatting()
	_test_asset_icons()
	_test_get_all_tags()
	_test_asset_data_structure()
	print("[AssetRegistryTest] All tests completed.")
	queue_free()
func _test_system_initialization() -> void:
	print("[Test] System initialization...")
	_assert(AssetRegistry != null, "AssetRegistry should exist as autoload")
	_assert(AssetRegistry.assets is Dictionary, "assets should be Dictionary")
	_assert(AssetRegistry.assets.size() > 0, "assets should contain asset definitions")
	_assert(AssetRegistry.default_cycle is Array, "default_cycle should be Array")
	_assert(AssetRegistry.exploration_cycle is Array, "exploration_cycle should be Array")
	_assert(AssetRegistry.combat_cycle is Array, "combat_cycle should be Array")
	_assert(AssetRegistry.puzzle_cycle is Array, "puzzle_cycle should be Array")
	_assert(AssetRegistry.narrative_cycle is Array, "narrative_cycle should be Array")
	_assert(AssetRegistry.context_cycles is Dictionary, "context_cycles should be Dictionary")
	print("[Test] System initialization PASSED ")
func _test_asset_lookup() -> void:
	print("[Test] Asset lookup...")
	var lever = AssetRegistry.get_asset("Generic_Lever")
	_assert(not lever.is_empty(), "Should return asset data for valid ID")
	_assert(lever.has("id"), "Asset should have ID")
	_assert(lever["id"] == "Generic_Lever", "Asset ID should match")
	_assert(lever.has("default_name"), "Asset should have default_name")
	_assert(lever.has("tags"), "Asset should have tags")
	_assert(lever.has("summary"), "Asset should have summary")
	_assert(lever.has("icon"), "Asset should have icon path")
	var chest = AssetRegistry.get_asset("Generic_Chest")
	_assert(not chest.is_empty(), "Should return chest asset data")
	_assert(chest["id"] == "Generic_Chest", "Chest ID should match")
	print("[Test] Asset lookup PASSED ")
func _test_invalid_asset_lookup() -> void:
	print("[Test] Invalid asset lookup...")
	var invalid = AssetRegistry.get_asset("NonexistentAsset_XYZ")
	_assert(invalid.is_empty(), "Should return empty Dictionary for invalid ID")
	var empty = AssetRegistry.get_asset("")
	_assert(empty.is_empty(), "Should return empty Dictionary for empty ID")
	print("[Test] Invalid asset lookup PASSED ")
func _test_get_asset_ids() -> void:
	print("[Test] Get asset IDs...")
	var asset_ids = AssetRegistry.get_asset_ids()
	_assert(asset_ids is Array, "Should return Array")
	_assert(asset_ids.size() > 0, "Should return multiple asset IDs")
	_assert("Generic_Lever" in asset_ids, "Should include Generic_Lever")
	_assert("Generic_Chest" in asset_ids, "Should include Generic_Chest")
	_assert("Generic_Monster" in asset_ids, "Should include Generic_Monster")
	for id in asset_ids:
		_assert(id is String, "All asset IDs should be Strings")
	print("[Test] Get asset IDs PASSED ")
func _test_tag_filtering() -> void:
	print("[Test] Tag filtering...")
	var interactables = AssetRegistry.get_assets_by_tags(["Interactable"])
	_assert(interactables is Array, "Should return Array")
	_assert(interactables.size() > 0, "Should find assets with Interactable tag")
	for asset in interactables:
		var tags: Array = asset.get("tags", [])
		_assert("Interactable" in tags, "All returned assets should have Interactable tag")
	var mystic = AssetRegistry.get_assets_by_tags(["Mystic"])
	_assert(mystic.size() > 0, "Should find assets with Mystic tag")
	for asset in mystic:
		var tags: Array = asset.get("tags", [])
		_assert("Mystic" in tags, "All returned assets should have Mystic tag")
	print("[Test] Tag filtering PASSED ")
func _test_multiple_tag_filtering() -> void:
	print("[Test] Multiple tag filtering...")
	var interactable_mechanical = AssetRegistry.get_assets_by_tags(["Interactable", "Mechanical"])
	_assert(interactable_mechanical is Array, "Should return Array")
	for asset in interactable_mechanical:
		var tags: Array = asset.get("tags", [])
		_assert("Interactable" in tags, "Asset should have Interactable tag")
		_assert("Mechanical" in tags, "Asset should have Mechanical tag")
	var impossible = AssetRegistry.get_assets_by_tags(["Safe", "Hazard"])
	_assert(impossible is Array, "Should return Array even if no matches")
	print("[Test] Multiple tag filtering PASSED ")
func _test_context_cycles() -> void:
	print("[Test] Context cycles...")
	var default_assets = AssetRegistry.get_assets_for_context({"context_type": "default"})
	_assert(default_assets.size() > 0, "Default cycle should return assets")
	_assert(default_assets.size() == AssetRegistry.default_cycle.size(), "Should return all default cycle assets")
	var exploration_assets = AssetRegistry.get_assets_for_context({"context_type": "exploration"})
	_assert(exploration_assets.size() > 0, "Exploration cycle should return assets")
	_assert(exploration_assets.size() == AssetRegistry.exploration_cycle.size(), "Should return all exploration cycle assets")
	var combat_assets = AssetRegistry.get_assets_for_context({"context_type": "combat"})
	_assert(combat_assets.size() > 0, "Combat cycle should return assets")
	_assert(combat_assets.size() == AssetRegistry.combat_cycle.size(), "Should return all combat cycle assets")
	var puzzle_assets = AssetRegistry.get_assets_for_context({"context_type": "puzzle"})
	_assert(puzzle_assets.size() > 0, "Puzzle cycle should return assets")
	var narrative_assets = AssetRegistry.get_assets_for_context({"context_type": "narrative"})
	_assert(narrative_assets.size() > 0, "Narrative cycle should return assets")
	print("[Test] Context cycles PASSED ")
func _test_context_type_normalization() -> void:
	print("[Test] Context type normalization...")
	var cycle_suffix = AssetRegistry.get_assets_for_context({"context_type": "combat_cycle"})
	_assert(cycle_suffix.size() > 0, "Should handle _cycle suffix")
	var uppercase = AssetRegistry.get_assets_for_context({"context_type": "COMBAT"})
	_assert(uppercase.size() > 0, "Should handle uppercase")
	var whitespace = AssetRegistry.get_assets_for_context({"context_type": "  exploration  "})
	_assert(whitespace.size() > 0, "Should handle whitespace")
	var normal = AssetRegistry.get_assets_for_context({"context_type": "combat"})
	_assert(cycle_suffix.size() == normal.size(), "Normalized contexts should return same count")
	print("[Test] Context type normalization PASSED ")
func _test_context_with_explicit_ids() -> void:
	print("[Test] Context with explicit IDs...")
	var specific_assets = AssetRegistry.get_assets_for_context({
		"asset_ids": ["Generic_Lever", "Generic_Chest", "Generic_Monster"]
	})
	_assert(specific_assets.size() == 3, "Should return exactly 3 assets")
	var ids = []
	for asset in specific_assets:
		ids.append(asset["id"])
	_assert("Generic_Lever" in ids, "Should include Generic_Lever")
	_assert("Generic_Chest" in ids, "Should include Generic_Chest")
	_assert("Generic_Monster" in ids, "Should include Generic_Monster")
	var mixed = AssetRegistry.get_assets_for_context({
		"asset_ids": ["Generic_Lever", "InvalidAsset_XYZ", "Generic_Chest"]
	})
	_assert(mixed.size() == 2, "Should only return valid assets")
	print("[Test] Context with explicit IDs PASSED ")
func _test_context_with_tags() -> void:
	print("[Test] Context with tags...")
	var tagged_assets = AssetRegistry.get_assets_for_context({
		"required_tags": ["Interactable", "Mechanical"]
	})
	_assert(tagged_assets.size() > 0, "Should return assets matching tags")
	for asset in tagged_assets:
		var tags: Array = asset.get("tags", [])
		_assert("Interactable" in tags, "Should have Interactable tag")
		_assert("Mechanical" in tags, "Should have Mechanical tag")
	print("[Test] Context with tags PASSED ")
func _test_default_cycle_fallback() -> void:
	print("[Test] Default cycle fallback...")
	var empty_context = AssetRegistry.get_assets_for_context({})
	_assert(empty_context.size() > 0, "Empty context should return default cycle")
	_assert(empty_context.size() == AssetRegistry.default_cycle.size(), "Should match default cycle size")
	var unknown = AssetRegistry.get_assets_for_context({"context_type": "unknown_type_xyz"})
	_assert(unknown.size() > 0, "Unknown context should return default cycle")
	print("[Test] Default cycle fallback PASSED ")
func _test_prompt_formatting() -> void:
	print("[Test] Prompt formatting...")
	var assets = AssetRegistry.get_assets_for_context({"context_type": "default"})
	var prompt_en = AssetRegistry.format_assets_for_prompt(assets, "en")
	var prompt_zh = AssetRegistry.format_assets_for_prompt(assets, "zh")
	var prompt_de = AssetRegistry.format_assets_for_prompt(assets, "de")
	_assert(prompt_en is String, "English prompt should return String")
	_assert(prompt_en.length() > 0, "English prompt should not be empty")
	_assert(prompt_en.contains("Assets available in this scene:"), "English prompt should contain English header")
	_assert(prompt_en.contains("Generic_Lever"), "English prompt should include asset IDs from the list")
	_assert(prompt_zh.contains(LocalizationManager.get_translation("ASSET_REG_AVAILABLE_ASSETS", "zh")), "Chinese prompt should contain Chinese header")
	_assert(not prompt_zh.contains(LocalizationManager.get_translation("ASSET_REG_AVAILABLE_ASSETS", "en")), "Chinese prompt should not also inject English header")
	_assert(prompt_de.contains(LocalizationManager.get_translation("ASSET_REG_AVAILABLE_ASSETS", "de")), "German prompt should contain German header")
	_assert(not prompt_de.contains(LocalizationManager.get_translation("ASSET_REG_AVAILABLE_ASSETS", "zh")), "German prompt should not inject Chinese header")
	_assert(not prompt_de.contains(LocalizationManager.get_translation("ASSET_REG_AVAILABLE_ASSETS", "en")), "German prompt should not inject English header")
	var empty_prompt = AssetRegistry.format_assets_for_prompt([])
	_assert(empty_prompt.length() > 0, "Empty prompt should return message")
	_assert("No symbolic assets" in empty_prompt, "Should indicate no assets")
	print("[Test] Prompt formatting PASSED ")
func _test_asset_icons() -> void:
	print("[Test] Asset icons...")
	var assets = AssetRegistry.get_assets_for_context({"context_type": "combat"})
	var icon_map = AssetRegistry.get_asset_icons(assets)
	_assert(icon_map is Dictionary, "Should return Dictionary")
	_assert(icon_map.size() > 0, "Should contain icon mappings")
	for asset_id in icon_map.keys():
		_assert(asset_id is String, "Keys should be asset IDs (Strings)")
		var icon_path = icon_map[asset_id]
		_assert(icon_path is String, "Values should be icon paths (Strings)")
		if icon_path.length() > 0:
			_assert(icon_path.begins_with("res://"), "Icon paths should start with res://")
	var lever_assets = AssetRegistry.get_assets_for_context({"asset_ids": ["Generic_Lever"]})
	var lever_icons = AssetRegistry.get_asset_icons(lever_assets)
	_assert(lever_icons.has("Generic_Lever"), "Should map Generic_Lever icon")
	print("[Test] Asset icons PASSED ")
func _test_get_all_tags() -> void:
	print("[Test] Get all tags...")
	var all_tags = AssetRegistry.get_all_tags()
	_assert(all_tags is Array, "Should return Array")
	_assert(all_tags.size() > 0, "Should return multiple tags")
	_assert("Interactable" in all_tags, "Should include Interactable tag")
	_assert("Mechanical" in all_tags, "Should include Mechanical tag")
	_assert("Mystic" in all_tags, "Should include Mystic tag")
	_assert("Structure" in all_tags, "Should include Structure tag")
	_assert("Hazard" in all_tags, "Should include Hazard tag")
	var unique_tags = {}
	for tag in all_tags:
		_assert(not unique_tags.has(tag), "Tags should be unique (no duplicates)")
		unique_tags[tag] = true
	print("[Test] Get all tags PASSED ")
func _test_asset_data_structure() -> void:
	print("[Test] Asset data structure...")
	var asset_ids = AssetRegistry.get_asset_ids()
	for asset_id in asset_ids:
		var asset = AssetRegistry.get_asset(asset_id)
		_assert(asset.has("id"), "Asset %s should have 'id'" % asset_id)
		_assert(asset.has("default_name"), "Asset %s should have 'default_name'" % asset_id)
		_assert(asset.has("tags"), "Asset %s should have 'tags'" % asset_id)
		_assert(asset.has("summary"), "Asset %s should have 'summary'" % asset_id)
		_assert(asset.has("icon"), "Asset %s should have 'icon'" % asset_id)
		_assert(asset["id"] is String, "Asset ID should be String")
		_assert(asset["default_name"] is String, "default_name should be String")
		_assert(asset["tags"] is Array, "tags should be Array")
		_assert(asset["summary"] is String, "summary should be String")
		_assert(asset["icon"] is String, "icon should be String")
		_assert(asset["id"].length() > 0, "Asset ID should not be empty")
		_assert(asset["default_name"].length() > 0, "default_name should not be empty")
		_assert(asset["tags"].size() > 0, "Assets should have at least one tag")
	print("[Test] Asset data structure PASSED ")
func _assert(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
		print("    PASS  %s" % message)
	else:
		tests_failed += 1
		print("    FAIL  %s" % message)
