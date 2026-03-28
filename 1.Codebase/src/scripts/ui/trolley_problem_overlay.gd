extends Control
signal choice_selected(choice_id: String)
const ERROR_CONTEXT := "TrolleyProblemOverlay"
const TROLLEY_ON_SOUND := "trolley problem ON"
const TROLLEY_OFF_SOUND := "trolley problem OFF"
const TROLLEY_BGM := "trolley_problem_bgm"
@onready var scenario_label: RichTextLabel = $Root/ContentPanel/Margin/VBox/ScenarioText
@onready var choices_container: VBoxContainer = $Root/ContentPanel/Margin/VBox/ChoicesScroll/ChoicesContainer
@onready var title_label: Label = $Root/ContentPanel/Margin/VBox/Header/Title
@onready var subtitle_label: Label = $Root/ContentPanel/Margin/VBox/Header/Subtitle
@onready var thematic_label: RichTextLabel = $Root/ContentPanel/Margin/VBox/ThematicPoint
@onready var consequence_panel: PanelContainer = $Root/ContentPanel/Margin/VBox/ConsequencePanel
@onready var consequence_label: RichTextLabel = $Root/ContentPanel/Margin/VBox/ConsequencePanel/ConsequenceLabel
@onready var dilemma_icon: TextureRect = $Root/ContentPanel/Margin/VBox/Header/IconRow/DilemmaIcon
@onready var background_image: TextureRect = $BackgroundImage
var dilemma_data: Dictionary = {}
var _is_resolving: bool = false
var _choices_data: Array = []
var _playlist_was_active: bool = false
var _audio_manager: Node = null
var _audio_sequence_token: int = 0
var _overlay_music_started: bool = false
var _previous_music_name: String = ""
var _audio_restored: bool = false
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key)
	return key
func _ready() -> void:
	z_index = 200
	mouse_filter = Control.MOUSE_FILTER_STOP
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	var audio := _get_audio_manager()
	if audio and audio.has_method("play_sfx") and audio.has_method("has_sound") and audio.has_sound("heartbeat"):
		audio.play_sfx("heartbeat", 0.5)
	_audio_restored = false
	_start_overlay_audio()
	_animate_icon()
func _exit_tree() -> void:
	if _audio_restored:
		return
	_audio_sequence_token += 1
	var audio := _get_audio_manager()
	if not audio:
		return
	if audio.has_method("stop_sfx"):
		audio.stop_sfx(TROLLEY_ON_SOUND)
		audio.stop_sfx(TROLLEY_OFF_SOUND)
	if audio.has_method("get_current_music") and audio.has_method("stop_music"):
		if audio.get_current_music() == TROLLEY_BGM:
			audio.stop_music()
	_restore_normal_audio(audio)
func _animate_icon() -> void:
	if not dilemma_icon:
		return
	dilemma_icon.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var fade_tween := create_tween()
	fade_tween.tween_property(dilemma_icon, "modulate:a", 1.0, 0.8)
	await fade_tween.finished
	if not is_inside_tree():
		return
	var pulse_tween := create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(dilemma_icon, "scale", Vector2(1.06, 1.06), 1.2)
	pulse_tween.tween_property(dilemma_icon, "scale", Vector2(1.0, 1.0), 1.2)
func _get_audio_manager() -> Node:
	if is_instance_valid(_audio_manager):
		return _audio_manager
	if ServiceLocator and ServiceLocator.has_method("get_audio_manager"):
		_audio_manager = ServiceLocator.get_audio_manager()
	if _audio_manager == null and AudioManager:
		_audio_manager = AudioManager
	return _audio_manager
func _start_overlay_audio() -> void:
	var audio := _get_audio_manager()
	if not audio:
		return
	_audio_sequence_token += 1
	var token := _audio_sequence_token
	_playlist_was_active = audio.has_method("is_playlist_active") and audio.is_playlist_active()
	_previous_music_name = ""
	if audio.has_method("get_current_music"):
		_previous_music_name = audio.get_current_music()
	if audio.has_method("suspend_gameplay_playlist"):
		audio.suspend_gameplay_playlist()
	if audio.has_method("stop_music"):
		audio.stop_music(0.35)
	await get_tree().create_timer(0.35).timeout
	if not _is_audio_token_current(token):
		return
	await _play_sound_and_wait(audio, TROLLEY_ON_SOUND)
	if not _is_audio_token_current(token):
		return
	if is_inside_tree() and audio.has_method("play_music") and audio.has_method("has_sound"):
		if audio.has_sound(TROLLEY_BGM):
			audio.play_music(TROLLEY_BGM, true)
			_overlay_music_started = true
func _stop_overlay_audio() -> void:
	var audio := _get_audio_manager()
	if not audio:
		return
	_audio_sequence_token += 1
	var token := _audio_sequence_token
	if audio.has_method("stop_sfx"):
		audio.stop_sfx(TROLLEY_ON_SOUND)
	if audio.has_method("stop_music"):
		audio.stop_music(0.25 if _overlay_music_started else 0.0)
	if _overlay_music_started:
		await get_tree().create_timer(0.25).timeout
		if not _is_audio_token_current(token):
			return
	await _play_sound_and_wait(audio, TROLLEY_OFF_SOUND)
	if not _is_audio_token_current(token):
		return
	_overlay_music_started = false
	_restore_normal_audio(audio)
func _is_audio_token_current(token: int) -> bool:
	return token == _audio_sequence_token and is_inside_tree()
func _restore_normal_audio(audio: Node) -> void:
	if not audio:
		return
	_audio_restored = true
	if _playlist_was_active and audio.has_method("resume_gameplay_playlist"):
		audio.resume_gameplay_playlist()
	elif (
		not _previous_music_name.is_empty()
		and _previous_music_name != TROLLEY_BGM
		and audio.has_method("play_music")
		and audio.has_method("has_sound")
		and audio.has_sound(_previous_music_name)
	):
		audio.play_music(_previous_music_name, true)
const _SOUND_FALLBACK_DURATIONS := {
	"trolley problem ON": 3.5,
	"trolley problem OFF": 4.2,
}
func _play_sound_and_wait(audio: Node, sound_name: String, volume_multiplier: float = 1.0) -> void:
	if not audio or not audio.has_method("has_sound") or not audio.has_method("play_sfx"):
		return
	if not audio.has_sound(sound_name):
		return
	audio.play_sfx(sound_name, volume_multiplier)
	var sound_length := _get_sound_length(audio, sound_name)
	if sound_length <= 0.0:
		sound_length = _SOUND_FALLBACK_DURATIONS.get(sound_name, 0.0)
	if sound_length > 0.0:
		await get_tree().create_timer(sound_length).timeout
func _get_sound_length(audio: Node, sound_name: String) -> float:
	var sound_catalog = audio.get("sounds")
	if sound_catalog is Dictionary and sound_catalog.has(sound_name):
		var stream = sound_catalog[sound_name]
		if stream is AudioStream:
			return max(stream.get_length(), 0.0)
	return 0.0
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if _is_resolving:
		get_viewport().set_input_as_handled()
		return
	var kc := (event as InputEventKey).keycode
	match kc:
		KEY_1, KEY_KP_1:
			_try_keyboard_choice(0)
			get_viewport().set_input_as_handled()
		KEY_2, KEY_KP_2:
			_try_keyboard_choice(1)
			get_viewport().set_input_as_handled()
		KEY_3, KEY_KP_3:
			_try_keyboard_choice(2)
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			get_viewport().set_input_as_handled()
		_:
			get_viewport().set_input_as_handled()
func _try_keyboard_choice(index: int) -> void:
	if index < _choices_data.size():
		var choice_id: String = _choices_data[index].get("id", "")
		if not choice_id.is_empty():
			_resolve_choice(choice_id)
func setup(data: Dictionary) -> void:
	dilemma_data = data
	_choices_data = data.get("choices", [])
	var lang := GameState.current_language if GameState else "en"
	if title_label:
		title_label.text = _tr("TROLLEY_OVERLAY_MORAL_DILEMMA")
		_animate_title()
	if subtitle_label:
		var template: String = String(data.get("template_type", ""))
		subtitle_label.text = _get_template_label(template, lang)
	if scenario_label:
		var scenario: String = data.get("scenario", "")
		scenario_label.text = "[center]%s[/center]" % scenario
	if consequence_panel:
		consequence_panel.visible = false
	if thematic_label:
		var theme_text: String = data.get("thematic_point", "")
		if not theme_text.is_empty():
			var prefix := _tr("TROLLEY_OVERLAY_MORAL_WEIGHT")
			thematic_label.text = "[center][color=#888888][i]%s %s[/i][/color][/center]" % [prefix, theme_text]
			thematic_label.visible = true
		else:
			thematic_label.visible = false
	_create_choice_panels(_choices_data, lang)
func _get_template_label(template: String, lang: String) -> String:
	if lang == "zh":
		match template:
			"classic": return _tr("TROLLEY_TYPE_CLASSIC")
			"sacrifice": return _tr("TROLLEY_TYPE_SACRIFICE")
			"complicity": return _tr("TROLLEY_TYPE_COMPLICITY")
			"lesser_evil": return _tr("TROLLEY_TYPE_LESSER_EVIL")
			"positive_energy_trap": return _tr("TROLLEY_TYPE_POSITIVE_TRAP")
			_: return _tr("TROLLEY_TYPE_DEFAULT")
	else:
		match template:
			"classic": return "[ Classic Dilemma ]"
			"sacrifice": return "[ Sacrifice Dilemma ]"
			"complicity": return "[ Complicity Dilemma ]"
			"lesser_evil": return "[ Lesser Evil ]"
			"positive_energy_trap": return "[ Positive Energy Trap ]"
			_: return "[ Moral Conflict ]"
func _animate_title() -> void:
	if not title_label:
		return
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(title_label, "modulate", Color(1.0, 0.25, 0.1, 1.0), 0.7)
	tween.tween_property(title_label, "modulate", Color(1.0, 0.6, 0.15, 1.0), 0.7)
func _create_choice_panels(choices: Array, lang: String) -> void:
	if not choices_container:
		return
	for child in choices_container.get_children():
		child.queue_free()
	for i in choices.size():
		var panel := _build_choice_panel(choices[i], lang, i)
		choices_container.add_child(panel)
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 8)
		choices_container.add_child(spacer)
func _build_choice_panel(choice: Dictionary, lang: String, index: int) -> PanelContainer:
	var framing: String = choice.get("framing", "").to_lower()
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.set_border_width_all(2)
	match framing:
		"positive":
			style.bg_color = Color(0.04, 0.14, 0.04, 0.92)
			style.border_color = Color(0.25, 0.85, 0.25, 0.9)
		"honest":
			style.bg_color = Color(0.04, 0.04, 0.18, 0.92)
			style.border_color = Color(0.35, 0.55, 1.0, 0.9)
		"manipulative":
			style.bg_color = Color(0.18, 0.04, 0.12, 0.92)
			style.border_color = Color(0.9, 0.25, 0.55, 0.9)
		_:
			style.bg_color = Color(0.1, 0.1, 0.1, 0.92)
			style.border_color = Color(0.5, 0.5, 0.5, 0.8)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.mouse_entered.connect(_on_choice_hovered.bind(panel, true))
	panel.mouse_exited.connect(_on_choice_hovered.bind(panel, false))
	panel.gui_input.connect(_on_panel_gui_input.bind(choice.get("id", ""), panel))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)
	var header_row := HBoxContainer.new()
	header_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(header_row)
	var key_hint := Label.new()
	key_hint.text = "[%d]" % (index + 1)
	key_hint.add_theme_font_size_override("font_size", 13)
	key_hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.85))
	key_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key_hint.custom_minimum_size = Vector2(30, 0)
	header_row.add_child(key_hint)
	var badge := Label.new()
	badge.add_theme_font_size_override("font_size", 12)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	match framing:
		"positive":
			badge.text = "[+] " + (_tr("TROLLEY_OVERLAY_POSITIVE"))
			badge.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		"honest":
			badge.text = "[~] " + (_tr("TROLLEY_OVERLAY_HONEST"))
			badge.add_theme_color_override("font_color", Color(0.4, 0.65, 1.0))
		"manipulative":
			badge.text = "[!] " + (_tr("TROLLEY_OVERLAY_MANIPULATIVE"))
			badge.add_theme_color_override("font_color", Color(1.0, 0.3, 0.6))
		_:
			badge.text = "[?] " + (_tr("TROLLEY_OVERLAY_UNKNOWN"))
			badge.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	header_row.add_child(badge)
	var choice_text := Label.new()
	choice_text.text = "   " + choice.get("text", "Unknown Choice")
	choice_text.add_theme_font_size_override("font_size", 17)
	choice_text.add_theme_color_override("font_color", Color.WHITE)
	choice_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	choice_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_row.add_child(choice_text)
	var stat_changes: Dictionary = choice.get("stat_changes", {})
	if not stat_changes.is_empty():
		var stat_row := HBoxContainer.new()
		stat_row.add_theme_constant_override("separation", 16)
		stat_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(stat_row)
		_add_stat_chip(stat_row, _tr("TROLLEY_OVERLAY_REALITY"), stat_changes.get("reality", 0), true)
		_add_stat_chip(stat_row, _tr("TROLLEY_OVERLAY_PENERGY"), stat_changes.get("positive_energy", 0), false)
		_add_stat_chip(stat_row, _tr("TROLLEY_OVERLAY_ENTROPY"), stat_changes.get("entropy", 0), false)
	var immediate: String = choice.get("immediate_consequence", "")
	if not immediate.is_empty():
		var hint := Label.new()
		var trimmed: String = immediate.substr(0, 100) + ("..." if immediate.length() > 100 else "")
		hint.text = "→ " + trimmed
		hint.add_theme_font_size_override("font_size", 13)
		hint.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72))
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(hint)
	return panel
func _add_stat_chip(parent: HBoxContainer, stat_name: String, value: int, higher_is_good: bool) -> void:
	if value == 0:
		return
	var label := Label.new()
	var arrow := "▲" if value > 0 else "▼"
	label.text = "%s %s %d" % [arrow, stat_name, abs(value)]
	label.add_theme_font_size_override("font_size", 13)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var positive_outcome := (value > 0) == higher_is_good
	label.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3) if positive_outcome else Color(1.0, 0.35, 0.35))
	parent.add_child(label)
func _on_choice_hovered(panel: PanelContainer, entered: bool) -> void:
	var tween := create_tween()
	if entered:
		tween.tween_property(panel, "modulate", Color(1.15, 1.1, 1.05, 1.0), 0.12)
	else:
		tween.tween_property(panel, "modulate", Color.WHITE, 0.12)
func _on_panel_gui_input(event: InputEvent, choice_id: String, _panel: PanelContainer) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
		_resolve_choice(choice_id)
func _style_consequence_panel() -> void:
	if not consequence_panel:
		return
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.set_border_width_all(2)
	style.bg_color = Color(0.12, 0.08, 0.02, 0.93)
	style.border_color = Color(1.0, 0.67, 0.27, 0.85)
	style.set_content_margin_all(14)
	consequence_panel.add_theme_stylebox_override("panel", style)
func _resolve_choice(choice_id: String) -> void:
	if _is_resolving or choice_id.is_empty():
		return
	_is_resolving = true
	var audio := _get_audio_manager()
	if audio and audio.has_method("play_sfx") and audio.has_method("has_sound") and audio.has_sound("Zuruckbleiben bitte"):
		audio.play_sfx("Zuruckbleiben bitte")
	for child in choices_container.get_children():
		if child is PanelContainer:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lang := GameState.current_language if GameState else "en"
	var chosen: Dictionary = {}
	for c in _choices_data:
		if c.get("id", "") == choice_id:
			chosen = c
			break
	if not chosen.is_empty() and consequence_panel and consequence_label:
		var long_term: String = chosen.get("long_term_consequence", "")
		if not long_term.is_empty():
			var header := _tr("TROLLEY_OVERLAY_LONGTERM_CONSEQUENCE")
			consequence_label.text = "[color=#ffaa44][b]%s[/b][/color]\n%s" % [header, long_term]
			_style_consequence_panel()
			consequence_panel.modulate.a = 0.0
			consequence_panel.visible = true
			var fade := create_tween()
			fade.tween_property(consequence_panel, "modulate:a", 1.0, 0.4)
			await get_tree().create_timer(2.8).timeout
	await _stop_overlay_audio()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	await tween.finished
	choice_selected.emit(choice_id)
