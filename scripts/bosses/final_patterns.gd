class_name FinalPatterns
extends Node2D

const IDS:Array[String]=["spiral","rings","spears","orbs","crystals","beams","seals","totems"]
var game
var config:Dictionary={}
var jobs:Array[Dictionary]=[]
var shots:Array[Dictionary]=[]
var marks:Array[Dictionary]=[]
var queue:Array[Dictionary]=[]
var cooldown:float=0
var sequence:int=0
var emitted:int=0
var blocked:int=0
var wait_reason:String=""
var impacts:Array[Dictionary]=[]
var orb_texture=preload("res://assets/v12/siege_orb.png")
var beam_texture=preload("res://assets/effects/clock_beam.png")

func setup(owner_game):
 game=owner_game;z_index=7;config=JSON.parse_string(FileAccess.get_file_as_string("res://data/final_patterns.json"))
func reset():
 for target in game.enemies.duplicate():
  if target is HazardTarget:game.despawn_enemy(target)
 jobs.clear();shots.clear();marks.clear();queue.clear();impacts.clear();cooldown=0;sequence=0;emitted=0;blocked=0;wait_reason="";queue_redraw()
func clear_owner(owner:int):
 for target in game.enemies.duplicate():
  if target is HazardTarget and target.owner_boss==owner:game.despawn_enemy(target)
 jobs=jobs.filter(func(j):return j.owner!=owner);shots=shots.filter(func(s):return s.owner!=owner);marks=marks.filter(func(m):return m.owner!=owner);queue=queue.filter(func(q):return q.owner!=owner);impacts.clear()
 cooldown=float(config.recovery);queue_redraw()
func owner_node(serial:int):
 for enemy in game.enemies:
  if is_instance_valid(enemy) and enemy.serial==serial and enemy.alive:return enemy
 return null
func idle()->bool:return jobs.is_empty() and shots.is_empty() and marks.is_empty() and queue.is_empty()
func routes()->Array:
 var result:Array=[]
 for player in game.team_players():
  var best:Vector2=Vector2.INF
  for i in 24:
   var stop:Vector2=player.position+Vector2.from_angle(i*TAU/24)*150
   if not game.arena.safe_position(stop,player.radius+6) or not game.navigation.clear_segment(player.position,stop,player.radius+6):continue
   var clear:bool=true
   for sample in range(1,9):
    var fraction:float=sample/8.0
    if forecast_danger(player.position.lerp(stop,fraction),fraction*150/maxf(1,player.speed),player.radius+3):clear=false;break
   if clear:best=stop;break
  if best==Vector2.INF:return []
  result.append({"source":player.position,"end":best})
 return result
func forecast_danger(at:Vector2,after:float,radius:float)->bool:
 for shot in shots:
  if shot.age+after<shot.life and at.distance_to(shot.at+shot.velocity*after)<radius+shot.radius+4:return true
 for shot in game.enemy_projectiles.arrows+game.specials.bolts:
  if after<shot.life and at.distance_to(shot.at+shot.velocity*after)<radius+float(shot.get("radius",4))+4:return true
 for pool in game.specials.areas:
  var age:float=pool.age+after
  if age>=game.specials.balance.flask_warning and age<game.specials.balance.flask_warning+game.specials.balance.pool_duration and at.distance_to(pool.at)<radius+game.specials.balance.pool_radius:return true
 for mark in marks:
  if mark.age+after<mark.warning or mark.age+after>mark.warning+mark.duration:continue
  var offset:Vector2=(at-mark.at).rotated(-mark.angle)
  if mark.kind=="spear":
   if absf(offset.x)<=mark.length*.5+radius and absf(offset.y)<=mark.width*.5+radius:return true
  elif offset.length()<=mark.radius+radius:return true
 for job in jobs:
  if job.kind!="beams" or job.age+after<job.warning or job.age+after>job.warning+float(config.beam_duration):continue
  var predicted:Dictionary=job.duplicate();predicted.age+=after
  for segment in beam_segments(predicted):
   if Geometry2D.get_closest_point_to_segment(at,segment.source,segment.end).distance_to(at)<float(config.beam_width)*.5+radius:return true
 return false
func old_busy()->bool:
 return not game.late_arena.areas.is_empty() or not game.late_arena.shots.is_empty() or not game.late_arena.bursts.is_empty() or game.enemy_projectiles.arrows.any(func(s):return is_instance_valid(game.boss) and int(s.get("owner",0))==game.boss.get_instance_id()) or not game.arena.dynamic_walls.is_empty()
func can_start()->bool:
 if not idle() or cooldown>0:wait_reason="Aguardando o padrão atual terminar";return false
 if old_busy():wait_reason="Aguardando os poderes anteriores terminarem";return false
 if routes().is_empty():wait_reason="Aguardando uma rota livre para cada jogador";return false
 wait_reason="";return true
func request(kind:String,boss,companion:String="")->bool:
 if kind not in IDS or not can_start():return false
 if not companion.is_empty() and not config.combination_pairs.any(func(pair):return pair[0]==kind and pair[1]==companion):return false
 var paths:Array=routes()
 if paths.is_empty():return false
 if not start(kind,boss,paths):return false
 if not companion.is_empty():queue.append({"owner":boss.serial,"kind":companion,"delay":.65,"lanes":paths})
 return true
func start(kind:String,boss,lanes:Array)->bool:
 sequence+=1
 var players:Array=game.team_players()
 var player=players[sequence%players.size()]
 var job:Dictionary={"id":sequence,"kind":kind,"owner":boss.serial,"at":boss.position,"age":0.0,"warning":float(config.warning),"step":0,"next":float(config.warning),"lanes":lanes,"gap":(player.position-boss.position).angle(),"phase":boss.form,"damage":game.late_arena.damage("column",boss)*(float(config.phase2_damage) if boss.form==2 else 1.0)}
 if kind=="orbs":
  var points:Array=plan_points(player.position,int(config.orb_count),220,14,lanes,true)
  if points.size()!=int(config.orb_count):return false
  job.orbs=[]
  for i in points.size():job.orbs.append({"at":points[i],"locked_target":players[i%players.size()].position})
 if kind in ["crystals","totems"]:
  var count:int=int(config.crystal_count if kind=="crystals" else config.totem_count)
  if game.enemies.filter(func(e):return e is HazardTarget).size()+count>int(config.max_targets):return false
  var points:Array=plan_points(player.position if kind=="crystals" else boss.position,count,180,16,lanes)
  if points.size()!=count:return false
  job.targets=[]
  for i in count:job.targets.append({"at":points[i],"serial":0,"destroyed":false,"index":i})
 jobs.append(job);queue_redraw();return true
func plan_points(center:Vector2,count:int,distance:float,radius:float,lanes:Array=[],line_of_sight:bool=false)->Array:
 var result:Array=[]
 for i in count:
  for attempt in 120:
   var angle:float=i*TAU/count+attempt*.31
   var at:Vector2=center+Vector2.from_angle(angle)*(distance+attempt%5*18)
   if not game.arena.safe_position(at,radius) or not game.navigation.reachable(at,radius) or game.players_near(at,65):continue
   if line_of_sight and not game.navigation.clear_segment(at,center,5):continue
   if result.any(func(p):return p.distance_to(at)<50):continue
   if lanes.any(func(l):return Geometry2D.get_closest_point_to_segment(at,l.source,l.end).distance_to(at)<radius+24):continue
   result.append(at);break
 return result
func shot_batch(job:Dictionary,at:Vector2,angles:Array,speed:float=-1)->bool:
 if shots.size()+angles.size()>int(config.max_projectiles):blocked+=1;return false
 if speed<0:speed=float(config.projectile_speed)*(float(config.phase2_speed) if job.phase==2 else 1)
 for angle in angles:
  shots.append({"at":at,"velocity":Vector2.from_angle(angle)*speed,"age":0.0,"life":float(config.projectile_life),"radius":float(config.projectile_radius),"owner":job.owner,"damage":job.damage,"phase":job.phase})
 emitted+=angles.size();return true
func tick(delta:float):
 cooldown=maxf(0,cooldown-delta)
 for pending in queue.duplicate():
  pending.delay-=delta
  if pending.delay>0:continue
  var boss=owner_node(pending.owner)
  if boss==null:queue.erase(pending);continue
  if jobs.size()>=int(config.max_jobs) or routes().is_empty():pending.delay=.2;wait_reason="Combinação aguardando rotas livres";continue
  if jobs.size()<int(config.max_jobs):
   if start(pending.kind,boss,pending.lanes):queue.erase(pending);wait_reason=""
   else:pending.delay=.25;blocked+=1
 for job in jobs.duplicate():
  job.age+=delta
  tick_job(job,delta)
 tick_marks(delta)
 if game.state!="running":return
 for shot in shots:
  shot.age+=delta
  var stop:Vector2=shot.at+shot.velocity*delta
  var hit:Dictionary=get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(shot.at,stop,4))
  if not hit.is_empty():stop=hit.position;shot.age=shot.life
  var victim=game.projectile_victim(shot.at,stop,shot.radius)
  if victim!=null:victim.take_damage(shot.damage,shot.at);shot.age=shot.life
  if shot.age>=shot.life:impacts.append({"at":stop,"age":0.0})
  shot.at=stop
  if game.state!="running":return
 shots=shots.filter(func(s):return s.age<s.life)
 for fx in impacts:fx.age+=delta
 impacts=impacts.filter(func(f):return f.age<.25)
 if jobs.is_empty() and marks.is_empty():cooldown=maxf(cooldown,float(config.recovery)) if not shots.is_empty() else cooldown
 queue_redraw()
func add_mark(job:Dictionary,kind:String,at:Vector2,warning:float,duration:float)->Dictionary:
 var mark:Dictionary={"kind":kind,"owner":job.owner,"at":at,"age":0.0,"warning":warning,"duration":duration,"damage":job.damage,"hits":{},"radius":float(config.seal_radius),"width":float(config.spear_width),"length":640.0,"angle":0.0}
 marks.append(mark);return mark
func tick_marks(delta:float):
 for mark in marks:
  mark.age+=delta
  if mark.age<mark.warning:continue
  for player in game.team_players():
   if mark.hits.has(player.get_instance_id()):continue
   var offset:Vector2=(player.position-mark.at).rotated(-mark.angle)
   var inside:bool=absf(offset.x)<=mark.length*.5+player.radius and absf(offset.y)<=mark.width*.5+player.radius if mark.kind=="spear" else offset.length()<=mark.radius+player.radius
   if inside:mark.hits[player.get_instance_id()]=true;player.take_damage(mark.damage,mark.at)
   if game.state!="running":return
 marks=marks.filter(func(m):return m.age<m.warning+m.duration)
func target_removed(serial:int,kind:String="ice_crystal"):
 for job in jobs:
  for target in job.get("targets",[]):
   if target.serial==serial:target.destroyed=true;impacts.append({"at":target.at,"age":0.0,"kind":kind})
func beam_segments(job:Dictionary)->Array:
 var result:Array=[]
 var rotation:float=maxf(0,job.age-job.warning)*float(config.beam_speed)*(float(config.phase2_speed) if job.phase==2 else 1)*(-1 if job.phase==2 else 1)
 for i in int(config.beam_arms):
  var direction:Vector2=Vector2.from_angle(job.gap+.8+rotation+i*TAU/int(config.beam_arms))
  var source:Vector2=job.at+direction*float(config.beam_inner)
  var stop:Vector2=job.at+direction*float(config.beam_range)
  var collision:Dictionary=get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(job.at,stop,4))
  if not collision.is_empty():
   stop=collision.position
   if stop.distance_to(job.at)<float(config.beam_inner):continue
  result.append({"source":source,"end":stop})
 return result
func tick_job(job:Dictionary,_delta:float):
 if job.kind=="seals":
  if job.step<int(config.seal_steps) and job.age>=job.next:
   var positions:Array=[]
   for player in game.team_players():
    if positions.any(func(p):return p.distance_to(player.position)<float(config.seal_radius)*1.5):continue
    positions.append(player.position)
    var mark:Dictionary=add_mark(job,"seal",player.position,float(config.seal_warning),float(config.seal_duration))
    mark.age=-clampf(_delta-(job.age-job.next),0,_delta)
   job.step+=1;job.next=job.age+float(config.seal_spacing)
  if job.step>=int(config.seal_steps) and job.age>job.next+float(config.seal_warning)+float(config.seal_duration):jobs.erase(job)

 if job.kind=="beams":
  if job.age>=job.warning:
   for player in game.team_players():
    if job.age<float(job.get("hits",{}).get(player.get_instance_id(),0)):continue
    for segment in beam_segments(job):
     if Geometry2D.get_closest_point_to_segment(player.position,segment.source,segment.end).distance_to(player.position)<=float(config.beam_width)*.5+player.radius:
      if not job.has("hits"):job.hits={}
      job.hits[player.get_instance_id()]=job.age+.8;player.take_damage(job.damage,job.at);break
    if game.state!="running":return
  if job.age>=job.warning+float(config.beam_duration):jobs.erase(job)

 if job.kind in ["crystals","totems"]:
  var totems:bool=job.kind=="totems"
  if job.age<job.warning:return
  if job.step==0:
   for target in job.targets:
    var node=game.spawn_enemy("channel_totem" if totems else "ice_crystal",target.at,false,{"pattern_owner":job.owner});target.serial=node.serial
   job.step=1
  if job.age<job.warning+float(config.totem_charge if totems else config.crystal_charge):return
  var alive:Array=job.targets.filter(func(t):return not t.destroyed)
  if shots.size()+alive.size()*int(config.totem_sector_count if totems else config.crystal_radial_count)>int(config.max_projectiles):blocked+=1;return
  for target in alive:
   var angles:Array=[]
   if totems:
    for i in int(config.totem_sector_count):
     var angle:float=target.index*TAU/int(config.totem_count)-PI/4+(i+.5)*PI/2/int(config.totem_sector_count)
     if absf(wrapf(angle-job.gap,-PI,PI))<deg_to_rad(float(config.totem_default_gap_degrees))*.5:continue
     angles.append(angle)
   else:
    for i in int(config.crystal_radial_count):angles.append(i*TAU/int(config.crystal_radial_count))
   shot_batch(job,job.at if totems else target.at,angles)
   var node=owner_node(target.serial)
   if node!=null:game.despawn_enemy(node)
   impacts.append({"at":target.at,"age":0.0,"kind":"channel_totem" if totems else "ice_crystal"})
  jobs.erase(job)

 if job.kind=="orbs":
  if job.step<int(config.orb_burst) and job.age>=job.next:
   if shots.size()+job.orbs.size()>int(config.max_projectiles):blocked+=1;return
   for orb in job.orbs:shot_batch(job,orb.at,[(orb.locked_target-orb.at).angle()])
   job.step+=1;job.next=job.age+float(config.orb_spacing)
  if job.step>=int(config.orb_burst) and job.age>job.next+.4:jobs.erase(job)

 if job.kind=="spears":
  if job.step==0:
   var players:Array=game.team_players()
   if players.is_empty():jobs.erase(job);return
   var at:Vector2=players[0].position.clamp(Vector2(380,270),Vector2(1420,930))
   for i in int(config.spear_count):add_mark(job,"spear",at+Vector2(0,(i-2)*80),job.warning+i*float(config.spear_spacing),float(config.spear_duration))
   job.step=1
  if job.age>job.warning+int(config.spear_count)*float(config.spear_spacing)+float(config.spear_duration):jobs.erase(job)

 if job.kind=="rings":
  if job.step<int(config.ring_steps) and job.age>=job.next:
   var gap:float=job.gap+job.step*.9
   var angles:Array=[]
   for i in int(config.ring_count):
    var angle:float=i*TAU/int(config.ring_count)
    if absf(wrapf(angle-gap,-PI,PI))>=deg_to_rad(float(config.ring_gap_degrees))*.5:angles.append(angle)
   if shot_batch(job,job.at,angles):job.step+=1;job.next=job.age+float(config.ring_spacing)
  if job.step>=int(config.ring_steps) and job.age>job.next+.4:jobs.erase(job)
 if job.kind=="spiral":
  if job.step<int(config.spiral_steps) and job.age>=job.next:
   var angle:float=job.step*float(config.spiral_turn)
   if shot_batch(job,job.at,[job.gap+PI+angle,job.gap-angle]):job.step+=1;job.next=job.age+float(config.spiral_spacing)
  if job.step>=int(config.spiral_steps) and job.age>job.next+.4:jobs.erase(job)
func visual_tick(delta:float):
 for j in jobs:j.age+=delta
 for s in shots:s.at+=s.velocity*delta;s.age+=delta
 for m in marks:m.age+=delta
 queue_redraw()
func _draw():
 for mark in marks:
  if mark.kind!="seal":continue
  for i in 20:
   var at:Vector2=mark.at+Vector2.from_angle(i*TAU/20)*mark.radius
   draw_rect(Rect2(at.round()-Vector2.ONE,Vector2(2,2)),Color("e6b878") if mark.age<mark.warning else Color("ffe5b0"))
  if mark.age<mark.warning:
   var progress:float=mark.age/mark.warning
   draw_rect(Rect2(mark.at-Vector2(3,3),Vector2(6,6)),Color("cf9d68"),false,1)
   draw_line(mark.at+Vector2(-12,0),mark.at+Vector2(-12+24*progress,0),Color("e6b878"),1)
  else:
   draw_texture_rect_region(game.weapon_system.lightning_texture,Rect2(mark.at-Vector2(mark.radius,65),Vector2(mark.radius*2,70)),Rect2(mini(7,int((mark.age-mark.warning)*28))*48,0,48,96))
 for job in jobs:
  if job.kind!="beams":continue
  for segment in beam_segments(job):
   var direction:Vector2=(segment.end-segment.source).normalized()
   if job.age<job.warning:
    draw_line(segment.source.round(),segment.end.round(),Color("e5ca86"),1)
    var at:Vector2=segment.source.lerp(segment.end,.7)
    var tangent:Vector2=direction.orthogonal()*(-1 if job.phase==2 else 1)
    draw_line(at,at+tangent*20,Color("ebd28e"),2);draw_line(at+tangent*20,at+tangent*14-direction*5,Color("ebd28e"),2)
   else:
    draw_set_transform(segment.source.round(),direction.angle())
    var length:float=segment.source.distance_to(segment.end)
    var x:float=0
    while x<length:
     var width:float=minf(32,length-x)
     draw_texture_rect_region(beam_texture,Rect2(x,-float(config.beam_width)*.5,width,float(config.beam_width)),Rect2(int(job.age*18)%6*32,0,width,16));x+=width
    draw_set_transform(Vector2.ZERO)
 for job in jobs:
  if job.kind in ["crystals","totems"]:
   for target in job.targets:
    if job.kind=="totems":
     var angle:float=target.index*TAU/int(config.totem_count)
     var color:Color=Color("80c99e") if target.destroyed else Color("dca56b")
     for side in [-1,1]:draw_line(job.at+Vector2.from_angle(angle+side*PI/4)*45,job.at+Vector2.from_angle(angle+side*PI/4)*220,color,1)
    if target.destroyed:continue
    if job.age<job.warning:
     draw_rect(Rect2(target.at-Vector2(13,8),Vector2(26,16)),Color("96cce8"),false,1)
    else:
     var ratio:float=clampf((job.age-job.warning)/float(config.totem_charge if job.kind=="totems" else config.crystal_charge),0,1)
     draw_rect(Rect2(target.at-Vector2(12,-5),Vector2(24*ratio,2)),Color("9ed9ef"))
 for job in jobs:
  if job.kind=="orbs":
   for orb in job.orbs:
    draw_texture_rect_region(orb_texture,Rect2(orb.at-Vector2(16,24),Vector2(32,38)),Rect2(mini(2,int(job.age*2))*40,0,40,48))
    if job.age<job.warning:
     var direction:Vector2=(orb.locked_target-orb.at).normalized()
     draw_line(orb.at.round(),(orb.at+direction*90).round(),Color("b9d4de"),1)
 for mark in marks:
  if mark.kind!="spear":continue
  var active:bool=mark.age>=mark.warning
  for i in 20:
   var at:Vector2=mark.at+Vector2((i-9.5)*32,0)
   if not game.arena.safe_position(at,mark.width*.5):continue
   if active:draw_texture_rect_region(beam_texture,Rect2(at-Vector2(16,mark.width*.5),Vector2(32,mark.width)),Rect2(int(mark.age*20)%6*32,0,32,16))
   else:draw_rect(Rect2(at-Vector2(16,mark.width*.5),Vector2(32,mark.width)),Color("c6b583"),false,1)
 for job in jobs:
  if job.age<job.warning:
   for lane in job.lanes:draw_line(lane.source.round(),lane.end.round(),Color("9b9569"),1)
   for i in 16:
    var at:Vector2=job.at+Vector2.from_angle(i*TAU/16+job.age)*22
    draw_rect(Rect2(at.round()-Vector2.ONE,Vector2(2,2)),Color("e7c682"))
 for job in jobs:
  if job.kind=="rings":
   var gap:float=job.gap+job.step*.9
   var opening:float=deg_to_rad(float(config.ring_gap_degrees))
   for angle in [gap-opening*.5,gap+opening*.5]:draw_line(job.at+Vector2.from_angle(angle)*24,job.at+Vector2.from_angle(angle)*110,Color("c5ad6b"),1)
 for shot in shots:
  draw_set_transform(shot.at.round(),shot.velocity.angle())
  draw_texture_rect_region(orb_texture,Rect2(-5,-5,10,10),Rect2((int(shot.age*12)%3)*40,0,40,48))
  draw_set_transform(Vector2.ZERO)
 for fx in impacts:
  if fx.has("kind"):
   var texture:Texture2D=load("res://assets/v12/"+fx.kind+".png")
   draw_texture_rect_region(texture,Rect2(fx.at-Vector2(20,44),Vector2(40,48)),Rect2(120,0,40,48),Color(1,1,1,1-fx.age/.25))
  var radius:float=3+fx.age*25
  for i in 4:
   var at:Vector2=fx.at+Vector2.from_angle(i*PI/2)*radius
   draw_rect(Rect2(at.round(),Vector2(2,2)),Color("aed7ec"))
