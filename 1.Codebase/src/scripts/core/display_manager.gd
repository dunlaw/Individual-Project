extends Node
signal window_size_changed(new_size: Vector2i)
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
const ERROR_CONTEXT := "DisplayManager"
const DEFAULT_WINDOW_SIZE: Vector2i = Vector2i(1920, 1080)
const MIN_WINDOW_SIZE: Vector2i = Vector2i(1024, 600)
var current_window_size: Vector2i
var base_resolution: Vector2i = Vector2i(1920, 1080)
func _report_info(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, message, details)
func _report_warning(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, message, details)
func _report_error(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, -1, false, details)
func _ready():
	current_window_size = DisplayServer.window_get_size()
	if current_window_size.x <= 0 or current_window_size.y <= 0:
		current_window_size = DEFAULT_WINDOW_SIZE
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	call_deferred("apply_settings_from_config")
	_report_info("Initialized. Current window size: %s" % current_window_size)
func _on_viewport_size_changed():
	var new_size = get_viewport().size
	if new_size != current_window_size:
		current_window_size = Vector2i(new_size)
		window_size_changed.emit(current_window_size)
		_report_info("Window size changed to: %s" % current_window_size)
func get_scale_factor() -> Vector2:
	var viewport_size = get_viewport().size
	return Vector2(
		float(viewport_size.x) / float(base_resolution.x),
		float(viewport_size.y) / float(base_resolution.y),
	)
func get_uniform_scale_factor() -> float:
	var scale = get_scale_factor()
	return min(scale.x, scale.y)
func apply_settings_from_config():
	if OS.has_feature("web"):
		current_window_size = Vector2i(DisplayServer.window_get_size())
		_report_info("Web build: skipping window mode/size apply.")
		return
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		var font_size: int = int(config.get_value("display", "font_size", 2))
		var window_mode: int = clampi(int(config.get_value("display", "mode", 0)), 0, 2)
		var stored_resolution: Variant = config.get_value("display", "resolution", DEFAULT_WINDOW_SIZE)
		var resolution: Vector2i = _coerce_resolution(stored_resolution, DEFAULT_WINDOW_SIZE)
		if FontManager:
			FontManager.set_font_size(font_size)
		var window := get_window()
		if _is_window_embedded(window):
			current_window_size = Vector2i(DisplayServer.window_get_size())
			_report_info("Display settings saved; skipping apply in embedded window mode.")
			return
		_apply_window_mode(window_mode, resolution)
		_report_info("Display settings applied: Font: %d, Mode: %d" % [font_size, window_mode])
	else:
		_ensure_windowed_with_titlebar()
func _apply_window_mode(mode: int, resolution: Vector2i) -> void:
	var safe_mode: int = clampi(mode, 0, 2)
	var safe_resolution: Vector2i = _coerce_resolution(resolution, DEFAULT_WINDOW_SIZE)
	var window := get_window()
	match safe_mode:
		0:
			if window:
				window.mode = Window.MODE_WINDOWED
				window.borderless = false
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			call_deferred("_apply_window_size_deferred", safe_resolution)
		1:
			if window:
				window.borderless = false
				window.mode = Window.MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			current_window_size = Vector2i(DisplayServer.window_get_size())
		2:
			if window:
				window.mode = Window.MODE_WINDOWED
				window.borderless = true
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			call_deferred("_apply_window_size_deferred", safe_resolution)
func _apply_window_size_deferred(resolution: Vector2i) -> void:
	var safe_resolution: Vector2i = _coerce_resolution(resolution, DEFAULT_WINDOW_SIZE)
	var window := get_window()
	if window:
		window.size = safe_resolution
	DisplayServer.window_set_size(safe_resolution)
	current_window_size = safe_resolution
func _is_window_embedded(window: Window) -> bool:
	if window and window.has_method("is_embedded"):
		return bool(window.call("is_embedded"))
	return false
func _coerce_resolution(value: Variant, fallback: Vector2i) -> Vector2i:
	var parsed: Vector2i = fallback
	if value is Vector2i:
		parsed = value
	elif value is Vector2:
		var as_vec2: Vector2 = value
		parsed = Vector2i(roundi(as_vec2.x), roundi(as_vec2.y))
	elif value is Array:
		var as_array: Array = value
		if as_array.size() >= 2:
			parsed = Vector2i(int(as_array[0]), int(as_array[1]))
	return Vector2i(
		maxi(parsed.x, MIN_WINDOW_SIZE.x),
		maxi(parsed.y, MIN_WINDOW_SIZE.y),
	)
func _ensure_windowed_with_titlebar() -> void:
	var window := get_window()
	if window:
		if window.borderless:
			window.borderless = false
			_report_info("Restored window title bar")
	else:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
func set_window_size(size: Vector2i):
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		var safe_size: Vector2i = _coerce_resolution(size, DEFAULT_WINDOW_SIZE)
		var window := get_window()
		if window:
			window.size = safe_size
		DisplayServer.window_set_size(safe_size)
		current_window_size = safe_size
func toggle_fullscreen():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
