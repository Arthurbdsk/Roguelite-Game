extends Node2D
var lab
func _ready():z_index=40
func _draw():
 if lab==null or not lab.active:return
 if lab.show_spawn_sectors:
  for player in lab.game.team_players():
   for i in 8:
    var at:Vector2=player.position+Vector2.from_angle(i*TAU/8)*120
    draw_line(player.position,at,Color("76bde0"),1)
    draw_string(GameFonts.interface_font(),at,str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("f5da6e"))
 if not lab.show_colliders:return
 for e in lab.game.enemies:
  if is_instance_valid(e):draw_arc(e.position,e.radius,0,TAU,24,Color("f5da6e"),1)
 for rect in lab.game.arena.obstacles:draw_rect(rect,Color("76bde0"),false,1)
