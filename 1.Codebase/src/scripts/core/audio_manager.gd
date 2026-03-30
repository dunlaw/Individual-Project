extends Node
const ERROR_CONTEXT := "AudioManager"
const VOICE_BUS_NAME := "Voice"
const VOICE_INPUT_BUS_NAME := "VoiceInput"
const MAX_SFX_PLAYERS := 8
const DEFAULT_VOICE_SAMPLE_RATE := 24000
const AUDIO_DIRECTORIES := {
	"music": "res://1.Codebase/src/assets/music",
	"sfx": "res://1.Codebase/src/assets/sound",
}
const SUPPORTED_AUDIO_EXTENSIONS := ["mp3", "ogg", "wav", "opus", "flac", "webm"]
const WAV_HEADER_MIN_SIZE := 44
const WAV_RIFF_MAGIC := "RIFF"
const WAV_WAVE_MAGIC := "WAVE"
const WAV_FMT_CHUNK := "fmt "
const WAV_DATA_CHUNK := "data"
const WAV_FORMAT_PCM := 1
const WAV_SUPPORTED_BITS := 16
const GLORIA_VOICE_GROUP_COUNTS := {
	"accept": 4,
	"guilt": 8,
	"open": 4,
	"pua": 10,
}
const GLORIA_VOICE_LANGUAGES := ["en", "zh"]
const SFX_ALIASES := {
	"menu_close": "menu_click",
	"menu_back": "menu_click",
	"menu_focus": "happy_click",
	"prayer_start": "happy_click",
	"prayer_complete": "happy_click",
	"gloria_appears": "group_present",
	"night_start": "session_begin_sting",
	"heartbeat": "countdown",
	"ui_open": "menu_click",
	"ui_click": "menu_click",
	"ui_error": "angry_click",
	"ui_click_heavy": "angry_click",
	"ui_success": "asset_upgrade_confirm",
}
const _PRELOADED_SOUND_PATHS := {
	"Zuruckbleiben bitte": "res://1.Codebase/src/assets/sound/Zuruckbleiben bitte.mp3",
	"group_present": "res://1.Codebase/src/assets/sound/group_present.mp3",
	"happy_click": "res://1.Codebase/src/assets/sound/happy_click.mp3",
	"resource_spend_negative": "res://1.Codebase/src/assets/sound/resource_spend_negative.mp3",
	"angry_click": "res://1.Codebase/src/assets/sound/angry_click.mp3",
	"credits": "res://1.Codebase/src/assets/sound/credits.mp3",
	"menu_click": "res://1.Codebase/src/assets/sound/menu_click.mp3",
	"dilemma_outcome_resolved": "res://1.Codebase/src/assets/sound/dilemma_outcome_resolved.mp3",
	"resource_gain_positive": "res://1.Codebase/src/assets/sound/resource_gain_positive.mp3",
	"chance_roll_trigger": "res://1.Codebase/src/assets/sound/chance_roll_trigger.mp3",
	"story_card_flip": "res://1.Codebase/src/assets/sound/story_card_flip.mp3",
	"asset_upgrade_confirm": "res://1.Codebase/src/assets/sound/asset_upgrade_confirm.mp3",
	"resource_commit_revert": "res://1.Codebase/src/assets/sound/resource_commit_revert.mp3",
	"player_depart_notice": "res://1.Codebase/src/assets/sound/player_depart_notice.mp3",
	"prayer_choice_sting": "res://1.Codebase/src/assets/sound/prayer_choice_sting.mp3",
	"session_begin_sting": "res://1.Codebase/src/assets/sound/session_begin_sting.mp3",
	"resource_commit_confirm": "res://1.Codebase/src/assets/sound/resource_commit_confirm.mp3",
	"safe_zone_recovery": "res://1.Codebase/src/assets/sound/safe_zone_recovery.mp3",
	"session_fail_sting": "res://1.Codebase/src/assets/sound/session_fail_sting.mp3",
	"penalty_detained_alert": "res://1.Codebase/src/assets/sound/penalty_detained_alert.mp3",
	"asset_acquired_confirm": "res://1.Codebase/src/assets/sound/asset_acquired_confirm.mp3",
	"resource_depleted_alert": "res://1.Codebase/src/assets/sound/resource_depleted_alert.mp3",
	"dilemma_option_select": "res://1.Codebase/src/assets/sound/dilemma_option_select.mp3",
	"chance_roll_critical": "res://1.Codebase/src/assets/sound/chance_roll_critical.mp3",
	"countdown": "res://1.Codebase/src/assets/sound/countdown.mp3",
	"dilemma_prompt_reveal": "res://1.Codebase/src/assets/sound/dilemma_prompt_reveal.mp3",
	"splash_sequence": "res://1.Codebase/src/assets/sound/happy_click.mp3",
}
const _PRELOADED_MUSIC_PATHS := {
	"background_music": "res://1.Codebase/src/assets/music/background_music.mp3",
	"gloria_intervention_bgm": "res://1.Codebase/src/assets/music/gloria_intervention_bgm.mp3",
	"prayer_music": "res://1.Codebase/src/assets/music/prayer_music.mp3",
	"settings_bgm": "res://1.Codebase/src/assets/music/settings_bgm.mp3",
	"trolley_problem_bgm": "res://1.Codebase/src/assets/sound/trolley_problem_bgm.mp3",
	"story_bgm_0_10": "res://1.Codebase/src/assets/music/story_bgm_0_10.mp3",
	"story_bgm_11_20": "res://1.Codebase/src/assets/music/story_bgm_11_20.mp3",
	"story_bgm_20_30": "res://1.Codebase/src/assets/music/story_bgm_20_30.mp3",
	"story_bgm_30_41": "res://1.Codebase/src/assets/music/story_bgm_30_41.mp3",
	"hidden_credits-backup": "res://1.Codebase/src/assets/music/hidden_credits-backup.mp3",
	"night_concert_guitar": "res://1.Codebase/src/assets/music/night_concert_guitar.mp3",
	"night_concert_crowd": "res://1.Codebase/src/assets/music/night_concert_crowd.mp3",
	"mountain_king": "res://1.Codebase/src/assets/music/Peer Gynt, Op. 23 - IV. In the Hall of the Mountain King.mp3",
	"chopin_nocturne_op9_no2": "res://1.Codebase/src/assets/music/chopin_nocturne_op9_no2.mp3",
}
var music_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_next_index: int = 0
var master_volume: float = 0.8
var music_volume: float = 0.7
var sfx_volume: float = 0.8
var voice_volume: float = 0.8
var gloria_voice_enabled: bool = false
var is_muted: bool = false
var current_music: AudioStream = null
var current_voice_stream: AudioStream = null
var latest_voice_sample_rate: int = DEFAULT_VOICE_SAMPLE_RATE
var latest_voice_pcm: PackedByteArray = PackedByteArray()
var sounds: Dictionary = { }
var sound_manifest: Dictionary = { }
const PLAYLIST_EXCLUDED := [
	"hidden_credits-backup",
	"trolley_problem_bgm",
	"night_concert_guitar",
	"night_concert_crowd",
	"chopin_nocturne_op9_no2",
]
var _playlist: Array[String] = []
var _playlist_index: int = 0
var _playlist_active: bool = false
var _playlist_suspended: bool = false
var _web_audio_unlocked: bool = false
var _pending_music_name: String = ""
var _pending_music_loop: bool = true
var _pending_playlist_start: bool = false
var _is_web: bool = false
var _audio_output_available: bool = true
var _audio_output_warning_emitted: bool = false
signal voice_stream_started(sample_rate: int)
signal voice_stream_finished()
func _ready() -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, "Initializing audio system...")
	_warm_export_preloads()
	_is_web = OS.has_feature("web") or OS.get_name().to_lower() == "html5"
	if _is_web:
		_web_audio_unlocked = false
		ErrorReporterBridge.report_info(ERROR_CONTEXT, "Platform: WEB (audio unlock required)")
	else:
		_web_audio_unlocked = true
		ErrorReporterBridge.report_info(ERROR_CONTEXT, "Platform: DESKTOP (audio unlocked)")
	music_player = AudioStreamPlayer.new()
	music_player.bus = _resolve_bus("Music", "Master")
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	music_player.finished.connect(_on_music_finished)
	add_child(music_player)
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = _resolve_bus(VOICE_BUS_NAME, "SFX")
	voice_player.process_mode = Node.PROCESS_MODE_ALWAYS
	voice_player.finished.connect(_on_voice_finished)
	add_child(voice_player)
	for i in range(MAX_SFX_PLAYERS):
		var player = AudioStreamPlayer.new()
		player.bus = _resolve_bus("SFX", "Master")
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		sfx_players.append(player)
	_load_sounds()
	_load_saved_settings()
	_refresh_audio_output_state()
	sync_from_audio_server()
	update_volumes()
func _unhandled_input(event: InputEvent) -> void:
	if not _is_web or _web_audio_unlocked:
		return
	var is_gesture := (
		(event is InputEventMouseButton and (event as InputEventMouseButton).pressed) or
		(event is InputEventKey and (event as InputEventKey).pressed) or
		(event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
	)
	if is_gesture:
		unlock_web_audio()
func _exit_tree() -> void:
	sounds.clear()
	sound_manifest.clear()
func _load_saved_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		master_volume = config.get_value("audio", "master_volume", 100.0) / 100.0
		music_volume = config.get_value("audio", "music_volume", 100.0) / 100.0
		sfx_volume = config.get_value("audio", "sfx_volume", 100.0) / 100.0
		voice_volume = config.get_value("voice", "voice_volume", 100.0) / 100.0
		gloria_voice_enabled = bool(config.get_value("audio", "gloria_voice_enabled", false))
		is_muted = config.get_value("audio", "muted", false)
		var master_idx = AudioServer.get_bus_index("Master")
		if master_idx != -1:
			AudioServer.set_bus_mute(master_idx, is_muted)
		ErrorReporterBridge.report_info(ERROR_CONTEXT, "Loaded saved settings: muted=%s, sfx=%.0f%%, master=%.0f%%" % [is_muted, sfx_volume * 100, master_volume * 100])
func _resolve_bus(preferred_bus: String, fallback_bus: String) -> String:
	return preferred_bus if AudioServer.get_bus_index(preferred_bus) != -1 else fallback_bus
func _load_sounds() -> void:
	var preloaded_count := sounds.size()
	for category in AUDIO_DIRECTORIES.keys():
		var directory_path: String = AUDIO_DIRECTORIES[category]
		_load_audio_directory(directory_path, category)
	_register_sound_aliases()
	var scanned_count := sounds.size() - preloaded_count
	if scanned_count > 0:
		ErrorReporterBridge.report_info(ERROR_CONTEXT, "Discovered %d additional audio assets via directory scan." % scanned_count)
	ErrorReporterBridge.report_info(ERROR_CONTEXT, "Total: %d audio assets ready." % sounds.size())
func reload_sound_catalog() -> void:
	sounds.clear()
	sound_manifest.clear()
	_warm_export_preloads()
	_load_sounds()
	update_volumes()
func has_sound(sound_name: String) -> bool:
	return sounds.has(sound_name)
func _load_audio_directory(directory_path: String, category: String, prefix: String = "") -> void:
	var dir := DirAccess.open(directory_path)
	if dir == null:
		ErrorReporterBridge.report_warning(
			ERROR_CONTEXT,
			"Audio directory not found: %s" % directory_path,
			{ "path": directory_path },
		)
		return
	dir.list_dir_begin()
	while true:
		var entry := dir.get_next()
		if entry == "":
			break
		if entry == "." or entry == "..":
			continue
		var entry_path := _join_path(directory_path, entry)
		if dir.current_is_dir():
			if entry.begins_with("."):
				continue
			var nested_prefix := entry if prefix.is_empty() else "%s/%s" % [prefix, entry]
			_load_audio_directory(entry_path, category, nested_prefix)
			continue
		if entry.begins_with(".") or not _is_supported_audio_file(entry):
			continue
		var sound_name := entry.get_basename()
		if not prefix.is_empty():
			sound_name = "%s/%s" % [prefix, sound_name]
		_register_sound(sound_name, entry_path, category)
	dir.list_dir_end()
func _register_sound(sound_name: String, resource_path: String, category: String) -> void:
	if sounds.has(sound_name):
		var previous: Dictionary = sound_manifest.get(sound_name, { })
		var previous_path: String = String(previous.get("path", "unknown"))
		if previous_path == "preloaded":
			sound_manifest[sound_name] = {
				"path": resource_path,
				"category": category,
				"preloaded": true,
			}
			return
		if previous_path == resource_path:
			return
	if not _audio_resource_exists(resource_path):
		ErrorReporterBridge.report_warning(
			ERROR_CONTEXT,
			"Audio asset missing at %s (key: %s)" % [resource_path, sound_name],
			{ "path": resource_path, "key": sound_name },
		)
		return
	var stream := _load_audio_stream(resource_path)
	if stream == null or not (stream is AudioStream):
		ErrorReporterBridge.report_warning(
			ERROR_CONTEXT,
			"Failed to load audio stream at %s (key: %s)" % [resource_path, sound_name],
			{ "path": resource_path, "key": sound_name },
		)
		return
	if sounds.has(sound_name):
		var previous: Dictionary = sound_manifest.get(sound_name, { })
		var previous_path: String = String(previous.get("path", "unknown"))
		ErrorReporterBridge.report_warning(
			ERROR_CONTEXT,
			"Duplicate audio key '%s'. Replacing asset %s with %s." % [sound_name, previous_path, resource_path],
			{ "key": sound_name, "previous": previous_path, "new": resource_path },
		)
	sounds[sound_name] = stream
	sound_manifest[sound_name] = {
		"path": resource_path,
		"category": category,
	}
func _audio_resource_exists(resource_path: String) -> bool:
	return ResourceLoader.exists(resource_path, "AudioStream") or FileAccess.file_exists(resource_path)
func _load_audio_stream(resource_path: String) -> AudioStream:
	if ResourceLoader.exists(resource_path, "AudioStream"):
		var stream := ResourceLoader.load(resource_path, "AudioStream") as AudioStream
		if stream != null:
			return stream
	if resource_path.get_extension().to_lower() == "wav":
		return _load_wav_stream_direct(resource_path)
	return null
func _load_wav_stream_direct(resource_path: String) -> AudioStreamWAV:
	var file := FileAccess.open(resource_path, FileAccess.READ)
	if file == null:
		return null
	var bytes := file.get_buffer(file.get_length())
	if bytes.size() < WAV_HEADER_MIN_SIZE:
		return null
	if bytes.slice(0, 4).get_string_from_ascii() != WAV_RIFF_MAGIC:
		return null
	if bytes.slice(8, 12).get_string_from_ascii() != WAV_WAVE_MAGIC:
		return null
	var offset := 12
	var channels := 0
	var sample_rate := 0
	var bits_per_sample := 0
	var pcm_data := PackedByteArray()
	while offset + 8 <= bytes.size():
		var chunk_id := bytes.slice(offset, offset + 4).get_string_from_ascii()
		var chunk_size := int(bytes.decode_u32(offset + 4))
		var chunk_data_start := offset + 8
		var chunk_data_end: int = int(min(chunk_data_start + chunk_size, bytes.size()))
		if chunk_id == WAV_FMT_CHUNK and chunk_data_start + 16 <= bytes.size():
			var audio_format := int(bytes.decode_u16(chunk_data_start))
			if audio_format != WAV_FORMAT_PCM:
				return null
			channels = int(bytes.decode_u16(chunk_data_start + 2))
			sample_rate = int(bytes.decode_u32(chunk_data_start + 4))
			bits_per_sample = int(bytes.decode_u16(chunk_data_start + 14))
		elif chunk_id == WAV_DATA_CHUNK and chunk_data_end > chunk_data_start:
			pcm_data = bytes.slice(chunk_data_start, chunk_data_end)
		offset = chunk_data_start + chunk_size + (chunk_size % 2)
	if pcm_data.is_empty() or sample_rate <= 0 or channels < 1 or channels > 2:
		return null
	if bits_per_sample != WAV_SUPPORTED_BITS:
		return null
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.stereo = channels == 2
	wav.mix_rate = sample_rate
	wav.data = pcm_data
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return wav
func _register_sound_aliases() -> void:
	for alias in SFX_ALIASES.keys():
		var canonical: String = SFX_ALIASES[alias]
		if not sounds.has(canonical):
			ErrorReporterBridge.report_warning(
				ERROR_CONTEXT,
				"Alias '%s' references missing sound '%s'." % [alias, canonical],
				{ "alias": alias, "target": canonical },
			)
			continue
		sounds[alias] = sounds[canonical]
		var manifest_entry: Dictionary = sound_manifest.get(canonical, {}).duplicate()
		manifest_entry["alias_of"] = canonical
		sound_manifest[alias] = manifest_entry
func _log_gloria_sfx_event(event_name: String, sfx_name: String) -> void:
	var manifest_entry: Dictionary = sound_manifest.get(sfx_name, { })
	var path: String = String(manifest_entry.get("path", "unknown"))
	ErrorReporterBridge.report_info(ERROR_CONTEXT, "[%s] key=%s path=%s" % [event_name, sfx_name, path])
func _is_supported_audio_file(file_name: String) -> bool:
	var extension := file_name.get_extension().to_lower()
	return SUPPORTED_AUDIO_EXTENSIONS.has(extension)
func _join_path(base_path: String, element: String) -> String:
	var sanitized_base := base_path
	if sanitized_base.ends_with("/"):
		sanitized_base = sanitized_base.substr(0, sanitized_base.length() - 1)
	var sanitized_element := element
	if sanitized_element.begins_with("/"):
		sanitized_element = sanitized_element.substr(1, sanitized_element.length() - 1)
	return "%s/%s" % [sanitized_base, sanitized_element]
func _warm_export_preloads() -> void:
	for sound_name in _PRELOADED_SOUND_PATHS.keys():
		_register_preloaded_audio(sound_name, _PRELOADED_SOUND_PATHS[sound_name], "sfx")
	var gloria_voice_preloads := _build_gloria_voice_preloads()
	for sound_name in gloria_voice_preloads.keys():
		_register_preloaded_audio(sound_name, gloria_voice_preloads[sound_name], "sfx")
	for music_name in _PRELOADED_MUSIC_PATHS.keys():
		_register_preloaded_audio(music_name, _PRELOADED_MUSIC_PATHS[music_name], "music")
	ErrorReporterBridge.report_info(ERROR_CONTEXT, "Registered %d preloaded audio assets." % sounds.size())
func _register_preloaded_audio(sound_name: String, resource_path: String, category: String) -> void:
	var stream := ResourceLoader.load(resource_path, "AudioStream") as AudioStream
	if stream == null:
		ErrorReporterBridge.report_warning(
			ERROR_CONTEXT,
			"Failed to warm preload audio stream",
			{ "key": sound_name, "path": resource_path },
		)
		return
	sounds[sound_name] = stream
	sound_manifest[sound_name] = {
		"path": "preloaded",
		"category": category,
	}
func _build_gloria_voice_preloads() -> Dictionary:
	var voice_paths: Dictionary = {}
	for lang_code in GLORIA_VOICE_LANGUAGES:
		for group_name in GLORIA_VOICE_GROUP_COUNTS.keys():
			var clip_count: int = int(GLORIA_VOICE_GROUP_COUNTS[group_name])
			for clip_index in range(1, clip_count + 1):
				var voice_id := "gloria_%s_%02d" % [group_name, clip_index]
				var sound_key := "gloria/%s/%s" % [lang_code, voice_id]
				voice_paths[sound_key] = "res://1.Codebase/src/assets/sound/gloria/%s/%s.wav" % [lang_code, voice_id]
	return voice_paths
func _apply_music_loop(stream: AudioStream, loop: bool) -> void:
	if stream == null:
		return
	if stream is AudioStreamWAV and stream.has_method("set_loop_mode"):
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
	elif stream.has_method("set_loop"):
		stream.loop = loop
func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	if sfx_players.is_empty():
		return null
	var player: AudioStreamPlayer = sfx_players[sfx_next_index % sfx_players.size()]
	sfx_next_index = (sfx_next_index + 1) % sfx_players.size()
	return player
func _detect_audio_output_available() -> bool:
	if AudioServer.has_method("get_output_device_list"):
		var devices_variant: Variant = AudioServer.call("get_output_device_list")
		if devices_variant is Array:
			return not (devices_variant as Array).is_empty()
	return true
func _refresh_audio_output_state() -> bool:
	_audio_output_available = _detect_audio_output_available()
	if not _audio_output_available and not _audio_output_warning_emitted:
		_audio_output_warning_emitted = true
		ErrorReporterBridge.report_warning(
			ERROR_CONTEXT,
			"No audio output device detected. Audio playback will stay disabled for this session.",
		)
	return _audio_output_available
func is_output_available() -> bool:
	return _refresh_audio_output_state()
func play_music(music_name: String, loop: bool = true) -> void:
	if not sounds.has(music_name):
		ErrorReporterBridge.report_warning(
			ERROR_CONTEXT,
			"Music track not found: %s" % music_name,
			{ "music_name": music_name },
		)
		return
	if not _refresh_audio_output_state():
		return
	if _is_web and not _web_audio_unlocked:
		_pending_music_name = music_name
		_pending_music_loop = loop
		ErrorReporterBridge.report_info(ERROR_CONTEXT, "Web: audio locked, queuing music '%s' until user gesture" % music_name)
		return
	var stream: AudioStream = sounds[music_name]
	_apply_music_loop(stream, loop)
	var should_restart := current_music != stream or not music_player.playing
	current_music = stream
	music_player.stream = stream
	if should_restart:
		ErrorReporterBridge.report_info(ERROR_CONTEXT, "PLAY play_music: '%s'  loop=%s" % [music_name, loop])
		music_player.play()
	else:
		ErrorReporterBridge.report_info(ERROR_CONTEXT, "SKIP play_music: '%s' already playing, skipped restart" % music_name)
func unlock_web_audio() -> void:
	if _web_audio_unlocked:
		return
	ErrorReporterBridge.report_info(ERROR_CONTEXT, "Web: attempting to unlock audio context via user gesture")
	if OS.has_feature("web"):
		var unlock_result = JavaScriptBridge.eval("""
			(function() {
				var ctx = null;
				if (typeof GodotAudio !== 'undefined' && GodotAudio.ctx) {
					ctx = GodotAudio.ctx;
				} else if (typeof Module !== 'undefined' && Module.godot_audio_context) {
					ctx = Module.godot_audio_context;
				}
				if (ctx) {
					if (ctx.state === 'running') {
						return 'already_running';
					}
					// Try to resume - this returns a Promise
					ctx.resume().then(function() {
						console.log('[AudioManager] AudioContext successfully resumed');
					}).catch(function(e) {
						console.warn('[AudioManager] Failed to resume AudioContext: ' + e);
					});
					return ctx.state;
				}
				return 'no_context';
			})();
		""")
		ErrorReporterBridge.report_info(ERROR_CONTEXT, "Web: unlock attempt result: %s" % str(unlock_result))
		if unlock_result != "no_context":
			_web_audio_unlocked = true
			call_deferred("_resume_pending_audio")
	else:
		_web_audio_unlocked = true
		call_deferred("_resume_pending_audio")
func _resume_pending_audio() -> void:
	if _pending_playlist_start:
		_pending_playlist_start = false
		_playlist_suspended = false
		_play_playlist_track()
	elif not _pending_music_name.is_empty():
		var name := _pending_music_name
		var loop := _pending_music_loop
		_pending_music_name = ""
		play_music(name, loop)
func stop_music(fade_duration: float = 0.0) -> void:
	var prev := get_current_music()
	if music_player == null:
		current_music = null
		return
	ErrorReporterBridge.report_info(ERROR_CONTEXT, "STOP stop_music: '%s'  fade=%.1fs" % [prev if not prev.is_empty() else "(none)", fade_duration])
	if fade_duration > 0.0 and music_player.playing:
		var tween := create_tween()
		tween.tween_property(music_player, "volume_db", -80, fade_duration)
		await tween.finished
	music_player.stop()
	current_music = null
	update_volumes()
func play_sfx(sfx_name: String, volume_multiplier: float = 1.0) -> void:
	if not sounds.has(sfx_name):
		if sfx_name.begins_with("gloria/"):
			_log_gloria_sfx_event("missing", sfx_name)
		ErrorReporterBridge.report_warning(
			ERROR_CONTEXT,
			"Sound effect not found: %s" % sfx_name,
			{ "sfx_name": sfx_name },
		)
		return
	if not _refresh_audio_output_state():
		return
	if (not gloria_voice_enabled) and sfx_name.begins_with("gloria/"):
		_log_gloria_sfx_event("disabled", sfx_name)
		return
	if _is_web and not _web_audio_unlocked:
		ErrorReporterBridge.report_info(ERROR_CONTEXT, "Web: audio locked, dropping sfx '%s' until user gesture" % sfx_name)
		return
	if is_muted:
		return
	var player := _get_available_sfx_player()
	if player == null:
		ErrorReporterBridge.report_warning(
			ERROR_CONTEXT,
			"No SFX players available to play %s" % sfx_name,
			{ "sfx_name": sfx_name },
		)
		return
	player.stream = sounds[sfx_name]
	var safe_multiplier: float = max(volume_multiplier, 0.0)
	var sfx_idx = AudioServer.get_bus_index("SFX")
	var master_idx = AudioServer.get_bus_index("Master")
	if sfx_idx != -1:
		player.volume_db = _safe_linear_to_db(safe_multiplier)
	elif master_idx != -1:
		player.volume_db = _safe_linear_to_db(sfx_volume * safe_multiplier)
	else:
		player.volume_db = _safe_linear_to_db(sfx_volume * safe_multiplier * master_volume)
	if sfx_name.begins_with("gloria/"):
		_log_gloria_sfx_event("play", sfx_name)
	else:
		ErrorReporterBridge.report_info(ERROR_CONTEXT, "PLAY '%s' vol_mult=%.2f" % [sfx_name, safe_multiplier])
	player.play()
func update_volumes() -> void:
	if is_muted:
		if music_player:
			music_player.volume_db = -80
		if voice_player:
			voice_player.volume_db = -80
		for player in sfx_players:
			player.volume_db = -80
		return
	if music_player:
		if AudioServer.get_bus_index("Music") != -1:
			music_player.volume_db = 0.0
		else:
			music_player.volume_db = _safe_linear_to_db(music_volume * master_volume)
	if voice_player:
		if AudioServer.get_bus_index(VOICE_BUS_NAME) != -1:
			voice_player.volume_db = 0.0
		else:
			voice_player.volume_db = _safe_linear_to_db(voice_volume * master_volume)
	var sfx_bus_exists = AudioServer.get_bus_index("SFX") != -1
	for player in sfx_players:
		if sfx_bus_exists:
			player.volume_db = 0.0
		else:
			player.volume_db = _safe_linear_to_db(sfx_volume * master_volume)
func stop_sfx(sfx_name: String) -> void:
	if not sounds.has(sfx_name):
		return
	var target_stream: AudioStream = sounds[sfx_name]
	for player in sfx_players:
		if player.playing and player.stream == target_stream:
			player.stop()
			return
	if is_muted:
		if music_player:
			music_player.volume_db = -80
		if voice_player:
			voice_player.volume_db = -80
		for player in sfx_players:
			player.volume_db = -80
		return
	if music_player:
		if AudioServer.get_bus_index("Music") != -1:
			music_player.volume_db = 0.0
		else:
			music_player.volume_db = linear_to_db(music_volume * master_volume)
	if voice_player:
		if AudioServer.get_bus_index(VOICE_BUS_NAME) != -1:
			voice_player.volume_db = 0.0
		else:
			voice_player.volume_db = linear_to_db(voice_volume * master_volume)
	var sfx_bus_exists = AudioServer.get_bus_index("SFX") != -1
	for player in sfx_players:
		if sfx_bus_exists:
			player.volume_db = 0.0
		else:
			player.volume_db = linear_to_db(sfx_volume * master_volume)
func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx != -1:
		AudioServer.set_bus_volume_db(master_idx, _safe_linear_to_db(master_volume))
	update_volumes()
func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	var music_idx = AudioServer.get_bus_index("Music")
	if music_idx != -1:
		AudioServer.set_bus_volume_db(music_idx, _safe_linear_to_db(music_volume))
	else:
		if music_player:
			music_player.volume_db = _safe_linear_to_db(music_volume * master_volume)
func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	var sfx_idx = AudioServer.get_bus_index("SFX")
	if sfx_idx != -1:
		AudioServer.set_bus_volume_db(sfx_idx, _safe_linear_to_db(sfx_volume))
	else:
		update_volumes()
func set_voice_volume(volume: float) -> void:
	voice_volume = clamp(volume, 0.0, 1.0)
	var voice_idx = AudioServer.get_bus_index(VOICE_BUS_NAME)
	if voice_idx != -1:
		AudioServer.set_bus_volume_db(voice_idx, _safe_linear_to_db(voice_volume))
	if voice_player:
		voice_player.volume_db = _safe_linear_to_db(voice_volume * master_volume)
func set_gloria_voice_enabled(enabled: bool) -> void:
	gloria_voice_enabled = enabled
func is_music_playing() -> bool:
	return music_player != null and music_player.playing
func get_current_music() -> String:
	for key in sounds.keys():
		if sounds[key] == current_music:
			return key
	return ""
func set_muted(muted: bool) -> void:
	is_muted = muted
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx != -1:
		AudioServer.set_bus_mute(master_idx, muted)
	var voice_idx = AudioServer.get_bus_index(VOICE_BUS_NAME)
	if voice_idx != -1:
		AudioServer.set_bus_mute(voice_idx, muted)
	update_volumes()
func sync_from_audio_server() -> void:
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx != -1:
		is_muted = AudioServer.is_bus_mute(master_idx)
		if not is_muted:
			master_volume = _sanitize_linear_volume(db_to_linear(AudioServer.get_bus_volume_db(master_idx)), master_volume)
	var music_idx = AudioServer.get_bus_index("Music")
	if music_idx != -1:
		music_volume = _sanitize_linear_volume(db_to_linear(AudioServer.get_bus_volume_db(music_idx)), music_volume)
	var sfx_idx = AudioServer.get_bus_index("SFX")
	if sfx_idx != -1:
		sfx_volume = _sanitize_linear_volume(db_to_linear(AudioServer.get_bus_volume_db(sfx_idx)), sfx_volume)
	var voice_idx = AudioServer.get_bus_index(VOICE_BUS_NAME)
	if voice_idx != -1 and not is_muted:
		voice_volume = _sanitize_linear_volume(db_to_linear(AudioServer.get_bus_volume_db(voice_idx)), voice_volume)
func get_volume_settings() -> Dictionary:
	sync_from_audio_server()
	return {
		"master_volume": master_volume * 100.0,
		"music_volume": music_volume * 100.0,
		"sfx_volume": sfx_volume * 100.0,
		"voice_volume": voice_volume * 100.0,
		"gloria_voice_enabled": gloria_voice_enabled,
		"muted": is_muted,
	}
func apply_volume_settings(settings: Dictionary) -> void:
	var master_percent = float(settings.get("master_volume", master_volume * 100.0))
	var music_percent = float(settings.get("music_volume", music_volume * 100.0))
	var sfx_percent = float(settings.get("sfx_volume", sfx_volume * 100.0))
	var voice_percent = float(settings.get("voice_volume", voice_volume * 100.0))
	var gloria_enabled = bool(settings.get("gloria_voice_enabled", gloria_voice_enabled))
	var muted = bool(settings.get("muted", is_muted))
	master_volume = _sanitize_linear_volume(master_percent / 100.0, master_volume)
	music_volume = _sanitize_linear_volume(music_percent / 100.0, music_volume)
	sfx_volume = _sanitize_linear_volume(sfx_percent / 100.0, sfx_volume)
	voice_volume = _sanitize_linear_volume(voice_percent / 100.0, voice_volume)
	gloria_voice_enabled = gloria_enabled
	is_muted = muted
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx != -1:
		AudioServer.set_bus_mute(master_idx, muted)
		AudioServer.set_bus_volume_db(master_idx, _safe_linear_to_db(master_volume))
	var music_idx = AudioServer.get_bus_index("Music")
	if music_idx != -1:
		AudioServer.set_bus_volume_db(music_idx, _safe_linear_to_db(music_volume))
	var sfx_idx = AudioServer.get_bus_index("SFX")
	if sfx_idx != -1:
		AudioServer.set_bus_volume_db(sfx_idx, _safe_linear_to_db(sfx_volume))
	var voice_idx = AudioServer.get_bus_index(VOICE_BUS_NAME)
	if voice_idx != -1:
		AudioServer.set_bus_mute(voice_idx, muted)
		AudioServer.set_bus_volume_db(voice_idx, _safe_linear_to_db(voice_volume))
	update_volumes()
func play_voice_stream(stream: AudioStream) -> void:
	if voice_player == null or stream == null:
		return
	if not _refresh_audio_output_state():
		return
	current_voice_stream = stream
	if stream is AudioStreamWAV:
		var sample := stream as AudioStreamWAV
		latest_voice_sample_rate = sample.mix_rate
		latest_voice_pcm = sample.data
	else:
		latest_voice_sample_rate = DEFAULT_VOICE_SAMPLE_RATE
		latest_voice_pcm = PackedByteArray()
	voice_player.stream = stream
	if is_muted:
		voice_player.volume_db = -80
	else:
		voice_player.volume_db = _safe_linear_to_db(voice_volume * master_volume)
	voice_player.play()
	voice_stream_started.emit(latest_voice_sample_rate)
func play_voice_from_pcm(pcm_buffer: PackedByteArray, sample_rate: int = DEFAULT_VOICE_SAMPLE_RATE, stereo: bool = false) -> void:
	if pcm_buffer.is_empty():
		ErrorReporterBridge.report_warning(
			ERROR_CONTEXT,
			"Received empty PCM buffer for voice playback",
		)
		return
	var sample := AudioStreamWAV.new()
	sample.format = 16
	sample.stereo = stereo
	sample.mix_rate = sample_rate
	sample.data = pcm_buffer
	sample.loop_mode = AudioStreamWAV.LOOP_DISABLED
	latest_voice_sample_rate = sample_rate
	latest_voice_pcm = pcm_buffer
	play_voice_stream(sample)
func play_voice_from_base64(encoded: String, sample_rate: int = DEFAULT_VOICE_SAMPLE_RATE, stereo: bool = false) -> void:
	if encoded.is_empty():
		ErrorReporterBridge.report_warning(
			ERROR_CONTEXT,
			"Empty base64 voice payload",
		)
		return
	var raw := Marshalls.base64_to_raw(encoded)
	play_voice_from_pcm(raw, sample_rate, stereo)
func stop_voice(fade_duration: float = 0.0) -> void:
	if voice_player == null:
		return
	if fade_duration > 0.0 and voice_player.playing:
		var tween := create_tween()
		tween.tween_property(voice_player, "volume_db", -80, fade_duration)
		await tween.finished
	voice_player.stop()
	if is_muted:
		voice_player.volume_db = -80
	else:
		voice_player.volume_db = _safe_linear_to_db(voice_volume * master_volume)
	_on_voice_finished()
func _sanitize_linear_volume(value: float, fallback: float = 1.0) -> float:
	if is_nan(value) or is_inf(value):
		return clamp(fallback, 0.0, 1.0)
	return clamp(value, 0.0, 1.0)
func _safe_linear_to_db(value: float, silence_db: float = -80.0) -> float:
	var safe_value := _sanitize_linear_volume(value, 0.0)
	if safe_value <= 0.0001:
		return silence_db
	return linear_to_db(safe_value)
func is_voice_playing() -> bool:
	return voice_player != null and voice_player.playing
func get_last_voice_snapshot() -> Dictionary:
	return {
		"pcm": latest_voice_pcm.duplicate(),
		"sample_rate": latest_voice_sample_rate,
		"stream": current_voice_stream,
	}
func _on_music_finished() -> void:
	var finished_name := get_current_music()
	current_music = null
	ErrorReporterBridge.report_info(ERROR_CONTEXT, "STOP music finished: '%s'  playlist_active=%s suspended=%s" % [finished_name, _playlist_active, _playlist_suspended])
	if _playlist_active and not _playlist_suspended:
		_advance_playlist()
func start_gameplay_playlist() -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, "START start_gameplay_playlist")
	_playlist_active = true
	_playlist_suspended = false
	_build_playlist()
	_playlist_index = 0
	if _is_web and not _web_audio_unlocked:
		_pending_playlist_start = true
		_pending_music_name = ""
		ErrorReporterBridge.report_info(ERROR_CONTEXT, "Web: audio locked, playlist queued until user gesture")
		return
	_play_playlist_track()
func stop_gameplay_playlist() -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, "STOP stop_gameplay_playlist  tracks_had=%d" % _playlist.size())
	_playlist_active = false
	_playlist_suspended = false
	_playlist.clear()
func suspend_gameplay_playlist() -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, "PAUSE suspend_gameplay_playlist  current='%s'" % get_current_music())
	_playlist_suspended = true
func resume_gameplay_playlist() -> void:
	if not _playlist_active:
		ErrorReporterBridge.report_info(ERROR_CONTEXT, "resume_gameplay_playlist called but playlist not active, skipping")
		return
	ErrorReporterBridge.report_info(ERROR_CONTEXT, "RESUME resume_gameplay_playlist  music_playing=%s" % is_music_playing())
	_playlist_suspended = false
	if not is_music_playing():
		_play_playlist_track()
func is_playlist_active() -> bool:
	return _playlist_active and not _playlist_suspended
func _build_playlist() -> void:
	_playlist.clear()
	for key in sounds.keys():
		var entry: Dictionary = sound_manifest.get(key, {})
		if entry.get("category", "") != "music":
			continue
		if entry.has("alias_of"):
			continue
		if PLAYLIST_EXCLUDED.has(key):
			continue
		_playlist.append(key)
	_playlist.shuffle()
	ErrorReporterBridge.report_info(ERROR_CONTEXT, "Gameplay playlist built: %s" % [_playlist])
func _play_playlist_track() -> void:
	if _playlist.is_empty():
		ErrorReporterBridge.report_info(ERROR_CONTEXT, "_play_playlist_track: playlist is empty, nothing to play")
		return
	if _playlist_index >= _playlist.size():
		ErrorReporterBridge.report_info(ERROR_CONTEXT, "LOOP playlist reshuffled (end reached)")
		_playlist.shuffle()
		_playlist_index = 0
	var track: String = _playlist[_playlist_index]
	_playlist_index += 1
	ErrorReporterBridge.report_info(ERROR_CONTEXT, "NEXT playlist next track [%d/%d]: '%s'" % [_playlist_index, _playlist.size(), track])
	play_music(track, false)
func _advance_playlist() -> void:
	if not _playlist_active:
		return
	_play_playlist_track()
func _on_voice_finished() -> void:
	if current_voice_stream == null:
		return
	current_voice_stream = null
	voice_stream_finished.emit()
