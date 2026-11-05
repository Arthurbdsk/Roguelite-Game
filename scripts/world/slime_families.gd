class_name SlimeFamilies
extends Node2D
var game
var pending:Array[Dictionary]=[]
var reserved:Dictionary={}
var split_texture=preload("res://assets/slime_split.png")
func reset():
	pending.clear();reserved.clear();queue_redraw()
func can_add()->bool:
	return (reserved.size()+pending.size()+1)*game.balance.slime_children+maxi(game.balance.max_enemies,game.enemies.size())<=game.balance.split_entity_budget
func schedule(enemy):
	reserved.erase(enemy.serial)
	pending.append({"at":enemy.position,"age":0.0,"points":[],"spawned":0})
func tick(delta:float):
	for batch in pending.duplicate():
		if batch.points.is_empty():
			for i in game.balance.slime_children:
				for attempt in 120:
					var at:Vector2=batch.at+Vector2.from_angle((i+attempt*.37)*TAU/game.balance.slime_children)*(24+attempt%6*10)
					if not game.arena.safe_position(at,4):continue
					if batch.points.any(func(p):return p.distance_to(at)<8):continue
					batch.points.append(at);break
			if batch.points.size()!=game.balance.slime_children:batch.points.clear();continue
		batch.age+=delta
		if batch.age<game.balance.slime_split_warning:continue
		for i in range(int(batch.spawned),batch.points.size()):
			if game.enemies.size()>=game.balance.split_entity_budget:break
			var child=game.spawn_enemy("slime_small",batch.points[i])
			if child==null:break
			batch.spawned+=1
			child.grace=game.balance.slime_grace
			var gold:int=maxi(0,game.balance.slime_family_gold-game.enemy_data.slime_large.gold_value)
			var xp:int=maxi(0,game.balance.slime_family_xp-game.enemy_data.slime_large.experience)
			child.data.gold_value=gold/game.balance.slime_children+(1 if i<gold%game.balance.slime_children else 0)
			child.data.experience=xp/game.balance.slime_children+(1 if i<xp%game.balance.slime_children else 0)
		if batch.spawned==game.balance.slime_children:pending.erase(batch)
	queue_redraw()
func _draw():
	if game==null or game.state not in ["running","paused","upgrading"]:return
	for batch in pending:
		var f:int=mini(7,int(batch.age/game.balance.slime_split_warning*8))
		draw_texture_rect_region(split_texture,Rect2(batch.at-Vector2(40,40),Vector2(80,64)),Rect2(f*80,0,80,64))
		for at in batch.points:draw_rect(Rect2(at-Vector2(3,1),Vector2(6,2)),Color("80d9da"))
