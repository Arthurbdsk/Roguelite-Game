class_name Devourer
extends HordeEnemy
var meals:int=0
var swallowed_gold:int=0
var swallowed_xp:float=0
var search_clock:float=0
var food:Dictionary={}
func growth_visual():
	var size:float=minf(game.balance.devour_max_scale,1+meals*game.balance.devour_growth_step)
	if not game.enemy_space_free(position,data.radius*size,self):return
	sprite.scale=Vector2.ONE*size
	sprite.position.y=-12*size
	radius=data.radius*size
	var shape=get_child(0) as CollisionShape2D
	if shape!=null:shape.shape.radius=radius
func tick(delta:float):
	if not alive or tick_control(delta):return
	clock+=delta;attack_time-=delta;state_time+=delta;search_clock-=delta
	if search_clock<=0:
		if meals>0:growth_visual()
		food=game.food_index.nearest(position);search_clock=game.balance.food_search_interval
	if not food.is_empty() and (food.item.get("consumed",false) or food.item.get("attracted",false)):food={}
	var destination:Vector2=game.player.position if food.is_empty() else food.item.at
	var direction:Vector2=(destination-position).normalized()
	if not food.is_empty() and destination.distance_to(position)<=radius+3:
		if game.food_index.consume(food):
			if food.kind=="gold":swallowed_gold+=int(food.item.value)
			else:swallowed_xp+=float(food.item.xp)
			meals+=1;max_hp+=game.balance.devour_health_gain;hp+=game.balance.devour_health_gain
			data.damage+=game.balance.devour_damage_gain;growth_visual()
		food={};search_clock=0
	if food.is_empty():
		if state=="prepare":
			if state_time>=data.windup:
				game.damage_team_cone(position,charge_direction,radius+20,.9,data.damage)
				state="recovery";state_time=0;attack_time=data.attack_interval
		elif state=="recovery":
			if state_time>=data.recovery:state="approach"
		elif attack_time<=0 and position.distance_to(game.player.position)<radius+20:
			state="prepare";state_time=0;charge_direction=direction
	else:state="approach"
	if state=="approach":direction=game.navigation.steer(self,direction,destination).normalized()
	velocity=(direction*data.speed*(slow_factor if slow_remaining>0 else 1) if state=="approach" else Vector2.ZERO)+knockback
	knockback=knockback.move_toward(Vector2.ZERO,delta*500)
	velocity=game.crowd_velocity(self,velocity)
	move_and_slide()
	sprite.frame=4 if state=="prepare" else int(clock*7)%4
	sprite.flip_h=direction.x<0
	queue_redraw()
