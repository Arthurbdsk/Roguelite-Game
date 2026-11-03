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
	game.elapsed = 146
	game.gold = 17
	game.director.wave_index = 4
	game.director.phase = "active"
	game.banner = "HORDA 5  |  CORDAS NA ESCURIDÃO"
	for i in 26:
		var point: Vector2 = game.player.position + Vector2.from_angle(i * TAU / 26) * (85 + (i % 4) * 21)
		var enemy = game.spawn_enemy(["ghoul", "skeleton_sword", "skeleton_archer", "hound", "skeleton_archer"][i % 5], point)
		if i % 5 == 2:
			enemy.state = "prepare"
			enemy.sprite.frame = 4
			enemy.charge_direction = (game.player.position - point).normalized()
	for i in 12:
		game.gold_loot.drop(game.player.position + Vector2.from_angle(i * TAU / 12) * 66)
		game.pickups.append({"at": game.player.position + Vector2.from_angle((i + 0.5) * TAU / 12) * 90, "xp": 2, "attracted": false})
	game.enemy_projectiles.fire(game.player.position + Vector2(115, 37), Vector2(-1, 0.25), game.enemy_data.skeleton_archer)
	game.enemy_projectiles.fire(game.player.position + Vector2(-125, -64), Vector2(1, 0.25), game.enemy_data.skeleton_archer)
	game.weapon_system.update_combat(0.12)
	game.ui.update_hud(game.snapshot())
	await capture("arena")
	game.offers = game.weapon_system.get_offers()
	game.state = "upgrading"
	game.ui.render("upgrading", {"offers": game.offers})
	await capture("upgrades")
	game.ui.render("settings")
	await capture("settings")
	game.ui.render("result", {"won": true, "elapsed": 906, "kills": 811, "level": 18, "earned": 43, "gold": 217, "total_gold": 439, "wave": 10})
	await capture("victory")
	game.queue_free()
	await process_frame
	await process_frame
	print("RENDER_CAPTURE_OK")
	quit()
