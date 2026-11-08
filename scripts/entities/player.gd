class_name Sentinel
extends CharacterBody2D

var dev_invulnerable:bool=false
var game
var visual_clock:float=0
var swing_remaining:float=0
var anticipation_remaining:float=0
var hurt_remaining:float=0
var revive_remaining:float=0
var hp: float = 100.0
var max_hp: float = 100.0
var speed: float = 96.0
var pickup_radius: float = 42.0
var armor: float = 0.0
var damage_reduction:float=0
var radius: float = 7.0
var facing: Vector2 = Vector2.DOWN
var invulnerable: float = 0.0
var animation: float = 0.0
var actually_moving:bool=false
var sprite: Sprite2D
var movement_multiplier: float = 1.0
var time_since_damage: float = 0.0
var display_name: String = ""
var marker_color := Color("83c4bd")
var down: bool = false
var damage_revision: int = 0
var poison_remaining:float=0
var poison_clock:float=0
var poison_damage:float=2
var root_remaining:float=0
var damage_clock:float=0
var attacker_until:Dictionary={}
var next_attacker_cleanup:float=0
var poison_attacker:int=0
var tiny_soldier:bool=false
var bow_remaining:float=0
var death_visual_age:float=0
var visual_defeated:bool=false
var remote_prepare_left:float=0
var remote_prepare_frame:int=0

func _ready() -> void:
 collision_layer = 1
 collision_mask = 4
 var shape := CollisionShape2D.new()
 var circle := CircleShape2D.new()
 circle.radius = radius
 shape.shape = circle
 add_child(shape)
 sprite = Sprite2D.new()
 tiny_soldier=TinyCharacters.install(sprite,"soldier")
 if not tiny_soldier:
  sprite.texture = load("res://assets/v08/hero.png")
  sprite.hframes = 32
  sprite.position.y = -28
 var visual_root:=Node2D.new()
 visual_root.name="PlayerVisual"
 visual_root.scale=Vector2.ONE*PlatformTuning.hero_visual_multiplier()
 add_child(visual_root)
 visual_root.add_child(sprite)
 sprite.scale=Vector2.ONE*1.1
 sprite.position*=1.1
 set_process(false)

func _process(delta:float):
 # Solo defeat settles immediately as before; only the body keeps animating.
 if tiny_soldier and hp<=0 and not down:tick_visual(delta,false)
 else:set_process(false)

func tick(delta: float, movement: Vector2) -> void:
 if down:
  tick_visual(delta,false)
  return
 tick_status(delta)
 if down or hp <= 0 or game.state != "running":
  return
 root_remaining=maxf(0,root_remaining-delta)
 if root_remaining>0:movement=Vector2.ZERO
 invulnerable = maxf(0.0, invulnerable - delta)
 time_since_damage += delta
 if movement.length()<.12:movement=Vector2.ZERO
 velocity = movement.limit_length() * speed * movement_multiplier
 var before:Vector2=position
 sprite.modulate = Color(1, 0.55, 0.45) if invulnerable > 0.0 and fmod(invulnerable, 0.16) > 0.08 else Color.WHITE
 move_and_slide()
 position = position.clamp(Vector2(35, 45), Vector2(1765, 1165))
 var travelled:Vector2=position-before
 var actual_speed:float=travelled.length()/maxf(delta,.0001)
 actually_moving=actual_speed>(1.0 if actually_moving else 2.0)
 if actually_moving:
  facing=travelled.normalized()
  if absf(facing.x)>.05:sprite.flip_h=facing.x<0
 else:animation=0
 tick_visual(delta,actually_moving)
 queue_redraw()

func take_damage(amount: float, source: Vector2,attacker:int=0,scheduled_time:float=-1) -> bool:
 if dev_invulnerable or down or invulnerable > 0 or hp <= 0 or game.state != "running":
  return false
 if game.coop.active and not game.coop.hosting:return false
 var now:float=damage_clock if scheduled_time<0 else scheduled_time
 if attacker>0:
  if now+.000001<float(attacker_until.get(attacker,-1)):return false
  attacker_until[attacker]=now+game.balance.same_attacker_interval
 hurt_remaining=.2
 damage_revision += 1
 hp = maxf(0, hp - received_damage(amount))
 time_since_damage = 0
 game.shake_time = 0.16
 game.sound.play_cue("hurt")
 var direction := (position - source).normalized()
 move_and_collide(direction * 5)
 if hp <= 0:
  set_process(true)
  if not game.mastery.save_from_death():
   game.finish_run(false)
 return true

func _draw() -> void:
 # The fallen marker remains useful for revives; living players use names.
 if down:draw_arc(Vector2(0,1),10,0,TAU,16,Color("b65f42"),1,false)
 if not display_name.is_empty():
  var font: Font = GameFonts.interface_font()
  var width: float = font.get_string_size(display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
  draw_string(font, Vector2(-width * 0.5, (-32 if tiny_soldier else (-58 if sprite.hframes>=32 else -34))*1.1*PlatformTuning.hero_visual_multiplier()), display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, marker_color)

func apply_poison(duration:float,damage:float,attacker:int=0):
 if down:return
 if poison_remaining<=0:poison_clock=0
 poison_remaining=duration
 poison_damage=damage
 poison_attacker=attacker
func clear_status():
 poison_remaining=0
 poison_clock=0
 root_remaining=0
 visual_clock=0
 swing_remaining=0
 anticipation_remaining=0
 hurt_remaining=0
 revive_remaining=0
 damage_clock=0;attacker_until.clear();next_attacker_cleanup=0;poison_attacker=0
 bow_remaining=0;death_visual_age=0;visual_defeated=false;remote_prepare_left=0;set_process(false)
func tick_status(delta:float):
 damage_clock+=delta
 if damage_clock>=next_attacker_cleanup:
  next_attacker_cleanup=damage_clock+2
  for attacker in attacker_until.keys():
   if float(attacker_until[attacker])<damage_clock-1:attacker_until.erase(attacker)
 if dev_invulnerable:return
 if poison_remaining<=0:return
 var active:float=minf(delta,poison_remaining)
 poison_remaining=maxf(0,poison_remaining-delta)
 if game.coop!=null and game.coop.active and not game.coop.hosting:return
 poison_clock+=active
 while poison_clock>=0.999999 and not down:
  poison_clock=maxf(0,poison_clock-1)
  take_damage(poison_damage,position,poison_attacker,damage_clock-poison_clock)
  if hp<=0:break

func begin_swing(direction:Vector2):
 swing_remaining=.3
 sprite.flip_h=direction.x<0
func begin_bow(direction:Vector2):
 bow_remaining=.18
 if absf(direction.x)>.05:sprite.flip_h=direction.x<0

func receive_visual_frame(value:int,flipped:bool):
 sprite.frame=clampi(value,0,sprite.hframes-1);sprite.flip_h=flipped
 if not tiny_soldier:
  if value in range(10,16):swing_remaining=(16-value)*.05
  if value in [8,9]:anticipation_remaining=.12 if value==8 else .06
  return
 remote_prepare_left=0
 if TinyCharacters.contains("soldier","hurt",value):hurt_remaining=(39-value)*.05
 elif value in range(17,20):swing_remaining=(20-value)*.1
 elif value in [33,34]:bow_remaining=(35-value)*.09
 elif value in range(14,17) or value in range(26,33):remote_prepare_left=.15;remote_prepare_frame=value
 elif TinyCharacters.contains("soldier","idle",value) or TinyCharacters.contains("soldier","walk",value):swing_remaining=0;bow_remaining=0

func walking_frame()->bool:
 return TinyCharacters.contains("soldier","walk",sprite.frame) if tiny_soldier else sprite.frame in range(16,24)
func stop_walking_visual():
 if walking_frame():sprite.frame=TinyCharacters.frame("soldier","idle",visual_clock, true) if tiny_soldier else 0

func tiny_tick_visual(delta:float,moving:bool):
 bow_remaining=maxf(0,bow_remaining-delta);remote_prepare_left=maxf(0,remote_prepare_left-delta)
 var defeated:bool=down or hp<=0
 if defeated and not visual_defeated:death_visual_age=0
 visual_defeated=defeated
 if defeated:
  death_visual_age+=delta;sprite.frame=TinyCharacters.frame("soldier","death",death_visual_age/.45)
 elif revive_remaining>0:sprite.frame=TinyCharacters.frame("soldier","death",revive_remaining/.45)
 elif hurt_remaining>0:sprite.frame=TinyCharacters.frame("soldier","hurt",1-hurt_remaining/.2)
 elif swing_remaining>0:sprite.frame=17+clampi(int((1-swing_remaining/.3)*3),0,2)
 elif bow_remaining>0:sprite.frame=33+int(bow_remaining<=.09)
 elif remote_prepare_left>0:sprite.frame=remote_prepare_frame
 else:
  var w=game.weapon_system
  var target=w.bow_visual_target.get_ref() if w.bow_visual_target!=null else null
  var preparing:bool=w.attacks_enabled and int(w.levels.get("bolt",0))>0 and float(w.timers.get("bolt",1))<=.21 and is_instance_valid(target) and target.alive and target.position.distance_to(position)<=w._stat("bolt","reach")
  if preparing and not (game.coop.active and not game.coop.hosting):
   sprite.frame=26+clampi(int((1-float(w.timers.get("bolt",0))/.21)*7),0,6)
   if absf(target.position.x-position.x)>1:sprite.flip_h=target.position.x<position.x
  elif not (game.coop.active and not game.coop.hosting) and w.attacks_enabled and int(w.levels.get("sword",0))>0 and float(w.timers.get("sword",1))<.12 and game.nearest_enemy(position,w._stat("sword","reach")+25)!=null:sprite.frame=14+clampi(int((1-float(w.timers.get("sword",0))/.12)*3),0,2)
  elif moving:sprite.frame=TinyCharacters.frame("soldier","walk",visual_clock*1.25,true)
  else:sprite.frame=TinyCharacters.frame("soldier","idle",visual_clock,true)
func tick_visual(delta:float,moving:bool=false):
 visual_clock+=delta;swing_remaining=maxf(0,swing_remaining-delta);anticipation_remaining=maxf(0,anticipation_remaining-delta);hurt_remaining=maxf(0,hurt_remaining-delta);revive_remaining=maxf(0,revive_remaining-delta)
 if tiny_soldier:tiny_tick_visual(delta,moving);return
 if sprite.hframes<32:
  sprite.frame=int(animation)%4;return
 sprite.rotation=0
 if down:sprite.frame=26+mini(2,int(visual_clock*6))
 elif revive_remaining>0:sprite.frame=29+mini(2,int((.45-revive_remaining)/.15))
 elif hurt_remaining>0:sprite.frame=24+int(hurt_remaining<.1)
 elif swing_remaining>0:sprite.frame=10+mini(5,int((.3-swing_remaining)*20))
 elif anticipation_remaining>0:sprite.frame=8+int(anticipation_remaining<.06)
 elif not (game.coop.active and not game.coop.hosting) and game.weapon_system.levels.get("sword",0)>0 and float(game.weapon_system.timers.get("sword",1))<.12 and game.nearest_enemy(position,game.weapon_system._stat("sword","reach")+25)!=null:sprite.frame=8+int(float(game.weapon_system.timers.get("sword",1))<.06)
 elif moving:sprite.frame=16+int(visual_clock*10)%8
 else:sprite.frame=0

func received_damage(amount:float)->float:
 return maxf(amount*.2,maxf(0,amount-armor)*(1-clampf(damage_reduction,0,.8)))
func gold_collection_radius()->float:
 return game.balance.coin_attraction_radius*(1+game.mastery.value("pickup"))+14*int(game.weapon_system.passives.get("magnet",0))
