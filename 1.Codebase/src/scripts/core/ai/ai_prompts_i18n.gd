extends RefCounted
static func _tr(key: String, lang: String = "") -> String:
	var tree := Engine.get_main_loop() as SceneTree
	var localization_manager: Node = null
	if tree and tree.root:
		localization_manager = tree.root.get_node_or_null("LocalizationManager")
	if localization_manager and localization_manager.has_method("get_translation"):
		if lang.is_empty():
			return localization_manager.call("get_translation", key)
		return localization_manager.call("get_translation", key, lang)
	return key
const LANGUAGE_INSTRUCTIONS := {
	"en": "IMPORTANT: Respond in English. All narrative, dialogue, and descriptions must be in English.",
	"zh": "AI_I18N_LANG_INSTRUCTION",
	"de": "WICHTIG: Antworte auf Deutsch. Alle Erzählungen, Dialoge und Beschreibungen müssen auf Deutsch sein.",
}
const SECTION_HEADERS := {
	"session_data": {
		"en": "=== SESSION DATA ===",
		"zh": "AI_I18N_SECTION_SESSION_DATA",
		"de": "=== SITZUNGSDATEN ===",
	},
	"recent_events": {
		"en": "=== RECENT EVENTS ===",
		"zh": "AI_I18N_SECTION_RECENT_EVENTS",
		"de": "=== LETZTE EREIGNISSE ===",
	},
	"butterfly_effect": {
		"en": "=== BUTTERFLY EFFECT: PAST CHOICES ===",
		"zh": "AI_I18N_SECTION_BUTTERFLY_EFFECT",
		"de": "=== SCHMETTERLINGSEFFEKT: VERGANGENE ENTSCHEIDUNGEN ===",
	},
	"player_reflections": {
		"en": "=== PLAYER REFLECTIONS ===",
		"zh": "AI_I18N_SECTION_PLAYER_REFLECTIONS",
		"de": "=== SPIELERREFLEXIONEN ===",
	},
	"available_assets": {
		"en": "=== AVAILABLE ASSETS ===",
		"zh": "AI_I18N_SECTION_AVAILABLE_ASSETS",
		"de": "=== VERFÜGBARE RESSOURCEN ===",
	},
	"prompt": {
		"en": "=== PROMPT ===",
		"zh": "AI_I18N_SECTION_PROMPT",
		"de": "=== EINGABE ===",
	},
	"mission_generation": {
		"en": "=== Mission Generation ===",
		"zh": "AI_I18N_SECTION_MISSION_GENERATION",
		"de": "=== Missionsgenerierung ===",
	},
	"consequence_generation": {
		"en": "=== Consequence Generation ===",
		"zh": "AI_I18N_SECTION_CONSEQUENCE_GENERATION",
		"de": "=== Folgengenerierung ===",
	},
	"teammate_interference": {
		"en": "=== Teammate Interference ===",
		"zh": "AI_I18N_SECTION_TEAMMATE_INTERFERENCE",
		"de": "=== Teammitglied-Einmischung ===",
	},
}
const BUTTERFLY_EFFECT_INSTRUCTIONS := {
	"reference_past": {
		"en": "Consider referencing one of these past choices in your response if narratively appropriate.",
		"zh": "AI_I18N_BUTTERFLY_REFERENCE_PAST",
		"de": "Erwäge, eine dieser vergangenen Entscheidungen in deiner Antwort zu referenzieren, wenn es narrativ passend ist.",
	},
	"trigger_callback": {
		"en": "Use butterfly_tracker.trigger_consequence_for_choice() when a past choice should echo forward.",
		"zh": "AI_I18N_BUTTERFLY_TRIGGER_CALLBACK",
		"de": "Verwende butterfly_tracker.trigger_consequence_for_choice(), wenn eine vergangene Entscheidung nachhallen soll.",
	},
	"suggested_callback": {
		"en": "\n SUGGESTED CALLBACK: Consider having \"%s\" (from %d scenes ago, ID: %s) affect the current situation.",
		"zh": "AI_I18N_BUTTERFLY_SUGGESTED_CALLBACK",
		"de": "\n VORGESCHLAGENER RÜCKRUF: Erwäge, \"%s\" (von vor %d Szenen, ID: %s) die aktuelle Situation beeinflussen zu lassen.",
	},
}
const ASSET_CONTEXT_INSTRUCTIONS := {
	"freshest_context": {
		"en": "Newest asset IDs appear last; treat them as the freshest context.",
		"zh": "AI_I18N_ASSET_FRESHEST_CONTEXT",
		"de": "Neueste Asset-IDs erscheinen zuletzt; behandle sie als den aktuellsten Kontext.",
	},
}
const MISSION_PROMPT_INSTRUCTIONS := {
	"create_scenario": {
		"en": "Create a new mission scenario for the player.",
		"zh": "AI_I18N_MISSION_CREATE_SCENARIO",
		"de": "Erstelle ein neues Missionsszenario für den Spieler.",
	},
	"generate_list": {
		"en": "Please generate:",
		"zh": "AI_I18N_MISSION_GENERATE_LIST",
		"de": "Bitte generiere:",
	},
	"scene_description": {
		"en": "1. Scene description (200-300 words)",
		"zh": "AI_I18N_MISSION_SCENE_DESCRIPTION",
		"de": "1. Szenenbeschreibung (200-300 Wörter)",
	},
	"mission_objective": {
		"en": "2. Mission objective",
		"zh": "AI_I18N_MISSION_MISSION_OBJECTIVE",
		"de": "2. Missionsziel",
	},
	"challenges": {
		"en": "3. Potential dilemmas or challenges",
		"zh": "AI_I18N_MISSION_CHALLENGES",
		"de": "3. Mögliche Dilemmata oder Herausforderungen",
	},
	"tone": {
		"en": "Maintain dark humor and satirical tone.",
		"zh": "AI_I18N_MISSION_TONE",
		"de": "Behalte den schwarzen Humor und satirischen Ton bei.",
	},
}
const CONSEQUENCE_PROMPT_INSTRUCTIONS := {
	"player_chose": {
		"en": "Player chose: %s",
		"zh": "AI_I18N_CONSEQUENCE_PLAYER_CHOSE",
		"de": "Spieler wählte: %s",
	},
	"outcome_success": {
		"en": "Outcome: Success",
		"zh": "AI_I18N_CONSEQUENCE_OUTCOME_SUCCESS",
		"de": "Ergebnis: Erfolg",
	},
	"outcome_failure": {
		"en": "Outcome: Failure",
		"zh": "AI_I18N_CONSEQUENCE_OUTCOME_FAILURE",
		"de": "Ergebnis: Misserfolg",
	},
	"describe_consequences": {
		"en": "Describe the immediate consequences (%d-%d words).",
		"zh": "AI_I18N_CONSEQUENCE_DESCRIBE",
		"de": "Beschreibe die unmittelbaren Folgen (%d-%d Wörter).",
	},
	"include_header": {
		"en": "Include:",
		"zh": "AI_I18N_CONSEQUENCE_INCLUDE_HEADER",
		"de": "Einschließen:",
	},
	"immediate_events": {
		"en": "1. What happens immediately",
		"zh": "AI_I18N_CONSEQUENCE_IMMEDIATE_EVENTS",
		"de": "1. Was sofort geschieht",
	},
	"npc_reactions": {
		"en": "2. NPC/environment reactions",
		"zh": "AI_I18N_CONSEQUENCE_NPC_REACTIONS",
		"de": "2. NSC/Umgebungsreaktionen",
	},
	"long_term_hints": {
		"en": "3. Hints of long-term effects",
		"zh": "AI_I18N_CONSEQUENCE_LONG_TERM_HINTS",
		"de": "3. Hinweise auf langfristige Auswirkungen",
	},
}
const TEAMMATE_INTERFERENCE_INSTRUCTIONS := {
	"teammate_interferes": {
		"en": "Teammate %s decides to interfere with player's action.",
		"zh": "AI_I18N_TEAMMATE_INTERFERES",
		"de": "Teammitglied %s beschließt, in die Aktion des Spielers einzugreifen.",
	},
	"player_action": {
		"en": "Player is: %s",
		"zh": "AI_I18N_TEAMMATE_PLAYER_ACTION",
		"de": "Spieler macht: %s",
	},
	"describe_help": {
		"en": "Describe how the teammate 'helps' in their own dysfunctional way (%d words).",
		"zh": "AI_I18N_TEAMMATE_DESCRIBE_HELP",
		"de": "Beschreibe, wie das Teammitglied auf seine eigene dysfunktionale Art 'hilft' (%d Wörter).",
	},
	"stay_true": {
		"en": "Stay true to their personality and create unexpected complications.",
		"zh": "AI_I18N_TEAMMATE_STAY_TRUE",
		"de": "Bleibe ihrer Persönlichkeit treu und schaffe unerwartete Komplikationen.",
	},
}
const SCENE_DIRECTIVE_INSTRUCTIONS := {
	"important_json": {
		"en": "\n\n**IMPORTANT: Your response will use structured JSON format!**",
		"zh": "AI_I18N_SCENE_IMPORTANT_JSON",
		"de": "\n\n**WICHTIG: Deine Antwort wird das strukturierte JSON-Format verwenden!**",
	},
	"format_description": {
		"en": "Your response will be automatically formatted as JSON with:",
		"zh": "AI_I18N_SCENE_FORMAT_DESCRIPTION",
		"de": "Deine Antwort wird automatisch als JSON formatiert mit:",
	},
	"scene_fields": {
		"en": "- scene: {background, atmosphere, lighting}",
		"zh": "AI_I18N_SCENE_SCENE_FIELDS",
		"de": "- scene: {background, atmosphere, lighting}",
	},
	"characters_required": {
		"en": "- characters: Expressions for all 5 main characters (ALL REQUIRED)",
		"zh": "AI_I18N_SCENE_CHARACTERS_REQUIRED",
		"de": "- characters: Ausdrücke für alle 5 Hauptcharaktere (ALLE ERFORDERLICH)",
	},
	"character_list": {
		"en": "  MUST include: protagonist (main character), gloria (Gloria), donkey (Donkey), ark (Ark), one (One)",
		"zh": "AI_I18N_SCENE_CHARACTER_LIST",
		"de": "  MUSS enthalten: protagonist (Hauptcharakter), gloria (Gloria), donkey (Donkey), ark (Ark), one (One)",
	},
	"character_format": {
		"en": "  Each character: {expression: emotion}",
		"zh": "AI_I18N_SCENE_CHARACTER_FORMAT",
		"de": "  Jeder Charakter: {expression: emotion}",
	},
	"story_text": {
		"en": "- story_text: Your story content",
		"zh": "AI_I18N_SCENE_STORY_TEXT",
		"de": "- story_text: Dein Geschichtsinhalt",
	},
	"all_visible": {
		"en": "\n**IMPORTANT: All 5 characters are always visible. You MUST set an expression for each one.**",
		"zh": "AI_I18N_SCENE_ALL_VISIBLE",
		"de": "\n**WICHTIG: Alle 5 Charaktere sind immer sichtbar. Du MUSST für jeden einen Ausdruck festlegen.**",
	},
	"choose_expressions": {
		"en": "Choose appropriate expressions for each character based on the scene and story. Even if a character doesn't speak, give them a contextually appropriate expression.",
		"zh": "AI_I18N_SCENE_CHOOSE_EXPRESSIONS",
		"de": "Wähle passende Ausdrücke für jeden Charakter basierend auf der Szene und Geschichte. Auch wenn ein Charakter nicht spricht, gib ihm einen kontextuell angemessenen Ausdruck.",
	},
	"available_backgrounds": {
		"en": "\nAvailable backgrounds: ruins, cave, dungeon, forest, temple, laboratory, library, throne_room, battlefield, crystal_cavern, bridge, garden, portal_area, safe_zone, water, fire_area",
		"zh": "AI_I18N_SCENE_AVAILABLE_BACKGROUNDS",
		"de": "\nVerfügbare Hintergründe: ruins, cave, dungeon, forest, temple, laboratory, library, throne_room, battlefield, crystal_cavern, bridge, garden, portal_area, safe_zone, water, fire_area",
	},
	"available_expressions": {
		"en": "Available expressions: neutral, happy, sad, angry, confused, shocked, thinking, embarrassed",
		"zh": "AI_I18N_SCENE_AVAILABLE_EXPRESSIONS",
		"de": "Verfügbare Ausdrücke: neutral, happy, sad, angry, confused, shocked, thinking, embarrassed",
	},
}
const METADATA_LABELS := {
	"purpose": {
		"en": "Purpose: %s",
		"zh": "AI_I18N_META_PURPOSE",
		"de": "Zweck: %s",
	},
	"player_choice": {
		"en": "Player choice: %s",
		"zh": "AI_I18N_META_PLAYER_CHOICE",
		"de": "Spielerwahl: %s",
	},
	"success_check": {
		"en": "Success check: %s",
		"zh": "AI_I18N_META_SUCCESS_CHECK",
		"de": "Erfolgsprüfung: %s",
	},
	"player_prayer": {
		"en": "Player prayer: %s",
		"zh": "AI_I18N_META_PLAYER_PRAYER",
		"de": "Spielergebet: %s",
	},
	"player_action": {
		"en": "Player action: %s",
		"zh": "AI_I18N_META_PLAYER_ACTION",
		"de": "Spieleraktion: %s",
	},
	"current_teammate": {
		"en": "Current teammate: %s",
		"zh": "AI_I18N_META_CURRENT_TEAMMATE",
		"de": "Aktuelles Teammitglied: %s",
	},
}
const STATS_FORMAT := {
	"reality": {
		"en": "Reality %d/%d",
		"zh": "AI_I18N_STATS_REALITY",
		"de": "Realität %d/%d",
	},
	"positive": {
		"en": "Positive %d/%d",
		"zh": "AI_I18N_STATS_POSITIVE",
		"de": "Positiv %d/%d",
	},
	"entropy": {
		"en": "Entropy %d",
		"zh": "AI_I18N_STATS_ENTROPY",
		"de": "Entropie %d",
	},
	"stats_label": {
		"en": "Stats: %s",
		"zh": "AI_I18N_STATS_LABEL",
		"de": "Statistiken: %s",
	},
}
static func get_text(category: Dictionary, key: String, language: String = "en") -> String:
	if category.has(key) and category[key] is Dictionary:
		var text_dict: Dictionary = category[key]
		if language == "en" or language == "de":
			var direct: String = text_dict.get(language, "")
			if direct.is_empty():
				return text_dict.get("en", "")
			return direct
		var tr_key: String = text_dict.get(language, "")
		if tr_key.is_empty():
			return text_dict.get("en", "")
		return _tr(tr_key, language)
	return ""
static func get_language_instruction(language: String = "en") -> String:
	if language == "en" or language == "de":
		return LANGUAGE_INSTRUCTIONS.get(language, LANGUAGE_INSTRUCTIONS["en"])
	var tr_key: String = LANGUAGE_INSTRUCTIONS.get(language, "")
	if tr_key.is_empty():
		return LANGUAGE_INSTRUCTIONS["en"]
	return _tr(tr_key, language)
static func get_section_header(section: String, language: String = "en") -> String:
	return get_text(SECTION_HEADERS, section, language)
static func get_butterfly_effect_instruction(instruction: String, language: String = "en") -> String:
	return get_text(BUTTERFLY_EFFECT_INSTRUCTIONS, instruction, language)
