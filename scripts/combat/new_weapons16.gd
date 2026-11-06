class_name NewWeapons16
extends RefCounted
const IDS:Array=["garlic","whip","fire_wand","runetracer","magic_wand"]
var weapons
var shots:Array=[]
var strikes:Array=[]
var bursts:Array=[]
var aura_hits:Dictionary={}
var wall_query:=PhysicsRayQueryParameters2D.new()
func setup(owner):weapons=owner
func reset():shots.clear();strikes.clear();bursts.clear();aura_hits.clear()
func world():return weapons.game.world if weapons.game is CoopActor else weapons.game
func candidates(a:Vector2,b:Vector2)->Array:return weapons.arsenal.candidates(a,b)
func launch(id:String)->bool:
 var p=weapons.game.player;var n:int=int(weapons._stat(id,"count"))
 if shots.size()+n>256 or bursts.size()+n>64 or strikes.size()+n>64:return false
 if id=="whip":
  for i in n:strikes.append({"age":0.0,"delay":.1+i*.09,"at":p.position+Vector2(0,-12-i*5),"side":(1 if p.facing.x>=0 else -1)*(1 if i%2==0 else -1),"hit":false})
 elif id=="magic_wand":
  for i in n:bursts.append({"delay":i*.12})
 elif id=="fire_wand":
  var list:Array=world().query_enemies(p.position,weapons._stat(id,"reach")).filter(func(e):return weapons._valid_target(e) and p.position.distance_to(e.position)<=weapons._stat(id,"reach"))
  if list.is_empty():return false
  var e=list[weapons.rng.randi_range(0,list.size()-1)];var direction:Vector2=(e.position-p.position).normalized()
  for i in n:projectile(id,direction.rotated((i-(n-1)*.5)*.14))
 elif id=="runetracer":
  for i in n:projectile(id,Vector2.from_angle(weapons.rng.randf()*TAU))
 return true
func projectile(kind:String,direction:Vector2):
 var at:Vector2=weapons.game.player.position;var center:Vector2=at.clamp(Vector2(320,180),Vector2(1480,1020))
 shots.append({"kind":kind,"at":at,"velocity":direction*weapons._stat(kind,"projectile_speed")*weapons.projectile_factor(),"age":0.0,"life":weapons._stat(kind,"duration") if kind=="runetracer" else 4.0,"hits":{},"pierce":int(weapons._stat(kind,"pierce")),"bounds":Rect2(center-Vector2(320,180),Vector2(640,360)),"trail":[]})
func tick(delta:float,allow:bool):
 var origin:Vector2=weapons.game.player.position
 if allow and int(weapons.levels.get("garlic",0))>0:
  var radius:float=weapons._stat("garlic","reach")
  for e in world().query_enemies(origin,radius):
   if not weapons._valid_target(e) or e.position.distance_to(origin)>radius+e.radius or weapons.combat_time<float(aura_hits.get(e.serial,-1)):continue
   aura_hits[e.serial]=weapons.combat_time+weapons._interval("garlic")
   if not e is HordeBoss:e.garlic_until=world().elapsed+2
   weapons._hit(e,weapons._stat("garlic","damage"),Vector2.ZERO)
 if aura_hits.size()>512:
  for id in aura_hits.keys():
   if aura_hits[id]<weapons.combat_time-2:aura_hits.erase(id)
 for burst in bursts.duplicate():
  burst.delay-=delta
  if burst.delay>0:continue
  bursts.erase(burst)
  if not allow:continue
  var e=weapons.game.nearest_enemy(origin,weapons._stat("magic_wand","reach"))
  if weapons._valid_target(e):projectile("magic_wand",(e.position-origin).normalized())
 for strike in strikes:
  strike.age+=delta
  if strike.hit or strike.age<strike.delay:continue
  strike.hit=true
  var reach:float=weapons._stat("whip","reach");var half:float=12*weapons.area_factor()
  var end:Vector2=strike.at+Vector2(strike.side*reach,0)
  for e in candidates(strike.at-Vector2(0,half),end+Vector2(0,half)):
   if weapons._valid_target(e) and absf(e.position.y-strike.at.y)<=half+e.radius and (e.position.x-strike.at.x)*strike.side>=-e.radius and (e.position.x-strike.at.x)*strike.side<=reach+e.radius:weapons._hit(e,weapons._stat("whip","damage"),Vector2(strike.side*60,0))
 strikes=strikes.filter(func(s):return s.age<s.delay+.22)
 for shot in shots:
  shot.age+=delta
  if shot.age>=shot.life:shot.alive=false;continue
  var remaining:float=delta
  for bounce in 4:
   if remaining<=.00001 or not shot.get("alive",true):break
   var start:Vector2=shot.at;var end:Vector2=start+shot.velocity*remaining
   var normal:Vector2=Vector2.ZERO;var fraction:float=1
   var radius:float=weapons._stat(shot.kind,"projectile_radius")
   var bounds:Rect2=shot.bounds.grow(-radius)
   if shot.kind=="runetracer":
    for axis in 2:
     var low:float=bounds.position[axis];var high:float=bounds.end[axis]
     if end[axis]<low or end[axis]>high:
      var t:float=((low if end[axis]<low else high)-start[axis])/(end[axis]-start[axis])
      if t<fraction:fraction=maxf(0,t);normal=Vector2.ZERO;normal[axis]=1 if end[axis]<low else -1
   wall_query.from=start;wall_query.to=end;wall_query.collision_mask=4
   var wall:Dictionary=world().get_world_2d().direct_space_state.intersect_ray(wall_query)
   if not wall.is_empty():
    var f:float=start.distance_to(wall.position)/maxf(.0001,start.distance_to(end))
    if f<fraction:fraction=f;normal=wall.normal
   end=start.lerp(end,fraction)
   var near:Array=candidates(start-Vector2.ONE*radius,end+Vector2.ONE*radius)
   near.sort_custom(func(a,b):return start.distance_squared_to(a.position)<start.distance_squared_to(b.position))
   for e in near:
    if not weapons._valid_target(e) or weapons.combat_time<float(shot.hits.get(e.serial,-1)):continue
    if Geometry2D.get_closest_point_to_segment(e.position,start,end).distance_to(e.position)>e.radius+radius:continue
    shot.hits[e.serial]=weapons.combat_time+.5 if shot.kind=="runetracer" else INF
    weapons._hit(e,weapons._stat(shot.kind,"damage"),shot.velocity.normalized()*65 if shot.kind=="magic_wand" else Vector2.ZERO)
    if shot.kind!="runetracer":
     shot.pierce-=1
     if shot.pierce<=0:shot.alive=false;break
   shot.at=end
   if normal!=Vector2.ZERO:
    if shot.kind!="runetracer":shot.alive=false;break
    shot.velocity=Vector2(shot.velocity).bounce(normal);shot.at+=normal*.2;remaining*=1-fraction
   else:remaining=0

 shots=shots.filter(func(s):return s.get("alive",true))
