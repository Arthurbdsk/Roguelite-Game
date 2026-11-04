class_name HordeEnemy
extends CharacterBody2D

var game
var data: EnemyData
var hp: float
var max_hp: float
var radius: float
var alive: bool = true
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
var targetable: bool = true
var summoner_id: int = 0
var chain_root:int=0
var chain_generation:int=-1
var frozen_remaining:float=0
var freeze_resistance:float=0
var resistance_duration:float=1
var slow_remaining:float=0
var slow_factor:float=1

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
	collision_layer = 2
	collision_mask = 4
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	collision.shape = circle
	add_child(collision)
	sprite = Sprite2D.new()
	sprite.texture = load(data.texture)
	sprite.hframes = data.frames
	sprite.position.y = -float(sprite.texture.get_height()) * 0.5 + 4
	if elite:
		sprite.scale = Vector2(1.2, 1.2)
	add_child(sprite)

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
				attack_time = 4.0
	if data.behavior == "boss" and attack_time <= 0:
		attack_time = 4.5 if hp > max_hp * 0.5 else 3.2
		# Locked positions before impact. Never follow the player during the warning.
		game.add_hazard(game.player.position, 42, 1.3, 24)
		for i in 6:
			var point := position + Vector2.from_angle(i * TAU / 6 + clock * 0.15) * 95
			game.add_hazard(point, 22, 1.6, 16)
		state_time = 0
	if data.behavior == "boss" and state_time < 0.8:
		movement *= 0.15
	if state=="approach":movement=game.navigation.steer(self,movement)
	if slow_remaining>0:movement*=slow_factor
	velocity = movement + game.separation(self) * 14 + knockback
	knockback = knockback.move_toward(Vector2.ZERO, delta * 500)
	move_and_slide()
	if data.contact_damage and offset.length() < radius + game.player.radius:
		game.player.take_damage(data.damage * (1.25 if elite else 1), position)
	sprite.frame = int(clock * 7) % 4
	if data.frames >= 6 and state in ["prepare", "recovery"]:
		sprite.frame = 4 if state == "prepare" else 5
	sprite.flip_h = charge_direction.x < 0 if state == "prepare" else direction.x < 0
	sprite.modulate = Color(2, 2, 2) if hit_flash > 0 else (Color(1.3, 0.8, 0.6) if elite else Color.WHITE)
	queue_redraw()

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
				game.enemy_projectiles.fire(position + charge_direction * 12, charge_direction, data, summoner_id)
			else:
				# One damage decision per swing, at its locked direction.
				if distance <= data.attack_range + game.player.radius and absf(charge_direction.angle_to(direction)) <= deg_to_rad(data.attack_half_angle):
					game.player.take_damage(data.damage, position)
		return Vector2.ZERO
	if state == "recovery":
		if state_time >= data.recovery:
			state = "approach"
		return Vector2.ZERO
	return movement

func take_damage(amount: float, force: Vector2 = Vector2.ZERO) -> void:
	if not alive:
		return
	hp -= amount
	hit_flash = 0.09
	knockback += force * (0.2 if data.behavior == "boss" else 1.0)
	game.add_damage_number(position - Vector2(0, 18), int(amount))
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
		draw_rect(Rect2(-11, -sprite.texture.get_height() + 1, 22, 2), Color("12191d"))
		draw_rect(Rect2(-11, -sprite.texture.get_height() + 1, 22 * hp / max_hp, 2), Color("b65f42"))

func apply_time_control(duration:float,resistance:float,boss_slow:float,boss_duration:float):
	if self is HordeBoss:
		slow_remaining=maxf(slow_remaining,boss_duration)
		slow_factor=1-boss_slow
	elif frozen_remaining<=0 and freeze_resistance<=0:
		frozen_remaining=duration
		resistance_duration=resistance
	queue_redraw()
func tick_control(delta:float)->bool:
	freeze_resistance=maxf(0,freeze_resistance-delta)
	slow_remaining=maxf(0,slow_remaining-delta)
	if frozen_remaining>0:
		frozen_remaining=maxf(0,frozen_remaining-delta)
		if frozen_remaining<=0:freeze_resistance=resistance_duration
		velocity=Vector2.ZERO
		queue_redraw()
		return true
	return false
