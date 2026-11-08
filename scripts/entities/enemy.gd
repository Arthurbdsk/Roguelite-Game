class_name HordeEnemy
extends CharacterBody2D

var game
var data: EnemyData
var horde_health_bonus:float=0
var spawn_health_bonus:float=0
var last_hit_owner:String=""
var bestiary_seen:Dictionary={}
var bestiary_kill_registered:bool=false
var difficulty_health_factor:float=1
var hp: float
var max_hp: float
var radius: float
var alive: bool = true
var suppress_split:bool=false
var garlic_until:float=0
var garlic_sources:Dictionary={}
func movement_control_multiplier()->float:
	var factor:float=slow_factor if slow_remaining>0 else 1.0
	if self is HordeBoss:return factor
	for owner in garlic_sources.keys():
		var w=garlic_sources[owner].get_ref()
		if not is_instance_valid(w) or not w.attacks_enabled or int(w.levels.get("garlic",0))<=0 or w.game.player.down or position.distance_to(w.game.player.position)>w._stat("garlic","reach")+radius:
			garlic_sources.erase(owner)
		else:factor=minf(factor,.85)
	return factor
var elite: bool = false
var state: String = "approach"
var clock: float = 0
var state_time: float = 0
var attack_time: float = 2
var hit_flash: float = 0
var knockback: Vector2 = Vector2.ZERO
var charge_direction: Vector2 = Vector2.ZERO
var sprite: Sprite2D
var serial: int = 0
var tiny_kind:String=""
var motion_start:=Vector2.INF
var visual_attack_left:float=0
var visual_cast_release:float=0
var visual_attack_cooldown:float=0
var visual_attack_clip:String="attack"
var targetable: bool = true
var summoner_id: int = 0
var chain_root:int=0
var chain_generation:int=-1
var frozen_remaining:float=0
var freeze_resistance:float=0
var resistance_duration:float=1
var slow_remaining:float=0
var slow_factor:float=1
var last_visual_state:String=""
var last_visual_hp:float=-1
var last_visual_max:float=-1
var last_visual_radius:float=-1
var last_visual_charge:Vector2=Vector2.INF
var last_visual_frozen:bool=false
func refresh_visual():
	if state!=last_visual_state or hp!=last_visual_hp or max_hp!=last_visual_max or radius!=last_visual_radius or charge_direction!=last_visual_charge or (frozen_remaining>0)!=last_visual_frozen or state=="ambush":
		last_visual_state=state;last_visual_hp=hp;last_visual_max=max_hp;last_visual_radius=radius;last_visual_charge=charge_direction;last_visual_frozen=frozen_remaining>0;queue_redraw()
func move_body():
	var t:int=Time.get_ticks_usec() if game.perf_enabled else 0
	move_and_slide()
	if game.perf_enabled:game.perf_us["physics_bodies"]=int(game.perf_us.get("physics_bodies",0))+Time.get_ticks_usec()-t


func setup(owner_game, stats: EnemyData, is_elite: bool = false) -> void:
	game = owner_game
	data = stats
	elite = is_elite
	radius = data.radius * (1.2 if elite else 1.0)
	# Pressure comes from the encounter composition, never player upgrades or time.
	max_hp = data.health * (4.0 if elite else 1.0)
	if data.behavior == "boss":
		max_hp = data.health
	hp = max_hp
	attack_time = randf_range(1.5, 3.5)

func _ready() -> void:
	motion_mode=CharacterBody2D.MOTION_MODE_FLOATING
	max_slides=8
	platform_floor_layers=0
	collision_layer = 2
	collision_mask = 6
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	collision.shape = circle
	add_child(collision)
	sprite = Sprite2D.new()
	var family:String="orc" if data.id=="ghoul" else data.visual_family
	if not family.is_empty() and TinyCharacters.install(sprite,family):
		tiny_kind=family
	else:
		sprite.texture = load(data.texture if ResourceLoader.exists(data.texture) else "res://assets/ghoul.png")
		sprite.hframes = data.frames if ResourceLoader.exists(data.texture) else 4
		sprite.position.y = -float(sprite.texture.get_height()) * 0.5 + 4
	if elite and tiny_kind.is_empty():
		sprite.scale = Vector2(1.2, 1.2)
	add_child(sprite)
	sprite.scale*=1.1
	sprite.position*=1.1
	if data.damage_resistance>0 and not tiny_kind.begins_with("original_"):
		var badge:=Sprite2D.new();badge.texture=load(GameIcons.path("permanent:armor","res://assets/permanent/armor.png"));badge.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;badge.position=Vector2(0,-28 if not tiny_kind.is_empty() else -sprite.texture.get_height()-8);badge.scale=Vector2.ONE*10/badge.texture.get_width();add_child(badge)

func tick(delta: float) -> void:
	if not alive:
		return
	if tick_control(delta):return
	clock += delta
	state_time += delta
	attack_time -= delta
	hit_flash = maxf(0, hit_flash - delta)
	var offset: Vector2 = game.player.position - position
	var direction := offset.normalized()
	var movement := direction * data.speed
	if data.behavior in ["sword", "archer"]:
		movement = skeleton_attack(offset, direction)
	if data.behavior == "flank":
		movement += direction.orthogonal() * sin(clock * 2.5 + serial) * 15
	if data.behavior == "charge":
		if state == "approach" and attack_time <= 0 and offset.length() < 165:
			state = "prepare"
			state_time = 0
			charge_direction = direction
		elif state == "prepare":
			movement = Vector2.ZERO
			if state_time > 0.85:
				state = "attack"
				state_time = 0
		elif state == "attack":
			movement = charge_direction * 165 * game.balance.enemy_speed_multiplier * game.enemy_scale().speed
			if state_time > 0.65:
				state = "recovery"
				state_time = 0
		elif state == "recovery":
			movement = Vector2.ZERO
			if state_time > 1.25:
				state = "approach"
				attack_time = 4.0*game.balance.enemy_attack_interval_multiplier
	if data.behavior == "boss" and attack_time <= 0:
		attack_time = 4.5 if hp > max_hp * 0.5 else 3.2
		# Locked positions before impact. Never follow the player during the warning.
		game.add_hazard(game.player.position, 42, 1.3, 24,get_instance_id())
		for i in 6:
			var point := position + Vector2.from_angle(i * TAU / 6 + clock * 0.15) * 95
			game.add_hazard(point, 22, 1.6, 16,get_instance_id())
		state_time = 0
	if data.behavior == "boss" and state_time < 0.8:
		movement *= 0.15
	if state=="approach":movement=game.navigation.steer(self,movement)
	movement*=movement_control_multiplier()
	velocity = movement + game.separation(self) * 14 + knockback
	knockback = knockback.move_toward(Vector2.ZERO, delta * 500)
	velocity=game.crowd_velocity(self,velocity)
	var before_visual:Vector2=position
	move_body()
	if data.contact_damage and offset.length() < radius + game.player.radius:
		game.player.take_damage(data.damage * (1.25 if elite else 1), position,get_instance_id())
		if not tiny_kind.is_empty() and visual_attack_cooldown<=0:
			visual_attack_left=.22;visual_attack_cooldown=game.balance.same_attacker_interval;visual_attack_clip="attack" if serial%2==0 else "attack2"
	if not tiny_kind.is_empty():
		visual_attack_left=maxf(0,visual_attack_left-delta);visual_attack_cooldown=maxf(0,visual_attack_cooldown-delta)
		if tiny_kind.begins_with("original_"):
			original_visual(direction,position.distance_squared_to(before_visual)>pow(delta*2,2));refresh_visual();return
		if hit_flash>0:sprite.frame=TinyCharacters.frame(tiny_kind,"hurt",1-hit_flash/.09)
		elif visual_attack_left>0:sprite.frame=TinyCharacters.frame(tiny_kind,visual_attack_clip,.5+.5*(1-visual_attack_left/.22))
		elif position.distance_squared_to(before_visual)>pow(delta*2,2):sprite.frame=TinyCharacters.frame(tiny_kind,"walk",clock*1.25,true)
		else:sprite.frame=TinyCharacters.frame(tiny_kind,"idle",clock,true)
		sprite.flip_h=direction.x<0
		sprite.position.x=float(TinyCharacters.data(tiny_kind).offset[0])*(-1 if sprite.flip_h else 1)*sprite.scale.x
		sprite.modulate=Color(1.3,.8,.6) if elite else Color.WHITE
		refresh_visual();return
	sprite.frame = int(clock * 7) % 4
	if data.frames >= 6 and state in ["prepare", "recovery"]:
		sprite.frame = 4 if state == "prepare" else 5
	sprite.flip_h = charge_direction.x < 0 if state == "prepare" else direction.x < 0
	sprite.modulate = Color(2, 2, 2) if hit_flash > 0 else (Color(1.3, 0.8, 0.6) if elite else Color.WHITE)
	refresh_visual()

func original_visual(direction:Vector2,moving:bool):
	if hit_flash>0:sprite.frame=TinyCharacters.frame(tiny_kind,"hurt",1-hit_flash/.09)
	elif visual_cast_release>0:sprite.frame=TinyCharacters.frame(tiny_kind,"cast",.5)
	elif state=="attack":sprite.frame=TinyCharacters.frame(tiny_kind,"cast",clock*2,true)
	elif state=="prepare":sprite.frame=TinyCharacters.frame(tiny_kind,"attack",.5*state_time/maxf(.01,.85 if data.behavior=="charge" else data.windup))
	elif state=="conjure":sprite.frame=TinyCharacters.frame(tiny_kind,"cast",minf(.74,state_time/maxf(.01,game.specials.balance.summon_warning)*.75))
	elif state=="recovery":sprite.frame=TinyCharacters.frame(tiny_kind,"attack",.5+.5*state_time/maxf(.01,1.25 if data.behavior=="charge" else data.recovery))
	elif visual_attack_left>0:sprite.frame=TinyCharacters.frame(tiny_kind,"attack",.5+.5*(1-visual_attack_left/.22))
	else:sprite.frame=TinyCharacters.frame(tiny_kind,"walk" if moving else "idle",clock*1.5,true)
	sprite.flip_h=(charge_direction.x if state in ["prepare","attack","recovery"] else direction.x)<0
	sprite.position.x=float(TinyCharacters.data(tiny_kind).offset[0])*(-1 if sprite.flip_h else 1)*sprite.scale.x
	sprite.modulate=Color(1.3,.8,.6) if elite else Color.WHITE

func skeleton_attack(offset: Vector2, direction: Vector2) -> Vector2:
	var distance: float = offset.length()
	var movement := direction * data.speed
	if data.behavior == "archer":
		if distance < data.retreat_distance:
			movement = -direction * data.speed
		elif distance < data.preferred_distance:
			movement = direction.orthogonal() * sin(clock + serial) * data.speed * 0.4
	if state == "approach":
		if data.behavior == "sword" and distance <= data.attack_range:
			movement = Vector2.ZERO
		if attack_time <= 0 and distance <= data.attack_range and (data.behavior != "archer" or distance >= data.retreat_distance * 0.65):
			if data.behavior == "archer" and not game.enemy_projectiles.clear_shot(position, game.player.position):
				return direction.orthogonal() * data.speed
			state = "prepare"
			state_time = 0
			charge_direction = direction
			return Vector2.ZERO
		return movement
	if state == "prepare":
		if state_time >= data.windup:
			state = "recovery"
			state_time = 0
			attack_time = data.attack_interval
			if data.behavior == "archer":
				game.enemy_projectiles.fire(position + charge_direction * 12, charge_direction, data, summoner_id,get_instance_id())
			else:
				# One damage decision per swing, at its locked direction.
				if distance <= data.attack_range + game.player.radius and absf(charge_direction.angle_to(direction)) <= deg_to_rad(data.attack_half_angle):
					game.player.take_damage(data.damage, position,get_instance_id())
		return Vector2.ZERO
	if state == "recovery":
		if state_time >= data.recovery:
			state = "approach"
		return Vector2.ZERO
	return movement

func take_damage(amount: float, force: Vector2 = Vector2.ZERO,owner:String="") -> void:
	if not alive:
		return
	amount=received_damage(amount)
	if amount>0:last_hit_owner=owner
	hp -= amount
	hit_flash = 0.09
	knockback += force * (0.2 if data.behavior == "boss" else (1.3 if game.elapsed<garlic_until else 1.0))
	game.add_damage_number(position - Vector2(0, 18), amount)
	game.sound.play_cue("hit")
	if hp <= 0:
		alive = false
		game.enemy_killed(self)
		queue_free()

func _draw() -> void:
	if frozen_remaining>0:
		draw_arc(Vector2.ZERO,radius+5,0,TAU,20,Color("83c4bd"),2)
		draw_line(Vector2(-3,-34),Vector2(3,-34),Color("83c4bd"),2)
	draw_rect(Rect2(-radius, -1, radius * 2, 5), Color(0, 0, 0, 0.3))
	if state == "prepare":
		var reach: float = minf(data.attack_range, 78.0) if data.behavior == "archer" else (data.attack_range if data.behavior == "sword" or data.id=="beast" else 110.0)
		draw_line(Vector2.ZERO, charge_direction * reach, Color("d9a46a"), 1)
		draw_arc(Vector2.ZERO, radius + 5, 0, TAU, 20, Color("d9a46a"), 1, false)
		if data.behavior == "sword":
			var angle: float = charge_direction.angle()
			draw_arc(Vector2.ZERO, data.attack_range, angle - 0.8, angle + 0.8, 12, Color("dfb969"), 1, false)
	if state == "recovery" and data.behavior == "sword" and state_time < 0.14:
		var angle: float = charge_direction.angle()
		draw_arc(Vector2.ZERO, data.attack_range, angle - 1.1, angle + 1.1, 12, Color("eee0b8"), 2, false)
	if elite:
		draw_arc(Vector2.ZERO, radius + 3, 0, TAU, 20, Color("b65f42"), 1, false)
	if hp < max_hp and data.behavior != "boss":
		var bar_y:float=-sprite.texture.get_height()+1 if tiny_kind.is_empty() else -22
		if tiny_kind.begins_with("original_"):bar_y=-float(TinyCharacters.data(tiny_kind).get("visible_height",18))*sprite.scale.y-6
		draw_rect(Rect2(-11,bar_y,22,2), Color("12191d"))
		draw_rect(Rect2(-11,bar_y,22 * hp / max_hp,2), Color("b65f42"))

func apply_time_control(duration:float,resistance:float,boss_slow:float,boss_duration:float):
	if self is HordeBoss:
		slow_remaining=maxf(slow_remaining,boss_duration)
		slow_factor=1-boss_slow
	elif frozen_remaining<=0 and freeze_resistance<=0:
		frozen_remaining=minf(duration+1,duration*1.15) if game.elapsed<garlic_until else duration
		resistance_duration=resistance
	refresh_visual()
func tick_control(delta:float)->bool:
	if game.consumables!=null and game.consumables.freeze_left>0 and not self is HordeBoss:
		frozen_remaining=maxf(frozen_remaining,game.consumables.freeze_left)
		velocity=Vector2.ZERO
		refresh_visual()
		return true
	freeze_resistance=maxf(0,freeze_resistance-delta)
	slow_remaining=maxf(0,slow_remaining-delta)
	if frozen_remaining>0:
		frozen_remaining=maxf(0,frozen_remaining-delta)
		if frozen_remaining<=0:freeze_resistance=resistance_duration
		velocity=Vector2.ZERO
		refresh_visual()
		return true
	return false

func received_damage(amount:float)->float:
	return maxf(0,amount)*(1-clampf(data.damage_resistance,0,.75)) if data.behavior!="hazard_target" else maxf(0,amount)
