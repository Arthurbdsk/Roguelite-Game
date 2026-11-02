class_name HordeDirector
extends RefCounted

var game
var cooldown: float = 1.0
var elite_spawned: bool = false
var boss_spawned: bool = false
var total_spawned: int = 0
var skipped_spawns: int = 0
var rng := RandomNumberGenerator.new()
const MAX_ENEMIES := 180

func setup(owner_game) -> void:
	game = owner_game
	rng.randomize()

func reset() -> void:
	cooldown = 1
	elite_spawned = false
	boss_spawned = false
	total_spawned = 0
	skipped_spawns = 0

func tick(delta: float) -> void:
	if game.slice_mode:
		cooldown -= delta
		if cooldown <= 0 and game.enemies.size() < 12:
			spawn("ghoul")
			cooldown = 2
		return
	var minute: float = game.elapsed / 60.0
	cooldown -= delta
	if cooldown <= 0:
		cooldown = maxf(0.32, 1.4 - minute * 0.11)
		var batch := 1 + int(minute > 3) + int(minute > 7)
		for i in batch:
			# Two slots remain reserved for the milestone encounters.
			if game.enemies.size() >= MAX_ENEMIES - 2:
				break
			var roll := rng.randf()
			var id := "ghoul"
			if minute > 1.5 and roll < 0.24:
				id = "hound"
			if minute > 3.5 and roll > 0.78:
				id = "guard"
			spawn(id)
	if game.elapsed >= 300 and not elite_spawned:
		if spawn("guard", true):
			elite_spawned = true
			game.announce("O CARRASCO DESPERTOU", 4)
			game.sound.play_cue("elite")
	if game.elapsed >= 540 and not boss_spawned:
		if spawn("boss"):
			boss_spawned = true
			game.announce("O REI SEM BRASA", 5)
			game.sound.play_cue("boss")

func spawn(id: String, elite: bool = false) -> bool:
	if game.enemies.size() >= MAX_ENEMIES:
		return false
	var view: Rect2 = game.camera_rect().grow(40)
	for attempt in 24:
		var angle := rng.randf() * TAU
		var point: Vector2 = game.player.position + Vector2.from_angle(angle) * rng.randf_range(390, 460)
		if view.has_point(point) or not game.arena.safe_position(point, 20):
			continue
		game.spawn_enemy(id, point, elite)
		total_spawned += 1
		return true
	skipped_spawns += 1
	return false

func pressure() -> String:
	if game.elapsed >= 540:
		return "ÚLTIMA VIGÍLIA"
	if game.elapsed >= 300:
		return "CERCO"
	if game.elapsed >= 210:
		return "A MURALHA CEDE"
	if game.elapsed >= 90:
		return "RASTROS NA BRUMA"
	return "O PÁTIO DESPERTA"
