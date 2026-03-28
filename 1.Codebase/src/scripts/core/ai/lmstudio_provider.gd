extends "res://1.Codebase/src/scripts/core/ai/ai_provider_base.gd"
class_name LMStudioProvider
const DEFAULT_ENDPOINT = "http://127.0.0.1:1234/v1/chat/completions"
const DEFAULT_MAX_TOKENS := 4096
const MAX_TOKENS_CAP := 8192
var host: String = "127.0.0.1"
var port: int = 1234
var model: String = ""
var http_request: HTTPRequest
var pending_callback: Callable
func _init():
	provider_name = "LMStudio"
func _get_error_context() -> String:
	return "LMStudioProvider"
func setup(http_req: HTTPRequest) -> void:
	http_request = http_req
func is_configured() -> bool:
	return not host.is_empty() and port > 0
func get_configuration() -> Dictionary:
	return {
		"host": host,
		"port": port,
		"model": model,
	}
func apply_configuration(config: Dictionary) -> void:
	if config.has("host"):
		host = str(config["host"])
	if config.has("port"):
		port = int(config["port"])
	if config.has("model"):
		model = str(config["model"])
func _get_endpoint() -> String:
	return "http://%s:%d/v1/chat/completions" % [host, port]
func send_request(messages: Array, callback: Callable, _options: Dictionary = {}) -> void:
	if not is_configured():
		_emit_error("LMStudio is not configured")
		_notify_callback_failure(callback, "LMStudio is not configured")
		return
	clear_debug_snapshot()
	is_requesting = true
	pending_callback = callback
	request_started.emit()
	var openai_messages = _messages_to_openai_format(messages)
	var max_tokens := _resolve_max_tokens(_options)
	var body: Dictionary = {
		"messages": openai_messages,
		"temperature": 0.7,
		"max_tokens": max_tokens,
		"stream": false,
	}
	if not model.is_empty():
		body["model"] = model
	if _options.has("response_mime_type") and _options["response_mime_type"] == "application/json":
		body["response_format"] = {"type": "json_object"}
	var headers = [
		"Content-Type: application/json",
	]
	var json_body = JSON.stringify(body)
	_store_debug_request("openai", _get_endpoint(), json_body, { "model": model })
	_emit_progress({"status": "sending", "body_bytes": json_body.length()})
	var error = http_request.request(_get_endpoint(), headers, HTTPClient.METHOD_POST, json_body)
	if error != OK:
		is_requesting = false
		var err_msg = "Failed to send LMStudio request: " + str(error)
		_emit_error(err_msg)
		_notify_callback_failure(callback, err_msg)
		request_completed.emit(false)
func cancel_request() -> void:
	is_requesting = false
	if http_request:
		http_request.cancel_request()
func parse_response(result: int, response_code: int, body: PackedByteArray) -> Dictionary:
	var body_text := body.get_string_from_utf8()
	_store_debug_response(response_code, body_text)
	if result != HTTPRequest.RESULT_SUCCESS:
		_report_error("Network error, result code: %s" % result)
		return {"success": false, "error": "Network error (code: %d). Is LMStudio running?" % result, "content": ""}
	if response_code != 200:
		var error_text = "HTTP %d" % response_code
		var json = JSON.new()
		if json.parse(body_text) == OK:
			var data = json.data
			if data is Dictionary and data.has("error"):
				var err = data["error"]
				if err is Dictionary and err.has("message"):
					error_text += ": " + str(err["message"])
				elif err is String:
					error_text += ": " + err
		_report_error("HTTP error: %s" % error_text)
		return {"success": false, "error": error_text, "content": ""}
	var json = JSON.new()
	if json.parse(body_text) != OK:
		_report_error("JSON parse error. Body preview: %s" % body_text.left(200))
		return {"success": false, "error": "JSON parse error", "content": ""}
	var response_data = json.data
	var ai_text := ""
	if response_data is Dictionary and response_data.has("choices") and response_data["choices"] is Array and response_data["choices"].size() > 0:
		var choice = response_data["choices"][0]
		if choice is Dictionary:
			if choice.has("message") and choice["message"] is Dictionary and choice["message"].has("content"):
				ai_text = str(choice["message"]["content"])
			elif choice.has("text"):
				ai_text = str(choice["text"])
	if ai_text.is_empty():
		_report_warning("Empty AI response. Response data keys: %s" % (response_data.keys() if response_data is Dictionary else "not a dict"))
	var response := {
		"success": not ai_text.is_empty(),
		"content": ai_text,
		"error": "" if not ai_text.is_empty() else "Empty response from AI provider",
		"audio_payloads": [],
	}
	if response_data.has("usage"):
		var usage = response_data["usage"]
		response["input_tokens"] = usage.get("prompt_tokens", 0)
		response["output_tokens"] = usage.get("completion_tokens", 0)
	return response
func _messages_to_openai_format(messages: Array) -> Array:
	var openai_messages: Array = []
	for msg in messages:
		if not msg is Dictionary:
			continue
		var role = str(msg.get("role", "user")).to_lower()
		if role == "model":
			role = "assistant"
		var content_text = ""
		if msg.has("parts") and msg["parts"] is Array:
			for part in msg["parts"]:
				if part is Dictionary:
					if part.has("text"):
						content_text += str(part["text"])
		elif msg.has("content"):
			content_text = str(msg["content"])
		if not content_text.is_empty():
			openai_messages.append({
				"role": role,
				"content": content_text
			})
	return openai_messages
func _notify_callback_failure(callback: Callable, message: String) -> void:
	if not callback.is_valid():
		return
	callback.call({
		"success": false,
		"error": message,
		"content": "",
	})
func _resolve_max_tokens(options: Dictionary) -> int:
	var requested := DEFAULT_MAX_TOKENS
	if options.has("max_tokens"):
		requested = int(options.get("max_tokens", DEFAULT_MAX_TOKENS))
	return clampi(requested, 1, MAX_TOKENS_CAP)
