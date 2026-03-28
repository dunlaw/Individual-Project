extends Node
var tests_passed: int = 0
var tests_failed: int = 0
const AIPromptBuilderScript = preload("res://1.Codebase/src/scripts/core/ai/ai_prompt_builder.gd")
const NarrativePromptBuilderScript = preload("res://1.Codebase/src/scripts/core/ai/narrative_prompt_builder.gd")
var prompt_builder: RefCounted = null
var mock_game_state: Dictionary = { }
var mock_asset_registry: Dictionary = { }
var mock_memory_store: Dictionary = { }
func _ready() -> void:
	print("[AIPromptBuilderTest] Starting AIPromptBuilder unit tests...")
	await get_tree().process_frame
	_setup()
	_test_initialization()
	_test_build_basic_prompt()
	_test_language_handling()
	_test_metadata_lines()
	_test_stat_snapshot()
	_test_german_prompt_stays_localized_for_action_context()
	_test_german_prompt_filters_old_chinese_short_term_memory()
	_test_german_narrative_schemas_keep_canonical_json_format()
	_test_german_choice_followup_schema_keeps_canonical_ids()
	_test_german_skill_loading_stays_single_language()
	_test_constants()
	_teardown()
	print("[AIPromptBuilderTest] All tests completed.")
	queue_free()
func _setup() -> void:
	print("[Test Setup] Creating AIPromptBuilder...")
	mock_game_state = {
		"current_language": "en",
		"reality_score": 75,
		"positive_energy": 50,
		"entropy_level": 10,
		"get_recent_event_notes": func(limit, lang): return [],
		"get_recent_journal_entries": func(limit): return [],
		"set_metadata": func(key, value): pass,
		"butterfly_tracker": null,
	}
	mock_asset_registry = {
		"get_assets_for_context": func(context): return [],
		"format_assets_for_prompt": func(assets): return "",
		"get_asset_icons": func(assets): return [],
	}
	mock_memory_store = {
		"get_long_term_context": func(lang): return [],
		"get_notes_context": func(lang): return [],
		"get_short_term_memory": func(): return [],
	}
	prompt_builder = AIPromptBuilderScript.new()
func _teardown() -> void:
	if prompt_builder:
		prompt_builder = null
	mock_game_state.clear()
	mock_asset_registry.clear()
	mock_memory_store.clear()
func _test_initialization() -> void:
	print("[Test] Prompt builder initialization...")
	_assert(prompt_builder != null, "Prompt builder should be created")
	_assert(prompt_builder.has_method("setup"), "Should have setup method")
	_assert(prompt_builder.has_method("build_prompt"), "Should have build_prompt method")
	_assert(prompt_builder.has_method("set_system_persona"), "Should have set_system_persona method")
	print("[Test] Initialization PASSED")
func _test_build_basic_prompt() -> void:
	print("[Test] Basic prompt building...")
	if not prompt_builder:
		print("[Test] SKIPPED: Prompt builder not available")
		return
	prompt_builder.setup(null, null, null, null)
	prompt_builder.set_system_persona("Test persona")
	var context := {
		"purpose": "test",
		"reality_score": 75,
		"positive_energy": 50,
		"entropy_level": 10,
	}
	var messages: Array = prompt_builder.build_prompt("Test prompt", context)
	_assert(messages is Array, "Should return an Array")
	_assert(messages.size() > 0, "Should have at least one message")
	var has_user_message := false
	for msg in messages:
		if msg is Dictionary and msg.get("role") == "user":
			has_user_message = true
			var content: String = str(msg.get("content", ""))
			_assert(content.contains("Test prompt"), "Should contain the prompt text")
			break
	_assert(has_user_message, "Should have a user message")
	print("[Test] Basic prompt building PASSED")
func _test_language_handling() -> void:
	print("[Test] Language handling...")
	if not prompt_builder:
		print("[Test] SKIPPED: Prompt builder not available")
		return
	var context_en := {
		"purpose": "test_english",
		"reality_score": 50,
	}
	var messages_en: Array = prompt_builder.build_prompt("English test", context_en)
	var user_content_en := _extract_user_content(messages_en)
	_assert(user_content_en.contains("English test"), "Should contain English prompt")
	print("[Test] Language handling PASSED")
func _test_metadata_lines() -> void:
	print("[Test] Metadata lines...")
	if not prompt_builder:
		print("[Test] SKIPPED: Prompt builder not available")
		return
	var context := {
		"purpose": "test_purpose",
		"choice_text": "Test choice",
		"success": true,
		"player_action": "Testing",
		"teammate": "TestTeammate",
	}
	var messages: Array = prompt_builder.build_prompt("Test", context)
	var user_content := _extract_user_content(messages)
	_assert(user_content.contains("Purpose:") or user_content.contains("Purpose"), "Should include purpose")
	print("[Test] Metadata lines PASSED")
func _test_stat_snapshot() -> void:
	print("[Test] Stat snapshot...")
	if not prompt_builder:
		print("[Test] SKIPPED: Prompt builder not available")
		return
	var context := {
		"reality_score": 75,
		"positive_energy": 60,
		"entropy_level": 25,
	}
	var messages: Array = prompt_builder.build_prompt("Stats test", context)
	var user_content := _extract_user_content(messages)
	_assert(user_content.contains("75") or user_content.contains("Reality"), "Should include reality score")
	_assert(user_content.contains("60") or user_content.contains("Positive"), "Should include positive energy")
	_assert(user_content.contains("25") or user_content.contains("Entropy"), "Should include entropy")
	print("[Test] Stat snapshot PASSED")
func _test_german_prompt_stays_localized_for_action_context() -> void:
	print("[Test] German prompt localization for action context...")
	if not prompt_builder:
		print("[Test] SKIPPED: Prompt builder not available")
		return
	var game_state := _create_game_state_mock("de", [], [
		{
			"timestamp": "2026-03-28 19:14",
			"text": "Ich habe den Hebel nur halb gezogen.",
			"ai_summary": "Gloria nennt das kontrollierten Enthusiasmus.",
		},
	])
	var asset_registry := _create_asset_registry_mock()
	var memory_store := _create_memory_store_mock([], [])
	prompt_builder.setup(game_state, asset_registry, memory_store, null)
	prompt_builder.set_system_persona("Test persona")
	var messages: Array = prompt_builder.build_prompt("Pruefe die Konsole und entscheide vorsichtig.", {
		"purpose": "mission_test",
		"player_action": "Hebel halb ziehen",
		"teammate": "gloria",
		"reality_score": 62,
		"positive_energy": 44,
		"entropy_level": 5,
		"context_type": "default",
	})
	var joined := _join_message_content(messages)
	var user_content := _extract_user_content(messages)
	_assert(joined.contains("Verstanden."), "Assistant acknowledgement should follow German mode")
	_assert(user_content.contains("Spieleraktion:"), "User prompt should localize action metadata in German")
	_assert(user_content.contains("Aktueller Teamkollege:"), "User prompt should localize teammate metadata in German")
	_assert(user_content.contains("Statistiken:"), "Stat snapshot should be localized in German")
	_assert(user_content.contains("ASSET_LANG:de"), "Asset context should be requested in German")
	_assert(not user_content.contains("Purpose:"), "German prompt should not fall back to English metadata labels")
	_assert(not user_content.contains("Player action:"), "German prompt should not leak English action labels")
	game_state.free()
	asset_registry.free()
	print("[Test] German prompt localization PASSED")
func _test_german_prompt_filters_old_chinese_short_term_memory() -> void:
	print("[Test] German prompt filters old Chinese short-term memory...")
	if not prompt_builder:
		print("[Test] SKIPPED: Prompt builder not available")
		return
	var game_state := _create_game_state_mock("de")
	var asset_registry := _create_asset_registry_mock()
	var memory_store := _create_memory_store_mock([], [
		{"role": "assistant", "content": "[權衡] 與隊友協調折衷，風險與收益同時上升"},
		{"role": "assistant", "content": "A previous English detail can stay if needed."},
	])
	prompt_builder.setup(game_state, asset_registry, memory_store, null)
	var messages: Array = prompt_builder.build_prompt("Antworte nur auf Deutsch.", {
		"purpose": "language_switch_test",
		"player_action": "Konsole neu starten",
	})
	var joined := _join_message_content(messages)
	_assert(not joined.contains("[權衡]"), "German-mode prompt should drop old Chinese short-term memory")
	_assert(not joined.contains("風險與收益"), "German-mode prompt should not include Chinese memory payload")
	_assert(joined.contains("A previous English detail can stay if needed."), "Non-Chinese short-term memory should remain available")
	game_state.free()
	asset_registry.free()
	print("[Test] German short-term memory filtering PASSED")
func _test_german_narrative_schemas_keep_canonical_json_format() -> void:
	print("[Test] German narrative schemas keep canonical JSON format...")
	var mission_schema: String = NarrativePromptBuilderScript._build_json_schema("de")
	var scene_directives: String = NarrativePromptBuilderScript._build_scene_directives_template("de")
	var intro_schema: String = NarrativePromptBuilderScript._build_intro_json_schema("de")
	_assert(mission_schema.contains('"archetype": "cautious"'), "German mission schema should keep canonical cautious archetype ID")
	_assert(mission_schema.contains('"archetype": "balanced"'), "German mission schema should keep canonical balanced archetype ID")
	_assert(mission_schema.contains('"background": "<background_id>"'), "German mission schema should keep canonical JSON field names")
	_assert(mission_schema.contains("[Vorsichtig]"), "German mission schema should still require German preview labels")
	_assert(scene_directives.contains('"mission_status": "ongoing"'), "German scene directives should keep canonical mission_status values")
	_assert(scene_directives.contains('"complete"'), "German scene directives should instruct complete using canonical status ID")
	_assert(not scene_directives.contains("abgeschlossen"), "German scene directives should not translate mission_status enum values")
	_assert(intro_schema.contains('"archetype": "cautious"'), "German intro schema should keep canonical choice IDs")
	_assert(intro_schema.contains("[Beschweren]"), "German intro schema should require German preview labels")
	print("[Test] German narrative schema PASSED")
func _test_german_choice_followup_schema_keeps_canonical_ids() -> void:
	print("[Test] German choice follow-up schema keeps canonical IDs...")
	var followup_prompt: String = NarrativePromptBuilderScript.build_choice_followup_prompt("Der Altar summt weiter.", "de")
	_assert(followup_prompt.contains('"archetype":"cautious"'), "German choice follow-up should require canonical cautious ID")
	_assert(followup_prompt.contains("cautious, balanced, reckless, positive, complain"), "German choice follow-up should list canonical archetype IDs")
	_assert(not followup_prompt.contains("vorsichtig"), "German choice follow-up should not translate archetype IDs")
	_assert(not followup_prompt.contains("ausgewogen"), "German choice follow-up should not translate archetype IDs")
	print("[Test] German choice follow-up schema PASSED")
func _test_german_skill_loading_stays_single_language() -> void:
	print("[Test] German skill loading stays single-language...")
	_assert(SkillManager != null, "SkillManager autoload should exist for localized skill loading")
	_assert(SkillManager.is_initialized(), "SkillManager should be initialized")
	var scene_skill: String = SkillManager.load_skill("scene-directives", "de")
	var entropy_skill: String = SkillManager.load_skill("entropy-effects", "de")
	var profiles_skill: String = SkillManager.load_skill("character-profiles", "de")
	var scene_skill_zh: String = SkillManager.load_skill("scene-directives", "zh")
	var entropy_skill_zh: String = SkillManager.load_skill("entropy-effects", "zh")
	var profiles_skill_zh: String = SkillManager.load_skill("character-profiles", "zh")
	_assert(scene_skill.contains("Szenenanweisungs-System"), "German scene-directives skill should load the German file")
	_assert(not scene_skill.contains("Scene Directives System"), "German scene-directives skill should not fall back to English content")
	_assert(entropy_skill.contains("Entropieeffekte auf die Erzaehlung"), "German entropy skill should load the German file")
	_assert(not entropy_skill.contains("Chinese Version"), "German entropy skill should not include Chinese-version blocks")
	_assert(not entropy_skill.contains("English Version"), "German entropy skill should not include English-version blocks")
	_assert(profiles_skill.contains("GDA1-Charakterprofile"), "German character profiles should load the German file")
	_assert(not profiles_skill.contains("GDA1 Character Profiles"), "German character profiles should not fall back to English content")
	_assert(scene_skill_zh.contains("場景指令系統"), "Chinese scene-directives skill should load the Chinese file")
	_assert(not scene_skill_zh.contains("Scene Directives System"), "Chinese scene-directives skill should not fall back to English content")
	_assert(entropy_skill_zh.contains("熵值對敘事的影響"), "Chinese entropy skill should load the Chinese file")
	_assert(not entropy_skill_zh.contains("English Version"), "Chinese entropy skill should not include English-version blocks")
	_assert(profiles_skill_zh.contains("GDA1 角色檔案"), "Chinese character profiles should load the Chinese file")
	_assert(not profiles_skill_zh.contains("GDA1 Character Profiles"), "Chinese character profiles should not fall back to English content")
	print("[Test] German skill loading PASSED")
func _test_constants() -> void:
	print("[Test] Constants...")
	if not prompt_builder:
		print("[Test] SKIPPED: Prompt builder not available")
		return
	var builder_script = AIPromptBuilderScript
	_assert(builder_script.MAX_PRAYER_LENGTH == 320, "MAX_PRAYER_LENGTH should be 320")
	_assert(builder_script.MAX_CHOICE_TEXT_PREVIEW == 60, "MAX_CHOICE_TEXT_PREVIEW should be 60")
	_assert(builder_script.MAX_JOURNAL_ENTRIES == 3, "MAX_JOURNAL_ENTRIES should be 3")
	_assert(builder_script.REALITY_SCORE_MAX == 100, "REALITY_SCORE_MAX should be 100")
	_assert(builder_script.POSITIVE_ENERGY_MAX == 100, "POSITIVE_ENERGY_MAX should be 100")
	print("[Test] Constants PASSED")
func _extract_user_content(messages: Array) -> String:
	for msg in messages:
		if msg is Dictionary and msg.get("role") == "user":
			return str(msg.get("content", ""))
	return ""
func _join_message_content(messages: Array) -> String:
	var parts: Array[String] = []
	for msg in messages:
		if msg is Dictionary:
			parts.append(str(msg.get("content", "")))
	return "\n".join(parts)
func _create_game_state_mock(language: String, recent_events: Array = [], journal_entries: Array = []) -> Node:
	var script := GDScript.new()
	script.source_code = """
extends Node
var current_language: String = "en"
var butterfly_tracker = null
var _recent_events: Array = []
var _journal_entries: Array = []
func configure(lang: String, events: Array, entries: Array) -> void:
	current_language = lang
	_recent_events = events
	_journal_entries = entries
func get_recent_event_notes(_limit, _lang):
	return _recent_events
func get_recent_journal_entries(_limit):
	return _journal_entries
func set_metadata(_key, _value):
	pass
"""
	script.reload()
	var node := Node.new()
	node.set_script(script)
	node.configure(language, recent_events, journal_entries)
	return node
func _create_asset_registry_mock() -> Node:
	var script := GDScript.new()
	script.source_code = """
extends Node
func get_assets_for_context(_context):
	return [{"id": "Generic_Lever", "default_name": "Standard Lever", "tags": ["Interactable"], "summary": "Prompt asset"}]
func format_assets_for_prompt(_assets, language := ""):
	return "ASSET_LANG:%s" % language
func get_asset_icons(_assets):
	return {}
"""
	script.reload()
	var node := Node.new()
	node.set_script(script)
	return node
func _create_memory_store_mock(long_term_messages: Array, short_term_messages: Array) -> RefCounted:
	var script := GDScript.new()
	script.source_code = """
extends RefCounted
var _long_term_messages: Array = []
var _short_term_messages: Array = []
func configure(long_term_messages: Array, short_term_messages: Array) -> void:
	_long_term_messages = long_term_messages
	_short_term_messages = short_term_messages
func get_long_term_context(_lang):
	return _long_term_messages
func get_notes_context(_lang):
	return []
func get_short_term_memory():
	return _short_term_messages
"""
	script.reload()
	var store = script.new()
	store.configure(long_term_messages, short_term_messages)
	return store
func _assert(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
		print("    PASS  %s" % message)
	else:
		tests_failed += 1
		print("    FAIL  %s" % message)
