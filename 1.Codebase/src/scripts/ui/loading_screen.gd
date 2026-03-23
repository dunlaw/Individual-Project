extends Control
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
const ERROR_CONTEXT := "LoadingScreen"
const UIStyleManager := preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
@onready var progress_bar: ProgressBar = $CenterContainer/VBoxContainer/ProgressBar
@onready var loading_label: Label = $CenterContainer/VBoxContainer/LoadingLabel
@onready var tip_label: Label = $CenterContainer/VBoxContainer/TipLabel
@onready var spinner: Control = $CenterContainer/VBoxContainer/Spinner
var loading_tip_keys: Array[String] = [
	"LOADING_TIP_1",
	"LOADING_TIP_2",
	"LOADING_TIP_3",
	"LOADING_TIP_4",
	"LOADING_TIP_5",
	"LOADING_TIP_6",
	"LOADING_TIP_7",
]
var current_progress: float = 0.0
var target_progress: float = 0.0
var tip_rotation: float = 0.0
func _ready() -> void:
	_apply_styles()
	_show_random_tip()
	_start_spinner_animation()
	visible = false
func _apply_styles() -> void:
	if progress_bar:
		UIStyleManager.apply_progress_style(progress_bar, "accent")
		progress_bar.custom_minimum_size = Vector2(500, 30)
	if loading_label:
		loading_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
		loading_label.add_theme_font_size_override("font_size", 28)
	if tip_label:
		tip_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.95))
		tip_label.add_theme_font_size_override("font_size", 16)
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key)
	return key
func _report_info(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, message, details)
func _report_warning(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, message, details)
func _report_error(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, -1, false, details)
func show_loading(initial_text: String = "") -> void:
	if initial_text.is_empty():
		initial_text = _tr("LOADING_TEXT_DEFAULT")
	_report_info("Showing loading screen: '%s'" % initial_text)
	visible = true
	current_progress = 0.0
	target_progress = 0.0
	if progress_bar:
		progress_bar.value = 0.0
	if loading_label:
		loading_label.text = initial_text
	_show_random_tip()
	UIStyleManager.fade_in(self, 0.3)
func hide_loading() -> void:
	_report_info("Hiding loading screen")
	UIStyleManager.fade_out(self, 0.3)
	await get_tree().create_timer(0.3).timeout
	visible = false
func set_progress(value: float) -> void:
	target_progress = clamp(value, 0.0, 100.0)
func update_text(text: String) -> void:
	if loading_label:
		loading_label.text = text
func _process(delta: float) -> void:
	if not visible or not progress_bar:
		return
	var progress_speed: float = clampf(delta * 3.0, 0.0, 1.0)
	current_progress = lerp(current_progress, target_progress, progress_speed)
	if abs(target_progress - current_progress) < 0.5:
		current_progress = target_progress
	progress_bar.value = current_progress
	if spinner:
		tip_rotation = fmod(tip_rotation + delta * 180.0, 360.0)
		spinner.rotation_degrees = tip_rotation
func _show_random_tip() -> void:
	if tip_label and loading_tip_keys.size() > 0:
		var random_index: int = randi() % loading_tip_keys.size()
		tip_label.text = _tr(loading_tip_keys[random_index])
func _start_spinner_animation() -> void:
	if not spinner:
		return
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(spinner, "rotation", TAU, 1.0)
func add_tip(tip_key: String) -> void:
	if not tip_key.is_empty() and not loading_tip_keys.has(tip_key):
		loading_tip_keys.append(tip_key)
