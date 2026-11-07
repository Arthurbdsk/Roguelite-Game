extends Node2D
class_name WeaponSystem

const WEAPON_PATHS: Dictionary = {
	"garlic":"res://data/weapons/garlic.tres",
	"whip":"res://data/weapons/whip.tres",
	"fire_wand":"res://data/weapons/fire_wand.tres",
	"runetracer":"res://data/weapons/runetracer.tres",
	"magic_wand":"res://data/weapons/magic_wand.tres",

	"ice_wave":"res://data/weapons/ice_wave.tres",
	"bombs":"res://data/weapons/bombs.tres",
	"boomerang":"res://data/weapons/boomerang.tres",
	"axe":"res://data/weapons/axe.tres",
	"holy_water":"res://data/weapons/holy_water.tres",
	"sludge":"res://data/weapons/sludge.tres",
	"clock":"res://data/weapons/clock.tres",
	"lightning":"res://data/weapons/lightning.tres",
	"sword": "res://data/weapons/sword.tres",
	"bolt": "res://data/weapons/bolt.tres",
	"orbit": "res://data/weapons/orbit.tres",
}
const PASSIVE_PATHS: Dictionary = {
	"regeneration":"res://data/upgrades/regeneration.tres",
	"hourglass":"res://data/upgrades/hourglass.tres",
	"lens":"res://data/upgrades/lens.tres",
	"crown":"res://data/upgrades/crown.tres",
	"boots": "res://data/upgrades/boots.tres",
	"magnet": "res://data/upgrades/magnet.tres",
	"heart": "res://data/upgrades/heart.tres",
	"ward": "res://data/upgrades/ward.tres",
	"cadence": "res://data/upgrades/cadence.tres",
}
const MAX_WEAPONS: int = 6
const MAX_PASSIVES: int = 4
const MAX_PROJECTILES: int = 100

var attacks_enabled:bool=true
var game
var lightning_texture=preload("res://assets/effects/lightning.png")
var beam_texture=preload("res://assets/effects/clock_beam.png")
var additions:=NewWeapons16.new()
var arsenal:Arsenal
var ground:GroundAttacks
var levels: Dictionary = {"bolt": 1}:
	set(value):
		levels={}
		for id in value:
			if WEAPON_PATHS.has(id):levels[id]=clampi(int(value[id]),1,8)
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
var lightning_fx:Array[Dictionary]=[]
var beams:Array[Dictionary]=[]
var clock_index:int=0
var support: String = "none"
var last_offer_ids: Array[String] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var stat_cache:Dictionary={}
var cache_combat_stats:bool=false


func setup(game_ref) -> void:
	game = game_ref
	for id: String in WEAPON_PATHS:
		weapon_data[id] = load(WEAPON_PATHS[id])
		weapon_data[id].icon=GameIcons.path("weapon:"+id,weapon_data[id].icon)
	for id: String in PASSIVE_PATHS:
		passive_data[id] = load(PASSIVE_PATHS[id])
		passive_data[id].icon=GameIcons.path("passive:"+id,passive_data[id].icon)
	arsenal=Arsenal.new();add_child(arsenal);arsenal.setup(self)
	ground=GroundAttacks.new();add_child(ground);ground.setup(self)
	rng.randomize()
	reset()


# Call after the player has reset its base statistics for a fresh expedition.
func reset(support_id: String = "none") -> void:
	additions.setup(self);additions.reset()
	if arsenal!=null:arsenal.reset()
	if ground!=null:ground.reset()
	support = support_id
	levels = {"bolt": 1}
	passives.clear()
	beams.clear()
	clock_index=0
	lightning_fx.clear()
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


func update_combat(delta: float, allow_attacks: bool = true) -> void:
	allow_attacks=allow_attacks and attacks_enabled
	if game == null or not is_instance_valid(game.player):
		return
	combat_time += delta
	stat_cache.clear();cache_combat_stats=true
	for id: String in ["whip","fire_wand","runetracer","magic_wand","sword", "bolt", "lightning", "clock", "holy_water", "axe", "boomerang", "bombs", "ice_wave"]:
		if not allow_attacks: continue
		if int(levels.get(id,0)) <= 0:
			continue
		timers[id] = maxf(0.0, float(timers.get(id,0)) - delta)
		if float(timers[id]) <= 0.0:
			var fired: bool = additions.launch(id) if id in NewWeapons16.IDS else arsenal.launch(id) if id in ["axe","boomerang","bombs","ice_wave"] else ground.launch_water() if id=="holy_water" else _clock() if id=="clock" else _lightning() if id=="lightning" else (_swing_sword() if id == "sword" else _fire_bolts())
			timers[id] = _interval(id) if fired else 0.08
	for beam in beams:beam.life-=delta
	beams=beams.filter(func(beam):return beam.life>0)
	for fx in lightning_fx:fx.life-=delta
	lightning_fx=lightning_fx.filter(func(fx):return fx.life>0)
	additions.tick(delta,allow_attacks)
	arsenal.tick(delta,allow_attacks)
	ground.tick(delta,allow_attacks)
	_update_projectiles(delta)
	_update_orbit(delta, allow_attacks)
	for i: int in range(slashes.size() - 1, -1, -1):
		slashes[i]["remaining"] = float(slashes[i]["remaining"]) - delta
		if float(slashes[i]["remaining"]) <= 0.0:
			slashes.remove_at(i)
	cache_combat_stats=false
	queue_redraw()


func _stat(id: String, field: String) -> float:
	var cache_key:String=id+":"+field
	if cache_combat_stats and stat_cache.has(cache_key):return stat_cache[cache_key]
	var data = weapon_data[id]
	var values = data.get(field)
	var index: int = clampi(int(levels.get(id,0)) - 1, 0, values.size() - 1)
	var value:float=float(values[index])
	if field=="projectile_radius":value*=area_factor()*sqrt(1+permanent("area"))
	if (field=="reach" and id in ["sword","sludge","holy_water","ice_wave","garlic","whip"]) or field=="area_radius" or (field=="beam_width" and id=="clock"):value*=area_factor()*(sqrt(1+permanent("area")) if id in ["sword","sludge","holy_water","ice_wave","bombs","garlic","whip"] else 1)
	if field=="duration" and id in ["sludge","holy_water","ice_wave","runetracer"]:value*=1+.08*int(passives.get("hourglass",0))+permanent("duration")
	if field=="count" and id in ["bolt","axe","boomerang","bombs","holy_water","whip","fire_wand","runetracer","magic_wand"]:value+=permanent("amount")
	if cache_combat_stats:stat_cache[cache_key]=value
	return value


func _interval(id: String) -> float:
	var multiplier: float = 1.0 - 0.06 * int(passives.get("cadence", 0))
	if support == "library" and id == "bolt":
		multiplier *= 1.15
	return maxf(.15,_stat(id, "cooldown") * multiplier * (_mastery().interval_multiplier if _mastery() != null else 1.0))

func _mastery():
	return game.get("mastery") if game != null else null

func _valid_target(enemy) -> bool:
	return is_instance_valid(enemy) and enemy.alive and enemy.targetable

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
	if game.player.has_method("begin_swing"):game.player.begin_swing(direction)
	var half_angle: float = deg_to_rad(62.0 if int(levels.get("sword",0)) < 4 else 78.0)
	var arcs: int = int(_stat("sword", "count"))
	if _mastery() != null and _mastery().rank("sword_echo") > 0:
		arcs = maxi(2, arcs)
	for arc_index: int in arcs:
		var angle: float = direction.angle() + float(arc_index) * PI
		var origin: Vector2 = game.player.position
		slashes.append({"origin": origin, "angle": angle, "half": half_angle,
			"reach": reach, "remaining": 0.16, "evolved": int(levels.get("sword",0)) == 5})
		for enemy in arsenal.candidates(origin-Vector2.ONE*reach,origin+Vector2.ONE*reach):
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
		var velocity: Vector2 = direction.rotated(angle_offset) * 275.0 * projectile_factor()
		projectiles.append({"position": game.player.position, "velocity": velocity,
			"distance": 0.0, "reach": reach, "damage": _stat("bolt", "damage"),
			"pierce": (2 if int(levels.get("bolt",0)) >= 2 else 1) + (_mastery().rank("bolt_pierce") if _mastery() != null else 0),
			"bounce": 1 if int(levels.get("bolt",0)) >= 5 else 0, "hits": []})
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
		for enemy in arsenal.candidates(start,end):
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
					shot["velocity"] = (next_target.position - enemy.position).normalized() * 275.0 * projectile_factor()
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
	for enemy in arsenal.candidates(origin-Vector2.ONE*170,origin+Vector2.ONE*170):
		if not _valid_target(enemy) or excluded.has(enemy.get_instance_id()):
			continue
		var candidate: float = origin.distance_squared_to(enemy.position)
		if candidate < distance or (is_equal_approx(candidate, distance) and is_instance_valid(best) and enemy.get_instance_id() < best.get_instance_id()):
			best = enemy
			distance = candidate
	return best


func _update_orbit(delta: float, allow_attacks: bool = true) -> void:
	orbit_positions.clear()
	if int(levels.get("orbit",0)) <= 0:
		return
	var multiplier: float = 0.85 if support == "arsenal" else 1.0
	var angular_speed: float = (2.0 + 0.18 * int(levels.get("orbit",0))) * multiplier
	orbit_phase = fmod(orbit_phase + delta * angular_speed, TAU)
	var count: int = int(_stat("orbit", "count"))
	count += _mastery().rank("orbit_extra") if _mastery() != null else 0
	var reach: float = _stat("orbit", "reach")
	for index: int in count:
		var angle: float = orbit_phase + TAU * float(index) / float(count)
		orbit_positions.append(game.player.position + Vector2.from_angle(angle) * reach)
	if not allow_attacks: return
	for enemy in arsenal.candidates(game.player.position-Vector2.ONE*reach,game.player.position+Vector2.ONE*reach):
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
		var current: int = int(levels.get(id,0))
		if current <= 0:
			continue
		var data = weapon_data[id]
		var label: String = data.display_name
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
	if affinity.is_empty():return ""
	var passive_name: String = passive_data[affinity].display_name
	return "Nível 5 exige " + passive_name + "."


func get_offers() -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for id: String in WEAPON_PATHS:
		if not _weapon_available(id):
			continue
		var current: int = int(levels.get(id,0))
		var data = weapon_data[id]
		var description: String = upgrade_values(id,current)
		var label: String = data.display_name
		pool.append({"id": id, "name": label, "description": description,
			"detail": "Novo" if current==0 else "Nível %d → %d"%[current,current+1],
			"icon": data.icon, "level": current + 1, "weapon": true})
	for id: String in PASSIVE_PATHS:
		if not _passive_available(id):
			continue
		var current: int = int(passives.get(id, 0))
		var data = passive_data[id]
		pool.append({"id": id, "name": data.display_name,
			"description": data.level_descriptions[current],
			"detail": "Novo" if current==0 else "Nível %d → %d"%[current,current+1],
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
	var option_count:int=4 if rng.randf()<permanent("luck") else 3
	while result.size() < option_count and not pool.is_empty():
		var selected: Dictionary = _weighted_pick(pool)
		result.append(selected)
		pool.erase(selected)
	if result.is_empty():
		result=[{"id":"heal","name":"Recuperar vida","description":"Recupera até 35 de vida.","detail":"Efeito imediato","icon":GameIcons.path("ui:heal","res://assets/icons/heart.png")},{"id":"supplies","name":"Receber ouro","description":"Recebe 10 de ouro.","detail":"Efeito imediato","icon":GameIcons.path("ui:gold","res://assets/icons/crown.png")}]
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
		levels[id] = int(levels.get(id,0)) + 1
	elif passive_data.has(id):
		if not _passive_available(id):
			return false
		var current: int = int(passives.get(id, 0))
		passives[id] = current + 1
		match id:
			"boots":
				game.player.speed += 8.0
			"magnet":
				game.player.pickup_radius += 14.0
			"heart":
				game.player.max_hp += 10.0
				game.player.hp = minf(game.player.max_hp, game.player.hp + 15.0)
			"ward":
				game.player.armor += 1.0
	elif id == "heal":
		game.player.hp=minf(game.player.max_hp,game.player.hp+35)
	elif id == "supplies":
		game.gold += 10
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
	if game.has_method("record_discovery"):
		if weapon_data.has(id):game.record_discovery("weapon:"+id)
		elif passive_data.has(id):game.record_discovery("passive:"+id)
	queue_redraw()
	return true


func _play(cue: String) -> void:
	if game != null and is_instance_valid(game.sound):
		game.sound.play_cue(cue)


func _clock()->bool:
	var origin:Vector2=game.player.position
	var direction:Vector2=Vector2.UP.rotated(clock_index*TAU/12)
	clock_index=(clock_index+1)%12
	var end:Vector2=origin+direction*_stat("clock","reach")
	var width:float=_stat("clock","beam_width")
	beams.append({"origin":origin,"end":end,"width":width,"life":0.22})
	for enemy in arsenal.candidates(origin.min(end)-Vector2.ONE*width*.5,origin.max(end)+Vector2.ONE*width*.5):
		if not _valid_target(enemy):continue
		if Geometry2D.get_closest_point_to_segment(enemy.position,origin,end).distance_to(enemy.position)<=width/2+enemy.radius:
			enemy.apply_time_control(weapon_data.clock.freeze_duration,weapon_data.clock.freeze_resistance,weapon_data.clock.boss_slow,weapon_data.clock.boss_slow_duration)
			_hit(enemy,_stat("clock","damage"),Vector2.ZERO)
	return true

func _lightning()->bool:
	var candidates:Array=[]
	for enemy in arsenal.candidates(game.player.position-Vector2.ONE*_stat("lightning","reach"),game.player.position+Vector2.ONE*_stat("lightning","reach")):
		if _valid_target(enemy) and game.player.position.distance_to(enemy.position)<=_stat("lightning","reach"):candidates.append(enemy)
	if candidates.is_empty():return false
	for i in mini(int(_stat("lightning","count")),candidates.size()):
		var selected:int=rng.randi_range(0,candidates.size()-1)
		var enemy=candidates[selected];candidates.remove_at(selected)
		lightning_fx.append({"at":enemy.position,"life":0.24})
		_hit(enemy,_stat("lightning","damage"),Vector2.ZERO)
	_play("thunder")
	return true

func _draw() -> void:
	if game==null:return
	var world=game.world if game is CoopActor else game
	if not is_instance_valid(world):return
	var visible:Rect2=world.render_rect().grow(100)
	additions.visual.paint(self,additions,visible)
	for beam in beams:
		var length:float=beam.origin.distance_to(beam.end)
		draw_set_transform(beam.origin.round(),(beam.end-beam.origin).angle())
		var offset:float=0
		while offset<length:
			var segment:float=minf(32,length-offset)
			draw_texture_rect_region(beam_texture,Rect2(offset,-beam.width/2,segment,beam.width),Rect2(int(combat_time*18)%6*32,0,segment,16))
			offset+=segment
		draw_set_transform(Vector2.ZERO)
	for fx in lightning_fx:
		if not visible.has_point(fx.at):continue
		var frame:int=clampi(int((.24-fx.life)*32),0,7)
		draw_texture_rect_region(lightning_texture,Rect2(fx.at.round()-Vector2(24,84),Vector2(48,96)),Rect2(frame*48,0,48,96))

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
		if not visible.has_point(shot.position):continue
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

func offer_stat(id:String,field:String,index:int)->float:
	var value:float=weapon_data[id].get(field)[index]
	if _mastery()!=null:
		if field=="damage":value*=_mastery().damage_multiplier
		if field=="count" and id=="orbit":value+=_mastery().rank("orbit_extra")
		if field=="count" and id=="sword" and _mastery().rank("sword_echo")>0:value=maxf(2,value)
	if field=="cooldown":
		value*=(1-.06*int(passives.get("cadence",0)))*(_mastery().interval_multiplier if _mastery()!=null else 1)
		if support=="library" and id=="bolt":value*=1.15
	if (field=="reach" and id in ["sword","sludge","holy_water","ice_wave","garlic","whip"]) or field=="area_radius":value*=area_factor()*(sqrt(1+permanent("area")) if id in ["sword","sludge","holy_water","ice_wave","bombs","garlic","whip"] else 1)
	if field=="duration" and id in ["sludge","holy_water","ice_wave","runetracer"]:value*=1+.08*int(passives.get("hourglass",0))+permanent("duration")
	if field=="cooldown":value=maxf(.15,value)
	if field=="count" and id in ["bolt","axe","boomerang","bombs","holy_water","whip","fire_wand","runetracer","magic_wand"]:value+=permanent("amount")
	return value
func upgrade_values(id:String,current:int)->String:
	var data=weapon_data[id]
	var fields:Array[String]=[]
	if id in NewWeapons16.IDS:
		for f in ["projectile_speed","duration","pierce"]:
			if id in ["garlic","whip"] or (f=="duration" and id!="runetracer") or (f=="pierce" and id=="runetracer"):continue
			if current==0 or data.get(f)[current]!=data.get(f)[current-1]:fields.append(value_change({"projectile_speed":"Velocidade","duration":"Duração","pierce":"Perfuração"}[f],data.get(f)[maxi(0,current-1)],data.get(f)[current],current," s" if f=="duration" else ""))
	for spec in [["damage","Dano"],["cooldown","Intervalo"],["reach","Raio da poça" if id in ["sludge","holy_water"] else "Alcance"],["count","Alvos" if id=="lightning" else "Quantidade"]]:
		var after:float=offer_stat(id,spec[0],current)
		var before:float=offer_stat(id,spec[0],maxi(0,current-1))
		if current>0 and is_equal_approx(before,after):continue
		var unit:String=" s" if spec[0]=="cooldown" else ""
		fields.append(value_change(spec[1],before,after,current,unit))
	if id in ["sludge","holy_water"]:
		if current==0 or data.duration[current]!=data.duration[current-1]:fields.append(value_change("Duração",offer_stat(id,"duration",maxi(0,current-1)),offer_stat(id,"duration",current),current," s"))
		fields.append("Dano a cada %s. Sem dano extra por sobreposição."%DisplayNumbers.seconds(data.tick_interval))
	if id=="clock":
		fields.append(value_change("Largura",data.beam_width[maxi(0,current-1)]*area_factor(),data.beam_width[current]*area_factor(),current))
		fields.append("Paralisa %s. Chefes: -%d%% de movimento por %s."%[DisplayNumbers.seconds(data.freeze_duration),data.boss_slow*100,DisplayNumbers.seconds(data.boss_slow_duration)])
	elif id=="sword" and (current==0 or current==3):
		fields.append(value_change("Abertura",124,156 if current==3 else 124,current,"°"))
	elif id=="bolt":
		var extra:int=_mastery().rank("bolt_pierce") if _mastery()!=null else 0
		if current in [0,1]:fields.append(value_change("Atravessa",1+extra,1+extra if current==0 else 2+extra,current," inimigos"))
		if current==4:fields.append("Ricochetes: 0 → 1")
	elif id=="orbit":
		var multiplier:float=.85 if support=="arsenal" else 1
		fields.append(value_change("Giro",(2+.18*maxi(1,current))*multiplier,(2+.18*(current+1))*multiplier,current," rad/s"))
	if id=="axe":fields.append(value_change("Perfuração",data.pierce[maxi(0,current-1)],data.pierce[current],current))
	if id=="bombs":fields.append(value_change("Raio",data.area_radius[maxi(0,current-1)]*area_factor(),data.area_radius[current]*area_factor(),current))
	if id=="ice_wave":fields.append("Movimento -30%% por %s. Chefes: -15%% por até 1 s."%DisplayNumbers.seconds(offer_stat(id,"duration",current)))
	if id=="garlic":fields.append("Aura: lentidão de 15% e empurrão leve no primeiro contato. Respeita imunidades de chefes")
	return ". ".join(fields.filter(func(v):return not v.is_empty()))
func value_change(label:String,before:float,after:float,current:int,unit:String="")->String:
	return DisplayNumbers.change(label,before,after,current,unit)
func number_text(value:float)->String:return DisplayNumbers.number(value)
func build_stats()->String:
	var p=game.player
	var damage:float=(_mastery().damage_multiplier-1)*100 if _mastery()!=null else 0
	var interval:float=(1-.06*int(passives.get("cadence",0)))*(_mastery().interval_multiplier if _mastery()!=null else 1)
	var text:String="Vida: %d/%d | Defesa: %d\nMovimento: %d px/s\nDano: +%d%% | Vel. ataque: +%d%%\nColeta XP: %d | Ouro: %d\nExperiência: +%d%%"%[p.hp,p.max_hp,p.armor,p.speed,damage,(1/interval-1)*100,p.pickup_radius,p.gold_collection_radius(),7*int(passives.get("crown",0))+roundi(100*permanent("experience"))]
	for id in weapon_data:
		if int(levels.get(id,0))>0:text+="\n%s: %s dano | %s | %spx"%[weapon_data[id].display_name,number_text(_stat(id,"damage")*(1+damage/100)),DisplayNumbers.seconds(_interval(id)),number_text(_stat(id,"reach"))]
	text+="\nÁrea permanente: +%.0f%% | Duração: +%.0f%%\nVel. projéteis: +%d%% | Redução: %.0f%%\nRegeneração: %s | Ouro: +%.0f%%"%[100*permanent("area"),100*permanent("duration"),(projectile_factor()-1)*100,100*p.damage_reduction,DisplayNumbers.regeneration(_mastery().regeneration_rate() if _mastery()!=null else 0),100*permanent("gold")]
	return text

func area_factor()->float:
	return 1+.05*int(passives.get("lens",0))

func permanent(id:String)->float:return _mastery().value(id) if _mastery()!=null else 0.0
func projectile_factor()->float:return 1+permanent("projectile_speed")
