class_name NewWeaponVisuals17
extends RefCounted

# Shared atlases, local visual state only. No particles or trails travel over the network.
static var textures:Dictionary={}
var time:float=0
var tracks:Dictionary={}
var impacts:Array=[]
var last_delta:float=0

func reset():time=0;tracks.clear();impacts.clear()
func texture(id:String)->Texture2D:
 if not textures.has(id):textures[id]=load("res://assets/v17/"+id+".png")
 return textures[id]
func frame(canvas:CanvasItem,id:String,index:int,size:Vector2,rect:Rect2,color:Color=Color.WHITE):
 canvas.draw_texture_rect_region(texture(id),rect,Rect2(Vector2(index*size.x,0),size),color)
func tick(delta:float):
 last_delta=delta
 time+=delta
 for fx in impacts:fx.age+=delta
 impacts=impacts.filter(func(fx):return fx.age<.3)
func paint(canvas:Node2D,a,visible:Rect2):
 var w=a.weapons
 var p:Vector2=w.game.player.position
 if int(w.levels.get("garlic",0))>0:
  var r:float=w._stat("garlic","reach")
  if visible.intersects(Rect2(p-Vector2.ONE*r,Vector2.ONE*r*2)):
   frame(canvas,"garlic_aura",int(time*10)%6,Vector2(128,128),Rect2(p-Vector2.ONE*r,Vector2.ONE*r*2))
 for strike in a.strikes:
  var local_age:float=float(strike.age)-float(strike.delay)+.1
  if local_age<0 or local_age>=.32:continue
  var reach:float=w._stat("whip","reach")
  var at:Vector2=strike.at
  var height:float=24*w.area_factor()
  if not visible.intersects(Rect2(at-Vector2(reach,height),Vector2(reach*2,height*2))):continue
  canvas.draw_set_transform(at,0,Vector2(float(strike.side),1))
  frame(canvas,"whip_lash",mini(7,int(local_age/.04)),Vector2(128,32),Rect2(Vector2(0,-height*.5),Vector2(reach,height)))
  canvas.draw_set_transform(Vector2.ZERO)
 var live:Dictionary={}
 var remote:bool=w.game is CoopActor and not world_host(w)
 for shot in a.shots:
  var id:int=int(shot.get("id",0));live[id]=true
  var at:Vector2=shot.at
  if not tracks.has(id):tracks[id]={"at":at,"trail":[],"kind":shot.kind}
  var track:Dictionary=tracks[id]
  track.at=Vector2(track.at).lerp(at,1-exp(-last_delta*30)) if remote else at
  at=track.at
  if shot.kind=="runetracer":
   if track.trail.is_empty() or Vector2(track.trail.back()).distance_squared_to(at)>36:
    track.trail.append(at)
    if track.trail.size()>5:track.trail.pop_front()
   for i in track.trail.size():
    var point:Vector2=track.trail[i]
    if visible.has_point(point):
     var k:float=float(i+1)/track.trail.size()
     frame(canvas,"runetracer_trail",int(time*14)%6,Vector2(12,12),Rect2(point-Vector2.ONE*6,Vector2.ONE*12),Color(1,1,1,k*.55))
  if not visible.has_point(at):continue
  var radius:float=w._stat(shot.kind,"projectile_radius")
  var scale_factor:float=radius/4
  if shot.kind=="fire_wand" or shot.kind=="magic_wand":
   canvas.draw_set_transform(at,Vector2(shot.velocity).angle(),Vector2.ONE*scale_factor)
   # Collision core is centered at (23,12); the flame tail never changes damage.
   frame(canvas,shot.kind+"_shot",int(time*15+id)%6,Vector2(32,24),Rect2(Vector2(-23,-12),Vector2(32,24)))
  else:
   canvas.draw_set_transform(at,Vector2(shot.velocity).angle()+PI*.5,Vector2.ONE*scale_factor*.7)
   frame(canvas,"runetracer_shot",int(time*12+id)%6,Vector2(24,24),Rect2(Vector2(-12,-12),Vector2(24,24)))
  canvas.draw_set_transform(Vector2.ZERO)
 for id in tracks.keys():
  if not live.has(id):tracks.erase(id)
 for fx in impacts:
  if visible.has_point(fx.at):frame(canvas,fx.kind+"_impact",mini(5,int(fx.age*20)),Vector2(24,24),Rect2(fx.at-Vector2.ONE*12,Vector2.ONE*24))
func world_host(w)->bool:return w.game.world.coop.hosting
func impact(kind:String,at:Vector2):
 if impacts.size()<48:impacts.append({"kind":kind,"at":at,"age":0.0})
