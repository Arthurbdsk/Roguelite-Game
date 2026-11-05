class_name SpecialEnemy
extends HordeEnemy
var summon_cooldown:float=1.0
var ambush_at:Vector2=Vector2.ZERO
func tick(delta:float):
	if not alive:return
	if tick_control(delta):return
	clock+=delta;state_time+=delta;attack_time-=delta;summon_cooldown-=delta
	hit_flash=maxf(0,hit_flash-delta)
	var offset:Vector2=game.player.position-position
	var direction:Vector2=offset.normalized()
	var movement:Vector2=direction*data.speed
	if data.id in ["necromancer","plague"]:
		if offset.length()<110:movement=-direction*data.speed
		elif offset.length()<190:movement=Vector2.ZERO
		if state=="prepare":
			movement=Vector2.ZERO
			if state_time>=data.windup:
				if data.id=="necromancer":game.specials.magic(position,charge_direction,data.damage,chain_root)
				else:game.specials.flask(position,ambush_at,chain_root)
				state="recovery";state_time=0;attack_time=data.attack_interval
		elif state=="recovery":
			movement=Vector2.ZERO
			if state_time>=data.recovery:state="approach"
		elif state=="approach" and attack_time<=0 and offset.length()<data.attack_range:
			state="prepare";state_time=0;charge_direction=direction;ambush_at=game.player.position
		if data.id=="necromancer" and summon_cooldown<=0 and state in ["approach","conjure_wait"]:
			if game.specials.summon(self):
				summon_cooldown=game.specials.balance.summon_interval
				state="conjure";state_time=0
			else:
				summon_cooldown=.35
				if chain_root>0:state="conjure_wait"
		if state=="conjure_wait":movement=Vector2.ZERO
		if state=="conjure":
			movement=Vector2.ZERO
			if state_time>=game.specials.balance.summon_warning:state="approach"
	elif data.id=="beast":
		if state=="approach" and offset.length()<data.attack_range and attack_time<=0:
			state="prepare";state_time=0;charge_direction=direction
		elif state=="prepare":
			movement=Vector2.ZERO
			if state_time>=data.windup:
				game.damage_team_cone(position,charge_direction,data.attack_range,0.9,data.damage)
				state="recovery";state_time=0;attack_time=data.attack_interval
		elif state=="recovery":
			movement=Vector2.ZERO
			if state_time>=data.recovery:state="approach"
	elif data.id=="shadow":
		if state=="approach" and attack_time<=0:
			ambush_at=game.player.position;state="ambush";state_time=0;targetable=false;sprite.visible=false;collision_layer=0
		if state=="ambush":
			movement=Vector2.ZERO
			if state_time>=game.specials.balance.shadow_warning and game.enemy_space_free(ambush_at,radius,self):
				position=ambush_at;collision_layer=2;targetable=true;sprite.visible=true;state="recovery";state_time=0
				for player in game.team_players():
					if player.position.distance_to(ambush_at)<=game.specials.balance.shadow_radius+player.radius:
						if player.take_damage(data.damage,ambush_at):player.root_remaining=game.specials.balance.shadow_root
				attack_time=data.attack_interval
		elif state=="recovery":
			movement=Vector2.ZERO
			if state_time>=game.specials.balance.shadow_exposure:state="approach"
	if state=="approach":movement=game.navigation.steer(self,movement)+game.separation(self)*8
	if slow_remaining>0:movement*=slow_factor
	velocity=movement+knockback
	knockback=knockback.move_toward(Vector2.ZERO,delta*500)
	velocity=game.crowd_velocity(self,velocity)
	move_and_slide()
	if data.frames>=16:
		if state=="conjure_wait":sprite.frame=8+int(clock*4)%2
		elif state=="prepare":sprite.frame=8+mini(3,int(state_time/maxf(.01,data.windup)*4))
		elif state=="conjure":sprite.frame=8+mini(7,int(state_time/maxf(.01,game.specials.balance.summon_warning)*8))
		elif state=="recovery":sprite.frame=12+mini(3,int(state_time/maxf(.01,data.recovery)*4))
		else:sprite.frame=(4+int(clock*9)%4) if movement.length()>2 else int(clock*5)%4
		sprite.rotation=0
	else:sprite.frame=4 if state in ["prepare","conjure"] else (5 if state=="recovery" else int(clock*6)%4)
	if data.id=="plague" and data.frames<16:
		sprite.rotation=(-.12 if sprite.flip_h else .12) * sin(minf(1,state_time/maxf(.01,data.windup))*PI) if state=="prepare" else 0
	sprite.modulate=Color(1.5,1.5,1.5) if hit_flash>0 else Color.WHITE
	sprite.flip_h=direction.x<0
	queue_redraw()
func take_damage(amount:float,force:Vector2=Vector2.ZERO):
	if targetable:super.take_damage(amount,force)
func _draw():
	super._draw()
	if data.id=="beast" and state=="prepare":
		draw_arc(Vector2.ZERO,data.attack_range,charge_direction.angle()-.9,charge_direction.angle()+.9,16,Color("d9a46a"),1)
	if state=="ambush":
		draw_circle(ambush_at-position,game.specials.balance.shadow_radius,Color(0.3,0.22,0.4,0.25))
		draw_arc(ambush_at-position,game.specials.balance.shadow_radius,0,TAU,24,Color("ad8eac"),1)
