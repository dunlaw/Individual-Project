extends Node
const AgentProtocol = preload("res://1.Codebase/src/scripts/core/agent/agent_protocol.gd")
const GameStateExporter = preload("res://1.Codebase/src/scripts/core/agent/game_state_exporter.gd")
const AgentActionExecutor = preload("res://1.Codebase/src/scripts/core/agent/agent_action_executor.gd")
const ERROR_CONTEXT := "GameAgentServer"
const VERBOSE_LOGS := GameConstants.Debug.ENABLE_VERBOSE_LOGS
signal agent_connected(peer_id: int, protocol: String)
signal agent_disconnected(peer_id: int)
signal action_received(peer_id: int, action: Dictionary)
var _tcp_server: TCPServer
var _ws_tcp_server: TCPServer
var _tcp_clients: Dictionary = {}  
var _ws_clients: Dictionary = {}   
var _pending_ws_connections: Dictionary = {}  
var _next_peer_id: int = 1
var _server_enabled: bool = false
var _ws_port: int = AgentProtocol.DEFAULT_WS_PORT
var _tcp_port: int = AgentProtocol.DEFAULT_TCP_PORT
var _auto_mode_enabled: bool = false
var _auto_mode_delay_ms: int = 2000
var _auto_mode_timer: float = 0.0
var _broadcast_on_change: bool = true
var _last_broadcast_state: String = ""
func _ready() -> void:
	_load_settings()
	if _server_enabled:
		start_servers()
func _load_settings() -> void:
	if ProjectSettings.has_setting("game/agent_server/enabled"):
		_server_enabled = ProjectSettings.get_setting("game/agent_server/enabled")
	if ProjectSettings.has_setting("game/agent_server/ws_port"):
		_ws_port = ProjectSettings.get_setting("game/agent_server/ws_port")
	if ProjectSettings.has_setting("game/agent_server/tcp_port"):
		_tcp_port = ProjectSettings.get_setting("game/agent_server/tcp_port")
func start_servers() -> void:
	_start_tcp_server()
	_start_ws_server()
	_server_enabled = true
	ErrorReporterBridge.report_info(ERROR_CONTEXT, "Started: TCP:%d, WebSocket:%d" % [_tcp_port, _ws_port])
func stop_servers() -> void:
	_stop_tcp_server()
	_stop_ws_server()
	_server_enabled = false
	ErrorReporterBridge.report_info(ERROR_CONTEXT, "Stopped")
func _start_tcp_server() -> void:
	if _tcp_server:
		_tcp_server.stop()
	_tcp_server = TCPServer.new()
	var error := _tcp_server.listen(_tcp_port)
	if error != OK:
		ErrorReporterBridge.report_error(
			ERROR_CONTEXT,
			"Failed to start TCP server",
			-1,
			false,
			{ "port": _tcp_port, "error": error_string(error) },
		)
		_tcp_server = null
func _stop_tcp_server() -> void:
	for peer_id in _tcp_clients.keys():
		_disconnect_tcp_client(peer_id)
	if _tcp_server:
		_tcp_server.stop()
		_tcp_server = null
func _start_ws_server() -> void:
	if _ws_tcp_server:
		_ws_tcp_server.stop()
	_ws_tcp_server = TCPServer.new()
	var error := _ws_tcp_server.listen(_ws_port)
	if error != OK:
		ErrorReporterBridge.report_error(
			ERROR_CONTEXT,
			"Failed to start WebSocket server",
			-1,
			false,
			{ "port": _ws_port, "error": error_string(error) },
		)
		_ws_tcp_server = null
func _stop_ws_server() -> void:
	for peer_id in _ws_clients.keys():
		_disconnect_ws_client(peer_id)
	_pending_ws_connections.clear()
	if _ws_tcp_server:
		_ws_tcp_server.stop()
		_ws_tcp_server = null
func _process(delta: float) -> void:
	if not _server_enabled:
		return
	_poll_tcp_server()
	_poll_ws_server()
	_poll_tcp_clients()
	_poll_ws_clients()
	_check_state_changes()
	_process_auto_mode(delta)
func _poll_tcp_server() -> void:
	if not _tcp_server or not _tcp_server.is_listening():
		return
	while _tcp_server.is_connection_available():
		var client := _tcp_server.take_connection()
		if client:
			var peer_id := _next_peer_id
			_next_peer_id += 1
			_tcp_clients[peer_id] = client
			_debug_log("TCP client connected: %d" % peer_id)
			_send_welcome(peer_id, "tcp")
			agent_connected.emit(peer_id, "tcp")
func _poll_ws_server() -> void:
	if not _ws_tcp_server or not _ws_tcp_server.is_listening():
		return
	while _ws_tcp_server.is_connection_available():
		var tcp_client := _ws_tcp_server.take_connection()
		if tcp_client:
			var ws := WebSocketPeer.new()
			_pending_ws_connections[tcp_client] = {
				"ws": ws,
				"state": "handshake"
			}
	var to_remove: Array = []
	for tcp_client in _pending_ws_connections.keys():
		var data = _pending_ws_connections[tcp_client]
		var ws: WebSocketPeer = data["ws"]
		if tcp_client.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			to_remove.append(tcp_client)
			continue
		tcp_client.poll()
		if tcp_client.get_available_bytes() > 0:
			var request: String = tcp_client.get_string(tcp_client.get_available_bytes())
			if _is_websocket_upgrade_request(request):
				var response := _create_websocket_upgrade_response(request)
				tcp_client.put_data(response.to_utf8_buffer())
				var peer_id := _next_peer_id
				_next_peer_id += 1
				_ws_clients[peer_id] = {"tcp": tcp_client, "ws": ws, "buffer": PackedByteArray()}
				to_remove.append(tcp_client)
				_debug_log("WebSocket client connected: %d" % peer_id)
				_send_welcome(peer_id, "websocket")
				agent_connected.emit(peer_id, "websocket")
	for tcp_client in to_remove:
		_pending_ws_connections.erase(tcp_client)
func _is_websocket_upgrade_request(request: String) -> bool:
	return "Upgrade: websocket" in request or "upgrade: websocket" in request
func _create_websocket_upgrade_response(request: String) -> String:
	var key := ""
	for line in request.split("\r\n"):
		if line.to_lower().begins_with("sec-websocket-key:"):
			key = line.split(":")[1].strip_edges()
			break
	if key.is_empty():
		return ""
	var magic := "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
	var accept_key := Marshalls.raw_to_base64(
		(key + magic).sha1_buffer()
	)
	return "HTTP/1.1 101 Switching Protocols\r\n" + \
		"Upgrade: websocket\r\n" + \
		"Connection: Upgrade\r\n" + \
		"Sec-WebSocket-Accept: " + accept_key + "\r\n\r\n"
func _poll_tcp_clients() -> void:
	var to_disconnect: Array[int] = []
	for peer_id in _tcp_clients.keys():
		var client: StreamPeerTCP = _tcp_clients[peer_id]
		client.poll()
		var status := client.get_status()
		if status != StreamPeerTCP.STATUS_CONNECTED:
			to_disconnect.append(peer_id)
			continue
		if client.get_available_bytes() > 0:
			var data := client.get_utf8_string(client.get_available_bytes())
			_process_tcp_message(peer_id, data)
	for peer_id in to_disconnect:
		_disconnect_tcp_client(peer_id)
func _poll_ws_clients() -> void:
	var to_disconnect: Array[int] = []
	for peer_id in _ws_clients.keys():
		var client_data: Dictionary = _ws_clients[peer_id]
		var tcp: StreamPeerTCP = client_data["tcp"]
		tcp.poll()
		if tcp.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			to_disconnect.append(peer_id)
			continue
		if tcp.get_available_bytes() > 0:
			var raw_data := tcp.get_data(tcp.get_available_bytes())
			if raw_data[0] == OK:
				var frame_data := raw_data[1] as PackedByteArray
				var message := _decode_websocket_frame(frame_data)
				if not message.is_empty():
					_process_ws_message(peer_id, message)
	for peer_id in to_disconnect:
		_disconnect_ws_client(peer_id)
func _decode_websocket_frame(data: PackedByteArray) -> String:
	if data.size() < 2:
		return ""
	var first_byte := data[0]
	var second_byte := data[1]
	var opcode := first_byte & 0x0F
	if opcode == 0x8:  
		return ""
	var masked := (second_byte & 0x80) != 0
	var payload_len := second_byte & 0x7F
	var offset := 2
	if payload_len == 126:
		if data.size() < 4:
			return ""
		payload_len = (data[2] << 8) | data[3]
		offset = 4
	elif payload_len == 127:
		offset = 10
		payload_len = 0
		for i in range(8):
			payload_len = (payload_len << 8) | data[2 + i]
	var mask_key := PackedByteArray()
	if masked:
		if data.size() < offset + 4:
			return ""
		mask_key = data.slice(offset, offset + 4)
		offset += 4
	if data.size() < offset + payload_len:
		return ""
	var payload := data.slice(offset, offset + payload_len)
	if masked:
		for i in range(payload.size()):
			payload[i] = payload[i] ^ mask_key[i % 4]
	return payload.get_string_from_utf8()
func _encode_websocket_frame(message: String) -> PackedByteArray:
	var payload := message.to_utf8_buffer()
	var frame := PackedByteArray()
	frame.append(0x81)  
	if payload.size() < 126:
		frame.append(payload.size())
	elif payload.size() < 65536:
		frame.append(126)
		frame.append((payload.size() >> 8) & 0xFF)
		frame.append(payload.size() & 0xFF)
	else:
		frame.append(127)
		for i in range(8):
			frame.append((payload.size() >> (56 - i * 8)) & 0xFF)
	frame.append_array(payload)
	return frame
func _process_tcp_message(peer_id: int, data: String) -> void:
	_process_message(peer_id, data, "tcp")
func _process_ws_message(peer_id: int, data: String) -> void:
	_process_message(peer_id, data, "websocket")
func _process_message(peer_id: int, data: String, protocol: String) -> void:
	var action_data := AgentProtocol.parse_action_message(data)
	if action_data.has("error"):
		_send_to_peer(peer_id, protocol, AgentProtocol.create_error("PARSE_ERROR", action_data["error"]))
		return
	action_received.emit(peer_id, action_data)
	var result := AgentActionExecutor.execute(action_data)
	_send_to_peer(peer_id, protocol, result)
func _send_welcome(peer_id: int, protocol: String) -> void:
	var welcome := AgentProtocol.create_welcome_message()
	_send_to_peer(peer_id, protocol, welcome)
	var state: Dictionary = GameStateExporter.export_full_state()
	var observation := AgentProtocol.create_observation(state)
	_send_to_peer(peer_id, protocol, observation)
func _send_to_peer(peer_id: int, protocol: String, data: Dictionary) -> void:
	var json := AgentProtocol.to_json(data)
	if protocol == "tcp" and _tcp_clients.has(peer_id):
		var client: StreamPeerTCP = _tcp_clients[peer_id]
		client.put_data((json + "\n").to_utf8_buffer())
	elif protocol == "websocket" and _ws_clients.has(peer_id):
		var client_data: Dictionary = _ws_clients[peer_id]
		var tcp: StreamPeerTCP = client_data["tcp"]
		var frame := _encode_websocket_frame(json)
		tcp.put_data(frame)
func _disconnect_tcp_client(peer_id: int) -> void:
	if _tcp_clients.has(peer_id):
		var client: StreamPeerTCP = _tcp_clients[peer_id]
		client.disconnect_from_host()
		_tcp_clients.erase(peer_id)
		_debug_log("TCP client disconnected: %d" % peer_id)
		agent_disconnected.emit(peer_id)
func _disconnect_ws_client(peer_id: int) -> void:
	if _ws_clients.has(peer_id):
		var client_data: Dictionary = _ws_clients[peer_id]
		var tcp: StreamPeerTCP = client_data["tcp"]
		tcp.disconnect_from_host()
		_ws_clients.erase(peer_id)
		_debug_log("WebSocket client disconnected: %d" % peer_id)
		agent_disconnected.emit(peer_id)
func broadcast_observation() -> void:
	var state: Dictionary = GameStateExporter.export_full_state()
	var observation := AgentProtocol.create_observation(state)
	for peer_id in _tcp_clients.keys():
		_send_to_peer(peer_id, "tcp", observation)
	for peer_id in _ws_clients.keys():
		_send_to_peer(peer_id, "websocket", observation)
func _check_state_changes() -> void:
	if not _broadcast_on_change:
		return
	var state: Dictionary = GameStateExporter.export_full_state()
	var state_json := JSON.stringify(state)
	if state_json != _last_broadcast_state:
		_last_broadcast_state = state_json
		broadcast_observation()
func _process_auto_mode(delta: float) -> void:
	if not _auto_mode_enabled:
		return
	_auto_mode_timer += delta * 1000.0
	if _auto_mode_timer < _auto_mode_delay_ms:
		return
	_auto_mode_timer = 0.0
	var choices: Array = GameStateExporter._get_available_choices()
	if choices.is_empty():
		return
	var random_choice: int = randi() % choices.size()
	var action_data := {
		"action": AgentProtocol.ACTION_SELECT_CHOICE,
		"params": {"choice_id": random_choice}
	}
	AgentActionExecutor.execute(action_data)
func set_auto_mode(enabled: bool, delay_ms: int = 2000) -> void:
	_auto_mode_enabled = enabled
	_auto_mode_delay_ms = delay_ms
	_auto_mode_timer = 0.0
	_debug_log("Auto mode: %s (delay: %dms)" % ["enabled" if enabled else "disabled", delay_ms])
func get_connected_count() -> int:
	return _tcp_clients.size() + _ws_clients.size()
func is_server_running() -> bool:
	return _server_enabled
func enable_server() -> void:
	if not _server_enabled:
		start_servers()
func disable_server() -> void:
	if _server_enabled:
		stop_servers()
func _debug_log(message: String) -> void:
	if VERBOSE_LOGS:
		ErrorReporterBridge.report_info(ERROR_CONTEXT, message)
