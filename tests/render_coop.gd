extends SceneTree

var game

func _initialize() -> void: call_deferred("run")

func capture(name_value: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test_output/" + name_value + ".png")

func run() -> void:
	game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.test_mode = true
	game.persistence_enabled = false
	game.sound.volume = 0
	await capture("coop_title")
	game.open_online()
	await capture("coop_online")
	var session: CoopSession = game.coop
	session.connection.peer_id = "a"
	session.connection.host_id = "a"
	session.connection.code = "BRASA2"
	session.hosting = true
	var members: Array = [{"id":"a", "name":"Arthur", "skills": {}, "ready": true}, {"id":"b", "name":"Maya", "skills": {}, "ready": true}, {"id":"c", "name":"Davi", "skills": {}, "ready": false}, {"id":"d", "name":"Lia", "skills": {}, "ready": true}]
	session.connection.players = members
	game.ui.render("lobby")
	await capture("coop_lobby")
	session.begin({"run":"visual_fixture", "players":members})
	game.director.phase = "complete"
	game.player.position = Vector2(850,630)
	session.actors.b.player.position = Vector2(870,630)
	session.actors.c.player.position = Vector2(930,610)
	session.actors.d.player.position = Vector2(930,675)
	session.mark_down("b")
	session.revives.interactions = {"a": {"target":"b", "origin":game.player.position, "hp":100, "revision":0, "progress":2.7}}
	game.spawn_enemy("skeleton_sword", Vector2(1000,590))
	game.spawn_enemy("skeleton_archer", Vector2(1080,700))
	for i in 7: game.gold_loot.drop(Vector2(780+i*8, 685))
	game.banner = "HORDA 4  |  OSSOS NA NEBLINA"
	game.ui.update_hud(game.snapshot())
	await capture("coop_match")
	game.add_xp(6)
	session.open_upgrades()
	await capture("coop_upgrade")
	session.close_menu()
	game.toggle_pause()
	await capture("coop_pause")
	game.queue_free()
	await process_frame
	print("COOP_RENDER_PASS")
	quit()
