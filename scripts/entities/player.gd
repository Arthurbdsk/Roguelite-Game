class_name Sentinel
extends CharacterBody2D

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
var radius: float = 7.0
var facing: Vector2 = Vector2.DOWN
var invulnerable: float = 0.0
var animation: float = 0.0
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

func _ready() -> void:
 collision_layer = 1
 collision_mask = 4
 var shape := CollisionShape2D.new()
 var circle := CircleShape2D.new()
 circle.radius = radius
 shape.shape = circle
 add_child(shape)
 sprite = Sprite2D.new()
 sprite.texture = load("res://assets/v08/hero.png")
 sprite.hframes = 32
 sprite.position.y = -28
 add_child(sprite)

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
 velocity = movement.limit_length() * speed * movement_multiplier
 if movement.length_squared() > 0.01:
  facing = movement.normalized()
  animation += delta * 9
  if absf(movement.x) > 0.05:
   sprite.flip_h = movement.x < 0
 else:
  animation = 0
 tick_visual(delta,movement.length_squared()>.01)
 sprite.modulate = Color(1, 0.55, 0.45) if invulnerable > 0.0 and fmod(invulnerable, 0.16) > 0.08 else Color.WHITE
 move_and_slide()
 position = position.clamp(Vector2(35, 45), Vector2(1765, 1165))
 queue_redraw()

func take_damage(amount: float, source: Vector2) -> bool:
 if down or invulnerable > 0 or hp <= 0 or game.state != "running":
  return false
 hurt_remaining=.2
 damage_revision += 1
 hp = maxf(0, hp - maxf(1,maxf(amount*.2,amount-armor)))
 time_since_damage = 0
 invulnerable = 0.85
 game.shake_time = 0.16
 game.sound.play_cue("hurt")
 var direction := (position - source).normalized()
 move_and_collide(direction * 5)
 if hp <= 0:
  if not game.mastery.save_from_death():
   game.finish_run(false)
 return true

func _draw() -> void:
 draw_ellipse_shadow()
 # Cold pixels under the sentinel keep them visible in a dense crowd.
 draw_arc(Vector2(0, 1), 10, 0, TAU, 16, Color("b65f42") if down else marker_color, 1, false)
 if not display_name.is_empty():
  var font: Font = ThemeDB.fallback_font
  var width: float = font.get_string_size(display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
  draw_string(font, Vector2(-width * 0.5, -58 if sprite.hframes>=32 else -34), display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, marker_color)

func draw_ellipse_shadow() -> void:
 draw_rect(Rect2(-8, -1, 16, 5), Color(0, 0, 0, 0.35))

func apply_poison(duration:float,damage:float):
 if down:return
 if poison_remaining<=0:poison_clock=0
 poison_remaining=duration
 poison_damage=damage
func clear_status():
 poison_remaining=0
 poison_clock=0
 root_remaining=0
 visual_clock=0
 swing_remaining=0
 anticipation_remaining=0
 hurt_remaining=0
 revive_remaining=0
func tick_status(delta:float):
 if poison_remaining<=0:return
 var active:float=minf(delta,poison_remaining)
 poison_remaining=maxf(0,poison_remaining-delta)
 if game.coop!=null and game.coop.active and not game.coop.hosting:return
 poison_clock+=active
 while poison_clock>=0.999999 and not down:
  poison_clock=maxf(0,poison_clock-1)
  damage_revision+=1
  hp=maxf(0,hp-maxf(1,maxf(poison_damage*.2,poison_damage-armor)))
  time_since_damage=0
  if hp<=0:
   if not game.mastery.save_from_death():game.finish_run(false)
   break

func begin_swing(direction:Vector2):
 swing_remaining=.3
 sprite.flip_h=direction.x<0
func tick_visual(delta:float,moving:bool=false):
 visual_clock+=delta;swing_remaining=maxf(0,swing_remaining-delta);anticipation_remaining=maxf(0,anticipation_remaining-delta);hurt_remaining=maxf(0,hurt_remaining-delta);revive_remaining=maxf(0,revive_remaining-delta)
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
 else:sprite.frame=int(visual_clock*4)%4
