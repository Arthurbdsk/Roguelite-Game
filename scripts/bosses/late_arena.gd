class_name LateArena
extends Node2D
var game
var areas:Array[Dictionary]=[]
var shots:Array[Dictionary]=[]
var deaths:Array[Dictionary]=[]
var chain:=ChainBudget.new()
var seed_pending:Array[Dictionary]=[]
var bursts:Array[Dictionary]=[]
var patterns:FinalPatterns
var active_boss
var beam_texture=preload("res://assets/effects/clock_beam.png")
func setup(owner_game):
 game=owner_game;z_index=-4;patterns=FinalPatterns.new();add_child(patterns);patterns.setup(game)
func reset():
 if patterns!=null:patterns.reset()
 areas.clear();shots.clear();seed_pending.clear();bursts.clear();chain.reset();game.arena.sync_dynamic_walls({})
 for d in deaths:
  if is_instance_valid(d.boss):d.boss.queue_free()
 deaths.clear();active_boss=null;queue_redraw()
func begin_encounter(id:String)->bool:
 var point:=Vector2(900,630)
 var found:bool=false
 for i in 80:
  point=Vector2(900,630)+Vector2.from_angle(i*2.4)*(180+i%5*25)
  if game.arena.safe_position(point,36) and not game.players_near(point,100) and game.navigation.reachable(point,32):found=true;break
 if not found:return false
 active_boss=game.spawn_enemy(id,point)
 if active_boss==null:return false
 active_boss.combat_enabled=false;active_boss.targetable=false;active_boss.state="entry";active_boss.entry_age=0;active_boss.sprite.modulate.a=0
 game.announce(active_boss.data.title,3)
 return true
func damage(kind:String,boss)->float:
 return base_damage(game,boss.data.id,kind)*game.enemy_scale().damage
static func base_damage(world,species:String,kind:String)->float:
 if species=="guardian":return float(world.campaign.config.guardian_damage)
 var base:float=world.boss_balance.demon_charge_damage if kind=="dash" else (world.boss_balance.fire_damage if kind=="fire" else world.boss_balance.lightning_damage)
 return base*world.boss_balance.second_damage_multiplier*float(world.campaign.config.horror_damage_ratio_to_demon_phase2)
func clear_attacks(boss):
 patterns.clear_owner(boss.serial)
 areas=areas.filter(func(a):return a.owner!=boss.serial);shots=shots.filter(func(s):return s.owner!=boss.serial)
 game.enemy_projectiles.remove_owner(boss.get_instance_id())
 seed_pending=seed_pending.filter(func(m):return m.root!=boss.serial);bursts=bursts.filter(func(b):return b.owner!=boss.serial)
 for enemy in game.enemies.duplicate():
  if enemy!=boss and enemy.chain_root>0 and enemy.chain_root==boss.serial:game.despawn_enemy(enemy)
 game.specials.marks=game.specials.marks.filter(func(m):return int(m.get("root",0))!=boss.serial)
 game.specials.areas=game.specials.areas.filter(func(a):return int(a.get("root",0))!=boss.serial)
 game.specials.bolts=game.specials.bolts.filter(func(b):return int(b.get("root",0))!=boss.serial)
 chain.waiting.erase(-boss.serial)
 sync_walls();queue_redraw()
func on_death(boss):
 clear_attacks(boss);deaths.append({"boss":boss,"age":0.0})
func add_area(kind:String,at:Vector2,warning:float,duration:float,boss)->Dictionary:
 var area:Dictionary={"kind":kind,"at":at,"age":0.0,"warning":warning,"duration":duration,"owner":boss.serial,"attacker":boss.get_instance_id(),"damage":damage(kind,boss),"hits":{}}
 areas.append(area);return area
func cast(kind:String,boss)->bool:
 if kind in FinalPatterns.IDS:return patterns.request(kind,boss)
 if not can_cast(kind):return false
 var c:Dictionary=game.campaign.config
 if kind=="cross":
  for axis in 2:
   var area:Dictionary=add_area("cross",boss.locked_target,1.3,.35,boss)
   area.angle=boss.attack_index*.35+axis*PI/2;area.length=float(c.cross_length);area.width=float(c.cross_width)
 elif kind=="feathers":
  for i in int(c.feather_count):
   var stop:Vector2=boss.position+Vector2.from_angle(i*TAU/int(c.feather_count))*160
   stop=stop.clamp(Vector2(55,60),Vector2(1745,1140))
   if not game.arena.safe_position(stop,6):continue
   shots.append({"kind":"feather","at":boss.position,"source":boss.position,"stop":stop,"age":0.0,"velocity":(boss.locked_target-stop).normalized()*float(c.feather_speed),"warning":float(c.feather_warning),"damage":damage("feather",boss),"owner":boss.serial,"attacker":boss.get_instance_id(),"life":5.0})
 elif kind=="light_ring":
  var area:Dictionary=add_area("light_ring",boss.position,1.2,float(c.ring_radius)/float(c.ring_speed),boss)
  area.gap=(boss.locked_target-boss.position).angle()+.8;area.speed=float(c.ring_speed);area.width=float(c.ring_width);area.opening=deg_to_rad(float(c.ring_gap_degrees))
 else:return cast_horror(kind,boss)
 queue_redraw();return true
func tick(delta:float):
 patterns.tick(delta)
 if game.state!="running":return
 tick_advanced(delta)
 if is_instance_valid(active_boss) and active_boss.state=="entry":
  active_boss.entry_age+=delta;active_boss.sprite.frame=12;active_boss.sprite.modulate.a=minf(1,active_boss.entry_age/1.2)
  if active_boss.entry_age>=1.2:active_boss.enable_combat()
 for d in deaths.duplicate():
  d.age+=delta
  if is_instance_valid(d.boss):d.boss.sprite.frame=26+mini(5,int(d.age/1.5*6));d.boss.sprite.modulate.a=clampf(2-d.age/1.5*2,0,1)
  if d.age>=1.5:
   var id:String=d.boss.data.id if is_instance_valid(d.boss) else "guardian"
   if is_instance_valid(d.boss):d.boss.queue_free()
   deaths.erase(d);game.campaign.encounter_finished(id)
   if game.state!="running":return
 for area in areas:
  var previous:float=area.age;area.age+=delta
  if area.kind in ["ice","column"]:continue
  if area.age<area.warning:continue
  for player in game.team_players():
   if area.hits.has(player.get_instance_id()):continue
   var inside:bool=false
   if area.kind in ["cross","light_band"]:
    var offset:Vector2=(player.position-area.at).rotated(-area.angle)
    inside=absf(offset.x)<=area.length*.5 and absf(offset.y)<=area.width*.5+player.radius
   elif area.kind in ["light_ring","moving_ring"]:
    var offset:Vector2=player.position-area.at
    var near:float=maxf(0,previous-area.warning)*area.speed-area.width*.5-player.radius
    var far:float=(area.age-area.warning)*area.speed+area.width*.5+player.radius
    inside=offset.length()>=near and offset.length()<=far and absf(wrapf(offset.angle()-(area.gap+(area.age-area.warning)*.4 if area.kind=="moving_ring" else area.gap),-PI,PI))>area.opening*.5
   if inside:area.hits[player.get_instance_id()]=true;player.take_damage(area.damage,area.at,int(area.get("attacker",0)))
 for shot in shots:
  var previous:float=shot.age;shot.age+=delta
  if shot.age<.5:shot.at=shot.source.lerp(shot.stop,shot.age/.5)
  elif shot.age<shot.warning+.5:shot.at=shot.stop
  else:
   var end:Vector2=shot.at+shot.velocity*maxf(0,shot.age-maxf(previous,shot.warning+.5))
   var wall:Dictionary=get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(shot.at,end,4))
   if not wall.is_empty():end=wall.position;shot.life=shot.age
   var victim=game.projectile_victim(shot.at,end,4)
   if victim!=null:victim.take_damage(shot.damage,shot.at,int(shot.get("attacker",0)));shot.age=shot.life
   shot.at=end
 shots=shots.filter(func(s):return s.age<s.life)
 areas=areas.filter(func(a):return a.age<a.warning+a.duration)
 sync_walls();queue_redraw()
func visual_tick(delta:float):
 patterns.visual_tick(delta)
 for a in areas:a.age+=delta
 for s in shots:
  s.age+=delta
  if s.age<s.warning+.5:s.at=s.source.lerp(s.stop,minf(1,s.age/.5))
  else:s.at+=s.velocity*delta
 sync_walls();queue_redraw()
func _draw():
 for a in areas:
  if a.kind in ["cross","light_band"]:
   draw_set_transform(a.at.round(),a.angle)
   if a.age<a.warning:draw_rect(Rect2(-a.length/2,-a.width/2,a.length,a.width),Color("dbbe74"),false,1)
   else:
    var x:float=-a.length/2
    while x<a.length/2:
     draw_texture_rect_region(beam_texture,Rect2(x,-a.width/2,32,a.width),Rect2(int(game.elapsed*18)%6*32,0,32,16));x+=32
   draw_set_transform(Vector2.ZERO)
  elif a.kind in ["light_ring","moving_ring"]:
   var radius:float=maxf(12,(a.age-a.warning)*a.speed) if a.age>=a.warning else 28
   for i in 64:
    var angle:float=i*TAU/64
    if absf(wrapf(angle-(a.gap+(a.age-a.warning)*.4 if a.kind=="moving_ring" else a.gap),-PI,PI))<a.opening/2:continue
    var at:Vector2=a.at+Vector2.from_angle(angle)*radius
    draw_rect(Rect2(at.round()-Vector2(2,2),Vector2(4,4)),Color("fff0bc") if a.age>=a.warning else Color("9c865d"))
 for a in areas:
  if a.kind=="ice":IceVFX.render(self,game.boss_arena.ice_texture,a,a.age>=a.warning)
  elif a.kind=="column":
   if a.age<a.warning:draw_arc(a.at,a.radius,0,TAU,32,Color("bcdff1"),1)
   elif a.get("icy",false):draw_texture_rect_region(game.boss_arena.ice_texture,Rect2(a.at-Vector2(a.radius,a.radius*1.7),Vector2(a.radius*2,a.radius*2)),Rect2(mini(9,int((a.age-a.warning)*25))*32,0,32,56))
   else:draw_texture_rect_region(game.weapon_system.lightning_texture,Rect2(a.at-Vector2(a.radius,100),Vector2(a.radius*2,110)),Rect2(mini(7,int((a.age-a.warning)*25))*48,0,48,96))
 for m in seed_pending:draw_arc(m.at,16,0,TAU,16,Color("edb68e"),1)
 for s in shots:
  draw_set_transform(s.at.round(),s.velocity.angle()+PI/2)
  draw_colored_polygon(PackedVector2Array([Vector2(-2,-9),Vector2(3,-5),Vector2(3,2),Vector2(0,8),Vector2(-3,2)]),Color("dfd5b4"))
  draw_line(Vector2(0,-6),Vector2(0,8),Color("fff6dc"),1);draw_set_transform(Vector2.ZERO)

func can_cast(kind:String)->bool:
 if kind in FinalPatterns.IDS:return patterns.can_start()
 if not patterns.idle():return false
 if areas.size()>24 or shots.size()>64:return false
 var categories:Dictionary={}
 for a in areas:categories[a.kind]=true
 if not bursts.is_empty():categories.fire=true
 if not shots.is_empty():categories.feathers=true
 if categories.size()>=2:return false
 if kind in ["ice","columns","ice_sectors","light_bands","moving_ring"] and not areas.is_empty():return false
 if kind=="summon" and is_instance_valid(active_boss) and (chain.count(active_boss.serial)>0 or not seed_pending.is_empty()):return false
 return true
func cast_horror(kind:String,boss)->bool:
 var c:Dictionary=game.campaign.config
 if kind=="fire":
  for i in int(c.fire_volleys):bursts.append({"at":boss.position,"direction":boss.charge_direction,"age":-i*float(c.fire_spacing_seconds),"owner":boss.serial,"node_owner":boss.get_instance_id(),"damage":damage("fire",boss)})
 elif kind=="summon":
  if chain.count(boss.serial)>0 or not seed_pending.is_empty():return false
  var points:Array[Vector2]=[]
  for i in int(c.chain_initial):
   for attempt in 160:
    var at:Vector2=boss.position+Vector2.from_angle((i*2.4+attempt*.43))*float(190+attempt%7*32)
    if not game.arena.safe_position(at,16) or game.players_near(at,85):continue
    if points.any(func(p):return p.distance_to(at)<36):continue
    points.append(at);break
  if points.size()!=int(c.chain_initial):return false
  for at in points:seed_pending.append({"root":boss.serial,"at":at,"age":0.0})
  chain.request(-boss.serial,int(c.chain_initial))
 elif kind=="ice":
  var rects:Array[Rect2]=IceLayout.plan(game,game.boss_balance.ice_band_length,game.boss_balance.ice_band_width,game.boss_balance.ice_corridor,game.boss_balance.ice_opening)
  if rects.is_empty():return false
  for rect in rects:
   var a:Dictionary=add_area("ice",rect.get_center(),1.5,4,boss);a.size=rect.size;a.solid=true
 elif kind=="columns":
  var axis:Vector2=boss.charge_direction.orthogonal()
  for i in 7:
   var at:Vector2=boss.locked_target+axis*(i-3)*64
   if not game.arena.safe_position(at,30):continue
   var a:Dictionary=add_area("column",at,1.2+i*.18,.35,boss);a.radius=30.0
 elif kind=="ice_sectors":
  for i in 12:
   if i%4==0:continue
   var at:Vector2=boss.locked_target+Vector2.from_angle(i*TAU/12)*130
   if not game.arena.safe_position(at,28) or game.players_near(at,25):continue
   var a:Dictionary=add_area("column",at,1.3+(i%3)*.12,.4,boss);a.radius=28.0;a.icy=true
 elif kind=="light_bands":
  var angle:float=(boss.attack_index%4)*PI/4
  for i in 3:
   var a:Dictionary=add_area("light_band",boss.locked_target+Vector2.DOWN.rotated(angle)*(i-1)*100,1.3+i*.3,.3,boss)
   a.angle=angle;a.length=1000.0;a.width=32.0
 elif kind=="moving_ring":
  for i in 2:
   var a:Dictionary=add_area("moving_ring",boss.position,1.3+i*.6,3,boss)
   a.gap=boss.charge_direction.angle();a.speed=110.0;a.width=16.0;a.opening=deg_to_rad(80)
 else:return false
 queue_redraw();return true
func sync_walls():
 var walls:Dictionary={}
 for i in areas.size():
  var a:Dictionary=areas[i]
  if a.kind=="ice" and a.get("solid",false) and a.age>=a.warning and a.age<a.warning+a.duration:walls[str(a.owner)+"_"+str(i)]=Rect2(a.at-a.size/2,a.size)
 game.arena.sync_dynamic_walls(walls)
func reserved(root:int)->int:
 var count_value:int=seed_pending.filter(func(m):return m.root==root).size()
 for mark in game.specials.marks:
  if int(mark.get("root",0))==root:count_value+=1
 return count_value
func tick_advanced(delta:float):
 for seed in seed_pending.duplicate():
  seed.age+=delta
  if seed.age<1.2 or game.players_near(seed.at,45) or game.enemies.size()>=game.balance.max_enemies:continue
  if not game.enemy_space_free(seed.at,game.enemy_data.necromancer.radius):continue
  game.spawn_enemy("necromancer",seed.at,false,{"root":seed.root,"generation":0})
  seed_pending.erase(seed);chain.generated+=1
  chain.waiting[-int(seed.root)]=seed_pending.size()
  if seed_pending.is_empty():chain.waiting.erase(-int(seed.root))
 for burst in bursts.duplicate():
  burst.age+=delta
  if burst.age<0:continue
  var count_value:int=int(game.campaign.config.fire_count)
  if game.enemy_projectiles.fire_count()+count_value>int(game.campaign.config.fire_limit):continue
  for i in count_value:
   var direction:Vector2=burst.direction.rotated(-PI/2+PI*i/(count_value-1))
   game.enemy_projectiles.fire_ball(burst.at+direction*28,direction,int(burst.node_owner),3,burst.damage,int(game.campaign.config.fire_limit))
  bursts.erase(burst)
 for a in areas:
  if a.kind!="column" or a.get("hit",false) or a.age+delta<a.warning:continue
  a.hit=true;game.damage_team_area(a.at,a.radius,a.damage,int(a.get("attacker",0)))
