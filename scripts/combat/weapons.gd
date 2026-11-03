extends Node2D
class_name WeaponSystem

const WEAPON_PATHS: Dictionary = {
	"sword": "res://data/weapons/sword.tres",
	"bolt": "res://data/weapons/bolt.tres",
	"orbit": "res://data/weapons/orbit.tres",
}
const PASSIVE_PATHS: Dictionary = {
	"boots": "res://data/upgrades/boots.tres",
	"magnet": "res://data/upgrades/magnet.tres",
	"heart": "res://data/upgrades/heart.tres",
	"ward": "res://data/upgrades/ward.tres",
	"cadence": "res://data/upgrades/cadence.tres",
}
const MAX_WEAPONS: int = 3
const MAX_PASSIVES: int = 3
const MAX_PROJECTILES: int = 100

var game
var levels: Dictionary = {"sword": 1, "bolt": 0, "orbit": 0}
var passives: Dictionary = {}
var weapon_data: Dictionary = {}
var passive_data: Dictionary = {}
var projectiles: Array[Dictionary] = []
var slashes: Array[Dictionary] = []
var orbit_positions: Array[Vector2] = []
var orbit_hits: Dictionary = {}
var timers: Dictionary = {"sword": 0.1, "bolt": 0.2}
var orbit_phase: float = 0.0
var combat_time: float = 0.0
var support: String = "none"
var last_offer_ids: Array[String] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func setup(game_ref) -> void:
	game = game_ref
	for id: String in WEAPON_PATHS:
		weapon_data[id] = load(WEAPON_PATHS[id])
	for id: String in PASSIVE_PATHS:
		passive_data[id] = load(PASSIVE_PATHS[id])
	rng.randomize()
	reset()


# Call after the player has reset its base statistics for a fresh expedition.
func reset(support_id: String = "none") -> void:
	support = support_id
	levels = {"sword": 1, "bolt": 0, "orbit": 0}
	passives.clear()
	projectiles.clear()
	slashes.clear()
	orbit_positions.clear()
	orbit_hits.clear()
	timers = {"sword": 0.1, "bolt": 0.2}
	orbit_phase = 0.0
	combat_time = 0.0
	last_offer_ids.clear()
	if support == "arsenal":
		levels["bolt"] = 1
	elif support == "library":
		levels["orbit"] = 1
	queue_redraw()


func update_combat(delta: float) -> void:
	if game == null or not is_instance_valid(game.player):
		return
	combat_time += delta
	for id: String in ["sword", "bolt"]:
		if int(levels[id]) <= 0:
			continue
		timers[id] = maxf(0.0, float(timers[id]) - delta)
		if float(timers[id]) <= 0.0:
			var fired: bool = _swing_sword() if id == "sword" else _fire_bolts()
			timers[id] = _interval(id) if fired else 0.08
	_update_projectiles(delta)
	_update_orbit(delta)
	for i: int in range(slashes.size() - 1, -1, -1):
		slashes[i]["remaining"] = float(slashes[i]["remaining"]) - delta
		if float(slashes[i]["remaining"]) <= 0.0:
			slashes.remove_at(i)
	queue_redraw()


func _stat(id: String, field: String) -> float:
	var data = weapon_data[id]
	var values = data.get(field)
	var index: int = clampi(int(levels[id]) - 1, 0, values.size() - 1)
	return float(values[index])


func _interval(id: String) -> float:
	var multiplier: float = 1.0 - 0.12 * int(passives.get("cadence", 0))
	if support == "library" and id == "bolt":
		multiplier *= 1.15
	return _stat(id, "cooldown") * multiplier * (_mastery().interval_multiplier if _mastery() != null else 1.0)

func _mastery():
	return game.get("mastery") if game != null else null

func _valid_target(enemy) -> bool:
	return is_instance_valid(enemy) and enemy.alive and enemy.get("targetable") != false

func _hit(enemy, amount: float, force: Vector2) -> void:
	if not _valid_target(enemy):
		return
	if game.has_method("weapon_hit"):
		game.weapon_hit(enemy, amount, force)
	else:
		enemy.take_damage(amount, force)

func passive_limit() -> int:
	return _mastery().passive_limit() if _mastery() != null else MAX_PASSIVES


func _swing_sword() -> bool:
	var reach: float = _stat("sword", "reach")
	var target = game.nearest_enemy(game.player.position, reach + 25.0)
	if not is_instance_valid(target):
		return false
	var direction: Vector2 = (target.position - game.player.position).normalized()
	if direction.length_squared() < 0.1:
		direction = game.player.facing
	var half_angle: float = deg_to_rad(62.0 if int(levels["sword"]) < 4 else 78.0)
	var arcs: int = int(_stat("sword", "count"))
	if _mastery() != null and _mastery().rank("sword_echo") > 0:
		arcs = maxi(2, arcs)
	for arc_index: int in arcs:
		var angle: float = direction.angle() + float(arc_index) * PI
		var origin: Vector2 = game.player.position
		slashes.append({"origin": origin, "angle": angle, "half": half_angle,
			"reach": reach, "remaining": 0.16, "evolved": int(levels["sword"]) == 5})
		for enemy in game.enemies.duplicate():
			if not _valid_target(enemy):
				continue
			var offset: Vector2 = enemy.position - origin
			if offset.length() <= reach + enemy.radius and absf(wrapf(offset.angle() - angle, -PI, PI)) <= half_angle:
				_hit(enemy, _stat("sword", "damage"), offset.normalized() * 105.0)
	_play("sword")
	return true


func _fire_bolts() -> bool:
	var reach: float = _stat("bolt", "reach")
	var target = game.nearest_enemy(game.player.position, reach)
	if not is_instance_valid(target):
		return false
	var direction: Vector2 = (target.position - game.player.position).normalized()
	var count: int = int(_stat("bolt", "count"))
	for index: int in count:
		if projectiles.size() >= MAX_PROJECTILES:
			break
		var angle_offset: float = (float(index) - float(count - 1) * 0.5) * 0.18
		var velocity: Vector2 = direction.rotated(angle_offset) * 275.0
		projectiles.append({"position": game.player.position, "velocity": velocity,
			"distance": 0.0, "reach": reach, "damage": _stat("bolt", "damage"),
			"pierce": (2 if int(levels["bolt"]) >= 2 else 1) + (_mastery().rank("bolt_pierce") if _mastery() != null else 0),
			"bounce": 1 if int(levels["bolt"]) >= 5 else 0, "hits": []})
	_play("bolt")
	return true


func _update_projectiles(delta: float) -> void:
	for index: int in range(projectiles.size() - 1, -1, -1):
		var shot: Dictionary = projectiles[index]
		var start: Vector2 = shot["position"]
		var end: Vector2 = start + Vector2(shot["velocity"]) * delta
		shot["position"] = end
		shot["distance"] = float(shot["distance"]) + start.distance_to(end)
		var consumed: bool = false
		var collisions: Array[Dictionary] = []
		for enemy in game.enemies:
			if not _valid_target(enemy) or shot["hits"].has(enemy.get_instance_id()):
				continue
			var closest: Vector2 = Geometry2D.get_closest_point_to_segment(enemy.position, start, end)
			if closest.distance_squared_to(enemy.position) > pow(enemy.radius + 3.0, 2.0):
				continue
			collisions.append({"enemy": enemy, "distance": start.distance_squared_to(closest)})
		# Resolve along travel order, independent of the director's spawn ordering.
		collisions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			if is_equal_approx(float(a["distance"]), float(b["distance"])):
				return a["enemy"].get_instance_id() < b["enemy"].get_instance_id()
			return float(a["distance"]) < float(b["distance"]))
		for collision: Dictionary in collisions:
			var enemy = collision["enemy"]
			if not _valid_target(enemy):
				continue
			shot["hits"].append(enemy.get_instance_id())
			_hit(enemy, float(shot["damage"]), Vector2(shot["velocity"]).normalized() * 65.0)
			shot["pierce"] = int(shot["pierce"]) - 1
			if int(shot["pierce"]) > 0:
				continue
			if int(shot["bounce"]) > 0:
				var next_target = _bounce_target(enemy.position, shot["hits"])
				if is_instance_valid(next_target):
					shot["velocity"] = (next_target.position - enemy.position).normalized() * 275.0
					shot["position"] = enemy.position
					shot["bounce"] = 0
					shot["pierce"] = 1
					shot["distance"] = 0.0
					break
			consumed = true
			break
		if consumed or float(shot["distance"]) > float(shot["reach"]):
			projectiles.remove_at(index)


func _bounce_target(origin: Vector2, excluded: Array):
	var best = null
	var distance: float = 170.0 * 170.0
	for enemy in game.enemies:
		if not _valid_target(enemy) or excluded.has(enemy.get_instance_id()):
			continue
		var candidate: float = origin.distance_squared_to(enemy.position)
		if candidate < distance or (is_equal_approx(candidate, distance) and is_instance_valid(best) and enemy.get_instance_id() < best.get_instance_id()):
			best = enemy
			distance = candidate
	return best


func _update_orbit(delta: float) -> void:
	orbit_positions.clear()
	if int(levels["orbit"]) <= 0:
		return
	var multiplier: float = 0.85 if support == "arsenal" else 1.0
	var angular_speed: float = (2.0 + 0.18 * int(levels["orbit"])) * multiplier
	orbit_phase = fmod(orbit_phase + delta * angular_speed, TAU)
	var count: int = int(_stat("orbit", "count"))
	count += _mastery().rank("orbit_extra") if _mastery() != null else 0
	var reach: float = _stat("orbit", "reach")
	for index: int in count:
		var angle: float = orbit_phase + TAU * float(index) / float(count)
		orbit_positions.append(game.player.position + Vector2.from_angle(angle) * reach)
	for enemy in game.enemies.duplicate():
		if not _valid_target(enemy):
			continue
		var enemy_id: int = enemy.get_instance_id()
		if combat_time < float(orbit_hits.get(enemy_id, -1.0)):
			continue
		for point: Vector2 in orbit_positions:
			if point.distance_squared_to(enemy.position) <= pow(enemy.radius + 7.0, 2.0):
				var impulse: Vector2 = (enemy.position - game.player.position).normalized() * 25.0
				_hit(enemy, _stat("orbit", "damage"), impulse)
				orbit_hits[enemy_id] = combat_time + _interval("orbit")
				break
	# Expired object IDs must not accumulate across an entire ten-minute run.
	if orbit_hits.size() > 256:
		for enemy_id in orbit_hits.keys():
			if float(orbit_hits[enemy_id]) + 1.0 < combat_time:
				orbit_hits.erase(enemy_id)


func get_loadout() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id: String in WEAPON_PATHS:
		var current: int = int(levels[id])
		if current <= 0:
			continue
		var data = weapon_data[id]
		var label: String = data.evolution_name if current == data.max_level else data.display_name
		result.append({"id": id, "name": label, "level": current, "icon": data.icon,
			"evolution_hint": _evolution_hint(id)})
	return result


func get_passives() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id: String in PASSIVE_PATHS:
		if int(passives.get(id, 0)) <= 0:
			continue
		var data = passive_data[id]
		result.append({"id": id, "name": data.display_name, "level": int(passives[id]), "icon": data.icon})
	return result


func _evolution_hint(id: String) -> String:
	var affinity: String = weapon_data[id].affinity
	var passive_name: String = passive_data[affinity].display_name
	return "Nível 5 exige " + passive_name + "."


func get_offers() -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for id: String in WEAPON_PATHS:
		if not _weapon_available(id):
			continue
		var current: int = int(levels[id])
		var data = weapon_data[id]
		var description: String = data.level_descriptions[current]
		var label: String = data.evolution_name if current == 4 else data.display_name
		pool.append({"id": id, "name": label, "description": description,
			"detail": "ARMA  %d/5 · Só nesta expedição. %s" % [current + 1, _evolution_hint(id)],
			"icon": data.icon, "level": current + 1, "weapon": true})
	for id: String in PASSIVE_PATHS:
		if not _passive_available(id):
			continue
		var current: int = int(passives.get(id, 0))
		var data = passive_data[id]
		pool.append({"id": id, "name": data.display_name,
			"description": data.level_descriptions[current],
			"detail": "PASSIVA  %d/2 · Só nesta expedição. %d/%d vagas ocupadas." % [current + 1, passives.size(), passive_limit()],
			"icon": data.icon, "level": current + 1, "weapon": false})
	var result: Array[Dictionary] = []
	var weapons_pool: Array[Dictionary] = []
	for option: Dictionary in pool:
		if bool(option["weapon"]):
			weapons_pool.append(option)
	# Guarantee a weapon choice while any valid weapon growth remains.
	if not weapons_pool.is_empty():
		var selected: Dictionary = _weighted_pick(weapons_pool)
		result.append(selected)
		pool.erase(selected)
	while result.size() < 3 and not pool.is_empty():
		var selected: Dictionary = _weighted_pick(pool)
		result.append(selected)
		pool.erase(selected)
	var fallbacks: Array[Dictionary] = [
		{"id": "heal", "name": "Rações de vigília", "description": "Recupera 35 de vida. Com vida cheia, recebe 2 selos.", "detail": "CONSUMÍVEL · Efeito imediato.", "icon": "res://assets/icons/heart.png", "level": 1},
		{"id": "supplies", "name": "Tributo recuperado", "description": "Recebe 2 selos, mantidos mesmo após a morte.", "detail": "RECURSO · Sem bônus de combate.", "icon": "res://assets/icons/crown.png", "level": 1},
		{"id": "repulse", "name": "Última badalada", "description": "Causa 80 de dano e repele inimigos próximos.", "detail": "CONSUMÍVEL · Alcance 160. Não ocupa vaga.", "icon": "res://assets/icons/ward.png", "level": 1},
	]
	while result.size() < 3:
		result.append(fallbacks.pop_front())
	# The guaranteed weapon need not always occupy the first UI card.
	for index: int in range(result.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		var temp: Dictionary = result[index]
		result[index] = result[swap_index]
		result[swap_index] = temp
	last_offer_ids.clear()
	for option: Dictionary in result:
		last_offer_ids.append(String(option["id"]))
	return result


func _weighted_pick(pool: Array[Dictionary]) -> Dictionary:
	var total: float = 0.0
	var weights: Array[float] = []
	for option: Dictionary in pool:
		var id: String = option["id"]
		var weight: float = 0.45 if last_offer_ids.has(id) else 1.0
		if (support == "arsenal" and id == "bolt") or (support == "library" and id == "orbit"):
			weight *= 1.8
		weights.append(weight)
		total += weight
	var roll: float = rng.randf() * total
	for index: int in pool.size():
		roll -= weights[index]
		if roll <= 0.0:
			return pool[index]
	return pool.back()


func _weapon_available(id: String) -> bool:
	var current: int = int(levels.get(id, 0))
	var data = weapon_data[id]
	if current >= data.max_level:
		return false
	if current == 0 and get_loadout().size() >= MAX_WEAPONS:
		return false
	if current == 4 and int(passives.get(data.affinity, 0)) <= 0:
		return false
	return true


func _passive_available(id: String) -> bool:
	var current: int = int(passives.get(id, 0))
	if current >= passive_data[id].max_level:
		return false
	return current > 0 or passives.size() < passive_limit()


func apply_upgrade(id: String) -> bool:
	if weapon_data.has(id):
		if not _weapon_available(id):
			return false
		levels[id] = int(levels[id]) + 1
	elif passive_data.has(id):
		if not _passive_available(id):
			return false
		var current: int = int(passives.get(id, 0))
		passives[id] = current + 1
		match id:
			"boots":
				game.player.speed += 18.0
			"magnet":
				game.player.pickup_radius += 32.0 if current == 0 else 40.0
			"heart":
				game.player.max_hp += 25.0
				game.player.hp = minf(game.player.max_hp, game.player.hp + 30.0)
			"ward":
				game.player.armor += 2.0
	elif id == "heal":
		if game.player.hp >= game.player.max_hp:
			game.earned += 2
		else:
			game.player.hp = minf(game.player.max_hp, game.player.hp + 35.0)
	elif id == "supplies":
		game.earned += 2
	elif id == "repulse":
		for enemy in game.enemies.duplicate():
			if not _valid_target(enemy):
				continue
			var offset: Vector2 = enemy.position - game.player.position
			if offset.length_squared() <= 160.0 * 160.0:
				_hit(enemy, 80.0, offset.normalized() * 210.0)
		slashes.append({"origin": game.player.position, "angle": 0.0,
			"half": PI, "reach": 160.0, "remaining": 0.22, "evolved": true})
	else:
		return false
	_play("upgrade")
	queue_redraw()
	return true


func _play(cue: String) -> void:
	if game != null and is_instance_valid(game.sound):
		game.sound.play_cue(cue)


func _draw() -> void:
	var intensity: float = clampf(float(game.effects), 0.0, 1.0) if game != null else 1.0
	for slash: Dictionary in slashes:
		var origin: Vector2 = Vector2(slash["origin"]).round()
		var angle: float = float(slash["angle"])
		var half: float = float(slash["half"])
		var reach: float = float(slash["reach"])
		var alpha: float = clampf(float(slash["remaining"]) / 0.16, 0.0, 1.0)
		var color: Color = Color("83c4bd") if bool(slash["evolved"]) else Color("d7c9a1")
		color.a = alpha * (0.30 + 0.40 * intensity)
		var points: PackedVector2Array = PackedVector2Array()
		for step: int in range(17):
			var a: float = angle - half + 2.0 * half * float(step) / 16.0
			points.append((origin + Vector2.from_angle(a) * reach).round())
		for step: int in range(16, -1, -1):
			var a: float = angle - half + 2.0 * half * float(step) / 16.0
			points.append((origin + Vector2.from_angle(a) * (reach - 8.0)).round())
		draw_colored_polygon(points, color)
		color.a = alpha
		draw_polyline(PackedVector2Array(points.slice(0, 17)), color, 1.0, false)
	for shot: Dictionary in projectiles:
		var point: Vector2 = Vector2(shot["position"]).round()
		var direction: Vector2 = Vector2(shot["velocity"]).normalized()
		draw_line((point - direction * 7.0).round(), (point + direction * 3.0).round(), Color("d7c9a1"), 2.0, false)
		draw_rect(Rect2((point + direction * 3.0).round() - Vector2.ONE, Vector2(2, 2)), Color("b65f42"))
	for index: int in orbit_positions.size():
		var point: Vector2 = orbit_positions[index].round()
		var tail: Vector2 = Vector2.from_angle(orbit_phase + TAU * float(index) / float(orbit_positions.size()) - 0.4)
		if intensity > 0.25:
			draw_rect(Rect2(point - tail * 4.0 - Vector2(3, 3), Vector2(6, 6)), Color(0.71, 0.37, 0.26, 0.35))
		draw_rect(Rect2(point - Vector2(3, 3), Vector2(6, 6)), Color("b65f42"))
		draw_rect(Rect2(point - Vector2(1, 2), Vector2(3, 3)), Color("e4c37d"))
