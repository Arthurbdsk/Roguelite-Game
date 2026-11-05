extends Node2D
var lab
func _ready():z_index=40
func _draw():
 if lab==null or not lab.active or not lab.show_colliders:return
 for e in lab.game.enemies:
  if is_instance_valid(e):draw_arc(e.position,e.radius,0,TAU,24,Color("f5da6e"),1)
 for rect in lab.game.arena.obstacles:draw_rect(rect,Color("76bde0"),false,1)
