extends RefCounted
class_name SettingsMenuSaveLoad
static func save(data: Dictionary, game_state: Node) -> void:
	GameSave.save_settings(data)
	if game_state:
		game_state.settings.text_speed = float(data.get("text_speed", 1.0))
		game_state.settings.screen_shake_enabled = bool(data.get("screen_shake", true))
		game_state.settings.high_contrast_mode = bool(data.get("high_contrast", false))
		game_state.settings["max_rounds_per_mission"] = int(data.get("max_rounds_per_mission", 0))
		game_state.settings["trolley_ai_story_enabled"] = bool(data.get("trolley_ai_story_enabled", false))
static func load(
	defaults: Dictionary,
	game_state: Node,
	apply_audio_fn: Callable,
) -> Dictionary:
	var data := GameSave.load_settings(defaults)
	if not data.is_empty():
		apply_audio_fn.call()
		if game_state:
			game_state.settings.text_speed = float(data.get("text_speed", 1.0))
			game_state.settings.screen_shake_enabled = bool(data.get("screen_shake", true))
			game_state.settings.high_contrast_mode = bool(data.get("high_contrast", false))
			game_state.settings["max_rounds_per_mission"] = int(data.get("max_rounds_per_mission", 0))
			game_state.settings["trolley_ai_story_enabled"] = bool(data.get("trolley_ai_story_enabled", false))
	return data
static func get_default_font(language: String) -> String:
	if language == "zh":
		return FontManager.DEFAULT_ZH_FONT if FontManager else "Noto Sans SC"
	if language == "de":
		return FontManager.DEFAULT_DE_FONT if FontManager else "Berlin Type"
	return FontManager.DEFAULT_EN_FONT if FontManager else "Trajan Pro"
