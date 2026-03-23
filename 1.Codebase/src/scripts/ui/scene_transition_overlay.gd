extends Control
signal transition_completed
@onready var background: ColorRect = $Background
@onready var content_container: Control = $CenterContainer
@onready var mission_title: Label = $CenterContainer/VBoxContainer/MissionTitle
@onready var stats_label: Label = $CenterContainer/VBoxContainer/StatsLabel
const FADE_IN_DURATION := 1.0
const HOLD_DURATION := 2.5
const FADE_OUT_DURATION := 1.0
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key)
	return key
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100
	modulate.a = 0.0
	content_container.modulate.a = 0.0
func setup(mission_number: int, previous_turns: int) -> void:
	var lang = GameState.current_language if GameState else "en"
	if lang == "en":
		mission_title.text = "Mission %d" % mission_number
		if previous_turns > 0:
			stats_label.text = "Previous mission resolved in %d turns" % previous_turns
		else:
			stats_label.text = "The journey begins..."
	else:
		mission_title.text = _tr("SCENE_TRANS_CHAPTER") % mission_number
		if previous_turns > 0:
			stats_label.text = _tr("SCENE_TRANS_PREV_TURNS") % previous_turns
		else:
			stats_label.text = _tr("SCENE_TRANS_JOURNEY_START")
func play_transition() -> void:
	visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, FADE_IN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(content_container, "modulate:a", 1.0, FADE_IN_DURATION * 0.8).set_delay(FADE_IN_DURATION * 0.2)
	tween.tween_interval(HOLD_DURATION)
	tween.tween_callback(_on_hold_finished)
func _on_hold_finished() -> void:
	if not _is_finishing:
		_show_loading_state()
func _show_loading_state() -> void:
	var lang = GameState.current_language if GameState else "en"
	stats_label.text = _tr("SCENE_TRANS_GENERATING_STORY")
var _is_finishing: bool = false
var _transition_in_tween: Tween = null
func play_transition_in() -> void:
	visible = true
	_transition_in_tween = create_tween()
	_transition_in_tween.tween_property(self, "modulate:a", 1.0, FADE_IN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_transition_in_tween.parallel().tween_property(content_container, "modulate:a", 1.0, FADE_IN_DURATION * 0.8).set_delay(FADE_IN_DURATION * 0.2)
	_transition_in_tween.tween_interval(HOLD_DURATION)
	_transition_in_tween.tween_callback(_on_hold_finished)
func finish_transition() -> void:
	_is_finishing = true
	if _transition_in_tween and _transition_in_tween.is_valid():
		_transition_in_tween.kill()
		_transition_in_tween = null
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
