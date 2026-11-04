class_name RoomConnection
extends Node

signal message_received(message: Dictionary)
signal connection_failed(reason: String)
var socket: WebSocketPeer
var pending: Dictionary = {}
var peer_id: String = ""
var host_id: String = ""
var code: String = ""
var players: Array = []
var connected: bool = false
var age: float = 0
var endpoint: String = ""
var last_close_code: int = 0
var last_close_reason: String = ""
var send_errors: int = 0
var previous_poll: int = 0
var max_poll_gap_ms: int = 0

func _ready() -> void:
	var config := ConfigFile.new()
	var candidates: Array[String] = ["res://network.cfg"]
	if not OS.has_feature("editor"): candidates.push_front(OS.get_executable_path().get_base_dir().path_join("network.cfg"))
	for path in candidates:
		if config.load(path) == OK:
			endpoint = str(config.get_value("relay", "url", ""))
			break
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--relay="):
			endpoint = argument.trim_prefix("--relay=")

func connect_room(create: bool, display_name: String, room_code: String = "", skills: Dictionary = {}) -> void:
	if endpoint.is_empty():
		connection_failed.emit("O serviço de salas ainda não foi publicado.")
		return
	close()
	pending = {"type": "create" if create else "join", "name": display_name.strip_edges(), "code": room_code.strip_edges().to_upper(), "skills": skills}
	pending.game_version=ProjectSettings.get_setting("application/config/version","0.5.0")
	socket = WebSocketPeer.new()
	socket.inbound_buffer_size = 1048576
	socket.outbound_buffer_size = 1048576
	socket.heartbeat_interval = 10
	age = 0
	send_errors = 0
	previous_poll = Time.get_ticks_msec()
	max_poll_gap_ms = 0
	log_connection("connect", {"endpoint": endpoint})
	if socket.connect_to_url(endpoint) != OK:
		connection_failed.emit("Não foi possível conectar ao serviço de salas.")

func send_message(message: Dictionary) -> bool:
	if socket != null and socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var error: Error = socket.send_text(JSON.stringify(message))
		if error == OK: return true
		send_errors += 1
		if send_errors == 1 or send_errors % 60 == 0: log_connection("send_error", {"error": error, "count": send_errors, "buffered": socket.get_current_outbound_buffered_amount()})
	return false

func log_connection(event: String, details: Dictionary) -> void:
	details = details.duplicate()
	details.event = event
	details.time = Time.get_datetime_string_from_system()
	var file := FileAccess.open("user://network_%d.log" % OS.get_process_id(), FileAccess.READ_WRITE if FileAccess.file_exists("user://network_%d.log" % OS.get_process_id()) else FileAccess.WRITE)
	if file != null:
		file.seek_end()
		file.store_line(JSON.stringify(details))

func _process(delta: float) -> void:
	if socket == null:
		return
	age += delta
	var now: int = Time.get_ticks_msec()
	max_poll_gap_ms = maxi(max_poll_gap_ms, now - previous_poll)
	previous_poll = now
	socket.poll()
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		connected = true
		if not pending.is_empty():
			send_message(pending)
			pending = {}
		var polled: WebSocketPeer = socket
		while socket == polled and polled.get_available_packet_count() > 0:
			var parsed = JSON.parse_string(socket.get_packet().get_string_from_utf8())
			if not parsed is Dictionary:
				continue
			if parsed.get("type") == "joined":
				peer_id = parsed.id
				host_id = parsed.host
				code = parsed.code
			if parsed.get("type") == "lobby":
				players = parsed.players
			message_received.emit(parsed)
	elif socket.get_ready_state() == WebSocketPeer.STATE_CLOSED or age > 12 and not connected:
		last_close_code = socket.get_close_code()
		last_close_reason = socket.get_close_reason()
		log_connection("closed", {"code": last_close_code, "reason": last_close_reason, "age": age, "send_errors": send_errors, "max_poll_gap_ms": max_poll_gap_ms})
		socket = null
		connected = false
		var explanation: String = "Rede ou túnel interrompido."
		match last_close_code:
			1000: explanation = "A conexão foi encerrada."
			1008: explanation = "Limite de mensagens do servidor."
			1009: explanation = "Pacote acima do limite do servidor."
			1013: explanation = "Conexão congestionada."
		connection_failed.emit("Conexão encerrada (%d). %s" % [last_close_code, explanation])

func close() -> void:
	if socket != null:
		send_message({"type": "leave"})
		socket.close()
	socket = null
	connected = false
	peer_id = ""
	host_id = ""
	code = ""
	players.clear()
