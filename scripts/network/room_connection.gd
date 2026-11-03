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

func _ready() -> void:
	var config := ConfigFile.new()
	if config.load("res://network.cfg") == OK:
		endpoint = config.get_value("relay", "url", "")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--relay="):
			endpoint = argument.trim_prefix("--relay=")

func connect_room(create: bool, display_name: String, room_code: String = "", skills: Dictionary = {}) -> void:
	if endpoint.is_empty():
		connection_failed.emit("Relay público não configurado. Consulte docs/MULTIPLAYER.md.")
		return
	close()
	pending = {"type": "create" if create else "join", "name": display_name.strip_edges(), "code": room_code.strip_edges().to_upper(), "skills": skills}
	socket = WebSocketPeer.new()
	socket.inbound_buffer_size = 1048576
	socket.outbound_buffer_size = 1048576
	socket.heartbeat_interval = 10
	age = 0
	if socket.connect_to_url(endpoint) != OK:
		connection_failed.emit("Não foi possível conectar ao serviço de salas.")

func send_message(message: Dictionary) -> void:
	if socket != null and socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.send_text(JSON.stringify(message))

func _process(delta: float) -> void:
	if socket == null:
		return
	age += delta
	socket.poll()
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		connected = true
		if not pending.is_empty():
			send_message(pending)
			pending = {}
		while socket.get_available_packet_count() > 0:
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
		socket = null
		connected = false
		connection_failed.emit("Conexão com o serviço de salas encerrada.")

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
