extends Node
class_name LiveAPIClient
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
signal connection_established()
signal connection_closed(code: int, reason: String)
signal connection_error()
signal setup_response_received(response: Dictionary)
signal server_message_received(message: Dictionary)
signal error_received(error_message: String)
signal session_updated(session_handle: String)
const SERVICE_URL = "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent"
const ERROR_CONTEXT := "LiveAPIClient"
var websocket: WebSocketPeer = WebSocketPeer.new()
var is_connected: bool = false
var _is_setup_message_sent: bool = false
var _is_session_setup: bool = false
var _queued_history_turns: Array = []
var _queued_realtime_messages: Array = []
var _model_name: String
var _generation_config: Dictionary = {}
var _api_key: String
var _session_handle: String = ""
var _system_instruction: String = ""
var _speech_config: Dictionary = { }
var _transcription_config: Dictionary = {}
var _realtime_input_config: Dictionary = {}
func _process(_delta: float) -> void:
	if not is_connected:
		return
	websocket.poll()
	var state := websocket.get_ready_state()
	match state:
		WebSocketPeer.STATE_OPEN:
			if not _is_setup_message_sent:
				_setup_session()
				_is_setup_message_sent = true
				_on_setup_message_sent()
			while websocket.get_available_packet_count() > 0:
				_on_data_received()
		WebSocketPeer.STATE_CLOSING:
			pass
		WebSocketPeer.STATE_CLOSED:
			var code := websocket.get_close_code()
			var reason := websocket.get_close_reason()
			_on_connection_closed(code, reason)
func connect_to_server(
		model_name: String,
		api_key: String,
		config: Dictionary,
		session_handle: String = "",
		system_instruction: String = "",
		speech_config: Dictionary = { },
		transcription_config: Dictionary = { },
		realtime_input_config: Dictionary = { },
):
	_model_name = model_name
	_generation_config = config
	_api_key = api_key
	_session_handle = session_handle
	_system_instruction = system_instruction
	_speech_config = speech_config
	_transcription_config = transcription_config
	_realtime_input_config = realtime_input_config
	_queued_history_turns.clear()
	_queued_realtime_messages.clear()
	if is_connected or websocket.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		close_connection()
	var headers: PackedStringArray = [
		"x-goog-api-key: " + _api_key,
	]
	var url := SERVICE_URL + "?key=%s" % _api_key.uri_encode()
	if OS.get_name() != "Web":
		websocket.set_handshake_headers(headers)
	var err := websocket.connect_to_url(url)
	if err != OK:
		_on_connection_failed()
		return
	is_connected = true
	_is_setup_message_sent = false
	_is_session_setup = false
func close_connection(code: int = 1000, reason: String = "Client requested disconnect") -> void:
	if is_connected or websocket.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		websocket.close(code, reason)
		is_connected = false
		_is_setup_message_sent = false
		_is_session_setup = false
		_queued_history_turns.clear()
		_queued_realtime_messages.clear()
func seed_initial_history(turns: Array) -> void:
	_queued_history_turns = turns.duplicate(true)
func send_user_turn(parts: Array) -> void:
	if not is_connected or websocket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Attempted to send message while not connected")
		return
	if parts.is_empty():
		ErrorReporterBridge.report_error(ERROR_CONTEXT, "send_user_turn called with empty parts array")
		return
	var realtime_messages := _build_realtime_input_messages(parts)
	if realtime_messages.is_empty():
		ErrorReporterBridge.report_error(ERROR_CONTEXT, "Unable to convert user turn to realtime input messages")
		return
	if not _is_session_setup:
		_queued_realtime_messages = realtime_messages
		return
	_send_realtime_messages(realtime_messages)
func _on_connection_failed() -> void:
	ErrorReporterBridge.report_error(
		ERROR_CONTEXT,
		"Connection to %s failed" % SERVICE_URL,
		ErrorCodes.AI.NETWORK_ERROR,
		false,
		{ "service_url": SERVICE_URL },
	)
	is_connected = false
	_is_setup_message_sent = false
	_is_session_setup = false
	connection_error.emit()
func _on_connection_closed(code: int, reason: String) -> void:
	if is_connected:
		is_connected = false
		_is_setup_message_sent = false
		_is_session_setup = false
		connection_closed.emit(code, reason)
func _on_data_received() -> void:
	var packet := websocket.get_packet()
	if websocket.was_string_packet():
		var json := JSON.new()
		var text := packet.get_string_from_utf8()
		var err := json.parse(text)
		if err == OK:
			var data: Variant = json.data
			if data is Dictionary:
				_process_server_message(data)
			else:
				error_received.emit("Received non-dictionary JSON from server: " + text)
		else:
			error_received.emit("Failed to parse JSON from server: " + text)
	else:
		pass
func _process_server_message(data: Dictionary) -> void:
	if data.has("error"):
		var error_dict: Dictionary = data["error"]
		var error_msg := str(error_dict.get("message", "Unknown Live API error"))
		ErrorReporterBridge.report_error(
			ERROR_CONTEXT,
			"Received error from server: %s" % error_msg,
			ErrorCodes.AI.REQUEST_FAILED,
			false,
			{ "error_message": error_msg },
		)
		error_received.emit(error_msg)
		return
	if data.has("setupComplete") or data.has("setup_complete"):
		_is_session_setup = true
		setup_response_received.emit(data)
		_flush_queued_messages()
		return
	if data.has("sessionResumptionUpdate") or data.has("session_resumption_update"):
		var update_raw = data.get("sessionResumptionUpdate", data.get("session_resumption_update", {}))
		var update: Dictionary = update_raw if update_raw is Dictionary else {}
		var handle: String = str(update.get("newHandle", update.get("new_handle", "")))
		var resumable: bool = bool(update.get("resumable", update.get("resumable", false)))
		if not handle.is_empty() and resumable:
			session_updated.emit(handle)
	elif data.has("serverContent") or data.has("server_content"):
		server_message_received.emit(data)
	else:
		_is_session_setup = true
		setup_response_received.emit(data)
		_flush_queued_messages()
func _flush_queued_messages() -> void:
	if not is_connected or websocket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	if not _queued_history_turns.is_empty():
		var history_message := _build_client_content_message(_queued_history_turns)
		_queued_history_turns.clear()
		var history_err := websocket.send_text(JSON.stringify(history_message))
		if history_err != OK:
			ErrorReporterBridge.report_error(
				ERROR_CONTEXT,
				"Failed to send initial history message. Error: %s" % str(history_err),
				history_err,
				false,
				{ "error_code": history_err },
			)
			return
	if _queued_realtime_messages.is_empty():
		return
	var messages := _queued_realtime_messages.duplicate(true)
	_queued_realtime_messages.clear()
	_send_realtime_messages(messages)
func _setup_session() -> void:
	var generation_config := _generation_config.duplicate(true)
	generation_config["responseModalities"] = ["AUDIO"] if not _speech_config.is_empty() else ["TEXT"]
	if not _speech_config.is_empty():
		generation_config["speechConfig"] = _speech_config.duplicate(true)
	var setup_config: Dictionary = {
		"model": "models/" + _model_name,
		"generationConfig": generation_config,
		"sessionResumption": { },
	}
	if not _session_handle.is_empty():
		setup_config["sessionResumption"]["handle"] = _session_handle
	if not _system_instruction.is_empty():
		setup_config["systemInstruction"] = {
			"parts": [{ "text": _system_instruction }],
		}
	if bool(_transcription_config.get("input", false)):
		setup_config["inputAudioTranscription"] = { }
	if bool(_transcription_config.get("output", false)):
		setup_config["outputAudioTranscription"] = { }
	if not _realtime_input_config.is_empty():
		setup_config["realtimeInputConfig"] = _realtime_input_config.duplicate(true)
	if not _queued_history_turns.is_empty():
		setup_config["historyConfig"] = {
			"initialHistoryInClientContent": true,
		}
	var setup_message := _build_setup_message(setup_config)
	var err := websocket.send_text(JSON.stringify(setup_message))
	if err != OK:
		ErrorReporterBridge.report_error(
			ERROR_CONTEXT,
			"Failed to send setup message. Error: %s" % str(err),
			err,
			false,
			{ "error_code": err },
		)
		close_connection(1011, "Setup message failed")
func _build_setup_message(setup_config: Dictionary) -> Dictionary:
	return { "setup": setup_config }
func _build_client_content_message(turns: Array) -> Dictionary:
	return {
		"clientContent": {
			"turns": turns,
			"turnComplete": true,
		},
	}
func _build_realtime_input_messages(parts: Array) -> Array:
	var messages: Array = []
	var text_fragments: PackedStringArray = []
	for part in parts:
		if not (part is Dictionary):
			continue
		var part_dict: Dictionary = part
		if part_dict.has("text"):
			var text_value := str(part_dict.get("text", ""))
			if not text_value.is_empty():
				text_fragments.append(text_value)
			continue
		var inline_variant: Variant = part_dict.get("inlineData", part_dict.get("inline_data", null))
		if not (inline_variant is Dictionary):
			continue
		var inline_dict: Dictionary = inline_variant
		var mime_type := str(inline_dict.get("mimeType", inline_dict.get("mime_type", "")))
		var data_base64 := str(inline_dict.get("data", ""))
		if mime_type.is_empty() or data_base64.is_empty():
			continue
		if mime_type.begins_with("audio/"):
			messages.append({
				"realtimeInput": {
					"audio": {
						"mimeType": mime_type,
						"data": data_base64,
					},
				},
			})
			messages.append({
				"realtimeInput": {
					"audioStreamEnd": true,
				},
			})
		elif mime_type.begins_with("video/") or mime_type.begins_with("image/"):
			messages.append({
				"realtimeInput": {
					"video": {
						"mimeType": mime_type,
						"data": data_base64,
					},
				},
			})
	if not text_fragments.is_empty():
		messages.push_front({
			"realtimeInput": {
				"text": "".join(text_fragments),
			},
		})
	return messages
func _send_realtime_messages(messages: Array) -> void:
	for realtime_message in messages:
		var err := websocket.send_text(JSON.stringify(realtime_message))
		if err != OK:
			ErrorReporterBridge.report_error(
				ERROR_CONTEXT,
				"Failed to send realtime input message. Error: %s" % str(err),
				err,
				false,
				{ "error_code": err },
			)
			return
func _on_setup_message_sent() -> void:
	_report_info("Session setup message sent. Connection established.")
	connection_established.emit()
func _report_info(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, message, details)
func _report_warning(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, message, details)
func _report_error(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, -1, false, details)
