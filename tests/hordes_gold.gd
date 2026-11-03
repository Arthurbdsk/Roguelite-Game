extends SceneTree

var g
var checks: int = 0
var failures: int = 0
var metrics: Dictionary = {}
const STEP := 1.0 / 60.0

func _initialize() -> void:
	call_deferred("run")

func verify(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func fresh() -> void:
	g.start_run()
	g.director.phase = "complete"
	g.sound.volume = 0
	g.player.invulnerable = 10000

func run() -> void:
	if "--self-test" not in OS.get_cmdline_user_args():
		quit(2)
		return
	g = load("res://scenes/main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	g.balance = g.balance.duplicate(true)
	g.sound.volume = 0
	await test_skeletons()
	test_gold()
	test_persistence()
	await test_waves()
	await test_load()
	g.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	print("HORDES_GOLD_%s checks=%d failures=%d metrics=%s" % ["PASS" if failures == 0 else "FAIL", checks, failures, JSON.stringify(metrics)])
	var summary_path: String = "res://test_output/hordes_gold_summary.json" if OS.has_feature("editor") else "user://export_hordes_gold_summary.json"
	var output := FileAccess.open(summary_path, FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": checks, "failures": failures, "metrics": metrics}, "\t"))
	output.close()
	quit(0 if failures == 0 else 1)

func test_skeletons() -> void:
	fresh()
	var base_hp: float = g.enemy_data.ghoul.health
	var sword = g.spawn_enemy("skeleton_sword", g.player.position + Vector2(30, 0))
	verify(sword.hp > base_hp, "sword skeleton is tougher than basic ghoul")
	verify(sword.sprite.hframes == 6 and not sword.data.contact_damage, "sword has dedicated anticipation and attack frames, no contact damage")
	g.player.invulnerable = 0
	sword.attack_time = 0
	sword.tick(0.01)
	verify(sword.state == "prepare" and g.player.hp == 100, "sword telegraphs before damage")
	sword.tick(sword.data.windup - 0.01)
	verify(g.player.hp == 100, "sword preparation remains harmless")
	sword.tick(0.02)
	verify(g.player.hp == 88 and sword.state == "recovery", "one sword swing applies configured damage")
	g.player.invulnerable = 0
	for i in 20:
		sword.tick(0.01)
	verify(g.player.hp == 88, "sword cannot damage each frame during recovery")
	verify(sword.attack_time > 1, "sword has an independent attack cooldown")
	fresh()
	g.player.invulnerable = 0
	sword = g.spawn_enemy("skeleton_sword", g.player.position + Vector2(30, 0))
	sword.attack_time = 0
	sword.tick(0.01)
	g.player.position = sword.position + Vector2(0, -65)
	sword.tick(sword.data.windup + 0.01)
	verify(g.player.hp == 100, "moving out of the sword telegraph avoids its hit")
	fresh()
	var archer = g.spawn_enemy("skeleton_archer", g.player.position + Vector2(50, 0))
	archer.attack_time = 10
	await physics_frame
	archer.tick(STEP)
	verify(archer.velocity.x > 0, "archer retreats when the player is close")
	archer.position = g.player.position + Vector2(300, 0)
	archer.tick(STEP)
	verify(archer.velocity.x < 0, "archer approaches when beyond effective distance")
	archer.position = g.player.position + Vector2(170, 0)
	archer.attack_time = 0
	archer.tick(0.01)
	verify(archer.hp > base_hp and archer.state == "prepare", "archer has extra health and prepares its shot")
	verify(archer.velocity.length() < 0.1 and g.enemy_projectiles.arrows.is_empty(), "archer stops during warning and does not fire early")
	var locked: Vector2 = archer.charge_direction
	g.player.position += Vector2(0, 90)
	archer.tick(archer.data.windup + 0.01)
	verify(g.enemy_projectiles.arrows.size() == 1, "one preparation emits one arrow")
	verify(g.enemy_projectiles.arrows[0].velocity.normalized().is_equal_approx(locked), "arrow preserves its locked aim after player moves")
	verify(archer.attack_time > 2 and archer.state == "recovery", "archer enters recovery with configured shot interval")
	g.player.invulnerable = 0
	g.enemy_projectiles.tick(1.2)
	verify(g.player.hp == 100, "lateral movement dodges the fixed arrow")
	g.enemy_projectiles.tick(5)
	verify(g.enemy_projectiles.arrows.is_empty(), "arrows expire by configured lifetime")
	fresh()
	g.player.invulnerable = 0
	var data: EnemyData = g.enemy_data.skeleton_archer
	g.enemy_projectiles.fire(g.player.position + Vector2(100, 0), Vector2.LEFT, data)
	g.enemy_projectiles.tick(0.8)
	verify(g.player.hp == 90 and g.enemy_projectiles.arrows.is_empty(), "swept arrow collision deals damage and consumes projectile")
	g.player.invulnerable = 0
	g.enemy_projectiles.tick(1)
	verify(g.player.hp == 90, "consumed arrow cannot damage twice")
	var limited: EnemyData = data.duplicate()
	limited.arrow_range = 40
	limited.arrow_lifetime = 10
	g.enemy_projectiles.fire(g.player.position + Vector2(180, 0), Vector2.LEFT, limited)
	g.enemy_projectiles.tick(1)
	verify(g.enemy_projectiles.arrows.is_empty() and g.player.hp == 90, "arrows stop at their configured range")
	g.player.position = Vector2(740, 470)
	await physics_frame
	g.enemy_projectiles.fire(Vector2(650, 470), Vector2.RIGHT, data)
	g.enemy_projectiles.tick(1)
	verify(g.enemy_projectiles.arrows.is_empty() and g.player.hp == 90, "pillar blocks arrows before they hit a player behind it")
	verify(not g.enemy_projectiles.clear_shot(Vector2(650, 470), Vector2(740, 470)), "archer checks wall obstruction before preparing")
	fresh()
	var early = g.spawn_enemy("ghoul", Vector2(300, 300))
	g.elapsed = 9999
	g.level = 99
	var late = g.spawn_enemy("ghoul", Vector2(400, 300))
	verify(early.max_hp == late.max_hp and early.data.damage == late.data.damage, "time and player upgrades do not scale enemy health or damage")
	await process_frame

func test_gold() -> void:
	fresh()
	var count: int = 0
	for id in g.enemy_data:
		var at := Vector2(100 + count * 25, 150)
		var enemy = g.spawn_enemy(id, at)
		enemy.take_damage(99999)
		count += 1
		verify(g.gold_loot.coins.size() == count, "every enemy drops gold: " + id)
		verify(g.gold_loot.coins[-1].at == at and g.gold_loot.coins[-1].value >= 1, "gold appears at death position: " + id)
		enemy.take_damage(99999)
		verify(g.gold_loot.coins.size() == count, "dead enemies cannot drop a second coin: " + id)
	var elite = g.spawn_enemy("guard", Vector2(220, 150), true)
	elite.take_damage(99999)
	verify(g.gold_loot.coins.size() == count + 1, "elite also drops gold")
	var boss_rewards: int = g.boss_balance.executioner_reward + g.boss_balance.demon_reward * 2
	verify(g.gold == boss_rewards, "coin drops do not credit before arrival; only explicit boss rewards are immediate")
	g.gold_loot.tick(59.99)
	verify(g.gold_loot.coins.size() == count + 1, "coins remain until sixty seconds")
	g.toggle_pause()
	g.simulate(10)
	g.gold_loot.tick(10)
	verify(g.gold_loot.coins.size() == count + 1 and g.gold_loot.coins[0].age < 60, "pause freezes coin lifetime")
	g.toggle_pause()
	g.gold_loot.tick(0.02)
	verify(g.gold_loot.coins.is_empty() and g.gold == boss_rewards, "expired coins disappear without granting gold")
	fresh()
	g.gold_loot.drop(g.player.position + Vector2(40, 0), 3)
	g.gold_loot.tick(0.01)
	verify(g.gold_loot.coins[0].attracted and g.gold == 0, "coin starts attraction but does not credit on entering radius")
	g.gold_loot.tick(0.2)
	verify(g.gold == 3 and g.gold_loot.coins.is_empty(), "coin credits exact value only at arrival")
	g.gold_loot.tick(0.2)
	verify(g.gold == 3 and g.gold_loot.collected_count == 1, "collected coin cannot be counted twice")
	verify(not g.gold_loot.feedback.is_empty(), "gold arrival produces discreet visual feedback")
	g.gold_loot.drop(g.player.position, 5)
	g.gold_loot.coins[0].age = 59.99
	g.gold_loot.tick(0.02)
	verify(g.gold == 3, "expiration wins over simultaneous arrival")
	g.balance.coin_attraction_radius = 20
	g.balance.coin_collect_speed = 100
	g.balance.coin_value = 2
	g.gold_loot.drop(g.player.position + Vector2(30, 0), 1)
	g.gold_loot.tick(0.01)
	verify(not g.gold_loot.coins[0].attracted, "configured attraction radius is honored")
	g.player.position += Vector2(15, 0)
	var before: Vector2 = g.gold_loot.coins[0].at
	g.gold_loot.tick(0.01)
	verify(is_equal_approx(before.distance_to(g.gold_loot.coins[0].at), 1), "configured collection speed is honored")
	g.gold_loot.tick(0.2)
	verify(g.gold == 5, "configured gold value is honored")
	g.balance.coin_attraction_radius = 44
	g.balance.coin_collect_speed = 230
	g.balance.coin_value = 1

func test_persistence() -> void:
	var base_path: String = "user://gold_test_%d" % Time.get_ticks_usec()
	var old := GameProfile.new(base_path + "_v1.json")
	var fixture := FileAccess.open(old.path, FileAccess.WRITE)
	fixture.store_string(JSON.stringify({"version": 1, "seals": 21, "runs": 3, "wins": 1, "buildings": {"arsenal": true, "library": false}, "settings": {"volume": 0.3}}))
	fixture.close()
	verify(old.load_profile() and old.data.version == 3 and old.data.gold == 0, "version one migrates to current profile with zero gold")
	verify(old.data.seals == 21 and old.data.buildings.arsenal and old.data.settings.volume == 0.3, "migration preserves old currency, buildings and settings")
	var saved_profile = g.profile
	g.profile = GameProfile.new(base_path + "_actual.json")
	g.persistence_enabled = true
	fresh()
	g.gold = 11
	g.player.invulnerable = 0
	g.player.take_damage(99999, g.player.position)
	verify(g.state == "result" and g.profile.data.gold == 11, "death deposits collected gold")
	verify(g.ui.previous_data.gold == 11 and g.ui.previous_data.total_gold == 11, "result shows received gold and permanent total")
	var settled_id: String = g.run_id
	g.finish_run(false)
	g.enter_hub()
	verify(g.profile.data.gold == 11, "leaving and repeating result does not deposit twice")
	var loaded := GameProfile.new(g.profile.path)
	verify(loaded.load_profile() and loaded.data.gold == 11, "gold persists across profile reload")
	loaded.reward(0, 0, false, 0, 11, settled_id, 1)
	verify(loaded.data.gold == 11, "persisted run identifier prevents duplicate settlement")
	g.retry()
	verify(g.gold == 0 and g.profile.data.gold == 11, "new attempt resets run gold and preserves permanent balance")
	g.gold = 4
	g.retry()
	verify(g.profile.data.gold == 15 and g.gold == 0, "retry during a live run deposits gold once")
	g.gold = 6
	g.finish_run(true)
	verify(g.profile.data.gold == 21, "victory deposits collected gold")
	loaded = GameProfile.new(g.profile.path)
	verify(loaded.load_profile() and loaded.data.gold == 21, "new sessions restore accumulated gold")
	verify(FileAccess.file_exists(g.profile.path + ".bak"), "versioned gold save preserves previous profile backup")
	g.profile = saved_profile
	g.persistence_enabled = false

func test_waves() -> void:
	fresh()
	g.director.reset()
	var first = g.balance.waves[0]
	verify(first.count() == 8 and first.max_alive == 8, "first wave starts with few enemies")
	verify(g.balance.waves[2].composition.has("skeleton_sword"), "sword skeleton is introduced in wave three")
	verify(not g.balance.waves[3].composition.has("skeleton_archer") and g.balance.waves[4].composition.has("skeleton_archer"), "archers are introduced after melee in wave five")
	var last_count: int = 0
	var last_interval: float = 10
	var last_heavy: float = 0
	for wave in g.balance.waves:
		if wave.boss:
			verify(wave.composition.is_empty(), "final wave suspends normal reinforcement composition")
			continue
		verify(wave.count() > last_count, "wave quantity increases")
		verify(wave.spawn_interval <= last_interval and wave.spawn_interval >= g.balance.minimum_spawn_interval, "spawn intervals decrease within configured limit")
		var resistant: float = float(wave.composition.get("skeleton_sword", 0) + wave.composition.get("guard", 0)) / wave.count()
		verify(resistant >= last_heavy, "resistant share grows with wave composition")
		last_count = wave.count()
		last_interval = wave.spawn_interval
		last_heavy = resistant
	g.director.begin_wave()
	g.director.tick(0.5)
	verify(g.enemies.size() == 1 and g.director.phase == "active", "initial wave spawns gradually")
	var survivor = g.enemies[0]
	g.director.queue.clear()
	g.enemy_projectiles.fire(Vector2(200, 200), Vector2.RIGHT, g.enemy_data.skeleton_archer)
	g.director.tick(1)
	verify(g.director.phase == "active", "next wave waits for every remaining enemy")
	survivor.take_damage(99999)
	g.director.tick(STEP)
	verify(g.director.phase == "preparing" and g.director.preparation_left == g.balance.preparation_seconds, "clear starts configured preparation")
	verify(g.enemy_projectiles.arrows.is_empty(), "preparation clears lingering hostile projectiles")
	g.director.tick(g.balance.preparation_seconds - 0.1)
	verify(g.director.wave_index == 0, "preparation does not start the next wave early")
	g.director.tick(0.11)
	verify(g.director.wave_index == 1 and g.banner.begins_with("HORDA 2"), "next wave starts and announces its number")
	fresh()
	var sectors: Dictionary = {}
	for i in 24:
		verify(g.director.spawn("ghoul"), "director accepts safe distributed spawn")
		var enemy = g.enemies[-1]
		verify(not g.camera_rect().grow(g.balance.spawn_margin).has_point(enemy.position), "spawn is outside visible area")
		sectors[roundi((enemy.position - g.player.position).angle() / (TAU / 8))] = true
	verify(sectors.size() >= 6, "spawn directions cover multiple sectors")
	fresh()
	g.director.reset()
	var actual: Dictionary = {}
	var total: int = 1 # The executioner is scheduled by time, outside normal wave composition.
	for wave in g.balance.waves:
		total += wave.count()
	var steps: int = 0
	while g.state in ["running", "upgrading"] and steps < 15000:
		while g.state == "upgrading":
			g.choose_upgrade(g.offers[0].id)
		g.simulate(0.25)
		for enemy in g.enemies.duplicate():
			if not enemy.targetable:
				continue
			var key: String = "%d:%s:%s" % [g.director.wave_index, enemy.data.id, enemy.elite]
			actual[key] = int(actual.get(key, 0)) + 1
			enemy.take_damage(99999)
		steps += 1
		if steps % 30 == 0:
			await process_frame
	verify(g.state == "result" and g.ui.previous_data.won, "all ten cleared waves lead to victory")
	verify(g.kills == total and g.director.total_spawned == total, "wave traversal spawns exactly the defined total")
	for index in g.balance.waves.size():
		var wave = g.balance.waves[index]
		for id in wave.composition:
			verify(actual.get("%d:%s:false" % [index, id], 0) == wave.composition[id], "exact composition matches wave %d %s" % [index + 1, id])
		verify(actual.get("%d:guard:true" % index, 0) == wave.elite_guards, "elite quantity matches wave definition")
		verify(actual.get("%d:demon:false" % index, 0) == int(wave.boss), "boss quantity matches wave definition")
	metrics.wave_traversal = {"waves": g.director.wave_number(), "enemies": total, "steps": steps, "simulated_seconds": g.elapsed, "method": "Scheduled enemies are killed by test damage to verify exact counts and transitions, not balance."}

func test_load() -> void:
	fresh()
	g.weapon_system.levels = {"sword": 5, "bolt": 5, "orbit": 5}
	for i in 180:
		var angle: float = i * TAU / 180
		var enemy = g.spawn_enemy(["ghoul", "skeleton_sword", "skeleton_archer"][i % 3], g.player.position + Vector2.from_angle(angle) * 140)
		enemy.hp = 1000000
		enemy.max_hp = enemy.hp
		if enemy.data.behavior == "archer":
			enemy.attack_time = 0
	for i in 2000:
		g.gold_loot.drop(Vector2(100 + i % 50, 100 + i / 50))
	for i in 240:
		g.pickups.append({"at": Vector2(100 + i % 40, 200 + i / 40), "xp": 1, "attracted": false})
	for i in 320:
		g.enemy_projectiles.fire(Vector2(50, 50 + i % 30), Vector2.RIGHT, g.enemy_data.skeleton_archer)
	verify(not g.enemy_projectiles.fire(Vector2.ZERO, Vector2.RIGHT, g.enemy_data.skeleton_archer), "projectile budget rejects excess arrows")
	var cpu_us: int = 0
	for i in 240:
		await physics_frame
		var before: int = Time.get_ticks_usec()
		g.simulate(STEP)
		cpu_us += Time.get_ticks_usec() - before
		verify(g.enemies.size() <= g.balance.max_enemies and g.enemy_projectiles.arrows.size() <= g.balance.max_enemy_projectiles, "load budgets remain bounded")
	verify(g.enemies.size() == 180 and g.gold_loot.coins.size() == 2000, "full mixed crowd and two thousand uncollected coins coexist")
	for enemy in g.enemies:
		verify(enemy.position.is_finite(), "mixed crowd positions remain finite")
	verify(g.enemy_projectiles.arrows.size() < 320, "expired arrows are removed under load")
	var before_gold: int = g.gold
	g.gold_loot.tick(61)
	verify(g.gold_loot.coins.is_empty() and g.gold == before_gold, "bulk expiration removes coins without granting gold")
	metrics.load = {"physics_frames": 240, "enemies": 180, "coins": 2000, "experience_items": 240, "initial_arrows": 320, "cpu_ms": cpu_us / 1000.0, "method": "Headless real physics frames. CPU update time, not rendered FPS."}
