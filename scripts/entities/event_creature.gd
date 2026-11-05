extends SlimeEnemy
var event_kind:String=""
func tick(delta:float):
 if event_kind!="siege":super.tick(delta);return
 if not alive or tick_control(delta):return
 clock+=delta;state_time+=delta;attack_time-=delta
 if state=="prepare":
  if state_time>=data.windup:
   game.enemy_projectiles.fire(position+charge_direction*12,charge_direction,data,get_instance_id())
   state="recovery";state_time=0;attack_time=data.attack_interval
 elif state=="recovery":
  if state_time>=data.recovery:state="approach";state_time=0
 elif attack_time<=0 and position.distance_to(game.player.position)<=data.attack_range and game.enemy_projectiles.clear_shot(position,game.player.position):
  state="prepare";state_time=0;charge_direction=(game.player.position-position).normalized()
 sprite.frame=4 if state=="prepare" else 5 if state=="recovery" else int(clock*4)%4
 sprite.flip_h=game.player.position.x<position.x
 sprite.modulate=Color("b7d8e7")
 queue_redraw()
func _draw():
 super._draw()
 if event_kind=="siege":
  draw_rect(Rect2(-4,-27,8,3),Color("e3b968"))
