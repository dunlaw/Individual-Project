extends Node
signal language_changed(new_language: String)
var _translations: Dictionary = { }
var _current_language: String = "en"
var _game_state: Node = null
var _csv_path: String = "res://1.Codebase/localization/gda1_translations.csv"
const TRANSLATION_RESOURCE_PATHS := {
	"en": "res://1.Codebase/localization/gda1_translations.en.translation",
	"zh": "res://1.Codebase/localization/gda1_translations.zh.translation",
	"de": "res://1.Codebase/localization/gda1_translations.de.translation",
}
const FALLBACK_TRANSLATIONS := {
	"en": {
		"STAT_REALITY": "Reality Score",
		"STAT_POSITIVE": "Positive Energy",
		"STAT_ENTROPY": "Entropy Level",
		"PHASE_HONEYMOON": "Honeymoon Phase",
		"PHASE_NORMAL": "Normal Phase",
		"PHASE_CRISIS": "Crisis Phase",
		"TUTORIAL_first_stat_change": "Watch your Reality score. When it drops to 0 the game is over.",
		"TUTORIAL_first_prayer": "The prayer system lets you input positive wishes... then watch them turn into disasters.",
		"TUTORIAL_TITLE": "Tutorial Tip",
		"TUTORIAL_GOT_IT": "Got it!",
		"TUTORIAL_SKIP_ALL": "Skip all tutorials",
		"STORY_MISSION_GENERATION_INSTRUCTION": "Create a new mission scenario for the player.",
		"EVENT_PRAYER_RECORDED": "Prayer recorded: \"%s%s\"",
		"EVENT_PRAYER_LOGGED": "Prayer logged: \"%s\" | Reality %d, Positive %d",
		"UI_VERSION": "Version %s",
		"MENU_NEW_GAME": "NEW GAME",
		"MENU_CONTINUE": "CONTINUE",
		"MENU_SAVE_LOAD": "SAVE / LOAD",
		"MENU_JOURNAL": "JOURNAL",
		"MENU_ACHIEVEMENTS": "ACHIEVEMENTS",
		"MENU_HOW_TO_PLAY": "HOW TO PLAY",
		"MENU_TERMS": "TERMS",
		"MENU_SETTINGS": "SETTINGS",
		"MENU_QUIT": "QUIT",
		"MENU_AUTOSAVE": "Autosave",
		"MENU_TIMESTAMP_FMT": "%04d-%02d-%02d %02d:%02d",
		"MENU_SLOT_FMT": "Slot %d",
		"MENU_LAST_SAVE_FMT": "Last save: Reality %d | Missions %d | %s | %s",
		"MENU_CREATIVE_STATEMENT": "Glorious Deliverance Agency 1",
		"START_FSM_JOIN": "Join the Agency",
		"INTRO_CHAPTERS": "Chapters",
		"INTRO_CHAPTER_1": "Act I",
		"INTRO_CHAPTER_2": "Act II",
		"INTRO_CHAPTER_3": "Act III",
		"INTRO_CHAPTER_4": "Act IV",
		"GAME_EXIT_CONFIRM_TITLE": "Exit Game",
		"GAME_EXIT_CONFIRM_TEXT": "Are you sure you want to exit?",
		"GAME_EXIT_CONFIRM_OK": "Exit",
		"GAME_EXIT_CONFIRM_CANCEL": "Cancel",
		"SETTINGS_TITLE": "Settings",
		"SETTINGS_AI_LOG": "AI Interaction Logs",
		"SETTINGS_AI_LOG_TITLE": "AI Provider Logs",
	},
	"de": {
		"STAT_REALITY": "Realitätswert",
		"STAT_POSITIVE": "Positive Energie",
		"STAT_ENTROPY": "Entropiestufe",
		"PHASE_HONEYMOON": "Flitterwochen-Phase",
		"PHASE_NORMAL": "Normale Phase",
		"PHASE_CRISIS": "Krisenphase",
		"TUTORIAL_first_stat_change": "Beobachte deinen Realitätswert. Wenn er auf 0 fällt, ist das Spiel vorbei.",
		"TUTORIAL_first_prayer": "Das Gebetssystem lässt dich positive Wünsche eingeben... und zuschauen, wie sie in Katastrophen enden.",
		"TUTORIAL_TITLE": "Hinweis",
		"TUTORIAL_GOT_IT": "Verstanden!",
		"TUTORIAL_SKIP_ALL": "Alle Hinweise überspringen",
		"STORY_MISSION_GENERATION_INSTRUCTION": "Erstelle ein neues Missionsszenario für den Spieler.",
		"EVENT_PRAYER_RECORDED": "Gebet aufgezeichnet: \"%s%s\"",
		"EVENT_PRAYER_LOGGED": "Gebet gespeichert: \"%s\" | Realität %d, Positiv %d",
		"UI_VERSION": "Version %s",
		"MENU_NEW_GAME": "NEUES SPIEL",
		"MENU_CONTINUE": "WEITER",
		"MENU_SAVE_LOAD": "SPEICHERN / LADEN",
		"MENU_JOURNAL": "TAGEBUCH",
		"MENU_ACHIEVEMENTS": "ERRUNGENSCHAFTEN",
		"MENU_HOW_TO_PLAY": "ANLEITUNG",
		"MENU_TERMS": "BEDINGUNGEN",
		"MENU_SETTINGS": "EINSTELLUNGEN",
		"MENU_QUIT": "BEENDEN",
		"MENU_AUTOSAVE": "Automatisches Speichern",
		"MENU_TIMESTAMP_FMT": "%04d-%02d-%02d %02d:%02d",
		"MENU_SLOT_FMT": "Slot %d",
		"MENU_LAST_SAVE_FMT": "Letzter Stand: Realität %d | Missionen %d | %s | %s",
		"MENU_CREATIVE_STATEMENT": "Glorious Deliverance Agency 1",
		"START_FSM_JOIN": "FSM 30-Tage-Plan beitreten",
		"INTRO_CHAPTERS": "Kapitel",
		"INTRO_CHAPTER_1": "Akt I",
		"INTRO_CHAPTER_2": "Akt II",
		"INTRO_CHAPTER_3": "Akt III",
		"INTRO_CHAPTER_4": "Akt IV",
		"GAME_EXIT_CONFIRM_TITLE": "Spiel beenden",
		"GAME_EXIT_CONFIRM_TEXT": "Bist du sicher, dass du beenden möchtest?",
		"GAME_EXIT_CONFIRM_OK": "Beenden",
		"GAME_EXIT_CONFIRM_CANCEL": "Abbrechen",
		"SETTINGS_TITLE": "Einstellungen",
		"SETTINGS_AI_LOG": "KI-Interaktionsprotokolle",
		"SETTINGS_AI_LOG_TITLE": "KI-Anbieter-Protokolle",
	},
}
func _ready() -> void:
	var resources_loaded = _load_translations_from_resources()
	_load_translations(resources_loaded)
	for lang in TRANSLATION_RESOURCE_PATHS.keys():
		if not _translations.has(lang):
			_translations[lang] = {}
	if _translations.get("en", {}).is_empty():
		var fallback_en = FALLBACK_TRANSLATIONS.get("en", {})
		if _translations.has("en"):
			_translations["en"].merge(fallback_en)
		else:
			_translations["en"] = fallback_en.duplicate()
		resources_loaded = false
	_load_language_settings()
	var game_state := _get_game_state()
	if game_state:
		_current_language = game_state.current_language
	var key_counts := []
	for lang in _translations.keys():
		key_counts.append("%s: %d" % [lang, _translations[lang].size()])
	ErrorReporter.report_info(
		"LocalizationManager",
		"Initialized localization manager",
		{
			"language": _current_language,
			"resource_loaded": resources_loaded,
		},
	)
	TranslationServer.set_locale(_current_language)
	ErrorReporter.report_info(
		"LocalizationManager",
		"Loaded translation bundles",
		{
			"counts": key_counts,
		},
	)
func _exit_tree() -> void:
	_translations.clear()
func _load_translations(merge_only: bool = false) -> void:
	if not merge_only:
		_translations.clear()
	var file := FileAccess.open(_csv_path, FileAccess.READ)
	if file == null:
		if merge_only:
			return
		ErrorReporter.report_warning(
			"LocalizationManager",
			"Failed to load CSV, using fallback",
			{ "path": _csv_path },
		)
		_translations = FALLBACK_TRANSLATIONS.duplicate(true)
		return
	var headers: PackedStringArray = PackedStringArray()
	var line_number := 0
	while not file.eof_reached():
		var columns: PackedStringArray = file.get_csv_line()
		line_number += 1
		if columns.is_empty():
			continue
		var first_cell := columns[0].strip_edges()
		if first_cell.is_empty() or first_cell.begins_with("#"):
			continue
		if headers.is_empty():
			headers = columns
			for i in range(1, headers.size()):
				var lang := headers[i].strip_edges()
				headers[i] = lang
				if lang.is_empty():
					continue
				if not _translations.has(lang):
					_translations[lang] = { }
			continue
		var key := first_cell
		for i in range(1, headers.size()):
			var lang_header := headers[i]
			if lang_header.is_empty():
				continue
			var value := ""
			if i < columns.size():
				value = columns[i].replace("\\n", "\n")
			_translations[lang_header][key] = value
	file.close()
	if _translations.is_empty():
		if merge_only:
			return
		ErrorReporter.report_warning(
			"LocalizationManager",
			"CSV did not yield translations; using fallback",
			{ "path": _csv_path },
		)
		_translations = FALLBACK_TRANSLATIONS.duplicate(true)
		return
	ErrorReporter.report_info(
		"LocalizationManager",
		"Loaded translations from CSV" + (" (merged)" if merge_only else ""),
		{ "languages": _translations.keys(), "keys": _translations.get("en", { }).size() },
	)
func get_translation(key: String, language: String = "") -> String:
	var lang = language if not language.is_empty() else _current_language
	if _translations.has(lang) and _translations[lang].has(key):
		return _translations[lang][key]
	var godot_tr := TranslationServer.translate(key)
	if str(godot_tr) != key:
		return godot_tr
	if lang != "en" and _translations.has("en") and _translations["en"].has(key):
		return _translations["en"][key]
	if FALLBACK_TRANSLATIONS.has(lang) and FALLBACK_TRANSLATIONS[lang].has(key):
		return FALLBACK_TRANSLATIONS[lang][key]
	if FALLBACK_TRANSLATIONS.has("en") and FALLBACK_TRANSLATIONS["en"].has(key):
		return FALLBACK_TRANSLATIONS["en"][key]
	ErrorReporter.report_warning("LocalizationManager", "Translation key not found", { "key": key, "lang": lang })
	return key
func tr_stat(stat_id: String, language: String = "") -> String:
	var key = "STAT_" + stat_id.to_upper()
	return get_translation(key, language)
func tr_skill(skill_id: String, language: String = "") -> String:
	var key = "SKILL_" + skill_id.to_upper()
	return get_translation(key, language)
func tr_teammate(teammate_id: String, language: String = "") -> String:
	var key = "TEAMMATE_" + teammate_id.to_upper()
	return get_translation(key, language)
func tr_phase(phase_id: String, language: String = "") -> String:
	var key = "PHASE_" + phase_id.to_upper()
	return get_translation(key, language)
func tr_entropy_level(level_id: String, language: String = "") -> String:
	var key = "ENTROPY_LEVEL_" + level_id.to_upper()
	return get_translation(key, language)
func tr_reason(reason: String, language: String = "") -> String:
	var reason_map = {
		"Positive Energy Curse": "REASON_POSITIVE_CURSE",
		"Prayer aftershock": "REASON_PRAYER_AFTERSHOCK",
		"Gloria's negative-energy accusation": "REASON_GLORIA_ACCUSATION",
		"Teacher Chan's apocalypse concert": "REASON_TEACHER_CONCERT",
		"Forced to echo Gloria": "REASON_FORCED_ECHO",
		"Mission \"success\" backlash": "REASON_MISSION_SUCCESS",
		"Mission aftershock": "REASON_MISSION_AFTERSHOCK",
	}
	var trimmed = reason.strip_edges()
	if trimmed.is_empty():
		return ""
	if reason_map.has(trimmed):
		return get_translation(reason_map[trimmed], language)
	return trimmed
func set_language(language: String) -> void:
	if not _translations.has(language):
		ErrorReporter.report_warning("LocalizationManager", "Language not available", { "language": language })
		return
	var old_language = _current_language
	_current_language = language
	var game_state := _get_game_state()
	if game_state:
		game_state.current_language = language
	_save_language_settings()
	TranslationServer.set_locale(language)
	language_changed.emit(language)
	ErrorReporter.report_info("LocalizationManager", "Language changed", { "from": old_language, "to": language })
func _load_language_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		var saved_lang = config.get_value("game", "language", "")
		if saved_lang.is_empty():
			saved_lang = config.get_value("display", "language", "en")
		if _translations.has(saved_lang):
			_current_language = saved_lang
func _save_language_settings() -> void:
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("game", "language", _current_language)
	config.save("user://settings.cfg")
func _get_game_state() -> Node:
	if is_instance_valid(_game_state):
		return _game_state
	if ServiceLocator:
		_game_state = ServiceLocator.get_game_state()
	return _game_state
func get_language() -> String:
	return _current_language
func get_available_languages() -> Array:
	return _translations.keys()
func has_language(language: String) -> bool:
	return _translations.has(language)
func get_all_keys() -> Array:
	if _translations.has("en"):
		return _translations["en"].keys()
	return []
func reload_translations() -> void:
	_translations.clear()
	_load_translations()
	ErrorReporter.report_info("LocalizationManager", "Translations reloaded")
func _load_translations_from_resources() -> bool:
	var loaded := false
	for lang in TRANSLATION_RESOURCE_PATHS.keys():
		var path: String = TRANSLATION_RESOURCE_PATHS[lang]
		if not ResourceLoader.exists(path):
			continue
		var translation: Translation = ResourceLoader.load(path)
		if translation == null:
			continue
		TranslationServer.add_translation(translation)
		loaded = true
	if loaded:
		ErrorReporter.report_info(
			"LocalizationManager",
			"Loaded translations from .translation resources",
			{ "languages": TRANSLATION_RESOURCE_PATHS.keys() },
		)
	return loaded
func has_translation(key: String, language: String = "") -> bool:
	var lang = language if not language.is_empty() else _current_language
	if _translations.has(lang) and _translations[lang].has(key):
		return true
	if lang != "en" and _translations.has("en") and _translations["en"].has(key):
		return true
	if FALLBACK_TRANSLATIONS.has(lang) and FALLBACK_TRANSLATIONS[lang].has(key):
		return true
	if FALLBACK_TRANSLATIONS.has("en") and FALLBACK_TRANSLATIONS["en"].has(key):
		return true
	return false
