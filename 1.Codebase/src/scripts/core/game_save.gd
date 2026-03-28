class_name GameSave
const SETTINGS_PATH := "user://settings.cfg"
static func save_settings(data: Dictionary) -> void:
	var config := ConfigFile.new()
	config.set_value("display", "resolution", data.get("resolution", Vector2i(1024, 600)))
	config.set_value("display", "mode", data.get("mode", 0))
	config.set_value("display", "font_size", data.get("font_size", 2))
	config.set_value("display", "font_en", data.get("font_en", ""))
	config.set_value("display", "font_zh", data.get("font_zh", ""))
	config.set_value("display", "high_contrast", data.get("high_contrast", false))
	config.set_value("game", "language", data.get("language", "en"))
	config.set_value("game", "text_speed", data.get("text_speed", 1.0))
	config.set_value("game", "screen_shake", data.get("screen_shake", true))
	config.set_value("game", "max_rounds_per_mission", data.get("max_rounds_per_mission", 0))
	config.set_value("audio", "master_volume", data.get("master_volume", 100.0))
	config.set_value("audio", "music_volume", data.get("music_volume", 100.0))
	config.set_value("audio", "sfx_volume", data.get("sfx_volume", 100.0))
	config.set_value("audio", "gloria_voice_enabled", data.get("gloria_voice_enabled", false))
	config.set_value("audio", "muted", data.get("muted", false))
	config.set_value("voice", "enabled", data.get("voice_enabled", false))
	config.set_value("voice", "output_enabled", data.get("voice_output_enabled", false))
	config.set_value("voice", "input_enabled", data.get("voice_input_enabled", false))
	config.set_value("voice", "voice_volume", data.get("voice_volume", 80.0))
	config.set_value("voice", "voice_name", data.get("voice_voice_name", "Aoede"))
	config.set_value("voice", "voice_input_mode", data.get("voice_input_mode", 0))
	config.set_value("voice", "proactive_enabled", data.get("voice_proactive_enabled", false))
	config.set_value("controls", "touch_controls_enabled", data.get("touch_controls_enabled", false))
	config.save(SETTINGS_PATH)
static func load_settings(defaults: Dictionary) -> Dictionary:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	if err != OK:
		return {}
	var fallback_resolution: Vector2i = defaults.get("resolution", Vector2i(1024, 600))
	var stored_resolution: Variant = config.get_value("display", "resolution", fallback_resolution)
	return {
		"resolution": _coerce_vector2i(stored_resolution, fallback_resolution),
		"mode": clampi(int(config.get_value("display", "mode", 0)), 0, 2),
		"font_size": int(config.get_value("display", "font_size", 2)),
		"font_en": String(config.get_value("display", "font_en", defaults.get("font_en", ""))),
		"font_zh": String(config.get_value("display", "font_zh", defaults.get("font_zh", ""))),
		"high_contrast": bool(config.get_value("display", "high_contrast", false)),
		"language": String(config.get_value("game", "language", "en")),
		"text_speed": float(config.get_value("game", "text_speed", 1.0)),
		"screen_shake": bool(config.get_value("game", "screen_shake", true)),
		"max_rounds_per_mission": int(config.get_value("game", "max_rounds_per_mission", 0)),
		"master_volume": float(config.get_value("audio", "master_volume", 100.0)),
		"music_volume": float(config.get_value("audio", "music_volume", 100.0)),
		"sfx_volume": float(config.get_value("audio", "sfx_volume", 100.0)),
		"gloria_voice_enabled": bool(config.get_value("audio", "gloria_voice_enabled", defaults.get("gloria_voice_enabled", false))),
		"muted": bool(config.get_value("audio", "muted", false)),
		"voice_enabled": bool(config.get_value("voice", "enabled", defaults.get("voice_enabled", false))),
		"voice_output_enabled": bool(config.get_value("voice", "output_enabled", defaults.get("voice_output_enabled", false))),
		"voice_input_enabled": bool(config.get_value("voice", "input_enabled", defaults.get("voice_input_enabled", false))),
		"voice_volume": float(config.get_value("voice", "voice_volume", defaults.get("voice_volume", 80.0))),
		"voice_voice_name": String(config.get_value("voice", "voice_name", defaults.get("voice_voice_name", "Aoede"))),
		"voice_input_mode": int(config.get_value("voice", "voice_input_mode", defaults.get("voice_input_mode", 0))),
		"voice_proactive_enabled": bool(config.get_value("voice", "proactive_enabled", defaults.get("voice_proactive_enabled", false))),
		"touch_controls_enabled": bool(config.get_value("controls", "touch_controls_enabled", false)),
	}
static func _coerce_vector2i(value: Variant, fallback: Vector2i) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		var vec: Vector2 = value
		return Vector2i(roundi(vec.x), roundi(vec.y))
	if value is Array:
		var arr: Array = value
		if arr.size() >= 2:
			return Vector2i(int(arr[0]), int(arr[1]))
	return fallback
