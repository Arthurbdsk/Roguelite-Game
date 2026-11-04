class_name RunMastery
extends RefCounted

var game
var enabled: bool = true
var damage_multiplier: float = 1
var interval_multiplier: float = 1
var critical_chance: float = 0
var critical_multiplier: float = 1.6
var critical_ready: bool = false
var critical_cooldown: float = 0
var travelled: float = 0
var last_stand_spent: bool = false
var regeneration_clock: float = 0
var gold_since_heal: int = 0
var current_gold_wave: int = -1
var healed_waves: Dictionary = {}
var rng := RandomNumberGenerator.new()

func setup(owner_game) -> void:
	game = owner_game
	rng.randomize()

func rank(id: String) -> int:
	return game.skills.rank(id) if enabled else 0

func value(id: String) -> float:
	return game.skills.value(id) if enabled else 0.0

func begin(use_skills: bool = true) -> void:
	enabled = use_skills
	game.player.max_hp = 100 + value("vigor") + 10*rank("pact")
	game.player.hp = game.player.max_hp
	game.player.speed = 96 + value("stride")
	game.player.pickup_radius = 42 + value("magnet")
	game.player.armor = value("armor")
	game.player.movement_multiplier = 1
	game.player.time_since_damage = 0
	damage_multiplier = 1 + value("edge")
	interval_multiplier = 1 - value("tempo")
	critical_chance = value("critical")
	critical_ready = false
	critical_cooldown = 0
	travelled = 0
	last_stand_spent = false
	regeneration_clock = 0
	gold_since_heal = 0
	current_gold_wave = -1
	healed_waves.clear()

func tick(delta: float, distance_moved: float) -> void:
	critical_cooldown = maxf(0, critical_cooldown - delta)
	travelled += distance_moved
	if rank("opening") > 0 and travelled >= 48 and critical_cooldown <= 0:
		critical_ready = true
	if rank("recovery") > 0 and game.player.time_since_damage >= 4:
		regeneration_clock += delta
		if regeneration_clock >= 6:
			regeneration_clock -= 6
			game.player.hp = minf(game.player.max_hp, game.player.hp + value("recovery"))
	else:
		regeneration_clock = 0

func hit(enemy, amount: float, force: Vector2) -> void:
	var critical: bool = critical_ready or rng.randf() < critical_chance
	if critical_ready:
		critical_ready = false
		critical_cooldown = 4
		travelled = 0
	var result: float = amount * damage_multiplier * (critical_multiplier if critical else 1.0)
	enemy.take_damage(result, force)
	if critical:
		game.add_damage_number(enemy.position - Vector2(0, 32), int(result))

func save_from_death() -> bool:
	if rank("last_stand") == 0 or last_stand_spent:
		return false
	last_stand_spent = true
	game.player.hp = 15
	game.player.invulnerable = 2
	game.announce("SOBREVIVÊNCIA ATIVADA", 2)
	return true

func on_gold(amount: int) -> void:
	if rank("salvager") == 0:
		return
	var wave: int = game.director.wave_number()
	if wave != current_gold_wave:
		current_gold_wave = wave
		gold_since_heal = 0
	gold_since_heal += amount
	if gold_since_heal >= 10 and not healed_waves.has(wave):
		healed_waves[wave] = true
		gold_since_heal = 0
		game.player.hp = minf(game.player.max_hp, game.player.hp + 3)

func passive_limit() -> int:
	return 4

func coin_speed_multiplier() -> float:
	return 1.6 if rank("forager") > 0 and game.director.phase == "preparing" else 1.0
