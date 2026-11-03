extends SceneTree

const MAIN = preload("res://scenes/main.tscn")
const ProfileScript = preload("res://scripts/core/profile.gd")
const STEP: float = 1.0 / 60.0

var g
var assertions: int = 0
var failures: int = 0
var metrics: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + label)


func _run() -> void:
	if not "--self-test" in OS.get_cmdline_user_args():
		printerr("Use -- --self-test to isolate progress and disable the live simulation.")
		quit(2)
		return
	g = MAIN.instantiate()
	root.add_child(g)
	await process_frame
	# Sound identity and output are checked in the interactive run. Keeping the
	# accelerated suite silent also avoids pending mixer playbacks at shutdown.
	g.sound.volume = 0.0
	check(g.test_mode, "integration uses isolated self-test mode")
	await _test_slice()
	if not g.slice_mode:
		_test_director()
		_test_boss_and_outcome()
		_test_profile()
		await _test_load()
		await _test_full_run()
	var mode: String = "slice" if g.slice_mode else "complete"
	g.clear_run()
	g.queue_free()
	g = null
	await process_frame
	await process_frame
	if failures == 0:
		print("INTEGRATION_PASS mode=%s assertions=%d metrics=%s" % [mode, assertions, JSON.stringify(metrics)])
	else:
		printerr("INTEGRATION_FAIL mode=%s failures=%d assertions=%d metrics=%s" % [mode, failures, assertions, JSON.stringify(metrics)])
	quit(0 if failures == 0 else 1)


func _test_slice() -> void:
	g.start_run()
	var permanent: Dictionary = g.profile.data.duplicate(true)
	check(g.state == "running" and g.player.hp == 100, "start run restores playable state")
	check(g.weapon_system.get_loadout().size() == 1, "basic slice starts with one weapon")
	g.director.cooldown = 10000.0
	var start: Vector2 = g.player.position
	for _i: int in 10:
		await physics_frame
		g.player.tick(STEP, Vector2.RIGHT)
	var straight: float = start.distance_to(g.player.position)
	check(straight > 10.0 and straight < 20.0, "WASD motion advances character through real physics frames")
	g.player.position = start
	await physics_frame
	for _i: int in 10:
		await physics_frame
		g.player.tick(STEP, Vector2.ONE.normalized())
	var diagonal: float = start.distance_to(g.player.position)
	check(absf(diagonal - straight) < 0.5, "diagonal movement is normalized")
	# This pillar has a 24x16 collider centered at 700,470.
	g.player.position = Vector2(665, 470)
	await physics_frame
	for _i: int in 20:
		await physics_frame
		g.player.tick(STEP, Vector2.RIGHT)
	check(g.player.position.x < 682.0 and g.player.position.x > 675.0, "visible pillar blocks player movement")
	g.player.position = start
	g.player.invulnerable = 0.0
	check(g.player.take_damage(12, start - Vector2.RIGHT * 20), "first contact applies damage")
	check(g.player.hp == 88.0, "damage reduces health")
	check(not g.player.take_damage(12, start), "consecutive contact blocked during invulnerability")
	check(g.player.hp == 88.0, "invulnerability prevents duplicate damage")
	g.player.invulnerable = 0.0
	g.player.take_damage(1000, start)
	check(g.state == "result" and not bool(g.ui.previous_data.get("won", true)), "zero life produces defeat")
	g.retry()
	check(g.state == "running" and g.player.hp == 100 and g.kills == 0, "retry restores health and score")
	g.director.cooldown = 10000.0
	g.player.invulnerable = 1000.0
	var target = g.spawn_enemy("ghoul", g.player.position + Vector2(30, 0))
	target.hp = 1.0
	var target_position: Vector2 = target.position
	g.weapon_system.timers["sword"] = 0.0
	g.simulate(STEP, Vector2.ZERO)
	check(g.kills == 1 and not target.alive, "automatic weapon kills a real enemy")
	check(not g.pickups.is_empty(), "enemy death drops experience")
	var dropped_xp: int = int(g.pickups[0]["xp"]) if not g.pickups.is_empty() else 0
	g.player.position = target_position
	g.update_pickups(STEP)
	check(g.xp == dropped_xp and g.pickups.is_empty(), "experience pickup transfers its exact value")
	g.add_xp(g.xp_needed - g.xp)
	check(g.state == "upgrading" and g.level == 2, "experience threshold opens level selection")
	check(g.offers.size() == 3, "level selection presents three offers")
	var ids: Dictionary = {}
	for offer: Dictionary in g.offers:
		ids[offer["id"]] = true
	check(ids.size() == 3, "level choices have distinct IDs")
	var frozen_time: float = g.elapsed
	var frozen_position: Vector2 = g.player.position
	g.simulate(1.0, Vector2.RIGHT)
	check(g.elapsed == frozen_time and g.player.position == frozen_position, "upgrade selection pauses simulation")
	g.choose_upgrade("invalid_offer")
	check(g.state == "upgrading", "invalid upgrade cannot unpause or alter the build")
	g.choose_upgrade(String(g.offers[0]["id"]))
	check(g.state == "running", "valid upgrade resumes the expedition")
	g.toggle_pause()
	frozen_time = g.elapsed
	g.simulate(1.0, Vector2.RIGHT)
	check(g.state == "paused" and g.elapsed == frozen_time, "pause freezes game time")
	g.toggle_pause()
	check(g.state == "running", "pause can resume")
	g.retry()
	check(g.level == 1 and g.xp == 0 and g.elapsed == 0 and g.enemies.is_empty(), "retry clears all temporary progression")
	check(g.weapon_system.passives.is_empty() and g.weapon_system.get_loadout().size() == 1, "retry clears temporary equipment upgrades")
	check(g.profile.data == permanent, "self-test leaves permanent progress untouched")
	await process_frame


func _test_director() -> void:
	g.start_run()
	g.director.rng.seed = 74281
	var successes: int = 0
	for corner: Vector2 in [Vector2(900, 630), Vector2(60, 60), Vector2(1740, 60), Vector2(60, 1140), Vector2(1740, 1140)]:
		g.player.position = corner
		var corner_spawns: int = 0
		for _attempt: int in 10:
			if g.director.spawn("ghoul"):
				var enemy = g.enemies.back()
				check(not g.camera_rect().grow(g.balance.spawn_margin).has_point(enemy.position), "director spawn remains outside camera plus margin")
				check(g.arena.safe_position(enemy.position, 20), "director spawn avoids obstacles and world edges")
				successes += 1
				corner_spawns += 1
		check(corner_spawns > 0, "director can reinforce each world corner")
	metrics["offscreen_spawns_checked"] = successes
	g.start_run()
	for _i: int in 180:
		g.spawn_enemy("ghoul", Vector2(100, 100))
	var accepted: bool = g.director.spawn("ghoul")
	check(not accepted and g.enemies.size() <= 180, "director enforces entity cap on direct spawn requests")
	g.elapsed = 540.0
	g.director.cooldown = 0.0
	g.director.tick(STEP)
	check(g.enemies.size() <= 180, "elite and boss scheduling respect the same entity cap")
	g.start_run()
	check(not g.director.boss_spawned and not g.director.elite_spawned, "restart resets one-time director events")


func _test_boss_and_outcome() -> void:
	g.start_run()
	g.elapsed = 540.0
	g.director.cooldown = 10000.0
	g.director.elite_spawned = true
	g.director.boss_spawned = true
	g.player.invulnerable = 0.0
	var enemy = g.spawn_enemy("boss", g.player.position + Vector2(140, 0))
	enemy.attack_time = 0.0
	g.rebuild_grid()
	enemy.tick(STEP)
	check(g.hazards.size() == 7, "boss creates one aimed warning and six surrounding warnings")
	var aimed_at: Vector2 = g.hazards[0]["at"] if not g.hazards.is_empty() else Vector2.ZERO
	var health: float = g.player.hp
	g.update_hazards(0.5)
	check(g.player.hp == health, "boss warning does not damage before its timer")
	g.player.position += Vector2(0, 175)
	enemy.tick(STEP)
	check(Vector2(g.hazards[0]["at"]) == aimed_at, "boss telegraph locks impact position instead of tracking movement")
	g.update_hazards(1.0)
	check(g.player.hp == health, "moving out of the marked area avoids the boss strike")
	enemy.take_damage(10000.0)
	check(g.boss_defeated and g.boss == null, "boss death records the victory prerequisite")
	check(g.state == "running", "killing boss early does not skip remaining survival time")
	g.director.wave_index = g.balance.waves.size() - 1
	g.director.phase = "active"
	g.director.queue.clear()
	g.simulate(STEP)
	check(g.state == "result" and bool(g.ui.previous_data.get("won", false)), "clearing final wave after boss death yields victory")
	var reward: int = g.banked_reward
	g.finish_run(true)
	check(g.banked_reward == reward, "result cannot settle rewards twice")
	g.start_run()
	g.director.cooldown = 10000.0
	g.director.elite_spawned = true
	g.director.boss_spawned = true
	g.director.wave_index = g.balance.waves.size() - 1
	g.director.phase = "active"
	g.director.queue.clear()
	g.simulate(STEP)
	check(g.state == "result" and not bool(g.ui.previous_data.get("won", true)), "clearing final wave without defeating its boss cannot grant victory")


func _write(path: String, content: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(content)
		file.close()
	else:
		check(false, "test fixture file can be written")


func _test_profile() -> void:
	var prefix: String = "user://integration_test_%d" % Time.get_ticks_usec()
	var missing = ProfileScript.new(prefix + "_missing.json")
	check(not missing.load_profile() and missing.data["seals"] == 0, "missing save produces safe defaults")
	var invalid_path: String = prefix + "_invalid.json"
	_write(invalid_path, "{ invalid save")
	var invalid = ProfileScript.new(invalid_path)
	check(not invalid.load_profile() and invalid.data["seals"] == 0, "invalid JSON produces safe defaults")
	check(FileAccess.get_file_as_string(invalid_path) == "{ invalid save", "corrupted save is preserved")
	var future_path: String = prefix + "_future.json"
	_write(future_path, JSON.stringify({"version": 999, "seals": 200}))
	var future = ProfileScript.new(future_path)
	check(not future.load_profile() and future.data["seals"] == 0, "unknown save version is rejected")
	var shape_path: String = prefix + "_shape.json"
	_write(shape_path, JSON.stringify({"version": 1, "seals": {}, "settings": {"volume": []}}))
	var bad_shape = ProfileScript.new(shape_path)
	check(not bad_shape.load_profile(), "valid JSON with invalid field types is rejected safely")
	var valid_path: String = prefix + "_valid.json"
	var original = ProfileScript.new(valid_path)
	original.data["seals"] = 20
	original.data["buildings"]["arsenal"] = true
	original.data["settings"]["volume"] = 0.25
	check(original.save(), "new versioned profile writes successfully")
	var restored = ProfileScript.new(valid_path)
	check(restored.load_profile(), "saved profile loads successfully")
	check(restored.data["seals"] == 20 and restored.data["buildings"]["arsenal"], "currency and building unlock persist")
	check(is_equal_approx(float(restored.data["settings"]["volume"]), 0.25), "volume setting persists")
	var reward: int = restored.reward(61.0, 65, true, 3)
	check(reward == 17 and restored.data["seals"] == 37, "reward follows time, kills, collected seals and victory rule")
	check(restored.data["runs"] == 1 and restored.data["wins"] == 1, "run and victory counters persist")
	check(restored.purchase("library") and restored.data["seals"] == 29, "building purchase consumes eight seals")
	check(not restored.purchase("library"), "purchased building cannot charge twice")
	check(FileAccess.file_exists(valid_path + ".bak"), "replacement save retains previous version backup")
	var after_purchase = ProfileScript.new(valid_path)
	check(after_purchase.load_profile() and after_purchase.data["buildings"]["library"], "building purchase survives another load")
	metrics["save_fixtures"] = prefix


func _pick_upgrade() -> void:
	var priorities: Array[String] = ["ward", "boots", "magnet", "sword", "bolt", "orbit", "heal", "repulse", "supplies"]
	for id: String in priorities:
		for offer: Dictionary in g.offers:
			if offer["id"] == id:
				g.choose_upgrade(id)
				return
	if not g.offers.is_empty():
		g.choose_upgrade(String(g.offers[0]["id"]))


func _test_load() -> void:
	g.start_run()
	g.director.cooldown = 10000.0
	g.player.invulnerable = 10000.0
	g.weapon_system.levels = {"sword": 5, "bolt": 5, "orbit": 5}
	for index: int in 180:
		var angle: float = TAU * float(index) / 180.0
		var enemy = g.spawn_enemy("ghoul", g.player.position + Vector2.from_angle(angle) * 130.0)
		enemy.hp = 1000000.0
		enemy.max_hp = enemy.hp
	g.enemies[0].position = g.player.position + Vector2(50, 0)
	g.enemies[1].position = g.player.position - Vector2(50, 0)
	check(g.nearest_enemy(g.player.position, 200) == g.enemies[0], "equal-distance target selection prefers the oldest serial under load")
	var cpu_us: int = 0
	for step: int in 240:
		await physics_frame
		var before: int = Time.get_ticks_usec()
		g.simulate(STEP, Vector2.ZERO)
		cpu_us += Time.get_ticks_usec() - before
	check(g.enemies.size() == 180, "combat with 180 durable enemies preserves the cap")
	check(g.weapon_system.projectiles.size() <= 100, "player projectile limit holds under enemy load")
	check(g.numbers.size() <= 20, "damage number budget holds under enemy load")
	for enemy in g.enemies:
		check(enemy.position.is_finite(), "crowd movement and separation remain finite")
	metrics["load_180"] = {"steps": 240, "simulation_cpu_ms": cpu_us / 1000.0, "entities": g.enemies.size(), "method": "240 real physics frames with 180 durable enemies, headless. CPU time only; not rendered FPS."}
	g.start_run()
	await process_frame


func _bot_direction() -> Vector2:
	var target: Vector2 = Vector2(900, 630)
	var distance: float = INF
	for pickup: Dictionary in g.pickups:
		var candidate: float = g.player.position.distance_squared_to(pickup["at"])
		if candidate < distance:
			distance = candidate
			target = pickup["at"]
	if distance == INF:
		var enemy = g.nearest_enemy(g.player.position, 1500.0)
		if is_instance_valid(enemy):
			target = enemy.position
	var direction: Vector2 = target - g.player.position
	return direction.normalized() if direction.length_squared() > 16.0 else Vector2.ZERO


func _test_full_run() -> void:
	g.start_run()
	g.director.rng.seed = 35117
	g.weapon_system.rng.seed = 2813
	g.sound.volume = 0.0
	var permanent: Dictionary = g.profile.data.duplicate(true)
	var steps: int = 0
	var maximum_entities: int = 0
	var saw_elite: bool = false
	var saw_boss: bool = false
	var started_us: int = Time.get_ticks_usec()
	var simulate_us: int = 0
	var last_report: int = 0
	while g.state in ["running", "upgrading"] and steps < 120000:
		while g.state == "upgrading":
			_pick_upgrade()
		if g.state != "running":
			break
		# The accelerated test explicitly grants invulnerability. This is a systems
		# traversal, not a difficulty, physical-step accuracy or framerate claim.
		g.player.invulnerable = 10000.0
		var before_us: int = Time.get_ticks_usec()
		g.simulate(STEP, _bot_direction())
		simulate_us += Time.get_ticks_usec() - before_us
		steps += 1
		maximum_entities = maxi(maximum_entities, g.enemies.size())
		saw_elite = saw_elite or g.director.elite_spawned
		saw_boss = saw_boss or g.director.boss_spawned
		if steps % 30 == 0:
			await process_frame
		var minute: int = floori(g.elapsed / 120.0)
		if minute > last_report:
			last_report = minute
			print("TRAVERSAL_PROGRESS seconds=%d entities=%d kills=%d level=%d" % [g.elapsed, g.enemies.size(), g.kills, g.level])
	check(g.state == "result" and g.director.phase == "complete", "entire sequence of hordes reaches a defined result")
	check(maximum_entities <= 180, "entity count stays within cap over full run")
	check(saw_elite, "elite event occurs during full traversal")
	check(saw_boss, "boss event occurs during full traversal")
	check(g.profile.data == permanent, "accelerated traversal does not write permanent progression")
	check(bool(g.ui.previous_data.get("won", false)) == g.boss_defeated, "full run result agrees with boss prerequisite")
	metrics["full_run"] = {
		"simulated_seconds": g.elapsed, "fixed_delta": STEP, "steps": steps,
		"wall_ms": (Time.get_ticks_usec() - started_us) / 1000.0,
		"simulation_cpu_ms": simulate_us / 1000.0,
		"maximum_entities": maximum_entities, "kills": g.kills,
		"level": g.level, "spawned": g.director.total_spawned,
		"boss_defeated": g.boss_defeated,
		"waves": g.director.wave_number(), "gold_collected": g.gold,
		"method": "Invulnerable bot; synchronous 1/60 calls; yield every 30 steps. Not real-time FPS, balance or physics validation."
	}
