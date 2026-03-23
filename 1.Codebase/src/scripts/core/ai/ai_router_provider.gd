extends "res://1.Codebase/src/scripts/core/ai/ai_provider_base.gd"
class_name AIRouterProvider
enum APIFormat {
	OPENAI = 0,
	CLAUDE = 1,
	GEMINI = 2,
}
const DEFAULT_HOST := "127.0.0.1"
const DEFAULT_PORT := 8046
const ANTHROPIC_VERSION := "2023-06-01"
const DEFAULT_MAX_TOKENS := 4096
const MAX_TOKENS_CAP := 8192
var host: String = DEFAULT_HOST
var port: int = DEFAULT_PORT
var api_key: String = ""
var model: String = ""
var api_format: APIFormat = APIFormat.OPENAI
var custom_endpoint: String = ""
var http_request: HTTPRequest
var pending_callback: Callable
func _init():
	provider_name = "AI Router"
func _get_error_context() -> String:
	return "AIRouterProvider"
func setup(http_req: HTTPRequest) -> void:
	http_request = http_req
func is_configured() -> bool:
	return not host.is_empty()
func get_configuration() -> Dictionary:
	return {
		"host": host,
		"port": port,
		"api_key": api_key,
		"model": model,
		"api_format": api_format,
		"custom_endpoint": custom_endpoint,
	}
func apply_configuration(config: Dictionary) -> void:
	if config.has("host"):
		host = str(config["host"])
	if config.has("port"):
		port = int(config["port"])
	if config.has("api_key"):
		api_key = str(config["api_key"])
	if config.has("model"):
		model = str(config["model"])
	if config.has("api_format"):
		api_format = int(config["api_format"])
	if config.has("custom_endpoint"):
		custom_endpoint = str(config["custom_endpoint"])
func _get_endpoint() -> String:
	var base_url := "http://%s:%d" % [host, port]
	if not custom_endpoint.is_empty():
		if custom_endpoint.begins_with("/"):
			return base_url + custom_endpoint
		else:
			return base_url + "/" + custom_endpoint
	match api_format:
		APIFormat.OPENAI:
			return base_url + "/v1/chat/completions"
		APIFormat.CLAUDE:
			return base_url + "/v1/messages"
		APIFormat.GEMINI:
			return base_url + "/v1/models/" + model + ":generateContent"
		_:
			return base_url + "/v1/chat/completions"
func send_request(messages: Array, callback: Callable, _options: Dictionary = {}) -> void:
	if not is_configured():
		_emit_error("AI Router is not configured")
		_notify_callback_failure(callback, "AI Router is not configured")
		return
	is_requesting = true
	pending_callback = callback
	request_started.emit()
	var endpoint := _get_endpoint()
	var headers: Array = []
	var json_body: String = ""
	match api_format:
		APIFormat.OPENAI:
			headers = _build_openai_headers()
			json_body = _build_openai_body(messages, _options)
		APIFormat.CLAUDE:
			headers = _build_claude_headers()
			json_body = _build_claude_body(messages, _options)
		APIFormat.GEMINI:
			headers = _build_gemini_headers()
			json_body = _build_gemini_body(messages, _options)
	_emit_progress({"status": "sending", "body_bytes": json_body.length(), "endpoint": endpoint})
	var error = http_request.request(endpoint, headers, HTTPClient.METHOD_POST, json_body)
	if error != OK:
		is_requesting = false
		var err_msg := "Failed to send AI Router request: " + str(error)
		_emit_error(err_msg)
		_notify_callback_failure(callback, err_msg)
		request_completed.emit(false)
func cancel_request() -> void:
	is_requesting = false
	if http_request:
		http_request.cancel_request()
func parse_response(result: int, response_code: int, body: PackedByteArray) -> Dictionary:
	if result != HTTPRequest.RESULT_SUCCESS:
		_report_error("Network error, result code: %s" % result)
		return {"success": false, "error": "Network error (code: %d)" % result, "content": ""}
	if response_code != 200:
		var error_text := "HTTP %d" % response_code
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var data = json.data
			if data is Dictionary and data.has("error"):
				var err = data["error"]
				if err is Dictionary and err.has("message"):
					error_text += ": " + str(err["message"])
				elif err is String:
					error_text += ": " + err
		_report_error("HTTP error: %s" % error_text)
		return {"success": false, "error": error_text, "content": ""}
	match api_format:
		APIFormat.OPENAI:
			return _parse_openai_response(body)
		APIFormat.CLAUDE:
			return _parse_claude_response(body)
		APIFormat.GEMINI:
			return _parse_gemini_response(body)
		_:
			return _parse_openai_response(body)
func _build_openai_headers() -> Array:
	var headers := [
		"Content-Type: application/json",
	]
	if not api_key.is_empty():
		headers.append("Authorization: Bearer " + api_key)
	return headers
func _build_openai_body(messages: Array, options: Dictionary) -> String:
	var openai_messages := _messages_to_openai_format(messages)
	var max_tokens := _resolve_max_tokens(options)
	var body := {
		"model": model,
		"messages": openai_messages,
		"temperature": 0.9,
		"max_tokens": max_tokens,
	}
	if options.has("response_mime_type") and options["response_mime_type"] == "application/json":
		body["response_format"] = {"type": "json_object"}
	return JSON.stringify(body)
func _messages_to_openai_format(messages: Array) -> Array:
	var openai_messages: Array = []
	for msg in messages:
		if not msg is Dictionary:
			continue
		var role = str(msg.get("role", "user")).to_lower()
		if role == "model":
			role = "assistant"
		var content_text := _get_message_text(msg)
		if not content_text.is_empty():
			openai_messages.append({
				"role": role,
				"content": content_text
			})
	return openai_messages
func _parse_openai_response(body: PackedByteArray) -> Dictionary:
	var json = JSON.new()
	var body_text := body.get_string_from_utf8()
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
	var response := {
		"success": not ai_text.is_empty(),
		"content": ai_text,
		"error": "" if not ai_text.is_empty() else "Empty response from AI Router",
		"audio_payloads": [],
	}
	if response_data.has("usage"):
		var usage = response_data["usage"]
		response["input_tokens"] = usage.get("prompt_tokens", 0)
		response["output_tokens"] = usage.get("completion_tokens", 0)
	return response
func _build_claude_headers() -> Array:
	var headers := [
		"Content-Type: application/json",
		"anthropic-version: " + ANTHROPIC_VERSION,
	]
	if not api_key.is_empty():
		headers.append("x-api-key: " + api_key)
	return headers
func _build_claude_body(messages: Array, options: Dictionary) -> String:
	var claude_messages := _messages_to_claude_format(messages)
	var system_prompt := _extract_system_prompt(messages)
	var body: Dictionary = {
		"model": model,
		"messages": claude_messages,
		"max_tokens": _resolve_max_tokens(options),
	}
	if not system_prompt.is_empty():
		body["system"] = system_prompt
	return JSON.stringify(body)
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
		var content_text := _get_message_text(msg)
		if not content_text.is_empty():
			claude_messages.append({
				"role": role,
				"content": content_text
			})
	return claude_messages
func _parse_claude_response(body: PackedByteArray) -> Dictionary:
	var json = JSON.new()
	var body_text := body.get_string_from_utf8()
	if json.parse(body_text) != OK:
		_report_error("JSON parse error. Body preview: %s" % body_text.left(200))
		return {"success": false, "error": "JSON parse error", "content": ""}
	var response_data = json.data
	var ai_text := ""
	if response_data is Dictionary and response_data.has("content") and response_data["content"] is Array:
		for content_block in response_data["content"]:
			if content_block is Dictionary and content_block.get("type") == "text":
				ai_text += str(content_block.get("text", ""))
	var response := {
		"success": not ai_text.is_empty(),
		"content": ai_text,
		"error": "" if not ai_text.is_empty() else "Empty response from AI Router",
		"audio_payloads": [],
	}
	if response_data.has("usage"):
		var usage = response_data["usage"]
		response["input_tokens"] = usage.get("input_tokens", 0)
		response["output_tokens"] = usage.get("output_tokens", 0)
	return response
func _build_gemini_headers() -> Array:
	var headers := [
		"Content-Type: application/json",
	]
	if not api_key.is_empty():
		headers.append("x-goog-api-key: " + api_key)
	return headers
func _build_gemini_body(messages: Array, options: Dictionary) -> String:
	var gemini_contents := _messages_to_gemini_format(messages)
	var body := {
		"contents": gemini_contents,
		"generationConfig": {
			"temperature": 0.9,
			"maxOutputTokens": _resolve_max_tokens(options),
		}
	}
	return JSON.stringify(body)
func _messages_to_gemini_format(messages: Array) -> Array:
	var gemini_contents: Array = []
	for msg in messages:
		if not msg is Dictionary:
			continue
		var role = str(msg.get("role", "user")).to_lower()
		if role == "assistant":
			role = "model"
		elif role == "system":
			role = "user"
		var content_text := _get_message_text(msg)
		if not content_text.is_empty():
			gemini_contents.append({
				"role": role,
				"parts": [{"text": content_text}]
			})
	return gemini_contents
func _parse_gemini_response(body: PackedByteArray) -> Dictionary:
	var json = JSON.new()
	var body_text := body.get_string_from_utf8()
	if json.parse(body_text) != OK:
		_report_error("JSON parse error. Body preview: %s" % body_text.left(200))
		return {"success": false, "error": "JSON parse error", "content": ""}
	var response_data = json.data
	var ai_text := ""
	if response_data is Dictionary and response_data.has("candidates") and response_data["candidates"] is Array:
		var candidates = response_data["candidates"]
		if candidates.size() > 0:
			var candidate = candidates[0]
			if candidate is Dictionary and candidate.has("content"):
				var content = candidate["content"]
				if content is Dictionary and content.has("parts") and content["parts"] is Array:
					for part in content["parts"]:
						if part is Dictionary and part.has("text"):
							ai_text += str(part["text"])
	var response := {
		"success": not ai_text.is_empty(),
		"content": ai_text,
		"error": "" if not ai_text.is_empty() else "Empty response from AI Router",
		"audio_payloads": [],
	}
	if response_data.has("usageMetadata"):
		var usage = response_data["usageMetadata"]
		response["input_tokens"] = usage.get("promptTokenCount", 0)
		response["output_tokens"] = usage.get("candidatesTokenCount", 0)
	return response
func _get_message_text(msg: Dictionary) -> String:
	var content_text := ""
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
static func get_api_format_name(format: APIFormat) -> String:
	match format:
		APIFormat.OPENAI:
			return "OpenAI"
		APIFormat.CLAUDE:
			return "Claude"
		APIFormat.GEMINI:
			return "Gemini"
		_:
			return "Unknown"
