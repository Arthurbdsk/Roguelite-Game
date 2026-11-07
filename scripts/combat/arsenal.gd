class_name Arsenal
extends Node2D
const EMPTY_QUERY:Array=[]
var weapons
var shots:Array[Dictionary]=[]
var zones:Array[Dictionary]=[]
var blade_points:Array[Vector2]=[]
var blade_hits:Dictionary={}
var angle:float=0
var textures:Dictionary={}
var bomb_texture=preload("res://assets/v08/bombs.png")
var snow_texture=preload("res://assets/v10/snowflake.png")
var explosion_texture=preload("res://assets/v10/explosion.png")
func setup(w):
 weapons=w
 for id in ["axe","boomerang","bombs","ice_wave"]:textures[id]=load("res://assets/icons/"+id+".png")
 textures.boomerang=load("res://assets/v08/boomerang.png")
 textures.axe=load("res://assets/v18/axe.png")
func reset():
 shots.clear();zones.clear();blade_points.clear();blade_hits.clear();angle=0;queue_redraw()
func launch(id:String)->bool:
 if shots.size()+int(weapons._stat(id,"count"))>120:return false
 var origin:Vector2=weapons.game.player.position
 var target=weapons.game.nearest_enemy(origin,weapons._stat(id,"reach"))
 if id=="bombs":
  var best:int=-1;var considered:int=0
  for candidate in weapons.game.enemies:
   if not weapons._valid_target(candidate) or candidate.position.distance_to(origin)>weapons._stat(id,"reach"):continue
   var score:int=0
   for other in weapons.game.enemies:
    if weapons._valid_target(other) and other.position.distance_to(candidate.position)<70:score+=1
   if score>best:best=score;target=candidate
   considered+=1
   if considered>=12:break
 var direction:Vector2=(target.position-origin).normalized() if target!=null else weapons.game.player.facing
 if id=="ice_wave":
  zones.append({"speed_factor":weapons.projectile_factor(),"kind":id,"at":origin,"age":0.0,"delay":0.0,"radius":weapons._stat(id,"reach"),"life":.4,"hits":{}})
  return true
 for i in int(weapons._stat(id,"count")):
  var dir:Vector2=direction.rotated((i-(weapons._stat(id,"count")-1)/2)*.22)
  if id=="bombs":
   var at:Vector2=origin+dir*80
   if target!=null:at=target.position
   var world=weapons.game.world if weapons.game is CoopActor else weapons.game
   if not world.arena.safe_position(at,8):at=origin
   zones.append({"kind":id,"at":at,"source":origin,"age":0.0,"flight_delay":(.7+i*.12)/weapons.projectile_factor(),"delay":.7+i*.12,"radius":weapons._stat(id,"area_radius"),"life":1.1+i*.12,"hit":false})
  else:shots.append({"speed_factor":weapons.projectile_factor(),"kind":id,"at":origin,"origin":origin,"direction":dir,"age":0.0,"leg":0,"flight":maxf(.25,origin.distance_to(target.position)/170) if target!=null else .9,"hits":{},"pierce":int(weapons._stat(id,"pierce"))})
 return true
func tick(delta:float,allow_attacks:bool=true):
 for shot in shots.duplicate():
  shot.age+=delta
  var start:Vector2=shot.at
  var speed:float=float(shot.get("speed_factor",1));var travel:float=shot.age*speed
  if shot.kind=="axe":shot.at=shot.origin+shot.direction*170*travel+Vector2(0,180*travel*(travel-shot.flight))
  else:
   if shot.leg==0 and travel>=weapons._stat("boomerang","reach")/250:shot.leg=1;shot.hits.clear()
   shot.at+=shot.direction*250*delta*speed if shot.leg==0 else (weapons.game.player.position-shot.at).normalized()*300*delta*speed
  for e in candidates(start,shot.at):
   if not weapons._valid_target(e) or shot.hits.has(e.serial):continue
   if Geometry2D.get_closest_point_to_segment(e.position,start,shot.at).distance_to(e.position)<=e.radius+(5.75 if shot.kind=="axe" else 5):
    shot.hits[e.serial]=true;weapons._hit(e,weapons._stat(shot.kind,"damage"),Vector2.ZERO)
    if shot.kind=="axe":shot.pierce-=1
    if shot.kind=="axe" and shot.pierce<=0:break
  var center:Vector2=weapons.game.player.position.clamp(Vector2(320,180),Vector2(1480,1020))
  var outside:bool=not Rect2(center-Vector2(320,180),Vector2(640,360)).grow(14).has_point(shot.at)
  if (shot.kind=="axe" and (shot.pierce<=0 or outside)) or (shot.kind=="boomerang" and (travel>3 or (shot.leg==1 and shot.at.distance_to(weapons.game.player.position)<12))):shots.erase(shot)
 for zone in zones:
  zone.age+=delta
  if zone.kind=="ice_wave":
   for e in candidates(zone.at-Vector2.ONE*zone.radius,zone.at+Vector2.ONE*zone.radius):
    if weapons._valid_target(e) and not zone.hits.has(e.serial) and e.position.distance_to(zone.at)<=zone.radius*minf(1,zone.age/.35):
     zone.hits[e.serial]=true;weapons._hit(e,weapons._stat("ice_wave","damage"),Vector2.ZERO)
     e.slow_remaining=maxf(e.slow_remaining,minf(1,weapons._stat("ice_wave","duration")) if e is HordeBoss else weapons._stat("ice_wave","duration"));e.slow_factor=.85 if e is HordeBoss else .7
  if zone.kind=="bombs" and zone.age>=zone.delay and not zone.hit:
   zone.hit=true
   for e in candidates(zone.at-Vector2.ONE*zone.radius,zone.at+Vector2.ONE*zone.radius):
    if weapons._valid_target(e) and e.position.distance_to(zone.at)<=zone.radius:weapons._hit(e,weapons._stat("bombs","damage"),Vector2.ZERO)
 zones=zones.filter(func(z):return z.age<z.life)
 blade_points.clear()
 queue_redraw()
func _draw():
 for shot in shots:
  draw_set_transform(shot.at.round(),shot.age*12)
  if shot.kind=="axe":draw_texture_rect(textures.axe,Rect2(-9.2,-9.2,18.4,18.4),false)
  else:draw_texture(textures[shot.kind],-textures[shot.kind].get_size()*.5)
  draw_set_transform(Vector2.ZERO)
 for zone in zones:
  if zone.kind=="bombs" and zone.age<zone.delay:
   var t:float=clampf(zone.age/float(zone.get("flight_delay",zone.delay)),0,1);var at:Vector2=zone.source.lerp(zone.at,t)-Vector2(0,sin(t*PI)*40)
   draw_set_transform(at.round(),t*TAU)
   draw_texture_rect_region(bomb_texture,Rect2(-16,-16,32,32),Rect2(int(zone.age*12)%4*32,0,32,32))
   draw_set_transform(Vector2.ZERO)
  else:
   var progress:float=clampf((zone.age-zone.delay)/.4,0,1)
   if zone.kind=="bombs":
    draw_texture_rect_region(explosion_texture,Rect2(zone.at-Vector2.ONE*zone.radius,Vector2.ONE*zone.radius*2),Rect2(mini(7,int(progress*8))*96,0,96,96))
    continue
   if zone.kind=="ice_wave":
    var count:int=clampi(ceili(TAU*zone.radius/28),12,32)
    for i in count:
     var at:Vector2=zone.at+Vector2.from_angle(i*TAU/count)*zone.radius*minf(1,zone.age/.35)
     draw_texture_rect_region(snow_texture,Rect2(at.round()-Vector2(12,12),Vector2(24,24)),Rect2(mini(7,int(progress*8))*32,0,32,32))
    continue
   for i in 40:
    var at:Vector2=zone.at+Vector2.from_angle(i*TAU/40)*zone.radius*progress
    draw_rect(Rect2(at.round(),Vector2(2,3)),Color("abddeb") if zone.kind=="ice_wave" else Color("e9b45a"))

func candidates(start:Vector2,end:Vector2)->Array:
 var world=weapons.game.world if weapons.game is CoopActor else weapons.game
 if world.grid.is_empty():return weapons.game.enemies
 var margin:float=world.enemy_collision_margin
 var low:=Vector2i(floori((minf(start.x,end.x)-margin)/40),floori((minf(start.y,end.y)-margin)/40))
 var high:=Vector2i(floori((maxf(start.x,end.x)+margin)/40),floori((maxf(start.y,end.y)+margin)/40))
 var result:Array=[]
 for x in range(low.x,high.x+1):
  for y in range(low.y,high.y+1):result.append_array(world.grid.get(Vector2i(x,y),[]))
 return result
