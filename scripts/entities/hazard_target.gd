class_name HazardTarget
extends HordeEnemy
var owner_boss:int=0
func tick(delta:float):
 if not alive:return
 clock+=delta;hit_flash=maxf(0,hit_flash-delta)
 sprite.frame=mini(2,int(clock*.65))
 sprite.modulate=Color(1.5,1.5,1.5) if hit_flash>0 else Color.WHITE
 queue_redraw()
func take_damage(amount:float,_force:Vector2=Vector2.ZERO):
 if not alive or not targetable:return
 hp=maxf(0,hp-maxf(0,amount));hit_flash=.1
 if hp>0:return
 alive=false;targetable=false
 game.late_arena.patterns.target_removed(serial,data.id)
 game.despawn_enemy(self)
func apply_time_control(_duration:float,_resistance:float,_boss_slow:float,_boss_duration:float):pass
func _draw():
 draw_rect(Rect2(-12,-45,24,3),Color("172433"))
 draw_rect(Rect2(-12,-45,24*hp/maxf(1,max_hp),3),Color("9cdbe0"))
