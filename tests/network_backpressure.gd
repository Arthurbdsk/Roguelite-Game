extends SceneTree

class FailingConnection extends RoomConnection:
	var fail: bool = true
	var recorded: Array[Dictionary] = []
	func send_message(packet: Dictionary) -> bool:
		recorded.append(packet.duplicate(true))
		return not fail

var checks: int = 0
var failures: int = 0

func _initialize() -> void: call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + label)

func run() -> void:
	var game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.test_mode = true
	game.persistence_enabled = false
	game.sound.volume = 0
	var session: CoopSession = game.coop
	session.connection.queue_free()
	var connection := FailingConnection.new()
	session.add_child(connection)
	session.connection = connection
	connection.peer_id = "a"
	connection.host_id = "a"
	session.hosting = true
	session.begin({"run":"backpressure_fixture","players":[{"id":"a","name":"A","skills":{}}]})
	check(session.sent_entities.is_empty(), "failed initial snapshot does not advance baseline")
	connection.fail = false
	session.broadcast_state()
	check(session.sent_entities.has("a"), "successful retry establishes baseline")
	var enemy = game.spawn_enemy("ghoul",Vector2(1400,900))
	var enemy_id: String = "e" + str(enemy.serial)
	var coin_id: String = "c" + str(game.gold_loot.drop(Vector2(1400,950)))
	session.broadcast_state()
	check(session.sent_entities.has(enemy_id) and session.sent_entities.has(coin_id), "entities registered after successful send")
	connection.fail = true
	game.despawn_enemy(enemy)
	game.gold_loot.coins.clear()
	game.player.position += Vector2(20,0)
	session.broadcast_state()
	check(session.sent_entities.has(enemy_id) and session.sent_entities.has(coin_id), "failed deletion packet retains original baseline")
	connection.fail = false
	session.broadcast_state()
	var packet: Dictionary = connection.recorded.back()
	check(packet.data.removals.has(enemy_id) and packet.data.removals.has(coin_id), "retry preserves enemy and coin deletions")
	check(not session.sent_entities.has(enemy_id) and not session.sent_entities.has(coin_id), "baseline advances after retry only")
	connection.fail = true
	session.publish({"type":"progress","data":{"gold":12}})
	session.flush_events()
	check(session.outbox.size() == 1, "reliable events survive failed send")
	connection.fail = false
	session.flush_events()
	check(session.outbox.is_empty() and connection.recorded.back().type == "events", "reliable events retry successfully")
	var first_batch: int = connection.recorded.size()
	for i in 500: session.publish({"type":"chunk_fixture","index":i,"padding":"x".repeat(1024)})
	session.flush_events()
	check(not session.outbox.is_empty() and JSON.stringify(connection.recorded.back()).to_utf8_buffer().size() < 65536, "large pending queue is split below packet budget")
	while not session.outbox.is_empty(): session.flush_events()
	var indices: Array = []
	for emitted in connection.recorded.slice(first_batch):
		for entry in emitted.data: indices.append(entry.data.index)
	check(indices == range(500), "chunked reliable queue preserves order without loss or duplication")
	game.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.2).timeout
	print("NETWORK_BACKPRESSURE_%s checks=%d failures=%d" % ["PASS" if failures == 0 else "FAIL",checks,failures])
	quit(0 if failures == 0 else 1)
