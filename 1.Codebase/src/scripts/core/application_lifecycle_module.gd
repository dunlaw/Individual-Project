extends RefCounted
const ERROR_CONTEXT := "ApplicationLifecycleModule"
const VERBOSE_LOGS := GameConstants.Debug.ENABLE_VERBOSE_LOGS
signal autosave_requested()
signal focus_lost()
signal focus_gained()
signal application_paused()
signal application_resumed()
signal application_closing()
var autosave_enabled: bool = true
var autosave_interval: float = 300.0
var _autosave_timer: float = 0.0
var settings: Dictionary = {
	"text_speed": 1.0,
	"screen_shake_enabled": true,
	"high_contrast_mode": false,
	"auto_advance_enabled": false,
	"trolley_ai_story_enabled": false,
}
func process_autosave(delta: float) -> bool:
	if not autosave_enabled:
		return false
	_autosave_timer += delta
	if _autosave_timer >= autosave_interval:
		_autosave_timer = 0.0
		return true
	return false
func reset_autosave_timer() -> void:
	_autosave_timer = 0.0
func handle_notification(what: int) -> void:
	match what:
		Node.NOTIFICATION_APPLICATION_PAUSED:
			on_application_paused()
		Node.NOTIFICATION_APPLICATION_RESUMED:
			on_application_resumed()
		Node.NOTIFICATION_WM_CLOSE_REQUEST:
			on_application_closing()
		Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			on_window_focus_lost()
		Node.NOTIFICATION_WM_WINDOW_FOCUS_IN:
			on_window_focus_gained()
func on_application_paused() -> void:
	application_paused.emit()
	if autosave_enabled:
		_debug_log("Application paused, requesting autosave")
		autosave_requested.emit()
func on_application_resumed() -> void:
	_debug_log("Application resumed")
	application_resumed.emit()
func on_application_closing() -> void:
	application_closing.emit()
	if autosave_enabled:
		_debug_log("Application closing, requesting final save")
		autosave_requested.emit()
func on_window_focus_lost() -> void:
	focus_lost.emit()
	if autosave_enabled:
		_debug_log("Window focus lost, requesting autosave")
		autosave_requested.emit()
func on_window_focus_gained() -> void:
	_debug_log("Window focus gained, game resumed")
	focus_gained.emit()
func get_setting(key: String, default_value: Variant = null) -> Variant:
	return settings.get(key, default_value)
func set_setting(key: String, value: Variant) -> void:
	settings[key] = value
func get_save_data() -> Dictionary:
	return {
		"autosave_enabled": autosave_enabled,
		"autosave_interval": autosave_interval,
		"settings": settings.duplicate(),
	}
func load_save_data(data: Dictionary) -> void:
	autosave_enabled = data.get("autosave_enabled", true)
	autosave_interval = data.get("autosave_interval", 300.0)
	var settings_data = data.get("settings", {})
	if settings_data is Dictionary:
		for key in settings_data:
			settings[key] = settings_data[key]
func _debug_log(message: String) -> void:
	if VERBOSE_LOGS:
		ErrorReporterBridge.report_info(ERROR_CONTEXT, message)
