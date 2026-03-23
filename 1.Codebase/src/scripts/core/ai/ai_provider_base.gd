extends RefCounted
class_name AIProviderBase
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
signal request_started()
signal request_completed(success: bool)
signal request_progress(update: Dictionary)
signal request_error(message: String)
var provider_name: String = "BaseProvider"
var is_requesting: bool = false
const ERROR_CONTEXT := "AIProviderBase"
func send_request(_messages: Array, _callback: Callable, _options: Dictionary = { }) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, "send_request must be implemented by subclass")
func cancel_request() -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, "cancel_request must be implemented by subclass")
func is_configured() -> bool:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, "is_configured must be implemented by subclass")
	return false
func get_configuration() -> Dictionary:
	return { }
func apply_configuration(_config: Dictionary) -> void:
	pass
func _get_error_context() -> String:
	return ERROR_CONTEXT
func _report_info(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_info(_get_error_context(), message, details)
func _report_warning(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_warning(_get_error_context(), message, details)
func _report_error(message: String, error_code: int = -1, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_error(_get_error_context(), message, error_code, false, details)
func _emit_error(message: String) -> void:
	request_error.emit(message)
func _emit_progress(update: Dictionary) -> void:
	var progress_data := update.duplicate(true)
	progress_data["provider"] = provider_name
	request_progress.emit(progress_data)
