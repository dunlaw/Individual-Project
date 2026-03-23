extends RefCounted
class_name NarrativePromptBuilder
const MIN_CONSEQUENCE_WORDS := 150
const MAX_CONSEQUENCE_WORDS := 250
const TEAMMATE_DESCRIPTION_WORDS := 150
static func _get_skill_manager() -> Node:
	if ServiceLocator and ServiceLocator.has_method("get_skill_manager"):
		var sl_skill_manager = ServiceLocator.get_skill_manager()
		if sl_skill_manager != null:
			return sl_skill_manager
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		var service_locator = tree.root.get_node_or_null("ServiceLocator")
		if service_locator and service_locator.has_method("get_skill_manager"):
			var locator_skill_manager = service_locator.call("get_skill_manager")
			if locator_skill_manager != null:
				return locator_skill_manager
	return null
static func get_localized_archetype_labels(lang: String = "") -> Dictionary:
	return {
		"cautious": _s_tr("ARCHETYPE_LABEL_CAUTIOUS", lang),
		"balanced": _s_tr("ARCHETYPE_LABEL_BALANCED", lang),
		"reckless": _s_tr("ARCHETYPE_LABEL_RECKLESS", lang),
		"positive": _s_tr("ARCHETYPE_LABEL_POSITIVE", lang),
		"complain": _s_tr("ARCHETYPE_LABEL_COMPLAIN", lang),
	}
const TEAMMATE_NAMES := {
	"logic_larry": "Logic Larry",
	"positive_gloria": "Gloria",
	"chaos_charlie": "Chaos Charlie",
	"gloria": "Gloria",
	"donkey": "Donkey",
	"ark": "ARK",
	"one": "One",
}
static func build_mission_prompt(game_state: Variant, selected_assets: Array, asset_registry: Variant) -> String:
	var lang: String = game_state.current_language if game_state else "en"
	var prompt_parts: Array[String] = []
	prompt_parts.append(_s_tr("NARRATIVE_PROMPT_MISSION_GENERATION", lang))
	prompt_parts.append(LocalizationManager.get_translation("STORY_MISSION_GENERATION_INSTRUCTION", lang))
	if game_state:
		prompt_parts.append(_build_stats_info(game_state, lang))
		if game_state.is_in_honeymoon():
			prompt_parts.append(_build_honeymoon_info(lang))
	prompt_parts.append(_build_generation_instructions(lang))
	prompt_parts.append(_build_json_schema(lang))
	return "\n".join(prompt_parts)
static func build_consequence_prompt(choice: Dictionary, success: bool, lang: String, force_complete: bool = false) -> String:
	var prompt_parts: Array[String] = []
	prompt_parts.append(_s_tr("NARRATIVE_CONSEQUENCE_HEADER", lang))
	prompt_parts.append(_s_tr("NARRATIVE_PLAYER_CHOSE", lang) % choice.get("text", ""))
	var outcome_str: String = _s_tr("NARRATIVE_OUTCOME_SUCCESS", lang) if success else _s_tr("NARRATIVE_OUTCOME_FAILURE", lang)
	prompt_parts.append(_s_tr("NARRATIVE_OUTCOME_FORMAT", lang) % outcome_str)
	prompt_parts.append(_build_scene_directives_template(lang))
	if force_complete:
		prompt_parts.append(_build_force_complete_instructions(lang))
	return "\n".join(prompt_parts)
static func build_night_cycle_prompt(last_text: String, lang: String) -> String:
	var skill_mgr := _get_skill_manager()
	if skill_mgr and skill_mgr.is_initialized():
		var skill_content: String = skill_mgr.load_skill("night-cycle")
		if not skill_content.is_empty():
			var context_header: String = _s_tr("NARRATIVE_NIGHT_CYCLE_CONTEXT", lang) % last_text
			return context_header + skill_content
	return _build_night_cycle_prompt_fallback(last_text, lang)
static func _build_night_cycle_prompt_fallback(last_text: String, lang: String) -> String:
	var prompt_parts: Array[String] = []
	prompt_parts.append(_s_tr("NARRATIVE_NIGHT_CYCLE_HEADER", lang))
	prompt_parts.append(_s_tr("NARRATIVE_NIGHT_CYCLE_DESC", lang))
	prompt_parts.append(_s_tr("NARRATIVE_NIGHT_CYCLE_LAST_STORY", lang) % last_text)
	prompt_parts.append("\nOUTPUT MUST BE VALID JSON ONLY.")
	return "\n".join(prompt_parts)
static func build_interference_prompt(teammate_id: String, action: String, lang: String, is_honeymoon: bool) -> String:
	var teammate_name: String = TEAMMATE_NAMES.get(teammate_id, teammate_id)
	var prompt_parts: Array[String] = []
	prompt_parts.append(_s_tr("NARRATIVE_INTERFERENCE_HEADER", lang))
	if is_honeymoon:
		prompt_parts.append(_s_tr("NARRATIVE_HONEYMOON_ACTIVE", lang))
	prompt_parts.append(_s_tr("NARRATIVE_TEAMMATE_LABEL", lang) % teammate_name)
	prompt_parts.append(_s_tr("NARRATIVE_PLAYER_ACTION", lang) % action)
	prompt_parts.append(_build_character_directives_template(teammate_id, lang))
	return "\n".join(prompt_parts)
static func build_gloria_prompt(choice: Dictionary, lang: String) -> String:
	var prompt_parts: Array[String] = []
	prompt_parts.append(_s_tr("NARRATIVE_GLORIA_HEADER", lang))
	prompt_parts.append(_s_tr("NARRATIVE_GLORIA_PLAYER_CHOSE", lang) % choice.get("text", ""))
	prompt_parts.append(_build_character_directives_template("gloria", lang))
	return "\n".join(prompt_parts)
static func build_choice_followup_prompt(story_excerpt: String, lang: String) -> String:
	var excerpt := story_excerpt.strip_edges().substr(0, min(story_excerpt.length(), 1200))
	return _s_tr("NARRATIVE_CHOICE_FOLLOWUP", lang) % excerpt
static func _build_stats_info(game_state: Variant, lang: String) -> String:
	return _s_tr("NARRATIVE_STATS_INFO", lang) % [
		game_state.reality_score,
		game_state.positive_energy,
		game_state.entropy_level,
	]
static func _build_honeymoon_info(lang: String) -> String:
	return _s_tr("NARRATIVE_HONEYMOON_INFO", lang)
static func _build_generation_instructions(lang: String) -> String:
	return _s_tr("NARRATIVE_GENERATION_INSTRUCTIONS", lang)
static func _build_json_schema(lang: String) -> String:
	return _s_tr("NARRATIVE_JSON_SCHEMA", lang)
static func _build_scene_directives_template(lang: String) -> String:
	return _s_tr("NARRATIVE_SCENE_DIRECTIVES", lang)
static func _build_character_directives_template(character_id: String, lang: String) -> String:
	return _s_tr("NARRATIVE_CHARACTER_DIRECTIVES", lang) % character_id
static func _build_force_complete_instructions(lang: String) -> String:
	return _s_tr("NARRATIVE_FORCE_COMPLETE", lang)
static func build_intro_story_prompt(lang: String) -> String:
	var skill_mgr := _get_skill_manager()
	if skill_mgr and skill_mgr.is_initialized():
		var skill_content: String = skill_mgr.load_skill("intro-story")
		if not skill_content.is_empty():
			var schema := _build_intro_json_schema(lang)
			return _s_tr("NARRATIVE_INTRO_HEADER", lang) + skill_content + schema
	return _build_intro_story_prompt_fallback(lang)
static func _build_intro_story_prompt_fallback(lang: String) -> String:
	var prompt_parts: Array[String] = []
	prompt_parts.append(_s_tr("NARRATIVE_INTRO_FALLBACK_HEADER", lang))
	prompt_parts.append(_s_tr("NARRATIVE_INTRO_FALLBACK_DESC", lang))
	prompt_parts.append(_s_tr("NARRATIVE_INTRO_FALLBACK_INSTRUCTION", lang))
	prompt_parts.append(_build_intro_json_schema(lang))
	return "\n".join(prompt_parts)
static func _build_intro_json_schema(lang: String) -> String:
	return _s_tr("NARRATIVE_INTRO_JSON_SCHEMA", lang)
static func _s_tr(key: String, lang: String = "") -> String:
	if LocalizationManager:
		if lang.is_empty():
			return LocalizationManager.get_translation(key)
		return LocalizationManager.get_translation(key, lang)
	return key
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key)
	return key
