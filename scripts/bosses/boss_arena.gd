class_name BossArena
extends Node2D

var game
var ice_texture=preload("res://assets/effects/demon_ice.png")
var stage: String = "idle"
var portal_age: float = 0
var portal_sound_played: bool = false
var center := Vector2(900, 630)
var demon = null
var areas: Array[Dictionary] = []
var pending_summons: Array[Dictionary] = []
var summons: Dictionary = {}
var bursts: Array[Dictionary] = []
var deaths: Array[Dictionary] = []
var swings: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var attack_history: Array[String] = []

func setup(owner_game) -> void:
	game = owner_game
	z_index = -5
	rng.randomize()

func reset() -> void:
	stop_combat()
	for death in deaths:
		if is_instance_valid(death.boss) and not death.boss.is_queued_for_deletion():
			death.boss.queue_free()
	deaths.clear()
	demon = null
	portal_age = 0
	portal_sound_played = false
	attack_history.clear()
	queue_redraw()

func stop_combat() -> void:
	stage = "idle"
	if game.get("specials")!=null:
		game.specials.areas.clear();game.specials.bolts.clear();game.specials.marks.clear()
		game.specials.casters.clear()
	areas.clear()
	pending_summons.clear()
	bursts.clear()
	swings.clear()
	for minion in summons.values():
		if is_instance_valid(minion):
			game.despawn_enemy(minion)
	summons.clear()
	if is_instance_valid(game.enemy_projectiles):
		game.enemy_projectiles.reset()
	if is_instance_valid(game.player):
		game.player.movement_multiplier = 1
	if game.state != "running":
		for death in deaths:
			if is_instance_valid(death.boss):
				death.boss.queue_free()
		deaths.clear()
	queue_redraw()

func final_active() -> bool:
	return stage in ["portal", "combat", "death"]

func begin_portal() -> bool:
	stop_combat()
	stage = "portal"
	portal_age = 0
	portal_sound_played = false
	demon = game.spawn_enemy("demon", center)
	if demon==null:stage="idle";return false
	demon.combat_enabled = false
	demon.targetable = false
	demon.sprite.visible = false
	demon.velocity = Vector2.ZERO
	game.enemy_projectiles.reset()
	game.hazards.clear()
	game.announce("DEMÔNIO", 3.0)
	queue_redraw()
	return true

func on_boss_death(boss: HordeBoss) -> void:
	var final_death: bool = boss == demon and stage in ["combat", "portal"]
	var owner: int = boss.get_instance_id()
	game.enemy_projectiles.remove_owner(owner)
	areas = areas.filter(func(area): return area.owner != owner)
	pending_summons = pending_summons.filter(func(mark): return mark.owner != owner)
	bursts = bursts.filter(func(burst): return burst.owner != owner)
	if final_death:
		stop_combat()
		stage = "death"
	deaths.append({"boss": boss, "age": 0.0, "final": final_death})
	queue_redraw()

func notify_enemy_removed(enemy) -> void:
	summons.erase(enemy.get_instance_id())

func tick(delta: float) -> void:
	if game.state != "running":
		return
	if stage == "portal":
		portal_age += delta
		var timing: BossBalance = game.boss_balance
		if portal_age >= timing.portal_trace and not portal_sound_played:
			portal_sound_played = true
			game.sound.play_cue("portal")
		var emerge_start: float = timing.portal_trace + timing.portal_open
		if is_instance_valid(demon) and portal_age >= emerge_start:
			var progress := clampf((portal_age - emerge_start) / timing.portal_emerge, 0, 1)
			demon.sprite.visible = true
			demon.sprite.frame = 12 if demon.data.frames>=32 else 4
			demon.sprite.position.y = -float(demon.sprite.texture.get_height())*.5+4 + roundf((1 - progress) * 28)
			demon.sprite.modulate = Color(1, 1, 1, progress)
		if portal_age >= timing.portal_duration() and is_instance_valid(demon):
			stage = "combat"
			demon.enable_combat()
			game.sound.play_cue("boss")
	for i in range(deaths.size() - 1, -1, -1):
		var death: Dictionary = deaths[i]
		death.age += delta
		if is_instance_valid(death.boss):
			var boss = death.boss
			boss.sprite.frame = TinyCharacters.frame(boss.tiny_kind,"death",death.age/game.boss_balance.death_duration) if boss.tiny_kind=="original_executioner" else boss.data.frames - 2 + int(death.age > game.boss_balance.death_duration * 0.5)
			boss.sprite.modulate = Color(1.0, 0.65, 0.50, clampf(2 - death.age / game.boss_balance.death_duration * 2, 0, 1))
		if death.age >= game.boss_balance.death_duration:
			deaths.remove_at(i)
			if is_instance_valid(death.boss):
				death.boss.queue_free()
			if death.final:
				stage = "complete"
				game.campaign.encounter_finished("demon")
				return
	for i in range(bursts.size() - 1, -1, -1):
		bursts[i].delay -= delta
		if bursts[i].delay <= 0:
			var burst: Dictionary = bursts[i]
			bursts.remove_at(i)
			fire_fan(burst.at, burst.direction, burst.count, burst.owner, burst.phase, true)
	for i in range(pending_summons.size() - 1, -1, -1):
		var mark: Dictionary = pending_summons[i]
		mark.age += delta
		if mark.age < game.boss_balance.summon_warning:
			continue
		if game.players_near(mark.at, 55) or not game.enemy_space_free(mark.at, game.enemy_data[mark.id].radius):
			mark.wait += delta
			continue
		if stage != "combat":pending_summons.remove_at(i);continue
		if stage == "combat" and summons.size() < game.boss_balance.summon_limit and game.enemies.size() < game.balance.max_enemies:
			var minion = game.spawn_enemy(mark.id, mark.at)
			if minion==null:
				continue
			minion.summoner_id = mark.owner
			summons[minion.get_instance_id()] = minion
			pending_summons.remove_at(i)
	for area in areas.duplicate():
		area.age += delta
		if area.kind=="ring":
			area.at=area.ring_center+Vector2.from_angle(area.ring_angle)*maxf(0,game.boss_balance.ring_radius-maxf(0,area.age-area.warning)*game.boss_balance.ring_speed)
			if area.age>=area.warning:
				if not area.has("hits"):area.hits={}
				for player in game.team_players():
					if not area.hits.has(player.get_instance_id()) and player.position.distance_to(area.at)<=area.radius+player.radius:
						area.hits[player.get_instance_id()]=true
						player.take_damage(area.damage,area.at,area.owner)
		if area.kind == "lightning" and area.age >= area.warning and not area.hit:
			area.hit = true
			game.sound.play_cue("thunder")
			game.damage_team_area(area.at, area.radius, area.damage,area.owner)
			if game.state != "running": return
	areas = areas.filter(func(area): return area.age < area.warning + area.duration)
	for swing in swings:
		swing.life -= delta
	swings = swings.filter(func(swing): return swing.life > 0)
	queue_redraw()

func can_cast(power: String) -> bool:
	if power in ["ice","lightning","ring"] and has_area("ring"):return false
	if power == "ring":return areas.is_empty()
	if power == "lightning":
		return not has_area("ice") and not has_area("lightning") and areas.size() < game.boss_balance.area_limit - 3
	if power == "ice":
		return not has_area("lightning") and not has_area("ice") and areas.size() < game.boss_balance.area_limit - 4
	if power == "summon":
		return game.boss_balance.summon_limit-summons.size()-pending_summons.size() >= (game.boss_balance.second_summon_batch if is_instance_valid(demon) and demon.form==2 else game.boss_balance.first_summon_batch)
	if power == "fire":
		return game.enemy_projectiles.fire_count() < game.boss_balance.fire_limit - 14
	return true

func has_area(kind: String) -> bool:
	for area in areas:
		if area.kind == kind:
			return true
	return false

func cast(power: String, boss, direction: Vector2, phase: int) -> bool:
	if not can_cast(power) or not boss.alive or not boss.combat_enabled:
		return false
	attack_history.append(power)
	if attack_history.size() > 64:
		attack_history.pop_front()
	var owner: int = boss.get_instance_id()
	if power == "fire":
		fire_fan(boss.position, direction, 5 if phase == 1 else (6 if phase == 2 else 7), owner, phase)
		var volleys:int=game.boss_balance.second_fire_volleys if boss.form==2 else game.boss_balance.first_fire_volleys
		for volley in range(1,volleys):
			bursts.append({"at":boss.position,"direction":direction,"count":6,"owner":owner,"phase":phase,"delay":game.boss_balance.second_fire_delay*volley})
	elif power == "summon":
		var count:int=game.boss_balance.second_summon_batch if boss.form==2 else game.boss_balance.first_summon_batch
		if game.boss_balance.summon_limit-summons.size()-pending_summons.size()<count:return false
		var points:Array[Vector2]=[]
		for i in count:
			for attempt in 80:
				var at:Vector2=boss.position+Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(170,310)
				if game.players_near(at,95) or not game.arena.safe_position(at,15):continue
				if points.any(func(p):return p.distance_to(at)<36):continue
				points.append(at);break
		if points.size()!=count:return false
		var types:Array=["ghoul","skeleton_sword","skeleton_archer"] if boss.form==1 else ["skeleton_sword","skeleton_archer","beast","plague"]
		for i in points.size():pending_summons.append({"at":points[i],"id":types[i%types.size()],"age":0.0,"wait":0.0,"owner":owner})
		game.sound.play_cue("summon")
	elif power == "lightning":
		var count:int=game.boss_balance.second_lightning_count if boss.form==2 else game.boss_balance.first_lightning_count
		var axis:Vector2=Vector2.RIGHT.rotated((boss.attack_index%6)*PI/6)
		var aim:Vector2=game.player.position
		for i in count:
			var at:Vector2=aim+axis*(i-(count-1)*.5)*70
			add_area("lightning",at,game.boss_balance.sector_radius,game.boss_balance.sector_warning,.3,game.boss_balance.lightning_damage,owner)
			areas.back().age=-i*game.boss_balance.sector_delay
	elif power == "ice":
		var rectangles:Array[Rect2]=IceLayout.plan(game,game.boss_balance.ice_band_length,game.boss_balance.ice_band_width,game.boss_balance.ice_corridor,game.boss_balance.ice_opening)
		if rectangles.is_empty():return false
		for rect in rectangles:
			add_area("ice",rect.get_center(),game.boss_balance.ice_radius,game.boss_balance.ice_warning,game.boss_balance.ice_duration,0,owner)
			areas.back().size=rect.size
		game.sound.play_cue("ice")
	elif power == "ring":
		var gap:int=boss.attack_index%12
		for i in 12:
			if i==gap or i==(gap+1)%12:continue
			var at:Vector2=game.player.position+Vector2.from_angle(i*TAU/12)*game.boss_balance.ring_radius
			add_area("ring",at,game.boss_balance.ring_hit_radius,1.5,game.boss_balance.ring_radius/game.boss_balance.ring_speed,game.boss_balance.lightning_damage,owner)
			areas.back().ring_center=game.player.position
			areas.back().ring_angle=i*TAU/12
	return true

func add_area(kind: String, at: Vector2, radius: float, warning: float, duration: float, damage: float, owner: int) -> void:
	if areas.size() >= game.boss_balance.area_limit:
		return
	areas.append({"kind": kind, "at": at, "radius": radius, "age": 0.0, "warning": warning, "duration": duration, "damage": damage * game.enemy_scale().damage * (game.boss_balance.second_damage_multiplier if is_instance_valid(demon) and demon.form==2 else 1), "owner": owner, "hit": false})
	queue_redraw()

func fire_fan(at: Vector2, direction: Vector2, count: int, owner: int, phase: int, offset: bool = false) -> void:
	var spacing: float = game.boss_balance.fire_spacing
	for i in count:
		var angle: float = (i - (count - 1) * 0.5) * spacing
		if offset:
			angle += 0.06
		game.enemy_projectiles.fire_ball(at + direction * 28, direction.rotated(angle), owner, phase)

func slow_multiplier(at: Vector2) -> float:
	for area in areas:
		if area.kind!="ice" or area.age<area.warning or area.age>=area.warning+area.duration:continue
		var inside:bool=Rect2(area.at-area.size/2,area.size).has_point(at) if area.has("size") else at.distance_squared_to(area.at)<area.radius*area.radius
		if inside:return game.boss_balance.ice_slow_multiplier
	return 1.0

func _draw() -> void:
	if game == null or game.state in ["title", "hub", "tree", "lab"]:
		return
	if stage == "portal":
		var vertices := PackedVector2Array()
		for i in 5:
			vertices.append(center + Vector2.from_angle(-PI / 2 + i * TAU / 5) * 72)
		var progress: float = minf(1, portal_age / game.boss_balance.portal_trace)
		for i in 5:
			var a: Vector2 = vertices[(i * 2) % 5]
			var b: Vector2 = vertices[((i + 1) * 2) % 5]
			draw_line(a.round(), b.round(), Color("4f3439"), 2)
			var portion: float = clampf(progress * 5 - i, 0, 1)
			if portion > 0:
				draw_line(a.round(), a.lerp(b, portion).round(), Color("dc8c58"), 2)
		draw_arc(center, 78, 0, TAU, 50, Color("b65f42"), 1)
		if portal_age >= game.boss_balance.portal_trace:
			var open_progress: float = clampf((portal_age - game.boss_balance.portal_trace) / game.boss_balance.portal_open, 0, 1)
			var closing: float = clampf((game.boss_balance.portal_duration() - portal_age) / game.boss_balance.portal_close, 0, 1)
			var radius: float = 48 * minf(open_progress, closing)
			draw_circle(center, radius, Color("101019"))
			draw_arc(center, radius, 0, TAU, 40, Color("ad6b83"), 3, false)
			for i in 12:
				var ember: Vector2 = center + Vector2.from_angle(i * TAU / 12 + portal_age) * (radius + 8)
				draw_rect(Rect2(ember.round(), Vector2(2, 3)), Color("df8956"))
	for mark in pending_summons:
		draw_arc(mark.at, 17, 0, TAU, 20, Color("ad8eac"), 1)
		draw_arc(mark.at, 17 * minf(1, mark.age / game.boss_balance.summon_warning), 0, TAU, 20, Color("d7c9a1"), 1)
	for area in areas:
		var active: bool = area.age >= area.warning
		if area.kind == "ice":
			if area.has("size"):
				draw_ice_barrier(area,active)
				continue
			var color := Color("83c4bd")
			draw_circle(area.at, area.radius, Color(color, 0.20 if active else 0.06))
			draw_arc(area.at, area.radius, 0, TAU, 32, color, 1)
			for i in 6:
				var line: Vector2 = Vector2.from_angle(i * TAU / 6) * area.radius * 0.7
				draw_line(area.at, (area.at + line).round(), Color(color, 0.6), 1)
		else:
			draw_circle(area.at, area.radius, Color(0.85, 0.68, 0.4, 0.30 if active else 0.06))
			draw_arc(area.at, area.radius, 0, TAU, 30, Color("dfb969"), 2 if active else 1)
			if active and area.kind=="lightning":
				draw_polyline(PackedVector2Array([area.at - Vector2(0, 90), area.at + Vector2(-8, -49), area.at + Vector2(7, -35), area.at]), Color("f4e6be"), 3, false)
	for swing in swings:
		var angle: float = swing.direction.angle()
		draw_arc(swing.at, game.boss_balance.executioner_swing_range, angle - 1.18, angle + 1.18, 30, Color("e3c9a1"), 3, false)

func clear_for_transform():
	areas.clear();pending_summons.clear();bursts.clear();swings.clear()
	for minion in summons.values():
		if is_instance_valid(minion):game.despawn_enemy(minion)
	summons.clear()
	game.enemy_projectiles.reset()
	game.hazards.clear()
	game.specials.areas.clear();game.specials.bolts.clear();game.specials.marks.clear()
	game.specials.casters.clear()
	queue_redraw()

func draw_ice_barrier(area:Dictionary,active:bool):
	IceVFX.render(self,ice_texture,area,active)
