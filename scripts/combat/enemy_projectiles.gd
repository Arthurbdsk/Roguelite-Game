class_name EnemyProjectiles
extends Node2D

var game
var arrows: Array[Dictionary] = []
var serial: int = 0

func setup(owner_game) -> void:
	game = owner_game
	z_index = 4

func reset() -> void:
	arrows.clear()
	queue_redraw()

func clear_shot(origin: Vector2, target: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(origin, target, 4)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func fire(origin: Vector2, direction: Vector2, stats: EnemyData) -> bool:
	if arrows.size() >= game.balance.max_enemy_projectiles or direction.length_squared() < 0.1:
		return false
	serial += 1
	arrows.append({"id": serial, "at": origin, "velocity": direction.normalized() * stats.arrow_speed, "damage": stats.damage, "distance": 0.0, "range": stats.arrow_range, "life": stats.arrow_lifetime})
	game.sound.play_cue("arrow")
	queue_redraw()
	return true

func tick(delta: float) -> void:
	if game.state != "running":
		return
	for i in range(arrows.size() - 1, -1, -1):
		var arrow: Dictionary = arrows[i]
		arrow.life -= delta
		if arrow.life <= 0:
			arrows.remove_at(i)
			continue
		var start: Vector2 = arrow.at
		var remaining: float = arrow.range - arrow.distance
		var movement: Vector2 = Vector2(arrow.velocity) * delta
		movement = movement.limit_length(maxf(0, remaining))
		var end: Vector2 = start + movement
		var query := PhysicsRayQueryParameters2D.create(start, end, 4)
		query.hit_from_inside = true
		var wall: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
		if not wall.is_empty():
			end = wall.position
		var nearest := Geometry2D.get_closest_point_to_segment(game.player.position, start, end)
		if nearest.distance_squared_to(game.player.position) <= pow(game.player.radius + game.balance.arrow_radius, 2):
			arrows.remove_at(i)
			game.player.take_damage(arrow.damage, start)
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
	for arrow in arrows:
		var point: Vector2 = arrow.at.round()
		var direction: Vector2 = arrow.velocity.normalized()
		draw_line((point - direction * 10).round(), point, Color("b68a55"), 2, false)
		draw_line((point - direction * 9).round(), (point - direction * 6).round(), Color("eee0b8"), 2, false)
		var tip: Vector2 = point + direction * 3
		draw_colored_polygon(PackedVector2Array([tip.round(), (point - direction.orthogonal() * 2).round(), (point + direction.orthogonal() * 2).round()]), Color("f1b26f"))
