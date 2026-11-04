extends SceneTree

var g
var checks: int = 0
var failures: int = 0
var metrics: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func verify(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func run() -> void:
	if "--self-test" not in OS.get_cmdline_user_args():
		quit(2)
		return
	g = load("res://scenes/main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	g.sound.volume = 0
	await test_skills()
	Engine.physics_ticks_per_second = 240
	Engine.time_scale = 4
	await test_executioner()
	await test_demon()
	await test_real_victory_save()
	await benchmark("executioner")
	await benchmark("demon")
	await test_intense_phase()
	g.queue_free()
	await process_frame
	await create_timer(0.5).timeout
	print("SKILLS_BOSSES_%s checks=%d failures=%d metrics=%s" % ["PASS" if failures == 0 else "FAIL", checks, failures, JSON.stringify(metrics)])
	quit(0 if failures == 0 else 1)

func test_skills() -> void:
	var path: String = "user://tree_test_%d.json" % Time.get_ticks_usec()
	g.profile = GameProfile.new(path)
	verify(g.skills.definitions.size() == 16, "catalog has sixteen data-driven nodes")
	verify(g.skills.state("edge").status == "unaffordable", "root reports insufficient gold")
	verify(not g.skills.purchase("edge") and g.profile.data.gold == 0, "insufficient gold cannot be spent")
	g.profile.data.gold = 3000
	verify(g.skills.state("tempo").status == "locked", "dependent skill is locked")
	verify(not g.skills.purchase("tempo") and g.profile.data.gold == 3000, "unmet prerequisite cannot charge gold")
	verify(g.skills.state("edge").status == "available", "root is available with enough gold")
	verify(g.skills.purchase("edge", 0), "first level purchases")
	verify(g.skills.rank("edge") == 1 and g.profile.data.gold == 2988, "first level deducts its exact cost")
	verify(g.skills.state("edge").status == "owned", "partial skill reports purchased state")
	verify(not g.skills.purchase("edge", 0) and g.profile.data.gold == 2988, "stale button cannot repeat the same level charge")
	verify(g.skills.purchase("edge", 1) and g.profile.data.gold == 2964, "next level has its own cost")
	verify(g.skills.state("edge").status == "maxed" and not g.skills.purchase("edge"), "maximized skill cannot charge again")
	verify(g.skills.state("tempo").can_buy, "parent unlocks the next skill")
	for definition in g.skills.definitions:
		verify(definition.max_rank() >= 1 and definition.max_rank() <= 2, "every skill has a bounded rank")
		verify(definition.benefits.size() == definition.max_rank(), "each rank has exact next benefit text")
		while g.skills.rank(definition.id) < definition.max_rank():
			verify(g.skills.purchase(definition.id), "purchase valid dependency sequence: " + definition.id)
		verify(not g.skills.purchase(definition.id), "no duplicated maximum: " + definition.id)
	verify(g.profile.data.gold >= 0, "all purchases preserve nonnegative balance")
	var restored := GameProfile.new(path)
	verify(restored.load_profile() and restored.data.skill_ranks == g.profile.data.skill_ranks, "all purchased ranks survive close and reload")
	verify(restored.data.gold == g.profile.data.gold, "purchase balance is saved immediately")
	var previous: Dictionary = g.profile.data.duplicate(true)
	g.state = "running"
	verify(not g.skills.purchase("edge") and previous == g.profile.data, "purchases are blocked inside an expedition")
	g.start_run()
	var stats := [g.player.max_hp, g.player.speed, g.player.pickup_radius, g.player.armor, g.mastery.damage_multiplier, g.mastery.interval_multiplier]
	verify(g.player.max_hp == 130 and g.player.speed == 108 and g.player.armor == 2, "permanent stats apply at start")
	g.retry()
	verify(stats == [g.player.max_hp, g.player.speed, g.player.pickup_radius, g.player.armor, g.mastery.damage_multiplier, g.mastery.interval_multiplier], "restart does not stack permanent stats")
	verify(g.weapon_system.passive_limit() == 3, "pact requires equipping all three weapons")
	g.weapon_system.apply_upgrade("bolt")
	g.weapon_system.apply_upgrade("orbit")
	verify(g.weapon_system.passive_limit() == 4, "pact unlocks a real fourth passive slot")
	for id in ["boots", "magnet", "ward", "cadence"]:
		verify(g.weapon_system.apply_upgrade(id), "fourth passive can be equipped: " + id)
	g.weapon_system.update_combat(0.01)
	verify(g.weapon_system.orbit_positions.size() == 4, "orbital specialization adds an actual ember")
	g.weapon_system.projectiles.clear()
	g.director.phase = "complete"
	var target = g.spawn_enemy("ghoul", g.player.position + Vector2(120, 0))
	target.hp = 1000
	g.weapon_system._fire_bolts()
	verify(g.weapon_system.projectiles[0].pierce == 2, "bolt specialization adds piercing")
	g.mastery.critical_ready = true
	var hp: float = target.hp
	g.mastery.hit(target, 10, Vector2.ZERO)
	verify(is_equal_approx(hp - target.hp, 17.92), "critical and permanent damage combine once")
	verify(not g.mastery.critical_ready and g.mastery.critical_cooldown == 4, "prepared critical is consumed with cooldown")
	g.mastery.tick(4.1, 48)
	verify(g.mastery.critical_ready, "movement prepares the next special critical")
	g.player.hp = 50
	g.player.time_since_damage = 5
	g.mastery.tick(6.1, 0)
	verify(g.player.hp == 52, "recovery applies the exact bounded heal")
	g.mastery.on_gold(10)
	verify(g.player.hp == 55, "salvager heals once after ten collected coins")
	g.mastery.on_gold(30)
	verify(g.player.hp == 55, "salvager cannot repeat its heal within a horde")
	g.director.wave_index = 1
	g.mastery.on_gold(1)
	verify(g.player.hp == 55, "extra coins from an old wave do not prepay the next wave heal")
	g.mastery.on_gold(9)
	verify(g.player.hp == 58, "next wave requires its own ten collected coins")
	g.player.hp = 1
	g.player.invulnerable = 0
	g.player.take_damage(100, g.player.position)
	verify(g.player.hp == 15 and g.state == "running", "last stand saves one lethal hit")
	g.player.invulnerable = 0
	g.player.take_damage(100, g.player.position)
	verify(g.state == "result", "last stand cannot trigger twice in one run")
	for version in [1, 2]:
		var fixture := FileAccess.open(path + str(version), FileAccess.WRITE)
		fixture.store_string(JSON.stringify({"version": version, "gold": 350, "seals": 12, "buildings": {"arsenal": true}}))
		fixture.close()
		var migrated := GameProfile.new(path + str(version))
		verify(migrated.load_profile() and migrated.data.version == 3 and migrated.data.skill_ranks.is_empty(), "old profile migrates to empty tree")
		verify(migrated.data.gold == 350 and migrated.data.seals == 12 and migrated.data.buildings.arsenal, "migration preserves gold and previous progression")
	g.profile = GameProfile.new(path + "_rollback")
	g.profile.data.gold = 50
	g.profile.path = "user://missing_skill_test_directory/profile.json"
	g.state = "title"
	verify(not g.skills.purchase("edge") and g.profile.data.gold == 50 and g.skills.rank("edge") == 0, "failed save rolls back purchase and gold")
	g.profile = restored
	g.open_skill_tree()
	await process_frame
	verify(g.ui.screen == "tree" and g.state == "tree", "functional tree screen opens outside run")
	g.close_skill_tree()
	g.profile = GameProfile.new(path + "_keyboard")
	g.profile.data.gold = 50
	g.ui.selected_skill = "edge"
	g.open_skill_tree()
	await process_frame
	await process_frame
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	key.keycode = KEY_SPACE
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	verify(g.skills.rank("edge") == 1 and g.profile.data.gold == 38, "keyboard Space purchases focused skill once through native UI")
	key.pressed = false
	Input.parse_input_event(key)
	g.close_skill_tree()

func fresh_boss(kind: String) -> void:
	g.start_boss_test(kind)
	g.sound.volume = 0
	g.player.invulnerable = 10000
	g.weapon_system.levels = {"sword": 0, "bolt": 0, "orbit": 0}

func test_executioner() -> void:
	fresh_boss("executioner")
	var boss = g.boss
	verify(is_equal_approx(boss.max_hp,936*g.balance.enemy_health_multiplier), "executioner has triple its previous maximum health")
	verify(g.boss_balance.executioner_speed > g.enemy_data.hound.speed and g.boss_balance.executioner_speed < 96, "executioner chases faster than common enemies but slower than base player")
	g.player.invulnerable = 0
	g.player.position = boss.position + Vector2(-50, 0)
	boss.begin_attack("execute")
	await physics_frame
	g.simulate(1.0 / 60.0, Vector2.DOWN)
	verify(boss.state == "windup" and g.player.hp == 100, "execution attack has a harmless warning")
	for i in 41:
		await physics_frame
		g.simulate(1.0 / 60.0, Vector2.DOWN)
	var locked: Vector2 = boss.charge_direction
	for i in 39:
		await physics_frame
		g.simulate(1.0 / 60.0, Vector2.DOWN)
	verify(g.player.hp == 100, "continuous movement can dodge execution in real physics frames")
	verify(boss.charge_direction.is_equal_approx(locked), "execution stops tracking before its swing")
	boss.position = Vector2(1000, 630)
	g.player.position = Vector2(850, 630)
	boss.begin_attack("charge")
	for i in 62:
		await physics_frame
		g.simulate(1.0 / 60.0, Vector2.DOWN)
	locked = boss.charge_direction
	verify(boss.state == "charge", "charge follows a visible warning")
	for i in 50:
		await physics_frame
		g.simulate(1.0 / 60.0, Vector2.DOWN)
	verify(g.player.hp == 100 and boss.charge_direction.is_equal_approx(locked), "charge trajectory stays locked and is dodgeable")
	verify(boss.state == "recovery", "missed charge exposes a recovery window")
	boss.hp = boss.max_hp * 0.49
	boss.tick(0.01)
	verify(boss.phase == 2, "executioner enrages below half life")
	boss.finish_attack()
	verify(boss.attack_time == g.boss_balance.executioner_enraged_interval, "enraged phase reduces intervals moderately")
	boss.attack_index = 0
	verify(boss.choose_attack() == "execute" and boss.choose_attack() == "charge", "executioner alternates complementary attacks")
	g.start_run()
	g.director.phase = "active"
	g.director.wave_index = 0
	g.director.queue.clear()
	g.director.queue.append({"id": "ghoul", "elite": false})
	g.director.cooldown = 10000
	g.elapsed = 299
	g.director.tick(0.01)
	verify(not g.director.elite_spawned, "executioner does not arrive before five minutes")
	g.elapsed = 300
	g.director.tick(0.01)
	verify(g.director.elite_spawned and g.boss is HordeBoss and g.boss.is_executioner, "five-minute event spawns the real executioner boss")
	var total: int = g.director.total_spawned
	g.director.tick(0.01)
	verify(g.director.total_spawned == total, "five-minute boss is scheduled once")

func test_demon() -> void:
	fresh_boss("demon")
	var boss = g.boss
	verify(is_equal_approx(boss.max_hp,1872*g.balance.enemy_health_multiplier) and is_equal_approx(boss.max_hp,g.boss_balance.executioner_health()*2*g.balance.enemy_health_multiplier), "demon starts at twice the strengthened executioner health")
	verify(boss.position == Vector2(900, 630) and g.boss_arena.stage == "portal", "portal starts at the arena center")
	var hp: float = boss.hp
	boss.take_damage(500)
	verify(boss.hp == hp and not boss.targetable, "emerging demon cannot receive damage or be targeted")
	g.player.position = Vector2(900, 630)
	g.player.invulnerable = 0
	for i in 224:
		await physics_frame
		g.simulate(1.0 / 60.0, Vector2.LEFT)
	verify(g.player.hp == 100, "portal entrance causes no unavoidable damage and player keeps control")
	verify(g.boss_arena.portal_sound_played and g.boss_arena.stage == "combat", "pentagram opening emergence and closing finish before combat")
	verify(boss.combat_enabled and boss.targetable and boss.attack_time > 0, "demon activates only after full entrance with reaction grace")
	verify(g.player.position.distance_to(Vector2(900, 630)) > 100, "portal does not lock player movement")
	g.player.position = Vector2(730, 630)
	g.player.invulnerable = 10000
	boss.attack_time = 10000
	boss.hp = boss.max_hp * 0.69
	boss.tick(0.01)
	verify(boss.phase == 2, "demon enters phase two at seventy percent")
	boss.hp = boss.max_hp * 0.34
	boss.tick(0.01)
	verify(boss.phase == 3, "demon enters phase three below thirty-five percent")
	verify(g.boss_arena.cast("summon", boss, Vector2.LEFT, 3), "demon can invoke reinforcements")
	verify(not g.boss_arena.pending_summons.is_empty() and g.boss_arena.summons.is_empty(), "summons have visible advance markers")
	for mark in g.boss_arena.pending_summons:
		verify(mark.at.distance_to(g.player.position) >= 95 and g.arena.safe_position(mark.at, 15), "summon markers avoid player and obstacles")
	g.boss_arena.tick(1.01)
	verify(g.boss_arena.summons.size() > 0, "marked enemies actually spawn after warning")
	for i in 8:
		g.boss_arena.cast("summon", boss, Vector2.LEFT, 3)
		g.boss_arena.tick(1.01)
	verify(g.boss_arena.summons.size() + g.boss_arena.pending_summons.size() <= g.boss_balance.summon_limit, "living and pending summons share the configured cap")
	g.enemy_projectiles.reset()
	g.boss_arena.cast("fire", boss, Vector2.LEFT, 1)
	verify(g.enemy_projectiles.fire_count() == 5, "phase one creates an actual five-projectile fan")
	var angles: Array[float] = []
	for shot in g.enemy_projectiles.arrows:
		angles.append(shot.velocity.angle())
	angles.sort()
	verify(absf(wrapf(angles[1] - angles[0], -PI, PI)) > 0.3, "fire fan has traversable angular gaps")
	g.enemy_projectiles.reset()
	g.boss_arena.bursts.clear()
	g.boss_arena.cast("fire", boss, Vector2.LEFT, 3)
	g.boss_arena.tick(0.41)
	verify(g.enemy_projectiles.fire_count() == 13, "phase three changes pattern with a staggered second fan")
	g.boss_arena.areas.clear()
	g.boss_arena.cast("lightning", boss, Vector2.LEFT, 3)
	verify(g.boss_arena.areas.size() == g.boss_balance.first_lightning_count, "first form marks its configured lightning sequence")
	var positions: Array[Vector2] = []
	for area in g.boss_arena.areas:
		positions.append(area.at)
	g.player.invulnerable = 0
	g.player.position = Vector2(1100, 900)
	var health: float = g.player.hp
	g.boss_arena.tick(0.5)
	verify(g.player.hp == health, "lightning warning is harmless")
	for index in positions.size():
		verify(g.boss_arena.areas[index].at == positions[index], "lightning locks its targets before impact")
	g.boss_arena.tick(0.65)
	verify(g.player.hp == health, "moving outside lightning marks avoids damage")
	verify(not g.boss_arena.can_cast("ice"), "controller blocks ice while lightning areas remain")
	g.boss_arena.tick(2.0)
	g.player.position = Vector2(900, 630)
	g.boss_arena.cast("ice", boss, Vector2.LEFT, 2)
	verify(g.boss_arena.areas.size() == 2, "ice forms two separated regions")
	verify(g.boss_arena.slow_multiplier(g.player.position) == 1, "ice leaves a clear central escape route")
	var at: Vector2 = g.boss_arena.areas[0].at
	verify(g.boss_arena.slow_multiplier(at) == 1, "forming ice does not slow early")
	g.boss_arena.tick(0.9)
	verify(is_equal_approx(g.boss_arena.slow_multiplier(at), 0.68), "active ice slows by thirty-two percent without freezing")
	verify(not g.boss_arena.can_cast("lightning"), "controller prevents lightning over active ice")
	g.boss_arena.tick(4.1)
	verify(g.boss_arena.slow_multiplier(at) == 1, "ice expires and restores normal movement")
	var permanent: int = g.profile.data.gold
	var gold_before: int = g.gold
	boss.take_damage(99999)
	boss.tick(g.boss_balance.transformation_duration + 0.01)
	boss.take_damage(99999)
	verify(g.gold == gold_before + g.boss_balance.demon_reward and g.boss_defeated, "demon grants its reward once")
	boss.take_damage(99999)
	verify(g.gold == gold_before + g.boss_balance.demon_reward, "demon death cannot pay twice")
	verify(g.boss_arena.summons.is_empty() and g.boss_arena.areas.is_empty() and g.enemy_projectiles.arrows.is_empty(), "boss death clears summons projectiles and hazards")
	verify(g.state == "running" and not g.boss_arena.deaths.is_empty(), "victory waits for the death animation")
	g.boss_arena.tick(g.boss_balance.death_duration + 0.01)
	verify(g.state == "result" and g.ui.previous_data.won, "death animation ends with victory")
	verify(g.profile.data.gold == permanent and g.ui.previous_data.dev, "development fight never credits permanent gold")
	g.retry()
	verify(g.boss_arena.areas.is_empty() and g.boss_arena.pending_summons.is_empty() and g.boss_arena.deaths.is_empty(), "restart cleans all boss state")

func bot_direction(boss) -> Vector2:
	for area in g.boss_arena.areas:
		if area.kind == "lightning" and g.player.position.distance_to(area.at) < area.radius + 25:
			return (Vector2(900, 630) - g.player.position).normalized() if g.player.position.distance_to(Vector2(900, 630)) > 35 else Vector2.UP
	if boss.state == "windup" and boss.attack_name in ["charge", "execute"]:
		return boss.charge_direction.orthogonal()
	if boss.state == "charge":
		return boss.charge_direction.orthogonal()
	var offset: Vector2 = boss.position - g.player.position
	return offset.normalized() if offset.length() > 46 else offset.orthogonal().normalized() * 0.25

func test_real_victory_save() -> void:
	var path: String = "user://boss_victory_test_%d.json" % Time.get_ticks_usec()
	g.profile = GameProfile.new(path)
	g.profile.data.gold = 60
	g.start_run()
	g.persistence_enabled = true
	g.director.phase = "boss"
	g.boss_arena.begin_portal()
	g.boss_arena.tick(g.boss_balance.portal_duration() + 0.01)
	var boss = g.boss
	g.gold = 10
	g.boss_arena.cast("summon", boss, Vector2.LEFT, 3)
	g.boss_arena.tick(1.01)
	var kills: int = g.kills
	boss.take_damage(99999)
	boss.tick(g.boss_balance.transformation_duration + 0.01)
	boss.take_damage(99999)
	verify(g.kills == kills + 1 and g.boss_arena.summons.is_empty(), "retired summons do not create extra rewards or kills")
	g.boss_arena.tick(g.boss_balance.death_duration + 0.01)
	verify(g.profile.data.gold == 190 and g.state == "result", "real victory banks collected gold plus unique boss reward")
	var restored := GameProfile.new(path)
	verify(restored.load_profile() and restored.data.gold == 190, "victory gold survives close and reopening")
	g.finish_run(true)
	g.enter_hub()
	verify(g.profile.data.gold == 190, "victory and leaving results cannot repeat payout")
	g.persistence_enabled = false

func benchmark(kind: String) -> void:
	g.start_boss_test(kind)
	g.sound.volume = 0
	var boss = g.boss
	g.player.invulnerable = 10000
	var simulated: float = 0
	var steps: int = 0
	var max_projectiles: int = 0
	var max_summons: int = 0
	while g.state == "running" and steps < 18000:
		await physics_frame
		g.player.invulnerable = 10000
		g.simulate(1.0 / 60.0, bot_direction(boss) if boss.alive and boss.combat_enabled else Vector2.LEFT * 0.1)
		simulated += 1.0 / 60.0
		steps += 1
		max_projectiles = maxi(max_projectiles, g.enemy_projectiles.arrows.size())
		max_summons = maxi(max_summons, g.boss_arena.summons.size())
		if kind == "executioner" and not boss.alive and g.boss_arena.deaths.is_empty():
			break
	verify(not is_instance_valid(boss) or not boss.alive, "representative build defeats " + kind)
	verify(simulated < 150, "boss fight stays below multi-minute repetition in representative benchmark: " + kind)
	metrics[kind] = {"simulated_seconds": simulated, "physics_steps": steps, "max_projectiles": max_projectiles, "max_summons": max_summons, "build": "three weapons rank %d, boots/ward/magnet rank 2, no permanent skills" % (4 if kind == "executioner" else 5), "method": "Invulnerable movement bot, real physics frames at 4x time scale. Duration evidence, not human balance or FPS."}
	print("BOSS_BENCH %s %s" % [kind, JSON.stringify(metrics[kind])])

func test_intense_phase() -> void:
	fresh_boss("demon")
	g.boss_arena.tick(g.boss_balance.portal_duration() + 0.01)
	var boss = g.boss
	boss.hp = boss.max_hp * 0.25
	boss.attack_time = 0
	g.player.invulnerable = 10000
	for i in 10:
		g.boss_arena.cast("summon", boss, Vector2.LEFT, 3)
		g.boss_arena.tick(1.01)
	for i in 100:
		g.enemy_projectiles.fire_ball(boss.position, Vector2.from_angle(i * TAU / 100), boss.get_instance_id(), 3)
	verify(g.enemy_projectiles.fire_count() == g.boss_balance.fire_limit, "intense phase respects fireball cap")
	var cpu_us: int = 0
	for i in 480:
		await physics_frame
		var before: int = Time.get_ticks_usec()
		g.simulate(1.0 / 60.0, Vector2.ZERO)
		cpu_us += Time.get_ticks_usec() - before
		verify(g.enemy_projectiles.arrows.size() <= g.boss_balance.final_projectile_limit, "intense phase total projectile budget")
		verify(g.boss_arena.summons.size() + g.boss_arena.pending_summons.size() <= g.boss_balance.summon_limit, "intense phase living plus pending summon budget")
		verify(not (g.boss_arena.has_area("ice") and g.boss_arena.has_area("lightning")), "controller never combines ice and lightning coverage")
		verify(g.boss_arena.areas.size() <= g.boss_balance.area_limit, "intense phase area budget")
	metrics.intense_phase = {"physics_steps": 480, "cpu_ms": cpu_us / 1000.0, "fire_limit": 72, "summon_limit": g.boss_balance.summon_limit, "method": "Headless CPU update time; not rendered FPS."}
	g.player.invulnerable = 0
	g.player.take_damage(99999, g.player.position)
	verify(g.state == "result" and g.boss_arena.areas.is_empty() and g.boss_arena.pending_summons.is_empty() and g.enemy_projectiles.arrows.is_empty(), "defeat clears boss threats")
