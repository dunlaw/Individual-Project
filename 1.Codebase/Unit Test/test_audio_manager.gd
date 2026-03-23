extends Node
var tests_passed: int = 0
var tests_failed: int = 0
const TOL := 0.05
var _timer_fired: bool = false
func _ready() -> void:
	print("[AudioTest] Starting AudioManager tests…")
	await get_tree().process_frame
	_test_basics()
	await _test_mute_and_volumes()
	_test_volume_clamping()
	await _test_event_sfx_pooling()
	await _test_music_playback()
	await _test_non_blocking_under_load()
	print("[AudioTest] All checks executed.")
	queue_free()
func _test_basics() -> void:
	_assert(AudioManager != null, "AudioManager autoload missing")
	var settings: Dictionary = AudioManager.get_volume_settings()
	_assert(settings.has("master_volume"), "Missing master_volume in settings")
	_assert(settings.has("music_volume"), "Missing music_volume in settings")
	_assert(settings.has("sfx_volume"), "Missing sfx_volume in settings")
	_assert(settings.has("muted"), "Missing muted in settings")
	_assert(AudioManager.has_sound("gloria/zh/gloria_guilt_03"), "Missing zh Gloria WAV sound (gloria_guilt_03)")
	print("[AudioTest] Basics OK")
func _test_mute_and_volumes() -> void:
	AudioManager.set_muted(true)
	var s := AudioManager.get_volume_settings()
	_assert(s.muted == true, "Mute state not applied to AudioServer")
	if AudioManager.music_player:
		_assert(AudioManager.music_player.volume_db <= -60.0, "Music not silenced when muted")
	for p in AudioManager.sfx_players:
		_assert(p.volume_db <= -60.0, "SFX not silenced when muted")
	AudioManager.set_muted(false)
	AudioManager.set_master_volume(0.5)
	AudioManager.set_music_volume(0.4)
	AudioManager.set_sfx_volume(0.3)
	await get_tree().process_frame
	s = AudioManager.get_volume_settings()
	_assert(abs((s.master_volume / 100.0) - 0.5) <= TOL, "Master volume mismatch after set")
	_assert(abs((s.music_volume / 100.0) - 0.4) <= 0.1, "Music volume mismatch after set")
	_assert(abs((s.sfx_volume / 100.0) - 0.3) <= 0.1, "SFX volume mismatch after set")
	print("[AudioTest] Mute/volume toggles OK")
func _test_volume_clamping() -> void:
	AudioManager.set_master_volume(1.5)
	var s := AudioManager.get_volume_settings()
	_assert(abs((s.master_volume / 100.0) - 1.0) <= TOL, "Master volume not clamped to 1.0")
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx != -1:
		var actual_db = AudioServer.get_bus_volume_db(master_idx)
		var expected_db = linear_to_db(1.0)
		_assert(abs(actual_db - expected_db) <= TOL, "Master bus DB not clamped properly at max")
	AudioManager.set_master_volume(-0.5)
	s = AudioManager.get_volume_settings()
	_assert(abs((s.master_volume / 100.0) - 0.0) <= TOL, "Master volume not clamped to 0.0")
	if master_idx != -1:
		var actual_db = AudioServer.get_bus_volume_db(master_idx)
		_assert(actual_db <= -60.0 or actual_db <= linear_to_db(0.001), "Master bus DB not clamped properly at min")
	print("[AudioTest] Volume boundary clamping OK")
func _test_event_sfx_pooling() -> void:
	var t0 := Time.get_ticks_msec()
	AudioManager.play_sfx("menu_click")
	var t1 := Time.get_ticks_msec()
	_assert((t1 - t0) < 10, "play_sfx appears blocking")
	for i in range(AudioManager.MAX_SFX_PLAYERS + 4):
		AudioManager.play_sfx("happy_click")
	await get_tree().create_timer(0.1).timeout
	print("[AudioTest] Event-driven SFX and pooling OK")
func _test_music_playback() -> void:
	if not AudioManager.sounds.has("background_music"):
		print("[AudioTest] Skipping music test (no background_music asset)")
		return
	await AudioManager.stop_music(0.0)
	await get_tree().process_frame
	AudioManager.play_music("background_music", true)
	await get_tree().create_timer(0.05).timeout
	_assert(AudioManager.is_music_playing(), "Music did not start")
	_assert(AudioManager.get_current_music() == "background_music", "Unexpected current music name")
	await AudioManager.stop_music(0.1)
	await get_tree().process_frame
	_assert(not AudioManager.is_music_playing(), "Music did not stop after fade")
	print("[AudioTest] Music playback OK")
func _test_non_blocking_under_load() -> void:
	_timer_fired = false
	var timer := get_tree().create_timer(0.05)
	timer.timeout.connect(_on_timer_timeout)
	for i in range(0, 12):
		AudioManager.play_sfx("angry_click")
	await get_tree().process_frame
	await timer.timeout
	_assert(_timer_fired, "Timer blocked by audio activity")
	print("[AudioTest] Non-blocking under load OK")
func _on_timer_timeout() -> void:
	_timer_fired = true
func _assert(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
		print("    PASS  %s" % message)
	else:
		tests_failed += 1
		print("    FAIL  %s" % message)
