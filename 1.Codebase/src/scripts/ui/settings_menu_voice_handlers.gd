extends RefCounted
class_name SettingsMenuVoiceHandlers
const SettingsMenuVoiceSectionScript = preload("res://1.Codebase/src/scripts/ui/settings_menu_voice_section.gd")
const VOICE_VOICE_NAMES := [
	"Aoede",
	"Callisto",
	"Elektra",
	"Orion",
	"Sol",
]
const VOICE_INPUT_MODE_LABELS := {
	0: "Push to talk",
	1: "Continuous",
}
const VOICE_CAPTURE_SECONDS := 4.0
var voice_enabled: bool = false
var voice_output_enabled: bool = false
var voice_input_enabled: bool = false
var voice_volume: float = 80.0
var voice_voice_name: String = "Aoede"
var voice_input_mode: int = 0
var voice_proactive_enabled: bool = false
var voice_supported: bool = false
var voice_capture_active: bool = false
var _get_ai_manager_fn: Callable       
var _get_audio_manager_fn: Callable    
var _apply_audio_settings_fn: Callable 
var _play_sfx_fn: Callable             
var _tr_fn: Callable                   
var _set_button_safely_fn: Callable    
var _availability_label: Label
var _enabled_check: CheckBox
var _options_box: VBoxContainer
var _output_check: CheckBox
var _input_check: CheckBox
var _voice_option: OptionButton
var _volume_slider: HSlider
var _volume_value: Label
var _input_mode_option: OptionButton
var _proactive_check: CheckBox
var _preview_button: Button
var _capture_button: Button
var _status_label: Label
func setup(
	get_ai_manager_fn: Callable,
	get_audio_manager_fn: Callable,
	apply_audio_settings_fn: Callable,
	play_sfx_fn: Callable,
	tr_fn: Callable,
	set_button_safely_fn: Callable,
) -> void:
	_get_ai_manager_fn      = get_ai_manager_fn
	_get_audio_manager_fn   = get_audio_manager_fn
	_apply_audio_settings_fn = apply_audio_settings_fn
	_play_sfx_fn            = play_sfx_fn
	_tr_fn                  = tr_fn
	_set_button_safely_fn   = set_button_safely_fn
func set_node_refs(refs: Dictionary) -> void:
	_availability_label = refs.get("availability_label")
	_enabled_check      = refs.get("enabled_check")
	_options_box        = refs.get("options_box")
	_output_check       = refs.get("output_check")
	_input_check        = refs.get("input_check")
	_voice_option       = refs.get("voice_option")
	_volume_slider      = refs.get("volume_slider")
	_volume_value       = refs.get("volume_value")
	_input_mode_option  = refs.get("input_mode_option")
	_proactive_check    = refs.get("proactive_check")
	_preview_button     = refs.get("preview_button")
	_capture_button     = refs.get("capture_button")
	_status_label       = refs.get("status_label")
func initialize(preloaded: Dictionary = {}) -> void:
	if not preloaded.is_empty():
		voice_enabled           = bool(preloaded.get("voice_enabled", voice_enabled))
		voice_output_enabled    = bool(preloaded.get("voice_output_enabled", voice_output_enabled))
		voice_input_enabled     = bool(preloaded.get("voice_input_enabled", voice_input_enabled))
		voice_volume            = float(preloaded.get("voice_volume", voice_volume))
		voice_voice_name        = String(preloaded.get("voice_voice_name", voice_voice_name))
		voice_input_mode        = int(preloaded.get("voice_input_mode", voice_input_mode))
		voice_proactive_enabled = bool(preloaded.get("voice_proactive_enabled", voice_proactive_enabled))
	if _voice_option:
		_voice_option.clear()
		for voice_name in VOICE_VOICE_NAMES:
			_voice_option.add_item(voice_name)
	if _input_mode_option:
		_input_mode_option.clear()
		for mode in VOICE_INPUT_MODE_LABELS.keys():
			_input_mode_option.add_item(VOICE_INPUT_MODE_LABELS[mode], mode)
	var audio_manager = _get_audio_manager_fn.call()
	if audio_manager:
		var audio_snapshot: Dictionary = audio_manager.get_volume_settings()
		voice_volume = float(audio_snapshot.get("voice_volume", voice_volume))
	var ai_manager = _get_ai_manager_fn.call()
	if ai_manager:
		var ai_voice_settings: Dictionary = ai_manager.get_voice_settings()
		voice_supported         = bool(ai_voice_settings.get("native_voice_supported", voice_supported))
		voice_enabled           = bool(ai_voice_settings.get("prefer_native_audio", voice_enabled))
		voice_output_enabled    = bool(ai_voice_settings.get("voice_output_enabled", voice_output_enabled))
		voice_input_enabled     = bool(ai_voice_settings.get("voice_input_enabled", voice_input_enabled))
		voice_voice_name        = String(ai_voice_settings.get("preferred_voice_name", voice_voice_name))
		voice_input_mode        = int(ai_voice_settings.get("voice_input_mode", voice_input_mode))
		voice_proactive_enabled = bool(ai_voice_settings.get("proactive_audio_enabled", voice_proactive_enabled))
		connect_ai_signals(ai_manager)
	if not voice_supported:
		voice_enabled        = false
		voice_output_enabled = false
		voice_input_enabled  = false
	if not SettingsMenuVoiceSectionScript.supports_proactive_audio(_get_ai_manager_fn.call()):
		voice_proactive_enabled = false
	if _volume_slider:
		_volume_slider.value = voice_volume
	_update_volume_display()
	if _voice_option:
		var voice_index := 0
		for i in range(_voice_option.item_count):
			if _voice_option.get_item_text(i) == voice_voice_name:
				voice_index = i
				break
		_voice_option.select(voice_index)
	if _input_mode_option:
		var selected_index := 0
		for i in range(_input_mode_option.item_count):
			if _input_mode_option.get_item_id(i) == voice_input_mode:
				selected_index = i
				break
		_input_mode_option.select(selected_index)
	_set_button_safely_fn.call(_proactive_check, voice_proactive_enabled)
	update_availability_label()
	sync_ui_state()
	if _status_label and not _status_label.text:
		_update_status("Voice idle.")
func connect_ai_signals(ai_manager: Node) -> void:
	if not ai_manager:
		return
	if not ai_manager.voice_capability_changed.is_connected(_on_voice_capability_changed):
		ai_manager.voice_capability_changed.connect(_on_voice_capability_changed)
	if not ai_manager.voice_audio_received.is_connected(_on_voice_audio_received):
		ai_manager.voice_audio_received.connect(_on_voice_audio_received)
	if not ai_manager.voice_input_buffer_ready.is_connected(_on_voice_input_buffer_ready):
		ai_manager.voice_input_buffer_ready.connect(_on_voice_input_buffer_ready)
	if not ai_manager.voice_transcription_ready.is_connected(_on_voice_transcription_ready):
		ai_manager.voice_transcription_ready.connect(_on_voice_transcription_ready)
	if not ai_manager.voice_transcription_failed.is_connected(_on_voice_transcription_failed):
		ai_manager.voice_transcription_failed.connect(_on_voice_transcription_failed)
func disconnect_ai_signals(ai_manager: Node) -> void:
	if not ai_manager:
		return
	if ai_manager.voice_capability_changed.is_connected(_on_voice_capability_changed):
		ai_manager.voice_capability_changed.disconnect(_on_voice_capability_changed)
	if ai_manager.voice_audio_received.is_connected(_on_voice_audio_received):
		ai_manager.voice_audio_received.disconnect(_on_voice_audio_received)
	if ai_manager.voice_input_buffer_ready.is_connected(_on_voice_input_buffer_ready):
		ai_manager.voice_input_buffer_ready.disconnect(_on_voice_input_buffer_ready)
	if ai_manager.voice_transcription_ready.is_connected(_on_voice_transcription_ready):
		ai_manager.voice_transcription_ready.disconnect(_on_voice_transcription_ready)
	if ai_manager.voice_transcription_failed.is_connected(_on_voice_transcription_failed):
		ai_manager.voice_transcription_failed.disconnect(_on_voice_transcription_failed)
func cancel_capture(ai_manager: Node) -> void:
	if voice_capture_active and ai_manager:
		ai_manager.cancel_voice_capture()
		voice_capture_active = false
func sync_ui_state() -> void:
	var supported := voice_supported
	var proactive_supported := SettingsMenuVoiceSectionScript.supports_proactive_audio(_get_ai_manager_fn.call())
	if voice_enabled and not supported:
		voice_enabled        = false
		voice_output_enabled = false
		voice_input_enabled  = false
	if not proactive_supported:
		voice_proactive_enabled = false
	if not (voice_enabled and supported):
		voice_capture_active = false
	_set_button_safely_fn.call(_enabled_check, voice_enabled and supported)
	_enabled_check.disabled = _get_ai_manager_fn.call() == null
	_options_box.visible    = voice_enabled and supported
	_set_button_safely_fn.call(_output_check, voice_output_enabled)
	_output_check.disabled = not (voice_enabled and supported)
	_set_button_safely_fn.call(_input_check, voice_input_enabled)
	_input_check.disabled = not (voice_enabled and supported)
	_volume_slider.editable    = voice_enabled and supported
	_volume_slider.focus_mode  = (
		Control.FOCUS_ALL if voice_enabled and supported else Control.FOCUS_NONE
	)
	_volume_slider.value = voice_volume
	_update_volume_display()
	var continuous_available := voice_enabled and supported and voice_input_enabled
	_input_mode_option.disabled = not continuous_available
	_set_button_safely_fn.call(_proactive_check, voice_proactive_enabled)
	_proactive_check.disabled  = not (voice_enabled and supported and voice_output_enabled and proactive_supported)
	if _proactive_check:
		_proactive_check.tooltip_text = "" if proactive_supported else "Gemini 3.1 Flash Live does not support proactive audio."
	_preview_button.disabled   = not (voice_enabled and supported and voice_output_enabled)
	_capture_button.disabled   = not (voice_enabled and supported and voice_input_enabled)
	_capture_button.text       = (
		_tr_fn.call("SETTINGS_CANCEL_CAPTURE")
		if voice_capture_active else
		_tr_fn.call("SETTINGS_CAPTURE_MIC_TEST")
	)
	_status_label.visible = voice_enabled and supported
	update_availability_label()
func update_availability_label() -> void:
	if not _availability_label:
		return
	_availability_label.text = SettingsMenuVoiceSectionScript.build_availability_text(
		_get_ai_manager_fn.call(), voice_supported
	)
func try_enable_native_audio() -> bool:
	voice_supported = SettingsMenuVoiceSectionScript.try_enable_gemini_native_audio(
		_get_ai_manager_fn.call()
	)
	update_availability_label()
	return voice_supported
func _update_volume_display() -> void:
	if _volume_value:
		_volume_value.text = "%d%%" % int(round(voice_volume))
func _update_status(message: String, is_error: bool = false) -> void:
	if not _status_label:
		return
	_status_label.text = message
	if is_error:
		_status_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	else:
		_status_label.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
func _apply_preferences() -> void:
	var ai_manager = _get_ai_manager_fn.call()
	if not ai_manager:
		return
	var prefs := SettingsMenuVoiceSectionScript.gather_preferences(
		voice_enabled, voice_output_enabled, voice_input_enabled,
		voice_voice_name, voice_input_mode, voice_proactive_enabled
	)
	ai_manager.apply_voice_settings(prefs)
	ai_manager.refresh_voice_capabilities()
	ai_manager.save_ai_settings()
	voice_supported = ai_manager.is_native_voice_supported()
	sync_ui_state()
func _on_voice_capability_changed(supported: bool) -> void:
	voice_supported = supported
	if not supported:
		voice_enabled        = false
		voice_output_enabled = false
		voice_input_enabled  = false
	update_availability_label()
	sync_ui_state()
	var state_text := "enabled" if supported else "disabled"
	_update_status("Native audio %s for current model." % state_text)
func _on_voice_audio_received(payload: Dictionary) -> void:
	if not (voice_enabled and voice_output_enabled):
		return
	var mime: String    = str(payload.get("mime_type", "audio/pcm"))
	var sample_rate := int(payload.get("sample_rate", 24000))
	_update_status("Received AI audio (%s @ %d Hz)." % [mime, sample_rate])
func _on_voice_input_buffer_ready(pcm: PackedByteArray, sample_rate: int, metadata: Dictionary) -> void:
	voice_capture_active = false
	var length_sec := float(metadata.get("length_seconds", float(pcm.size()) / max(sample_rate * 2, 1)))
	_update_status("Captured microphone sample (%.2f s @ %d Hz)." % [length_sec, sample_rate])
	sync_ui_state()
func _on_voice_transcription_ready(transcript: String, metadata: Dictionary) -> void:
	voice_capture_active = false
	var direction: String = str(metadata.get("direction", "output"))
	var label := "AI transcription" if direction == "output" else "Input transcription"
	_update_status("%s: %s" % [label, transcript])
	sync_ui_state()
func _on_voice_transcription_failed(reason: String) -> void:
	voice_capture_active = false
	_update_status("Voice transcription failed: %s" % reason, true)
	sync_ui_state()
func on_voice_enabled_toggled(button_pressed: bool) -> void:
	if button_pressed and not voice_supported:
		if try_enable_native_audio():
			_update_status("Native audio enabled.")
		else:
			_set_button_safely_fn.call(_enabled_check, false)
			_update_status("Current model does not support native audio.", true)
			return
	voice_enabled = button_pressed and voice_supported
	if not voice_enabled:
		voice_output_enabled = false
		voice_input_enabled  = false
	voice_capture_active = false
	_apply_preferences()
	sync_ui_state()
func on_voice_output_toggled(button_pressed: bool) -> void:
	if not (voice_enabled and voice_supported):
		_set_button_safely_fn.call(_output_check, false)
		_update_status("Enable native voice first.", true)
		return
	voice_output_enabled = button_pressed
	_apply_preferences()
	sync_ui_state()
func on_voice_input_toggled(button_pressed: bool) -> void:
	if not (voice_enabled and voice_supported):
		_set_button_safely_fn.call(_input_check, false)
		_update_status("Enable native voice first.", true)
		return
	voice_input_enabled = button_pressed
	if not voice_input_enabled:
		voice_capture_active = false
		var ai_manager = _get_ai_manager_fn.call()
		if ai_manager:
			ai_manager.cancel_voice_capture()
	_apply_preferences()
	sync_ui_state()
func on_voice_voice_option_selected(index: int) -> void:
	if _voice_option:
		voice_voice_name = _voice_option.get_item_text(index)
	_apply_preferences()
func on_voice_volume_changed(value: float) -> void:
	voice_volume = value
	_update_volume_display()
	_apply_audio_settings_fn.call()
func on_voice_input_mode_selected(index: int) -> void:
	if not _input_mode_option:
		return
	var selected_id: int = _input_mode_option.get_item_id(index)
	if selected_id == -1:
		selected_id = _input_mode_option.selected
	voice_input_mode = selected_id
	_apply_preferences()
func on_voice_proactive_toggled(button_pressed: bool) -> void:
	if not SettingsMenuVoiceSectionScript.supports_proactive_audio(_get_ai_manager_fn.call()):
		voice_proactive_enabled = false
		_set_button_safely_fn.call(_proactive_check, false)
		_update_status("Gemini 3.1 Flash Live does not support proactive audio.", true)
		return
	voice_proactive_enabled = button_pressed
	_apply_preferences()
func on_voice_preview_button_pressed() -> void:
	if not (voice_enabled and voice_supported and voice_output_enabled):
		_update_status("Enable native voice output to preview audio.", true)
		return
	var audio_manager = _get_audio_manager_fn.call()
	if not audio_manager:
		_update_status("AudioManager unavailable for preview.", true)
		return
	var ai_manager = _get_ai_manager_fn.call()
	if not ai_manager:
		_update_status("AI Manager unavailable for preview.", true)
		return
	var snapshot: Dictionary = ai_manager.get_state_snapshot()
	if not snapshot.is_empty() and not ai_manager:
		_update_status("No voice playback data available yet.", true)
		return
	if snapshot.has("stream") and snapshot["stream"]:
		audio_manager.play_voice_stream(snapshot["stream"])
		_update_status("Replaying most recent AI voice output.")
		return
	var pcm: PackedByteArray = snapshot.get("pcm", PackedByteArray())
	if pcm.is_empty():
		_update_status("No AI voice output captured yet.", true)
		return
	var sample_rate := int(snapshot.get("sample_rate", audio_manager.DEFAULT_VOICE_SAMPLE_RATE))
	audio_manager.play_voice_from_pcm(pcm, sample_rate)
	_update_status("Replaying buffered AI voice sample.")
func on_voice_capture_button_pressed() -> void:
	if voice_capture_active:
		var ai_manager = _get_ai_manager_fn.call()
		if ai_manager:
			ai_manager.cancel_voice_capture()
		voice_capture_active = false
		_update_status("Capture cancelled.")
		sync_ui_state()
		return
	if not (voice_enabled and voice_supported and voice_input_enabled):
		_update_status("Enable native voice input to capture audio.", true)
		return
	var ai_manager = _get_ai_manager_fn.call()
	if not ai_manager:
		_update_status("AI Manager unavailable for capture.", true)
		return
	voice_capture_active = true
	_update_status("Listening for %.1f seconds..." % VOICE_CAPTURE_SECONDS)
	sync_ui_state()
	ai_manager.request_voice_capture(VOICE_CAPTURE_SECONDS)
