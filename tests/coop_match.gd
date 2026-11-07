extends SceneTree

var game
var session: CoopSession
var hosting: bool = false
var index: int = 0
var code_file: String = ""
var fixture_map:String="courtyard"
var map_sent:bool=false
var started: bool = false
var checks: int = 0
var failures: int = 0
var finished: bool = false
var age: float = 0
var slot: String = ""
var disconnect_scenario: bool = false
var soak_seconds: int = 0

func _initialize() -> void: call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL peer=%d %s" % [index, description])

func run() -> void:
	var code: String = ""
	for argument in OS.get_cmdline_user_args():
		if argument == "--host": hosting = true
		if argument.begins_with("--map="):fixture_map=argument.trim_prefix("--map=")
		if argument == "--disconnect": disconnect_scenario = true
		if argument.begins_with("--soak-seconds="): soak_seconds = int(argument.trim_prefix("--soak-seconds="))
		if argument.begins_with("--index="): index = int(argument.trim_prefix("--index="))
		if argument.begins_with("--code-file="): code_file = argument.trim_prefix("--code-file=")
		if argument.begins_with("--room="): code = argument.trim_prefix("--room=")
	game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.profile.data = game.profile.defaults()
	game.sound.volume = 0
	session = game.coop
	session.connection.message_received.connect(receive)
	session.connection.connection_failed.connect(func(reason):
		if not finished:
			check(false, "unexpected disconnect: " + reason)
			finish_peer.call_deferred())
	session.connection.connect_room(hosting, "Peer%d" % index, code)

func receive(packet: Dictionary) -> void:
	match packet.get("type", ""):
		"joined":
			if hosting:
				var file := FileAccess.open(code_file, FileAccess.WRITE)
				file.store_string(packet.code)
				file.close()
		"lobby":
			if packet.players.size() == 4:
				if hosting and not map_sent:
					map_sent=true
					session.connection.send_message({"type":"map","map":fixture_map});return
				var ready: bool = true
				for member in packet.players:
					ready = ready and member.ready
					if member.id == session.connection.peer_id and not member.ready: session.connection.send_message({"type": "ready", "ready": true})
				if hosting and ready and not started:
					started = true
					session.connection.send_message({"type": "start"})
		"start":
			check(game.arena.map_id==packet.get("map","courtyard"),"selected map loaded before run")
			check(session.actors.size() == 4, "four real player contexts created")
			check(session.initial_size == 4, "initial party frozen at four")
			if hosting:
				game.director.phase = "complete"
				if soak_seconds > 0: host_soak.call_deferred()
				elif disconnect_scenario: host_disconnect.call_deferred()
				else: host_scenario.call_deferred()
		"event":
			if packet.data.get("type") == "fixture": client_command(packet.data)
		"events":
			for data in packet.data:
				if data.get("type") == "fixture": client_command(data)
		"error":
			check(false, "relay error: " + packet.reason)
		"closed":
			if disconnect_scenario:
				check(not session.active and game.state == "online", "host disconnect returns client to online menu")
				check(game.profile.data.gold == 11, "host disconnect preserves last confirmed shared gold")
				check(not session.message.is_empty(), "host disconnect presents a clear message")
				finish_peer.call_deferred()

func command(name_value: String) -> void:
	session.publish({"type": "fixture", "command": name_value})

func client_command(data: Dictionary) -> void:
	match data.command:
		"soak_move":
			session.local_input_override={"movement":Vector2.from_angle(game.elapsed*.25+index*TAU/4),"revive":false}
		"soak_finish":
			check(session.active and not session.ended, "long-running public connection remains active")
			finish_peer.call_deferred()
		"move":
			if index == 1: session.local_input_override = {"movement": Vector2.RIGHT, "revive": false}
		"stop": session.local_input_override = {"movement": Vector2.ZERO, "revive": false}
		"choose":
			check(int(session.received_personal.get("level", 0)) == 2, "shared experience arrives privately")
			var offers: Array = session.received_personal.get("offers", [])
			check(not offers.is_empty(), "private offers received")
			if index == 1 and not offers.is_empty(): session.choose(offers[0].id)
		"verify_gold": check(game.gold == 7, "shared gold is full value on each client")
		"verify_burst": check(game.gold == 2007 and session.active, "two thousand simultaneous pickups stay connected and count once")
		"rescue_host":
			if index == 2: session.local_input_override = {"movement": Vector2.ZERO, "revive": true}
		"verify_boss":
			check(is_instance_valid(game.boss) and game.boss is HordeBoss, "boss replica created")
			if is_instance_valid(game.boss): check(game.boss.attack_name == "execute" and game.boss.state == "windup", "boss attack telegraph replicated")
		"verify_ecology":
			var eaters=game.enemies.filter(func(e):return e is Devourer)
			check(eaters.size()==1 and eaters[0].meals==2 and eaters[0].sprite.scale.x>1,"devourer growth replicated")
			check(not actor_named("Peer0").weapon_system.ground.pools.is_empty(),"owner pools replicated")
			check(not actor_named("Peer2").weapon_system.ground.pools.is_empty(),"independent remote pools replicated")
		"verify_division":
			check(game.enemies.filter(func(e):return e.data.id=="slime_small").size()==15,"exactly fifteen replicated children")
		"verify_specials":
			for species in ["necromancer","beast","plague","shadow"]:
				check(game.enemies.any(func(e):return e.data.id==species and e.frozen_remaining>0),"new enemy and control replicated: "+species)
			check(not game.specials.areas.is_empty() and not game.specials.bolts.is_empty(),"poison warning and magic replicated")
			check(actor_named("Peer0").weapon_system.beams.size()==1 and actor_named("Peer0").weapon_system.lightning_fx.size()==1,"new weapon effects replicated")
			check(actor_named("Peer0").player.poison_remaining>0 and actor_named("Peer0").player.root_remaining>0,"player status replicated")
		"verify_form":
			check(game.boss.form==2 and game.boss.state=="transform" and not game.boss.targetable,"boss transformation replicated")
			check(is_equal_approx(game.boss.max_hp,game.boss_balance.demon_health()*2.5*game.balance.enemy_health_multiplier*5),"phase two health replicated without double scaling")
		"verify_replicas":
			check(game.enemies.size() >= 170, "replicated enemies under load")
			check(game.gold_loot.coins.size() >= 1990, "replicated gold under load")
			check(game.pickups.size() >= 230, "replicated experience under load")
			check(game.enemy_projectiles.arrows.size() >= 300, "replicated projectiles under load")
		"verify_revive":
			var target: CoopActor = actor_named("Peer1")
			check(not target.down and is_equal_approx(target.player.hp, target.player.max_hp * 0.4), "authoritative revive reaches all peers")
			var previous: float = target.player.hp
			session.apply_event({"type": "revive", "event": {"id": 1, "target": target.id, "hp": 999, "invulnerability": 99}})
			check(target.player.hp == previous, "duplicate revive event is ignored")
		"client_leave":
			if index == 3:
				session.leave()
				check(not session.active and game.state == "title", "client can leave independently")
				check(game.profile.data.gold == 2007, "leaving client banks its own shared gold")
				finish_peer.call_deferred()
		"verify_result":
			check(session.ended and game.state == "result", "team defeat settles clients")
			check(game.profile.data.gold == 2007, "client independently banks full shared gold")
			var loaded := GameProfile.new(game.profile.path)
			check(loaded.load_profile() and loaded.data.gold == 2007, "client gold survives profile reload")
			session.settle({})
			check(game.profile.data.gold == 2007, "duplicate settlement ignored")
		"finish": finish_peer.call_deferred()

func actor_named(name_value: String) -> CoopActor:
	for actor in session.actors.values():
		if actor.display_name == name_value: return actor
	return null

func wait_seconds(seconds: float) -> void: await create_timer(seconds).timeout

func host_scenario() -> void:
	await wait_seconds(0.3)
	var local: CoopActor = actor_named("Peer0")
	var remote: CoopActor = actor_named("Peer1")
	for actor in session.actors.values(): actor.player.invulnerable = 100
	var initial_x: float = remote.player.position.x
	command("move")
	await wait_seconds(0.8)
	command("stop")
	await wait_seconds(0.2)
	check(remote.player.position.x > initial_x + 45, "client input moves the official host character")
	check(local.player.position.x < initial_x, "private movement does not move another player")
	var scale: Dictionary = game.enemy_scale()
	check(is_equal_approx(scale.health, 2.5) and is_equal_approx(scale.damage, 2.5) and is_equal_approx(scale.speed, 1.6) and is_equal_approx(scale.count, 3.4), "four-player enemy multipliers")
	var enemy = game.spawn_enemy("skeleton_archer", Vector2(1400, 900))
	check(is_equal_approx(enemy.hp, game.enemy_data.skeleton_archer.health * 2.5 * game.balance.enemy_health_multiplier), "real spawned archer scales health")
	check(is_equal_approx(enemy.data.damage, game.enemy_data.skeleton_archer.damage * 2.5), "real spawned archer scales damage")
	var boss = game.spawn_enemy("demon", Vector2(1500, 950))
	check(is_equal_approx(boss.hp, game.boss_balance.demon_health() * 2.5 * game.balance.enemy_health_multiplier), "single boss scales health")
	check(game.enemies.size() == 2, "boss has not been multiplied")
	game.despawn_enemy(boss)
	game.despawn_enemy(enemy)
	game.boss = null
	game.director.wave_index = -1
	game.director.begin_wave()
	check(game.director.queue.size() == 41, "first cooperative horde uses rounded scaled total")
	game.director.queue.clear()
	game.director.phase = "complete"
	var executioner = game.spawn_enemy("executioner", Vector2(1200, 750))
	executioner.begin_attack("execute")
	await wait_seconds(0.2)
	command("verify_boss")
	await wait_seconds(0.2)
	game.despawn_enemy(executioner)
	game.boss = null
	for i in 4:
		var special=game.spawn_enemy(["necromancer","beast","plague","shadow"][i],Vector2(1400+i*40,950))
		special.frozen_remaining=10
	game.specials.flask(Vector2(1400,900),Vector2(1450,950))
	game.specials.magic(Vector2(1400,900),Vector2.RIGHT,12)
	local.player.apply_poison(10,2);local.player.root_remaining=2
	local.weapon_system.beams.append({"origin":local.player.position,"end":local.player.position+Vector2(0,-160),"width":8,"life":2.0})
	local.weapon_system.lightning_fx.append({"at":Vector2(1400,950),"life":2.0})
	await wait_seconds(.3);command("verify_specials");await wait_seconds(.2)
	for actor in session.actors.values():actor.player.clear_status();actor.player.hp=actor.player.max_hp
	for special in game.enemies.duplicate():game.despawn_enemy(special)
	game.specials.reset();local.weapon_system.beams.clear();local.weapon_system.lightning_fx.clear()
	var final_boss=game.spawn_enemy("demon",Vector2(1500,950));final_boss.take_damage(100000)
	await wait_seconds(.2);command("verify_form");await wait_seconds(.2)
	game.despawn_enemy(final_boss);game.boss=null
	var eater=game.spawn_enemy("devourer",Vector2(1400,950))
	game.gold_loot.drop(eater.position,5);game.drop_xp(eater.position,7)
	game.food_index.tick(1);eater.tick(.01);eater.tick(.01)
	check(eater.meals==2 and eater.swallowed_gold==5 and eater.swallowed_xp==7,"host consumes objects exactly once")
	local.weapon_system.levels.sludge=1
	local.weapon_system.ground.add_pool("sludge",Vector2(1100,700),local.player.position)
	second_actor_pool()
	await wait_seconds(.3);command("verify_ecology");await wait_seconds(.2)
	game.despawn_enemy(eater)
	var parent=game.spawn_enemy("slime_large",Vector2(1400,950));parent.take_damage(99999)
	await wait_seconds(.9);command("verify_division");await wait_seconds(.2)
	for node in game.enemies.duplicate():game.despawn_enemy(node)
	for actor in session.actors.values():actor.weapon_system.ground.reset()
	game.gold_loot.coins.clear();game.pickups.clear()
	game.add_xp(6)
	check(session.actors.values().all(func(actor): return actor.level == 2), "experience levels every actor")
	var elapsed_before: float = game.elapsed
	session.open_upgrades()
	await wait_seconds(0.25)
	check(game.elapsed > elapsed_before + 0.15 and game.state == "running", "private upgrade screen never pauses the world")
	session.close_menu()
	command("choose")
	await wait_seconds(0.4)
	check(remote.offers.is_empty(), "client choice applies on official host")
	check(not local.offers.is_empty(), "another player's choices remain pending")
	var gold_before: int = game.gold
	game.gold_loot.drop(remote.player.position, 7)
	await wait_seconds(0.3)
	check(game.gold == gold_before + 7, "one pickup grants gold once")
	command("verify_gold")
	var pending_id: String = local.offers[0].id
	session.open_upgrades()
	local.player.invulnerable = 0
	local.player.take_damage(9999, local.player.position)
	await wait_seconds(0.1)
	check(local.down and not session.menu_open, "upgrade screen grants no protection and closes on down")
	check(not local.choose(pending_id, local.generation), "down actor cannot consume pending choice")
	var second: CoopActor = actor_named("Peer2")
	second.player.position = local.player.position + Vector2(20,0)
	command("rescue_host")
	# Begin timing the five-second hold after the host receives it. Public WSS
	# may take more than the old fixed 0.4-second delivery allowance.
	for attempt in 60:
		if session.revives.interactions.has(second.id):break
		await wait_seconds(.05)
	check(session.revives.interactions.has(second.id), "remote rescue input reaches host")
	await wait_seconds(5.2)
	command("stop")
	check(not local.down and not local.offers.is_empty(), "client rescues host and preserves pending private choice")
	# Real downing, interruption by damage, then a full five-second rescue.
	remote.player.invulnerable = 0
	remote.player.take_damage(9999, remote.player.position - Vector2.RIGHT)
	check(remote.down and game.state == "running", "lethal damage downs without ending the team match")
	check(not remote.offers.size(), "previous selected upgrade preserved through down")
	local.player.position = remote.player.position + Vector2(20, 0)
	session.local_input_override = {"movement": Vector2.ZERO, "revive": true}
	await wait_seconds(1.1)
	check(session.revives.interactions.has(local.id), "host rescue begins in actual match")
	local.player.invulnerable = 0
	local.player.take_damage(3, local.player.position + Vector2.UP)
	await wait_seconds(0.1)
	check(not session.revives.interactions.has(local.id) or session.revives.interactions[local.id].progress < 0.3, "damage resets rescue progress")
	await wait_seconds(5.2)
	check(not remote.down, "five-second rescue restores ally")
	check(is_equal_approx(remote.player.hp, remote.player.max_hp * 0.4), "revive restores forty percent health")
	check(remote.player.invulnerable > 1.5, "revive grants two seconds protection")
	session.local_input_override = {"movement": Vector2.ZERO, "revive": false}
	command("verify_revive")
	await wait_seconds(0.2)
	# Many actual entities and projectiles through the same transport and renderer.
	for actor in session.actors.values(): actor.player.invulnerable = 100
	for i in 180:
		game.spawn_enemy("ghoul", Vector2(1450 + (i % 10) * 8, 950 + (i / 10) * 8))
	for i in 2000: game.gold_loot.drop(Vector2(1350 + i % 50, 1050 + i / 50))
	for i in 240: game.pickups.append({"id": 10000 + i, "at": Vector2(1400 + i % 40, 1080), "xp": 1, "attracted": false})
	for i in 320: game.enemy_projectiles.fire(Vector2(860, 520 + i%50*.5), Vector2.RIGHT, game.enemy_data.skeleton_archer)
	await wait_seconds(0.3)
	command("verify_replicas")
	await wait_seconds(0.25)
	check(session.bytes_sent < 1500000, "world delta bandwidth stays bounded in fixture")
	print("COOP_LOAD snapshots=%d bytes=%d enemies=%d coins=%d xp=%d" % [session.snapshot_count, session.bytes_sent, game.enemies.size(), game.gold_loot.coins.size(), game.pickups.size()])
	for enemy_node in game.enemies.duplicate(): game.despawn_enemy(enemy_node)
	for coin in game.gold_loot.coins: coin.at = local.player.position
	await wait_seconds(0.3)
	check(game.gold == 2007 and session.connection.connected, "bulk collection batches events without relay rate-limit disconnect")
	command("verify_burst")
	await wait_seconds(0.2)
	game.gold_loot.coins.clear()
	game.pickups.clear()
	game.enemy_projectiles.reset()
	command("client_leave")
	for attempt in 60:
		if session.actors.size()==3:break
		await wait_seconds(.05)
	check(session.actors.size() == 3 and game.state == "running", "client disconnect keeps remaining party running")
	check(session.initial_size == 4 and is_equal_approx(game.enemy_scale().health, 2.5), "disconnect does not lower frozen difficulty")
	for actor in session.actors.values():
		actor.player.invulnerable = 0
		actor.player.take_damage(9999, actor.player.position)
	await wait_seconds(0.3)
	check(session.ended and game.state == "result", "all players down ends real match")
	check(game.profile.data.gold == 2007, "host banks shared gold once")
	command("verify_result")
	await wait_seconds(0.25)
	command("finish")
	await wait_seconds(0.2)
	await finish_peer()

func host_disconnect() -> void:
	await wait_seconds(0.3)
	game.gold = 11
	session.publish({"type": "progress", "data": {"gold": 11, "earned": 0, "kills": 0}})
	await wait_seconds(0.3)
	session.leave()
	check(game.profile.data.gold == 11, "host departure banks host gold")
	await wait_seconds(0.4)
	await finish_peer()

func host_soak() -> void:
	game.director.reset()
	for actor in session.actors.values():
		actor.weapon_system.levels = {"sludge":8,"holy_water":8,"clock":8,"axe":8,"boomerang":8,"fire_wand":8}
		actor.weapon_system.passives = {"crown":1,"magnet":2,"ward":2}
		actor.player.pickup_radius = 114
	var started_at: int = Time.get_ticks_msec()
	var last_second: int = -1
	var load_at: int = mini(60,maxi(1,soak_seconds/5))
	var stress_started: bool = false
	var next_coins: int = load_at
	var next_arrows: int = load_at
	var next_collection: int = load_at + 15
	while Time.get_ticks_msec() - started_at < soak_seconds * 1000:
		var second: int = (Time.get_ticks_msec() - started_at) / 1000
		if second == last_second:
			await process_frame
			continue
		last_second = second
		command("soak_move")
		session.local_input_override={"movement":Vector2.from_angle(game.elapsed*.25),"revive":false}
		if not session.active or session.ended: check(false,"soak ended early"); break
		for actor in session.actors.values():
			actor.player.invulnerable = 100
			actor.player.hp=actor.player.max_hp
			if not actor.offers.is_empty(): actor.choose(actor.offers[0].id,actor.generation)
		if second >= load_at and not stress_started:
			stress_started = true
			game.director.phase = "complete"
			for i in maxi(0,160-game.enemies.size()):
				var enemy = game.spawn_enemy(["devourer","beast","plague","shadow","skeleton_archer","slime_small"][i%6],Vector2(900,630)+Vector2.from_angle(i*TAU/180)*220)
				enemy.max_hp = 100000
				enemy.hp = enemy.max_hp
			for i in 240: game.pickups.append({"id":10000+i,"at":Vector2(1450+i%40,1000),"xp":1,"attracted":false})
		if second >= next_coins:
			next_coins += 60
			for i in 2000: game.gold_loot.drop(Vector2(1400+i%50,1050+i/50))
		if second >= next_arrows:
			next_arrows += 30
			for i in maxi(0,320-game.enemy_projectiles.arrows.size()): game.enemy_projectiles.fire(Vector2(1400,800+i),Vector2.RIGHT,game.enemy_data.skeleton_archer)
		if second >= next_collection:
			next_collection += 60
			for coin in game.gold_loot.coins: coin.at = game.player.position
		if second % 30 == 0:
			print("SOAK_PROGRESS seconds=%d actors=%d enemies=%d snapshots=%d" % [second,session.actors.size(),game.enemies.size(),session.snapshot_count])
		await process_frame
	check(session.active and session.actors.size() == 4, "all four peers survive extended session")
	print("SOAK_DURATION wall_ms=%d target_seconds=%d" % [Time.get_ticks_msec()-started_at,soak_seconds])
	command("soak_finish")
	await wait_seconds(0.5)
	await finish_peer()

func finish_peer() -> void:
	if finished: return
	finished = true
	var profile_path: String = game.profile.path
	print("COOP_MATCH_PEER_%s index=%d checks=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", index, checks, failures])
	game.queue_free()
	await process_frame
	await process_frame
	DirAccess.remove_absolute(profile_path)
	quit(0 if failures == 0 else 1)

func _process(delta: float) -> bool:
	age += delta
	if age > maxi(35, soak_seconds + 90) and not finished:
		check(false, "actual match timed out")
		finish_peer.call_deferred()
	return false

func second_actor_pool():
	var actor=actor_named("Peer2")
	actor.weapon_system.levels.holy_water=1
	actor.weapon_system.ground.add_pool("holy_water",Vector2(1120,760),actor.player.position,.7)
