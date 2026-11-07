class_name SlimeFamilies
extends Node2D
var game
var pending:Array[Dictionary]=[]
var reserved:Dictionary={}
func reset():
	pending.clear();reserved.clear();queue_redraw()
func can_add()->bool:
	return (reserved.size()+pending.size()+1)*game.balance.slime_children+maxi(game.balance.max_enemies,game.enemies.size())<=game.balance.split_entity_budget
func schedule(enemy):
	reserved.erase(enemy.serial)
	pending.append({"at":enemy.position,"age":0.0,"points":[],"spawned":0,"visual_kind":enemy.tiny_kind,"flip":enemy.sprite.flip_h})
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
		# The shared death animation draws the first half-second. Keep its final
		# original-art pose during the remaining warning, never the old blue blob.
		var kind:String=batch.get("visual_kind","original_slime_large")
		if batch.age>=.5 and TinyCharacters.available(kind):
			var d:Dictionary=TinyCharacters.data(kind);var cell:=Vector2(float(d.cell[0]),float(d.cell[1]));var offset:=Vector2(float(d.offset[0]),float(d.offset[1]))
			var alpha:float=clampf((game.balance.slime_split_warning-float(batch.age))/.15,0,1)
			draw_set_transform(batch.at,0,Vector2(-1 if batch.get("flip",false) else 1,1))
			draw_texture_rect_region(TinyCharacters.texture(kind),Rect2(offset-cell*.5,cell),Rect2(TinyCharacters.frame(kind,"death",1)*cell.x,0,cell.x,cell.y),Color(1,1,1,alpha))
			draw_set_transform(Vector2.ZERO)
		for at in batch.points:draw_rect(Rect2(at-Vector2(3,1),Vector2(6,2)),Color("80d9da"))
