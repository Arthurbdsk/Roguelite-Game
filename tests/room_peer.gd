extends SceneTree

var connection: RoomConnection
var host_mode: bool = false
var started: bool = false
var acknowledged: Dictionary = {}
var code_path: String = ""
var finish_at: float = -1
var age: float = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var room: String = ""
	var display_name: String = "Guest"
	for argument in OS.get_cmdline_user_args():
		if argument == "--host": host_mode = true
		if argument.begins_with("--code-file="): code_path = argument.trim_prefix("--code-file=")
		if argument.begins_with("--room="): room = argument.trim_prefix("--room=")
		if argument.begins_with("--name="): display_name = argument.trim_prefix("--name=")
	connection = RoomConnection.new()
	root.add_child(connection)
	connection.message_received.connect(receive)
	connection.connection_failed.connect(func(reason): printerr(reason); quit(1))
	connection.connect_room(host_mode, display_name, room)

func receive(message: Dictionary) -> void:
	match message.type:
		"joined":
			if host_mode:
				var file := FileAccess.open(code_path, FileAccess.WRITE)
				file.store_string(message.code)
				file.close()
		"lobby":
			if message.players.size() == 4:
				var all_ready: bool = true
				for player in message.players:
					all_ready = all_ready and player.ready
					if player.id == connection.peer_id and not player.ready:
						connection.send_message({"type": "ready", "ready": true})
				if host_mode and all_ready and not started:
					started = true
					connection.send_message({"type": "start"})
		"start":
			if host_mode:
				connection.send_message({"type": "event", "data": {"test": "host_event"}})
		"event":
			connection.send_message({"type": "action", "data": {"ack": true}})
			finish_at = age + 0.4
		"action":
			acknowledged[message.from] = true
			if acknowledged.size() == 3:
				finish_at = age + 0.1
		"error":
			printerr(message.reason)
			quit(1)

func _process(delta: float) -> bool:
	age += delta
	if finish_at >= 0 and age >= finish_at:
		print("GODOT_ROOM_PEER_PASS host=%s" % host_mode)
		quit(0)
	if age > 20:
		printerr("ROOM_PEER_TIMEOUT")
		quit(1)
	return false
