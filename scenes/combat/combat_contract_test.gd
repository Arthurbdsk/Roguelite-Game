extends SceneTree

const WeaponsScript = preload("res://scripts/combat/weapons.gd")

class TestPlayer extends Node2D:
	var hp: float = 100.0
	var max_hp: float = 100.0
	var speed: float = 100.0
	var pickup_radius: float = 24.0
	var armor: float = 0.0
	var facing: Vector2 = Vector2.RIGHT

class TestEnemy extends Node2D:
	var hp: float = 1000.0
	var alive: bool = true
	var radius: float = 8.0
	func take_damage(amount: float, _knockback: Vector2 = Vector2.ZERO) -> void:
		hp -= amount
		alive = hp > 0.0

class TestSound extends Node:
	func play_cue(_id: String) -> void:
		pass

class TestGame extends Node2D:
	var player: TestPlayer
	var sound: TestSound
	var enemies: Array = []
	var earned: int = 0
	var effects: float = 1.0
	func nearest_enemy(origin: Vector2, reach: float):
		var best = null
		var closest: float = reach * reach
		for enemy in enemies:
			if not enemy.alive:
				continue
			var distance: float = origin.distance_squared_to(enemy.position)
			if distance <= closest:
				best = enemy
				closest = distance
		return best

var failures: int = 0
var assertions: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _enemy(game: TestGame, point: Vector2) -> TestEnemy:
	var enemy: TestEnemy = TestEnemy.new()
	enemy.position = point
	game.add_child(enemy)
	game.enemies.append(enemy)
	return enemy

func _run() -> void:
	var game: TestGame = TestGame.new()
	root.add_child(game)
	game.player = TestPlayer.new()
	game.sound = TestSound.new()
	game.add_child(game.player)
	game.add_child(game.sound)
	var weapons = WeaponsScript.new()
	game.add_child(weapons)
	weapons.setup(game)
	check(weapons.levels == {"sword": 1, "bolt": 0, "orbit": 0}, "fresh run contains only sword")
	check(weapons.get_loadout().size() == 1, "one initial loadout item")
	var rear: TestEnemy = _enemy(game, Vector2(-40, 0))
	var front: TestEnemy = _enemy(game, Vector2(40, 0))
	weapons._swing_sword()
	check(front.hp == 982.0, "sword damages front arc")
	check(rear.hp == 1000.0, "sword does not damage behind")
	weapons.levels["sword"] = 3
	weapons._swing_sword()
	check(rear.hp == 974.0 and front.hp == 956.0, "third sword level adds rear arc")
	game.enemies.clear()
	var bolt_a: TestEnemy = _enemy(game, Vector2(95, 0))
	var bolt_b: TestEnemy = _enemy(game, Vector2(120, 0))
	game.enemies.reverse()
	weapons.levels["bolt"] = 1
	weapons._fire_bolts()
	weapons._update_projectiles(0.5)
	check(bolt_a.hp == 986.0 and bolt_b.hp == 1000.0, "bolt hits nearest intersected enemy regardless of spawn order")
	bolt_a.hp = 1000.0
	weapons.projectiles.clear()
	weapons.levels["bolt"] = 2
	weapons._fire_bolts()
	weapons._update_projectiles(0.5)
	check(bolt_a.hp == 983.0 and bolt_b.hp == 983.0, "swept bolt collision pierces two targets")
	game.enemies.clear()
	var orb_target: TestEnemy = _enemy(game, Vector2(42, 0))
	weapons.levels["orbit"] = 1
	weapons._update_orbit(0.0)
	weapons._update_orbit(0.0)
	check(orb_target.hp == 991.0, "orbital cannot damage twice inside contact cooldown")
	weapons.combat_time = 0.5
	weapons._update_orbit(0.0)
	check(orb_target.hp == 982.0, "orbital can damage after cooldown")
	weapons.reset()
	weapons.levels["sword"] = 4
	check(not weapons.apply_upgrade("sword"), "evolution blocked without affinity")
	check(weapons.apply_upgrade("ward"), "affinity can be acquired")
	check(weapons.apply_upgrade("sword") and weapons.levels["sword"] == 5, "affinity unlocks sword evolution")
	check(weapons.apply_upgrade("boots") and weapons.apply_upgrade("magnet"), "three passive slots can be filled")
	check(not weapons.apply_upgrade("heart"), "fourth passive rejected")
	check(weapons.apply_upgrade("ward") and not weapons.apply_upgrade("ward"), "passive level cap enforced")
	for _iteration: int in 100:
		var offers: Array[Dictionary] = weapons.get_offers()
		check(offers.size() == 3, "three offers always returned")
		var ids: Dictionary = {}
		for offer: Dictionary in offers:
			ids[offer["id"]] = true
		check(ids.size() == 3, "offer IDs unique")
	weapons.levels = {"sword": 5, "bolt": 5, "orbit": 5}
	weapons.passives = {"ward": 2, "boots": 2, "magnet": 2}
	var complete: Array[Dictionary] = weapons.get_offers()
	check(complete.size() == 3, "full build receives three consumables")
	for option: Dictionary in complete:
		check(["heal", "supplies", "repulse"].has(option["id"]), "full build offers only consumables")
	game.player.hp = game.player.max_hp
	weapons.apply_upgrade("heal")
	check(game.earned == 2, "full health rations grant persistent currency")
	weapons.reset("arsenal")
	check(weapons.levels["bolt"] == 1, "arsenal support starts with bolt")
	weapons.reset("library")
	check(weapons.levels["orbit"] == 1, "library support starts with orbit")
	check(is_equal_approx(weapons._interval("bolt"), 1.2 * 1.15), "library imposes bolt cooldown cost")
	weapons.reset()
	check(weapons.passives.is_empty() and weapons.projectiles.is_empty() and weapons.orbit_hits.is_empty(), "restart clears temporary state")
	if failures == 0:
		print("COMBAT_CONTRACT_PASS: %d assertions; arc, swept collision, orbital cooldown, limits, offers, evolution, support and restart" % assertions)
	else:
		printerr("COMBAT_CONTRACT_FAIL: %d" % failures)
	game.free()
	quit(0 if failures == 0 else 1)
