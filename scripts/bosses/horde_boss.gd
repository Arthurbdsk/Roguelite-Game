class_name HordeBoss
extends HordeEnemy

var dev_summons_alive:int=0
var dev_frozen:bool=false
var dev_repeat:String=""
var dev_next_attack:String=""
var form:int=1
var first_phase_hp:float=0
var phase: int = 1
var attack_name: String = ""
var attack_index: int = 0
var combat_enabled: bool = true
var death_paid: bool = false
var charge_hit: bool = false
var contact_timer: float = 0.8
var is_executioner: bool = false
var visual_form:int=0

func _ready() -> void:
	super._ready()
	apply_visual_form()

func apply_visual_form() -> void:
	if is_executioner:return
	var shown:int=1 if form==1 or (state=="transform" and state_time<game.boss_balance.transformation_duration*.5) else 2
	if shown==visual_form:return
	visual_form=shown
	sprite.texture=load("res://assets/v08/demon_"+str(shown)+".png")
	sprite.hframes=32
	sprite.position.y=-float(sprite.texture.get_height())*.5+4

func animate_demon(moving:bool) -> void:
	apply_visual_form()
	if state=="transform":
		var progress:float=state_time/game.boss_balance.transformation_duration
		sprite.frame=26+mini(3,int(fmod(progress,.5)*8))
	elif hit_flash>0:sprite.frame=24+int(hit_flash<.04)
	elif state=="windup":sprite.frame=12+mini(3,int(state_time/maxf(.01,warning_duration())*4))
	elif state=="recovery":sprite.frame=16+mini(7,int(state_time/maxf(.01,game.boss_balance.charge_recovery if attack_name=="charge" else game.boss_balance.spell_recovery)*8))
	elif moving:sprite.frame=4+int(clock*9)%8
	else:sprite.frame=int(clock*4)%4

func setup(owner_game, stats: EnemyData, _is_elite: bool = false) -> void:
	super.setup(owner_game, stats, false)
	is_executioner = stats.behavior == "executioner"
	max_hp = game.boss_balance.executioner_health() if is_executioner else game.boss_balance.demon_health()
	max_hp *= game.balance.enemy_health_multiplier
	hp = max_hp
	state = "chase"
	attack_time = 1.2

func enable_combat() -> void:
	combat_enabled = true
	targetable = true
	state = "chase"
	state_time = 0
	attack_time = 1.1
	contact_timer = game.boss_balance.activation_grace
	sprite.visible = true
	sprite.modulate = Color.WHITE
	sprite.position.y = -float(sprite.texture.get_height()) * 0.5 + 4

func tick(delta: float) -> void:
	if dev_frozen or not alive or not combat_enabled:
		return
	tick_control(delta)
	if state=="transform":
		state_time+=delta
		animate_demon(false)
		queue_redraw()
		if state_time>=game.boss_balance.transformation_duration:
			state="chase";state_time=0;targetable=true;attack_time=1;contact_timer=1
			game.announce("DEMÔNIO | FASE 2",3)
		return
	clock += delta
	state_time += delta
	attack_time -= delta
	contact_timer -= delta
	hit_flash = maxf(0, hit_flash - delta)
	var previous_phase := phase
	phase = (2 if hp < max_hp * 0.5 else 1) if is_executioner else (3 if hp < max_hp * 0.35 else (2 if hp <= max_hp * 0.7 else 1))
	if phase > previous_phase:
		attack_time = minf(attack_time, 0.8)
		game.announce("O CARRASCO SE ENFURECE" if is_executioner else "DEMÔNIO | FASE %d" % form, 2.0)
	var offset: Vector2 = game.player.position - position
	var direction: Vector2 = offset.normalized()
	var movement := Vector2.ZERO
	if state == "chase":
		var speed: float = game.boss_balance.executioner_speed if is_executioner else game.boss_balance.demon_speed
		movement = direction * speed * game.balance.enemy_speed_multiplier * game.enemy_scale().speed * (1.06 if phase >= 2 and is_executioner else 1.0)
		if attack_time <= 0 and dev_attack_ready():
			begin_attack(choose_attack())
			movement = Vector2.ZERO
		if offset.length() < radius + game.player.radius and contact_timer <= 0:
			game.player.take_damage(data.damage*damage_scale(), position)
			contact_timer = 1.0
	elif state == "windup":
		if state_time < tracking_duration():
			charge_direction = direction
		if state_time >= warning_duration():
			execute_attack()
	elif state == "charge":
		movement = charge_direction * (game.boss_balance.executioner_charge_speed if is_executioner else game.boss_balance.demon_charge_speed) * game.balance.enemy_speed_multiplier * game.enemy_scale().speed
		if state_time >= game.boss_balance.charge_duration:
			finish_attack()
			movement = Vector2.ZERO
	elif state == "recovery":
		if state_time >= (game.boss_balance.charge_recovery if attack_name == "charge" else game.boss_balance.spell_recovery):
			state = "chase"
			state_time = 0
	if state=="chase":movement=game.navigation.steer(self,movement)
	var previous_position: Vector2 = position
	if slow_remaining>0:movement*=slow_factor
	velocity = movement
	move_and_slide()
	if state == "charge":
		var victim = game.projectile_victim(previous_position, position, radius)
		if not charge_hit and victim != null:
			charge_hit = true
			victim.take_damage((game.boss_balance.executioner_charge_damage if is_executioner else game.boss_balance.demon_charge_damage) * game.enemy_scale().damage * damage_scale(), previous_position)
		if is_on_wall():
			finish_attack()
	sprite.frame = int(clock * 7) % 4
	if state == "windup":
		var frames := {"execute": 4, "charge": 5, "fire": 4, "lightning": 6, "ice": 7, "summon": 8}
		sprite.frame = mini(frames.get(attack_name, 4), data.frames - 1)
	elif state == "charge":
		sprite.frame = 5
	if not is_executioner:animate_demon(movement.length_squared()>1)
	sprite.flip_h = charge_direction.x < 0 if state in ["windup", "charge"] else direction.x < 0
	sprite.modulate = Color(1.6, 1.6, 1.6) if hit_flash > 0 else Color.WHITE
	queue_redraw()

func dev_attack_ready()->bool:
	var requested:String=dev_next_attack if not dev_next_attack.is_empty() else dev_repeat
	if requested.is_empty() or requested in ["execute","charge","dash"]:return true
	return game.late_arena.can_cast(requested) if self is LateBoss else game.boss_arena.can_cast(requested)

func choose_attack() -> String:
	if not dev_next_attack.is_empty():
		var selected:String=dev_next_attack;dev_next_attack="";return selected
	if not dev_repeat.is_empty():return dev_repeat
	if is_executioner:
		var chosen: String = "execute" if attack_index % 2 == 0 else "charge"
		attack_index += 1
		return chosen
	if form==2:
		var choices:Array=["fire","lightning","ring","charge","summon","ice","fire"]
		for attempt in choices.size():
			var chosen:String=choices[attack_index%choices.size()];attack_index+=1
			if game.boss_arena.can_cast(chosen):return chosen
		return "charge"
	var order: Array = ["fire", "summon", "charge", "fire"]
	if phase == 2:
		order = ["lightning", "fire", "ice", "charge", "summon"]
	elif phase == 3:
		order = ["fire", "lightning", "charge", "summon", "ice", "fire"]
	for attempt in order.size():
		var candidate: String = order[attack_index % order.size()]
		attack_index += 1
		if game.boss_arena.can_cast(candidate):
			return candidate
	return "charge"

func begin_attack(id: String) -> void:
	attack_name = id
	state = "windup"
	state_time = 0
	charge_direction = (game.player.position - position).normalized()
	queue_redraw()

func warning_duration() -> float:
	if attack_name == "execute":
		return game.boss_balance.executioner_swing_warning
	return game.boss_balance.charge_warning if attack_name == "charge" else game.boss_balance.spell_warning

func tracking_duration() -> float:
	return game.boss_balance.executioner_tracking if attack_name == "execute" else game.boss_balance.charge_tracking

func execute_attack() -> void:
	if attack_name == "charge":
		state = "charge"
		state_time = 0
		charge_hit = false
		return
	if attack_name == "execute":
		game.damage_team_cone(position, charge_direction, game.boss_balance.executioner_swing_range, deg_to_rad(68), game.boss_balance.executioner_swing_damage * game.enemy_scale().damage)
		if game.state == "running":
			game.boss_arena.swings.append({"at": position, "direction": charge_direction, "life": 0.22})
	else:
		game.boss_arena.cast(attack_name, self, charge_direction, phase)
	finish_attack()

func finish_attack() -> void:
	state = "recovery"
	state_time = 0
	if is_executioner:
		attack_time = game.boss_balance.executioner_enraged_interval if phase == 2 else game.boss_balance.executioner_interval
	else:
		attack_time = game.boss_balance.demon_interval if phase == 1 else (game.boss_balance.demon_phase2_interval if phase == 2 else game.boss_balance.demon_phase3_interval)
	if not is_executioner and form==2:attack_time*=game.boss_balance.second_interval_multiplier

func damage_scale()->float:
	return game.boss_balance.second_damage_multiplier if not is_executioner and form==2 else 1.0

func take_damage(amount: float, _force: Vector2 = Vector2.ZERO) -> void:
	if not alive or not combat_enabled or not targetable:
		return
	hp = maxf(0, hp - amount)
	hit_flash = 0.08
	game.add_damage_number(position - Vector2(0, 35), int(amount))
	game.sound.play_cue("hit")
	if hp<=0 and not is_executioner and form==1:
		first_phase_hp=max_hp
		form=2
		dev_repeat="";dev_next_attack=""
		max_hp=first_phase_hp*game.boss_balance.second_health_multiplier
		hp=max_hp
		state="transform";state_time=0;targetable=false;velocity=Vector2.ZERO
		game.boss_arena.clear_for_transform()
		game.announce("DEMÔNIO | TRANSFORMAÇÃO",2)
		return
	if hp <= 0 and not death_paid:
		alive = false
		targetable = false
		death_paid = true
		state = "death"
		velocity = Vector2.ZERO
		game.enemy_killed(self)

func _draw() -> void:
	if state=="transform":
		draw_arc(Vector2.ZERO,30+state_time*25,0,TAU,40,Color("ad8eac"),3)
		return

	draw_rect(Rect2(-radius, -2, radius * 2, 7), Color(0, 0, 0, 0.4))
	if not combat_enabled or not alive:
		return
	if state == "windup":
		var color := Color("dfb969") if is_executioner else Color("dc7b51")
		if attack_name == "execute":
			var angle: float = charge_direction.angle()
			draw_arc(Vector2.ZERO, game.boss_balance.executioner_swing_range, angle - 1.18, angle + 1.18, 30, color, 2, false)
			draw_line(Vector2.ZERO, charge_direction.rotated(-1.18) * game.boss_balance.executioner_swing_range, color, 1)
			draw_line(Vector2.ZERO, charge_direction.rotated(1.18) * game.boss_balance.executioner_swing_range, color, 1)
		elif attack_name == "charge":
			draw_line(Vector2.ZERO, charge_direction * 165, color, 2)
			draw_line(charge_direction * 145 - charge_direction.orthogonal() * 9, charge_direction * 165, color, 1)
			draw_line(charge_direction * 145 + charge_direction.orthogonal() * 9, charge_direction * 165, color, 1)
		else:
			var mark := Vector2(0, -85)
			if attack_name == "lightning":
				draw_polyline(PackedVector2Array([mark + Vector2(4, -7), mark + Vector2(-3, 0), mark + Vector2(3, 0), mark + Vector2(-4, 7)]), Color("e6ddae"), 2)
			elif attack_name == "ice":
				draw_line(mark - Vector2(7, 0), mark + Vector2(7, 0), Color("83c4bd"), 2)
				draw_line(mark - Vector2(0, 7), mark + Vector2(0, 7), Color("83c4bd"), 2)
			elif attack_name == "summon":
				draw_rect(Rect2(mark - Vector2(7, 6), Vector2(14, 12)), Color("b184af"), false, 2)
			else:
				draw_rect(Rect2(mark - Vector2(5, 5), Vector2(10, 10)), Color("df8956"))
		draw_arc(Vector2.ZERO, radius + 7, 0, TAU, 30, color, 1)
