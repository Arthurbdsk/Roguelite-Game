class_name EnemyProjectiles
extends Node2D

var game
var fire_texture=preload("res://assets/effects/fire.png")
var impact_texture=preload("res://assets/effects/impact.png")
var visual_fire:Dictionary={}
var fire_impacts:Array[Dictionary]=[]
var arrows: Array[Dictionary] = []
var serial: int = 0
var wall_query:=PhysicsRayQueryParameters2D.new()

func setup(owner_game) -> void:
	game = owner_game
	z_index = 4

func reset() -> void:
	visual_fire.clear();fire_impacts.clear()
	arrows.clear()
	queue_redraw()

func clear_shot(origin: Vector2, target: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(origin, target, 4)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func fire(origin: Vector2, direction: Vector2, stats: EnemyData, owner: int = 0) -> bool:
	var limit: int = mini(game.balance.max_enemy_projectiles, game.boss_balance.final_projectile_limit) if game.boss_arena.final_active() else game.balance.max_enemy_projectiles
	if arrows.size() >= limit or direction.length_squared() < 0.1:
		return false
	serial += 1
	arrows.append({"id": serial, "at": origin, "velocity": direction.normalized() * stats.arrow_speed, "damage": stats.damage, "distance": 0.0, "range": stats.arrow_range, "life": stats.arrow_lifetime, "owner": owner, "kind": "arrow", "radius": game.balance.arrow_radius})
	game.sound.play_cue("arrow")
	queue_redraw()
	return true

func fire_count() -> int:
	var count: int = 0
	for projectile in arrows:
		count += int(projectile.get("kind", "arrow") == "fire")
	return count

func fire_ball(origin: Vector2, direction: Vector2, owner: int, phase: int, damage_override:float=-1,limit_override:int=-1) -> bool:
	if arrows.size() >= (game.boss_balance.final_projectile_limit if limit_override<0 else game.balance.max_enemy_projectiles) or fire_count() >= (game.boss_balance.fire_limit if limit_override<0 else limit_override):
		return false
	serial += 1
	arrows.append({"id": serial, "at": origin, "velocity": direction.normalized() * game.boss_balance.fire_speed * (1.08 if phase == 3 else 1), "damage": game.boss_balance.fire_damage * game.enemy_scale().damage * (game.boss_balance.second_damage_multiplier if is_instance_valid(game.boss_arena.demon) and game.boss_arena.demon.form==2 else 1), "distance": 0.0, "range": 900.0, "life": game.boss_balance.fire_lifetime, "owner": owner, "kind": "fire", "radius": 5.0})
	if damage_override>=0:arrows.back().damage=damage_override
	game.sound.play_cue("fire")
	queue_redraw()
	return true

func remove_owner(owner: int) -> void:
	arrows = arrows.filter(func(projectile): return projectile.get("owner", 0) != owner)
	queue_redraw()

func tick(delta: float) -> void:
	if game.state != "running":
		return
	for i in range(arrows.size() - 1, -1, -1):
		var arrow: Dictionary = arrows[i]
		if game.consumables!=null and game.consumables.paused_projectile(arrow):continue
		arrow.life -= delta
		if arrow.life <= 0:
			arrows.remove_at(i)
			continue
		var start: Vector2 = arrow.at
		var remaining: float = arrow.range - arrow.distance
		var movement: Vector2 = Vector2(arrow.velocity) * delta
		movement = movement.limit_length(maxf(0, remaining))
		var end: Vector2 = start + movement
		wall_query.from=start;wall_query.to=end;wall_query.collision_mask=4;wall_query.hit_from_inside=true
		var wall: Dictionary = get_world_2d().direct_space_state.intersect_ray(wall_query)
		if not wall.is_empty():
			end = wall.position
		var victim = game.projectile_victim(start, end, arrow.get("radius", game.balance.arrow_radius))
		if victim != null:
			arrows.remove_at(i)
			victim.take_damage(arrow.damage, start)
			if game.state != "running":
				queue_redraw()
				return
			continue
		arrow.at = end
		arrow.distance += start.distance_to(end)
		if not wall.is_empty() or arrow.distance >= arrow.range or not Rect2(20, 20, 1760, 1160).has_point(end):
			arrows.remove_at(i)
	queue_redraw()

func _draw() -> void:
	if game == null or game.state in ["title", "hub"]:
		return
	var current:Dictionary={}
	for arrow in arrows:
		if arrow.get("kind","")=="fire":current[str(arrow.id)]={"at":arrow.at,"angle":arrow.velocity.angle()}
	for id in visual_fire:
		if not current.has(id):fire_impacts.append({"at":visual_fire[id].at,"angle":visual_fire[id].angle,"start":game.elapsed})
	visual_fire=current
	fire_impacts=fire_impacts.filter(func(f):return game.elapsed-f.start<.4)
	for fx in fire_impacts:
		draw_set_transform(fx.at.round(),fx.angle)
		draw_texture_rect_region(impact_texture,Rect2(-12,-12,24,24),Rect2(mini(6,int((game.elapsed-fx.start)*18))*24,0,24,24))
		draw_set_transform(Vector2.ZERO)
	for arrow in arrows:
		var point: Vector2 = arrow.at.round()
		var direction: Vector2 = arrow.velocity.normalized()
		if arrow.get("kind", "arrow") == "fire":
			draw_set_transform(point,direction.angle())
			draw_texture_rect_region(fire_texture,Rect2(-25,-12,32,24),Rect2(int(game.elapsed*14)%6*32,0,32,24))
			draw_set_transform(Vector2.ZERO)
			continue
		draw_line((point - direction * 10).round(), point, Color("b68a55"), 2, false)
		draw_line((point - direction * 9).round(), (point - direction * 6).round(), Color("eee0b8"), 2, false)
		var tip: Vector2 = point + direction * 3
		draw_colored_polygon(PackedVector2Array([tip.round(), (point - direction.orthogonal() * 2).round(), (point + direction.orthogonal() * 2).round()]), Color("f1b26f"))
