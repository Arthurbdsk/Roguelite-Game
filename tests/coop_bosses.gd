extends SceneTree

var game
var checks: int = 0
var failures: int = 0

func _initialize() -> void: call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + label)

func fresh(kind: String):
	if game.coop.active: game.coop.leave()
	game.coop.connection.peer_id = "a"
	game.coop.connection.host_id = "a"
	game.coop.hosting = true
	game.coop.begin({"run":"boss_fixture", "players":[{"id":"a", "name":"A", "skills":{}},{"id":"b", "name":"B", "skills":{}},{"id":"c", "name":"C", "skills":{}},{"id":"d", "name":"D", "skills":{}}]})
	game.director.phase = "complete"
	game.player.position = Vector2(750,630)
	game.coop.actors.b.player.position = Vector2(450,350)
	game.coop.actors.c.player.position = Vector2(1300,350)
	game.coop.actors.d.player.position = Vector2(1300,900)
	for actor in game.coop.actors.values(): actor.weapon_system.levels = {"sword":0,"bolt":0,"orbit":0}
	return game.spawn_enemy(kind, Vector2(900,630))

func run() -> void:
	game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.test_mode = true
	game.persistence_enabled = false
	game.profile.data = game.profile.defaults()
	game.sound.volume = 0
	Engine.time_scale = 4
	Engine.physics_ticks_per_second = 240
	for kind in ["executioner", "demon"]:
		var boss = fresh(kind)
		await physics_frame
		game.simulate(1.0/60)
		check(is_equal_approx(boss.velocity.length(), (102.4 if kind == "executioner" else 112.0)*game.balance.enemy_speed_multiplier), "actual four-player chase speed: " + kind)
		for attack in (["execute", "charge"] if kind == "executioner" else ["charge"]):
			boss = fresh(kind)
			if attack == "execute": game.player.position = Vector2(840,630)
			boss.begin_attack(attack)
			game.coop.local_input_override = {"movement": Vector2.DOWN, "revive": false}
			var steps: int = 0
			while is_instance_valid(boss) and boss.state in ["windup", "charge"] and steps < 240:
				await physics_frame
				game.simulate(1.0/60)
				steps += 1
			check(game.player.hp == 100, "base-speed sideways movement avoids scaled attack: " + kind + " " + attack)
			check(boss.state == "recovery", "scaled attack exposes recovery: " + kind + " " + attack)
			print("COOP_BOSS_DODGE %s %s steps=%d hp=%.1f" % [kind,attack,steps,game.player.hp])
		game.coop.local_input_override.clear()
	var boss = fresh("executioner")
	boss.hp = boss.max_hp * 0.4
	await physics_frame
	game.simulate(1.0/60)
	check(is_equal_approx(boss.velocity.length(), 108.544*game.balance.enemy_speed_multiplier), "four-player enraged executioner retains requested speed multiplier")
	var fast=fresh("hound")
	game.player.position=Vector2(700,700);fast.position=Vector2(675,700)
	game.coop.local_input_override={"movement":Vector2.RIGHT,"revive":false}
	for i in 360:
		await physics_frame
		game.simulate(1.0/60)
	print("DIFFICULTY_RISK hound four-player speed=%.2f player=%.2f hp_after_6s=%.2f; straight retreat without attacks, initial gap 25px"%[fast.data.speed,game.player.speed,game.player.hp])
	game.coop.local_input_override.clear()
	# Spawn checks cover all four view rectangles even after the team splits.
	for actor in game.coop.actors.values(): actor.player.invulnerable = 100
	game.despawn_enemy(boss)
	game.boss = null
	for i in 32:
		check(game.director.spawn("ghoul"), "split-party spawn succeeds")
		var enemy = game.enemies.back()
		check(game.hidden_spawn(enemy.position, game.balance.spawn_margin), "spawn outside every living player's viewport")
	game.queue_free()
	await process_frame
	await process_frame
	Engine.time_scale = 1
	Engine.physics_ticks_per_second = 60
	print("COOP_BOSSES_%s checks=%d failures=%d" % ["PASS" if failures == 0 else "FAIL",checks,failures])
	quit(0 if failures == 0 else 1)
