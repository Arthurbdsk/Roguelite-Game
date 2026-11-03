class_name HordeDirector
extends RefCounted

var game
var cooldown: float = 0.0
var elite_spawned: bool = false
var boss_spawned: bool = false
var total_spawned: int = 0
var skipped_spawns: int = 0
var rng := RandomNumberGenerator.new()
const MAX_ENEMIES := 180
var wave_index: int = -1
var phase: String = "preparing"
var preparation_left: float = 0.0
var queue: Array[Dictionary] = []
var wave_spawned: int = 0
var last_sector: int = 0

func setup(owner_game) -> void:
	game = owner_game
	rng.randomize()

func reset() -> void:
	cooldown = 0
	elite_spawned = false
	boss_spawned = false
	total_spawned = 0
	skipped_spawns = 0
	wave_index = -1
	phase = "preparing"
	preparation_left = game.balance.initial_preparation
	queue.clear()
	wave_spawned = 0
	last_sector = rng.randi_range(0, 7)

func tick(delta: float) -> void:
	if game.slice_mode:
		cooldown -= delta
		if cooldown <= 0 and game.enemies.size() < 12:
			spawn("ghoul")
			cooldown = 2
		return
	if phase == "complete":
		return
	if not elite_spawned and game.elapsed >= game.boss_balance.executioner_arrival and phase != "boss":
		spawn("executioner")
	if phase == "boss":
		return
	if phase == "waiting_executioner":
		if game.executioner_defeated:
			begin_wave()
		return
	if phase == "preparing":
		preparation_left = maxf(0, preparation_left - delta)
		if preparation_left <= 0:
			begin_wave()
		return
	var wave: WaveData = game.balance.waves[wave_index]
	cooldown -= delta
	var budget: int = 8
	while cooldown <= 0 and not queue.is_empty() and budget > 0:
		if game.enemies.size() >= mini(wave.max_alive, game.balance.max_enemies):
			cooldown = 0.15
			break
		var entry: Dictionary = queue.front()
		if not spawn(entry.id, entry.elite):
			cooldown = 0.2
			break
		queue.pop_front()
		wave_spawned += 1
		cooldown += maxf(game.balance.minimum_spawn_interval, wave.spawn_interval)
		budget -= 1
	if queue.is_empty() and game.enemies.is_empty():
		if wave_index >= game.balance.waves.size() - 1:
			phase = "complete"
			game.finish_run(game.boss_defeated)
		else:
			phase = "preparing"
			preparation_left = game.balance.preparation_seconds
			game.enemy_projectiles.reset()
			game.hazards.clear()
			game.announce("HORDA %d CONCLUÍDA" % (wave_index + 1), 3)

func begin_wave() -> void:
	if wave_index + 1 >= game.balance.waves.size():
		return
	var next_wave: WaveData = game.balance.waves[wave_index + 1]
	if next_wave.boss and not game.executioner_defeated:
		phase = "waiting_executioner"
		return
	wave_index += 1
	var wave: WaveData = game.balance.waves[wave_index]
	queue.clear()
	if wave.boss:
		phase = "boss"
		boss_spawned = true
		total_spawned += 1
		game.boss_arena.begin_portal()
		return
	for id in wave.composition:
		for i in int(wave.composition[id]):
			queue.append({"id": id, "elite": false})
	for i in wave.elite_guards:
		queue.append({"id": "guard", "elite": true})
	for i in range(queue.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap: Dictionary = queue[i]
		queue[i] = queue[j]
		queue[j] = swap
	phase = "active"
	wave_spawned = 0
	cooldown = 0.25
	game.announce("HORDA %d  |  %s" % [wave_index + 1, wave.title], 3.0)
	game.sound.play_cue("wave")

func spawn(id: String, elite: bool = false) -> bool:
	if game.enemies.size() >= game.balance.max_enemies:
		return false
	var view: Rect2 = game.camera_rect().grow(game.balance.spawn_margin)
	# Rotate through sectors. Jitter changes the precise entrance without
	# allowing every reinforcement to join the same single-file direction.
	last_sector = (last_sector + 1 + rng.randi_range(0, 1)) % 8
	for attempt in 24:
		var sector: int = (last_sector + attempt) % 8
		var angle: float = sector * TAU / 8 + rng.randf_range(-0.22, 0.22)
		var point: Vector2 = game.player.position + Vector2.from_angle(angle) * rng.randf_range(game.balance.spawn_distance_min, game.balance.spawn_distance_max)
		if view.has_point(point) or not game.arena.safe_position(point, 20):
			continue
		game.spawn_enemy(id, point, elite)
		total_spawned += 1
		last_sector = sector
		if id == "executioner":
			elite_spawned = true
			game.announce("O CARRASCO DESPERTOU", 3)
			game.sound.play_cue("elite")
		if id == "boss":
			boss_spawned = true
			game.announce("O REI SEM BRASA", 4)
			game.sound.play_cue("boss")
		return true
	skipped_spawns += 1
	return false

func pressure() -> String:
	if phase == "waiting_executioner":
		return "DERROTE O CARRASCO" if elite_spawned else "CARRASCO AOS 5 MIN"
	if phase == "boss":
		return "PORTAL NO CENTRO" if game.boss_arena.stage == "portal" else "ÚLTIMA HORDA"
	if phase == "preparing":
		return "HORDA %d EM %ds" % [wave_index + 2, ceili(preparation_left)]
	if phase == "complete":
		return "VIGÍLIA CONCLUÍDA"
	return "HORDA %d  |  %d RESTANTES" % [wave_index + 1, queue.size() + game.enemies.size()]

func wave_number() -> int:
	return maxi(1, wave_index + 1)
