extends RefCounted
class_name NarrativePromptBuilder
const MIN_CONSEQUENCE_WORDS := 150
const MAX_CONSEQUENCE_WORDS := 250
const TEAMMATE_DESCRIPTION_WORDS := 150
const MAX_FOLLOWUP_EXCERPT_LENGTH := 1200
static func _get_skill_manager() -> Node:
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
	var fallback_prompt := _build_mission_prompt_fallback(game_state, lang)
	var context_parts: Array[String] = ["Mission generation request for GDA1."]
	if game_state:
		context_parts.append(_build_stats_snapshot(game_state))
		if game_state.is_in_honeymoon():
			context_parts.append("Honeymoon phase is active.")
	if not selected_assets.is_empty():
		context_parts.append("Selected assets count: %d" % selected_assets.size())
	if asset_registry != null:
		context_parts.append("Asset registry available: true")
	return _build_prompt_with_skill("mission-generation", lang, context_parts, fallback_prompt)
static func _build_mission_prompt_fallback(game_state: Variant, lang: String) -> String:
	var prompt_parts: Array[String] = []
	prompt_parts.append("Generate a new mission scene for Glorious Deliverance Agency 1.")
	prompt_parts.append(_build_language_output_instruction(lang))
	if game_state:
		prompt_parts.append(_build_stats_snapshot(game_state))
		if game_state.is_in_honeymoon():
			prompt_parts.append("Honeymoon phase is active.")
	prompt_parts.append("Return VALID JSON only with keys: mission_title, story_text, choices.")
	return "\n".join(prompt_parts)
static func build_consequence_prompt(choice: Dictionary, success: bool, lang: String, force_complete: bool = false) -> String:
	var fallback_prompt := _build_consequence_prompt_fallback(choice, success, lang, force_complete)
	var context_parts: Array[String] = [
		"Consequence generation request.",
		"Player choice: %s" % str(choice.get("text", "")),
		"Outcome: %s" % ("success" if success else "failure"),
	]
	if force_complete:
		context_parts.append("Force mission_status to complete in scene directives.")
	return _build_prompt_with_skill("consequence-generation", lang, context_parts, fallback_prompt)
static func _build_consequence_prompt_fallback(choice: Dictionary, success: bool, lang: String, force_complete: bool = false) -> String:
	var prompt_parts: Array[String] = []
	prompt_parts.append("Generate a consequence scene for the selected player choice.")
	prompt_parts.append(_build_language_output_instruction(lang))
	prompt_parts.append("Player chose: %s" % choice.get("text", ""))
	prompt_parts.append("Outcome: %s" % ("success" if success else "failure"))
	prompt_parts.append("Include [SCENE_DIRECTIVES] when needed, then narrative text, then 3-5 choice previews.")
	if force_complete:
		prompt_parts.append("Force mission_status to complete in scene directives.")
	return "\n".join(prompt_parts)
static func build_night_cycle_prompt(last_text: String, lang: String) -> String:
	var skill_mgr := _get_skill_manager()
	if skill_mgr and skill_mgr.is_initialized():
		var skill_content: String = skill_mgr.load_skill("night-cycle", lang)
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
	var fallback_prompt := _build_interference_prompt_fallback(teammate_id, action, lang, is_honeymoon)
	var context_parts: Array[String] = ["Teammate interference request."]
	if is_honeymoon:
		context_parts.append("Honeymoon phase is active.")
	context_parts.append("Teammate: %s" % teammate_name)
	context_parts.append("Player action: %s" % action)
	var replacements := {
		"name": teammate_name,
		"action": action,
		"teammate_id": teammate_id,
	}
	return _build_prompt_with_skill("teammate-interference", lang, context_parts, fallback_prompt, replacements)
static func _build_interference_prompt_fallback(teammate_id: String, action: String, lang: String, is_honeymoon: bool) -> String:
	var teammate_name: String = TEAMMATE_NAMES.get(teammate_id, teammate_id)
	var prompt_parts: Array[String] = []
	prompt_parts.append("Generate a teammate interference scene.")
	prompt_parts.append(_build_language_output_instruction(lang))
	if is_honeymoon:
		prompt_parts.append("Honeymoon phase is active.")
	prompt_parts.append("Teammate: %s" % teammate_name)
	prompt_parts.append("Player action: %s" % action)
	prompt_parts.append("Keep it around 120-180 words and optionally include [SCENE_DIRECTIVES].")
	return "\n".join(prompt_parts)
static func build_gloria_prompt(choice: Dictionary, lang: String) -> String:
	var fallback_prompt := _build_gloria_prompt_fallback(choice, lang)
	var choice_text := str(choice.get("text", ""))
	var context_parts: Array[String] = [
		"Gloria intervention request.",
		"Player choice: %s" % choice_text,
	]
	return _build_prompt_with_skill("gloria-intervention", lang, context_parts, fallback_prompt, {"choice_text": choice_text})
static func _build_gloria_prompt_fallback(choice: Dictionary, lang: String) -> String:
	var prompt_parts: Array[String] = []
	prompt_parts.append("Generate Gloria's toxic positivity intervention speech.")
	prompt_parts.append(_build_language_output_instruction(lang))
	prompt_parts.append("Player just chose: %s" % choice.get("text", ""))
	prompt_parts.append("Output ONLY Gloria speech (80-120 words), no choice previews.")
	return "\n".join(prompt_parts)
static func build_choice_followup_prompt(story_excerpt: String, lang: String) -> String:
	var excerpt := story_excerpt.strip_edges().substr(0, min(story_excerpt.length(), MAX_FOLLOWUP_EXCERPT_LENGTH))
	var fallback_prompt := "Generate 3-5 choice summaries as JSON only from this excerpt:\n%s" % excerpt
	return _build_prompt_with_skill("choice-followup", lang, [], fallback_prompt, {"story_excerpt": excerpt})
static func _build_stats_snapshot(game_state: Variant) -> String:
	return "Current stats: reality=%d, positive_energy=%d, entropy=%d" % [
		game_state.reality_score,
		game_state.positive_energy,
		game_state.entropy_level,
	]
static func _build_json_schema(lang: String) -> String:
	var preview_labels := {
		"cautious": "[Cautious]",
		"balanced": "[Balanced]",
		"reckless": "[Reckless]",
		"positive": "[Positive]",
		"complain": "[Complain]",
	}
	if lang == "de":
		preview_labels = {
			"cautious": "[Vorsichtig]",
			"balanced": "[Ausgewogen]",
			"reckless": "[Ruecksichtslos]",
			"positive": "[Positiv]",
			"complain": "[Beschweren]",
		}
	elif lang == "zh":
		preview_labels = {
			"cautious": "[謹慎]",
			"balanced": "[平衡]",
			"reckless": "[魯莽]",
			"positive": "[正能量]",
			"complain": "[抱怨]",
		}
	return """{
  "mission_title": "<title>",
  "scene": {"background": "<background_id>"},
  "story_text": "<narrative>",
  "choices": [
    {"archetype": "cautious", "summary": "..."},
    {"archetype": "balanced", "summary": "..."},
    {"archetype": "reckless", "summary": "..."},
    {"archetype": "positive", "summary": "..."},
    {"archetype": "complain", "summary": "..."}
  ]
}

Choice Preview labels:
%s %s %s %s %s""" % [
		preview_labels["cautious"],
		preview_labels["balanced"],
		preview_labels["reckless"],
		preview_labels["positive"],
		preview_labels["complain"],
	]
static func _build_scene_directives_template(_lang: String) -> String:
	return """[SCENE_DIRECTIVES]
{
  "mission_status": "ongoing",
  "characters": {
    "protagonist": {"expression": "neutral"}
  }
}
[/SCENE_DIRECTIVES]

Use only canonical mission_status values: "ongoing" or "complete".""" 
static func _build_language_output_instruction(lang: String) -> String:
	match lang:
		"zh":
			return "Output all player-facing text in Traditional Chinese."
		"de":
			return "Output all player-facing text in German."
		_:
			return "Output all player-facing text in English."
static func build_intro_story_prompt(lang: String) -> String:
	var skill_mgr := _get_skill_manager()
	if skill_mgr and skill_mgr.is_initialized():
		var skill_content: String = skill_mgr.load_skill("intro-story", lang)
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
static func _build_prompt_with_skill(skill_name: String, lang: String, context_parts: Array[String], fallback_prompt: String, replacements: Dictionary = {}) -> String:
	var skill_mgr := _get_skill_manager()
	if skill_mgr and skill_mgr.is_initialized():
		var skill_content: String = skill_mgr.load_skill(skill_name, lang)
		if not skill_content.is_empty():
			if not replacements.is_empty():
				skill_content = _replace_skill_tokens(skill_content, replacements)
			var parts: Array[String] = []
			for part in context_parts:
				var text := str(part).strip_edges()
				if not text.is_empty():
					parts.append(text)
			parts.append(skill_content.strip_edges())
			return "\n\n".join(parts)
	return fallback_prompt
static func _replace_skill_tokens(content: String, replacements: Dictionary) -> String:
	var result := content
	for key in replacements.keys():
		var token := "{%s}" % str(key)
		result = result.replace(token, str(replacements[key]))
	return result
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
