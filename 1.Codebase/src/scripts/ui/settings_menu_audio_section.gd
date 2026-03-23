extends RefCounted
class_name SettingsMenuAudioSection

## Applies volume settings to AudioManager or falls back to Godot's AudioServer directly.
## Expected keys: master_volume, music_volume, sfx_volume, voice_volume,
##                gloria_voice_enabled, muted
static func apply_audio_settings(data: Dictionary) -> void:
	if AudioManager:
		AudioManager.apply_volume_settings(data)
	else:
		var master_bus_idx := AudioServer.get_bus_index("Master")
		var music_bus_idx := AudioServer.get_bus_index("Music")
		var sfx_bus_idx := AudioServer.get_bus_index("SFX")
		var voice_bus_idx := AudioServer.get_bus_index("Voice")
		var is_muted: bool = data.get("muted", false)
		if master_bus_idx != -1:
			AudioServer.set_bus_mute(master_bus_idx, is_muted)
			if not is_muted:
				var master_db := linear_to_db(float(data.get("master_volume", 100.0)) / 100.0)
				var music_db := linear_to_db(float(data.get("music_volume", 100.0)) / 100.0)
				var sfx_db := linear_to_db(float(data.get("sfx_volume", 100.0)) / 100.0)
				var voice_db := linear_to_db(float(data.get("voice_volume", 80.0)) / 100.0)
				AudioServer.set_bus_volume_db(master_bus_idx, master_db)
				if music_bus_idx != -1:
					AudioServer.set_bus_volume_db(music_bus_idx, music_db)
				if sfx_bus_idx != -1:
					AudioServer.set_bus_volume_db(sfx_bus_idx, sfx_db)
				if voice_bus_idx != -1:
					AudioServer.set_bus_volume_db(voice_bus_idx, voice_db)

## Updates the percentage label inside an HBox volume row.
static func update_volume_label(hbox: Control, node_name: String, value: float) -> void:
	if hbox and hbox.has_node(node_name):
		hbox.get_node(node_name).text = str(int(value)) + "%"
