extends "res://1.Codebase/src/scripts/core/ai/ai_provider_base.gd"
class_name ClaudeProvider
const CLAUDE_ENDPOINT = "https://api.anthropic.com/v1/messages"
const ANTHROPIC_VERSION = "2023-06-01"
const DEFAULT_MAX_TOKENS := 4096
const MAX_TOKENS_CAP := 8192
var api_key: String = ""
var model: String = "claude-sonnet-4-5-20250929"
var http_request: HTTPRequest
var pending_callback: Callable
func _init():
	provider_name = "Claude"
func _get_error_context() -> String:
	return "ClaudeProvider"
func setup(http_req: HTTPRequest) -> void:
	http_request = http_req
func is_configured() -> bool:
	return not api_key.is_empty()
func get_configuration() -> Dictionary:
	return {
		"api_key": api_key,
		"model": model,
	}
func apply_configuration(config: Dictionary) -> void:
	if config.has("api_key"):
		api_key = str(config["api_key"])
	if config.has("model"):
		model = str(config["model"])
func send_request(messages: Array, callback: Callable, _options: Dictionary = {}) -> void:
	if not is_configured():
		_emit_error("Claude API key is not configured")
		_notify_callback_failure(callback, "Claude API key is not configured")
		return
	clear_debug_snapshot()
	is_requesting = true
	pending_callback = callback
	request_started.emit()
	var claude_messages = _messages_to_claude_format(messages)
	var system_prompt = _extract_system_prompt(messages)
	var body: Dictionary = {
		"model": model,
		"messages": claude_messages,
		"max_tokens": _resolve_max_tokens(_options),
	}
	if not system_prompt.is_empty():
		body["system"] = system_prompt
	var headers = [
		"Content-Type: application/json",
		"x-api-key: " + api_key,
		"anthropic-version: " + ANTHROPIC_VERSION,
	]
	var json_body = JSON.stringify(body)
	_store_debug_request("claude", CLAUDE_ENDPOINT, json_body, { "model": model })
	_emit_progress({"status": "sending", "body_bytes": json_body.length()})
	var error = http_request.request(CLAUDE_ENDPOINT, headers, HTTPClient.METHOD_POST, json_body)
	if error != OK:
		is_requesting = false
		var err_msg = "Failed to send Claude request: " + str(error)
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
		return {"success": false, "error": "Network error (code: %d)" % result, "content": ""}
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
	if response_data is Dictionary and response_data.has("content") and response_data["content"] is Array:
		for content_block in response_data["content"]:
			if content_block is Dictionary and content_block.get("type") == "text":
				ai_text += str(content_block.get("text", ""))
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
		response["input_tokens"] = usage.get("input_tokens", 0)
		response["output_tokens"] = usage.get("output_tokens", 0)
	return response
func _extract_system_prompt(messages: Array) -> String:
	for msg in messages:
		if not msg is Dictionary:
			continue
		var role = str(msg.get("role", "")).to_lower()
		if role == "system":
			return _get_message_text(msg)
	return ""
func _messages_to_claude_format(messages: Array) -> Array:
	var claude_messages: Array = []
	for msg in messages:
		if not msg is Dictionary:
			continue
		var role = str(msg.get("role", "user")).to_lower()
		if role == "system":
			continue
		if role == "model":
			role = "assistant"
		var content_text = _get_message_text(msg)
		if not content_text.is_empty():
			claude_messages.append({
				"role": role,
				"content": content_text
			})
	return claude_messages
func _get_message_text(msg: Dictionary) -> String:
	var content_text = ""
	if msg.has("parts") and msg["parts"] is Array:
		for part in msg["parts"]:
			if part is Dictionary:
				if part.has("text"):
					content_text += str(part["text"])
	elif msg.has("content"):
		content_text = str(msg["content"])
	return content_text
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
