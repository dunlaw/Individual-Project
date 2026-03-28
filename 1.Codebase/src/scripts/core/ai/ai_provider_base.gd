extends RefCounted
class_name AIProviderBase
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
signal request_started()
signal request_completed(success: bool)
signal request_progress(update: Dictionary)
signal request_error(message: String)
var provider_name: String = "BaseProvider"
var is_requesting: bool = false
var _last_debug_request: Dictionary = { }
var _last_debug_response: Dictionary = { }
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
func clear_debug_snapshot() -> void:
	_last_debug_request = { }
	_last_debug_response = { }
func get_debug_snapshot() -> Dictionary:
	return {
		"request": _last_debug_request.duplicate(true),
		"response": _last_debug_response.duplicate(true),
	}
func _store_debug_request(protocol: String, endpoint: String, body_text: String, extra: Dictionary = { }) -> void:
	_last_debug_request = {
		"protocol": protocol,
		"endpoint": _sanitize_endpoint(endpoint),
		"body": body_text,
		"captured_at": Time.get_datetime_string_from_system(),
	}
	for key in extra.keys():
		_last_debug_request[key] = extra[key]
func _store_debug_response(status_code: int, body_text: String, extra: Dictionary = { }) -> void:
	_last_debug_response = {
		"status_code": status_code,
		"body": body_text,
		"captured_at": Time.get_datetime_string_from_system(),
	}
	for key in extra.keys():
		_last_debug_response[key] = extra[key]
func _sanitize_endpoint(endpoint: String) -> String:
	if endpoint.is_empty():
		return endpoint
	var parts := endpoint.split("?", true, 1)
	if parts.size() < 2:
		return endpoint
	var base := parts[0]
	var query_items := parts[1].split("&", false)
	for i in range(query_items.size()):
		var item: String = query_items[i]
		var kv := item.split("=", true, 1)
		if kv.size() < 2:
			continue
		var key := kv[0].to_lower()
		if key in ["key", "api_key", "apikey", "token", "access_token"]:
			query_items[i] = kv[0] + "=[REDACTED]"
	return base + "?" + "&".join(query_items)
