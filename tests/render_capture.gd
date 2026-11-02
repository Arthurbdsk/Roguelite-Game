extends SceneTree

var game

func _initialize() -> void:
	call_deferred("run")

func capture(filename: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png("res://test_output/" + filename + ".png")

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await capture("title")
	game.enter_hub()
	await capture("fortress")
	game.start_run()
	game.director.cooldown = 9999
	game.weapon_system.apply_upgrade("bolt")
	game.weapon_system.apply_upgrade("orbit")
	game.weapon_system.apply_upgrade("magnet")
	game.weapon_system.apply_upgrade("ward")
	game.elapsed = 546
	game.banner = "O REI SEM BRASA"
	for i in 26:
		var point: Vector2 = game.player.position + Vector2.from_angle(i * TAU / 26) * (85 + (i % 4) * 21)
		game.spawn_enemy(["ghoul", "hound", "guard"][i % 3], point)
	game.spawn_enemy("boss", game.player.position + Vector2(170, -54))
	game.add_hazard(game.player.position + Vector2(-50, 48), 42, 1.3, 24)
	game.weapon_system.update_combat(0.12)
	game.ui.update_hud(game.snapshot())
	await capture("arena")
	game.offers = game.weapon_system.get_offers()
	game.state = "upgrading"
	game.ui.render("upgrading", {"offers": game.offers})
	await capture("upgrades")
	game.ui.render("settings")
	await capture("settings")
	game.ui.render("result", {"won": true, "elapsed": 600, "kills": 412, "level": 18, "earned": 43})
	await capture("victory")
	game.queue_free()
	await process_frame
	await process_frame
	print("RENDER_CAPTURE_OK")
	quit()
