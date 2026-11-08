class_name SpecialEncounters
extends Node2D
var game
var visual_bolts:Dictionary={}
var impact_fx:Array[Dictionary]=[]
var fire_texture=preload("res://assets/effects/fire.png")
var impact_texture=preload("res://assets/effects/impact.png")
var flask_texture=preload("res://assets/effects/flask.png")
var pool_texture=preload("res://assets/v24/poison_pool.png")
var splash_texture=preload("res://assets/effects/splash.png")
var balance:SpecialBalance=preload("res://data/encounters/special.tres")
var marks:Array[Dictionary]=[]
var areas:Array[Dictionary]=[]
var bolts:Array[Dictionary]=[]
var children:Dictionary={}
var casters:Dictionary={}
func setup(owner_game):
 game=owner_game
 z_index=2
func reset():
 marks.clear();areas.clear();bolts.clear();children.clear();casters.clear();visual_bolts.clear();impact_fx.clear();queue_redraw()
func living(owner:int)->int:
 var remaining:Array=[]
 for ref in children.get(owner,[]):
  var child=ref.get_ref()
  if is_instance_valid(child) and child.alive:remaining.append(ref)
 children[owner]=remaining
 return remaining.size()
func summon(caster)->bool:
 var owner:int=caster.get_instance_id()
 if living(owner)>0:return false
 for mark in marks:
  if mark.owner==owner:return false
 var chained:bool=caster.chain_root>0
 var count_value:int=int(game.campaign.config.chain_batch) if chained else balance.summon_count
 if chained:game.late_arena.chain.request(owner,count_value)
 if game.enemies.size()+marks.size()+count_value>game.balance.max_enemies:return false
 if chained and game.late_arena.chain.count(caster.chain_root)+game.late_arena.reserved(caster.chain_root)+count_value>int(game.campaign.config.chain_budget):return false
 var pool:Array=[]
 if chained:
  for id in game.campaign.config.chain_pool:
   if not game.enemy_data.has(id) or id in ["demon","executioner","guardian","horror"]:continue
   if id=="necromancer" and caster.chain_generation+1>=int(game.campaign.config.chain_depth):continue
   pool.append(id)
 else:pool=["skeleton_sword"]
 if pool.is_empty():pool=["ghoul"]
 var points:Array[Vector2]=[]
 for i in count_value:
  for attempt in 100:
   var at:Vector2=caster.position+Vector2.from_angle((i+attempt*.31)*TAU/count_value)*(85+attempt%8*20)
   if not game.arena.safe_position(at,18) or game.players_near(at,45):continue
   if points.any(func(p):return p.distance_to(at)<44):continue
   points.append(at);break
 if points.size()!=count_value:return false
 casters[owner]=weakref(caster)
 for i in count_value:
  marks.append({"owner":owner,"at":points[i],"age":0.0,"species":pool[randi()%pool.size()] if chained else ("skeleton_archer" if i==6 else "skeleton_sword"),"root":caster.chain_root,"generation":caster.chain_generation+1})
 if chained:game.late_arena.chain.waiting.erase(owner)
 return true

func magic(at:Vector2,direction:Vector2,damage:float,owner_root:int=0,attacker:int=0):
 if bolts.size()<96:bolts.append({"root":owner_root,"attacker":attacker,"visual_id":str(Time.get_ticks_usec()),"at":at,"velocity":direction*balance.magic_speed,"life":4.0,"damage":damage})
func flask(source:Vector2,at:Vector2,owner_root:int=0,attacker:int=0)->bool:
 if areas.size()>=balance.pool_limit:return false
 for area in areas:
  if area.at.distance_to(at)<balance.pool_radius*2.5:return false
 areas.append({"root":owner_root,"attacker":attacker,"at":at,"source":source,"age":0.0,"inside":[]})
 return true
func tick(delta:float):
 if game.consumables!=null and game.consumables.freeze_left>0:return
 var owners:Dictionary={}
 for mark in marks:mark.age+=delta;owners[mark.owner]=true
 for owner in owners:
  var caster=casters[owner].get_ref() if casters.has(owner) else null
  if not is_instance_valid(caster) or not caster.alive:
   marks=marks.filter(func(m):return m.owner!=owner)
   casters.erase(owner)
   continue
  var batch=marks.filter(func(m):return m.owner==owner)
  if batch[0].age<balance.summon_warning or game.enemies.size()+batch.size()>game.balance.max_enemies:continue
  if batch.any(func(m):return game.players_near(m.at,24) or not game.enemy_space_free(m.at,18)):continue
  var spawned:Array=[]
  for i in batch.size():
   var mark:Dictionary=batch[i]
   var child=game.spawn_enemy(mark.get("species","skeleton_sword"),mark.at,false,{"root":int(mark.get("root",0)),"generation":int(mark.get("generation",-1))})
   if child!=null:
    spawned.append(weakref(child))
    if child.chain_root>0:game.late_arena.chain.generated+=1
  children[owner]=spawned
  caster.visual_cast_release=.18
  marks=marks.filter(func(m):return m.owner!=owner)
  casters.erase(owner)
 for area in areas:
  area.age+=delta
  if area.age<balance.flask_warning:continue
  var inside:Array=[]
  for player in game.team_players():
   if player.position.distance_to(area.at)<=balance.pool_radius+player.radius:
    inside.append(player.get_instance_id())
    if not area.inside.has(player.get_instance_id()):player.apply_poison(balance.poison_duration,balance.poison_damage*(1+.05*game.run_challenge),int(area.get("attacker",0)))
  area.inside=inside
 areas=areas.filter(func(a):return a.age<balance.flask_warning+balance.pool_duration)
 for i in range(bolts.size()-1,-1,-1):
  var bolt=bolts[i];bolt.life-=delta
  var end:Vector2=bolt.at+bolt.velocity*delta
  var victim=game.projectile_victim(bolt.at,end,4)
  if victim!=null:victim.take_damage(bolt.damage,bolt.at,int(bolt.get("attacker",0)));bolt.life=0
  if game.state!="running":return
  bolt.at=end
  if bolt.life<=0:bolts.remove_at(i)
 for owner in children.keys():
  if living(owner)==0:children.erase(owner)
 queue_redraw()
func draw_frame(texture:Texture2D,at:Vector2,frame:int,dimensions:Vector2,scale_factor:float=1.0):
 draw_texture_rect_region(texture,Rect2(at.round()-dimensions*scale_factor/2,dimensions*scale_factor),Rect2(Vector2(frame*dimensions.x,0),dimensions))
func _draw():
 if game==null:return
 if game.state not in ["running","paused","upgrading"]:
  visual_bolts.clear();impact_fx.clear();return
 for mark in marks:draw_arc(mark.at,13,0,TAU,16,Color("ad8eac"),1)
 for area in areas:
  var active:bool=area.age>=balance.flask_warning
  if active:
   var fade:float=clampf((balance.flask_warning+balance.pool_duration-area.age)/.7,0,1)
   draw_set_transform(area.at.round(),0,Vector2.ONE)
   var remaining:float=balance.flask_warning+balance.pool_duration-area.age
   var frame:int=4+int((area.age-balance.flask_warning)*8)%8
   if remaining<.7:frame=12+mini(3,int((.7-remaining)/.7*4))
   draw_texture_rect_region(pool_texture,Rect2(-balance.pool_radius,-balance.pool_radius,balance.pool_radius*2,balance.pool_radius*2),Rect2(frame*64,0,64,64),Color(1,1,1,fade))
   draw_set_transform(Vector2.ZERO)
   var impact_age:float=area.age-balance.flask_warning
   if impact_age<.42:draw_frame(pool_texture,area.at,mini(3,int(impact_age/.42*4)),Vector2(64,64),balance.pool_radius/32)
  else:
   var t:float=clampf(area.age/balance.flask_warning,0,1)
   var ground:Vector2=area.source.lerp(area.at,t)
   var at:Vector2=ground+Vector2(signf(area.at.x-area.source.x)*9*(1-t),-sin(t*PI)*35-20*(1-t))
   var points:=PackedVector2Array()
   for i in 20:points.append((area.at+Vector2.from_angle(i*TAU/20)*balance.pool_radius).round())
   draw_polyline(points,Color("a6b85b"),1)
   draw_rect(Rect2(ground.round()-Vector2(4,1),Vector2(8,3)),Color(0,0,0,.5))
   draw_set_transform(at.round(),t*TAU*1.5)
   draw_frame(flask_texture,Vector2.ZERO,0,Vector2(24,24),.75)
   draw_set_transform(Vector2.ZERO)
 var current:Dictionary={}
 for bolt in bolts:
  var id:String=str(bolt.get("visual_id",""))
  current[id]={"at":bolt.at,"angle":bolt.velocity.angle()}
  draw_set_transform(bolt.at.round(),bolt.velocity.angle())
  draw_frame(fire_texture,Vector2(-10,0),int(game.elapsed*14)%6,Vector2(32,24))
  draw_set_transform(Vector2.ZERO)
 for id in visual_bolts:
  if not current.has(id):impact_fx.append({"at":visual_bolts[id].at,"angle":visual_bolts[id].angle,"start":game.elapsed})
 visual_bolts=current
 impact_fx=impact_fx.filter(func(f):return game.elapsed-f.start<.42)
 for fx in impact_fx:
  draw_set_transform(fx.at.round(),fx.angle)
  draw_frame(impact_texture,Vector2.ZERO,mini(6,int((game.elapsed-fx.start)*17)),Vector2(24,24))
  draw_set_transform(Vector2.ZERO)
