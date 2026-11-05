extends Node2D
var game
var rng:=RandomNumberGenerator.new()
var config:Dictionary={"start":180.0,"check_seconds":60.0,"siege_chance":.15,"king_chance":.10,"cooldown":180.0,"siege_count":20,"siege_radius":420.0,"siege_duration":45.0,"king_health":8.0,"entity_limit":420}
var active:String=""
var next_check:float=180
var last_event:float=-1000
var age:float=0
var members:Array=[]
var owners:Array=[]
var pending:Array[Dictionary]=[]
var retiring:Array[Dictionary]=[]
var death_fx:Array[Dictionary]=[]
var attempts:int=0
var deferred:int=0
var remote_pending:int=0
func setup(owner_game):game=owner_game;config=game.survival_config.events.duplicate(true);rng.randomize();z_index=1
func reset():active="";next_check=180;last_event=-1000;age=0;members.clear();owners.clear();pending.clear();retiring.clear();death_fx.clear();attempts=0;deferred=0
func blocked()->bool:
 return game.state!="running" or game.enemies.any(func(e):return e is HordeBoss and e.alive) or game.boss_arena.stage=="portal" or game.campaign.deciding
func start(kind:String)->bool:
 if active!="" or blocked():return false
 var players:Array=game.team_players()
 if players.is_empty():return false
 var target=players[rng.randi_range(0,players.size()-1)]
 if kind=="siege":
  var points:Array=[]
  for i in int(config.siege_count):
   var found:bool=false
   for attempt in 100:
    var at:Vector2=target.position+Vector2.from_angle(i*TAU/int(config.siege_count)+attempt*.12)*(float(config.siege_radius)+attempt%5*20)
    if not game.enemy_space_free(at,8) or game.players_near(at,65) or not game.navigation.reachable(at,8):continue
    if points.any(func(p):return p.distance_to(at)<22):continue
    points.append(at);found=true;break
   if not found:deferred+=1;return false
  if game.enemies.size()+points.size()>int(config.entity_limit):deferred+=1;return false
  for i in points.size():
   var e=game.spawn_enemy("siege_archer",points[i]);e.event_kind="siege";e.attack_time=2+i*.17
   members.append(weakref(e));owners.append(e.get_instance_id())
 elif kind=="king":
  var at:Vector2=game.free_enemy_position(target.position+Vector2(390,0),34)
  if at==Vector2.INF or game.players_near(at,90):return false
  var e=game.spawn_enemy("slime_king",at)
  if e==null:return false
  members.append(weakref(e))
 else:return false
 active=kind;age=0;last_event=game.elapsed;return true
func on_death(enemy)->bool:
 if enemy.data.id not in ["slime_king","event_blue","event_small"]:return false
 if enemy.data.id!="event_small":pending.append({"at":enemy.position,"kind":"event_blue" if enemy.data.id=="slime_king" else "event_small","left":15,"age":0.0})
 var xp:float=float(config.king_xp) if enemy.data.id=="slime_king" else float(config.blue_xp) if enemy.data.id=="event_blue" else float(config.small_xp)
 var gold:int=int(config.king_gold) if enemy.data.id=="slime_king" else int(config.blue_gold) if enemy.data.id=="event_blue" else 0
 if gold>0:game.gold_loot.drop(enemy.position,gold)
 game.drop_xp(enemy.position,xp*game.balance.death_experience_multiplier)
 if enemy.data.id=="slime_king":death_fx.append({"at":enemy.position,"age":0.0})
 return true
func tick(delta:float):
 if game.state!="running":return
 for fx in death_fx:fx.age+=delta
 death_fx=death_fx.filter(func(f):return f.age<.65)
 for r in retiring.duplicate():
  r.age+=delta
  var e=r.ref.get_ref()
  if is_instance_valid(e):e.sprite.modulate.a=1-r.age/.35
  if r.age>=.35:
   if is_instance_valid(e):game.despawn_enemy(e)
   retiring.erase(r)
 if active!="":
  age+=delta
  if active=="siege" and age>=float(config.siege_duration):
   for owner in owners:game.enemy_projectiles.remove_owner(owner)
   for ref in members:
    var e=ref.get_ref()
    if is_instance_valid(e) and e.alive:e.alive=false;e.targetable=false;e.collision_layer=0;retiring.append({"ref":ref,"age":0.0})
   members.clear();owners.clear();active="";last_event=game.elapsed
  for batch in pending.duplicate():
   batch.age+=delta
   if batch.age<.65:continue
   var budget:int=15
   while batch.left>0 and budget>0:
    if game.enemies.size()>=int(config.entity_limit):deferred+=1;break
    var slot:int=15-int(batch.left)
    var spacing:float=24.0 if batch.kind=="event_blue" else 6.5
    var desired:Vector2=batch.at+Vector2.from_angle(slot*2.39996323)*sqrt(slot+.5)*spacing
    var at:Vector2=game.free_enemy_position(desired,17 if batch.kind=="event_blue" else 4)
    if at==Vector2.INF:deferred+=1;break
    var e=game.spawn_enemy(batch.kind,at)
    if e==null:deferred+=1;break
    e.grace=.5;members.append(weakref(e));batch.left-=1;budget-=1
   if batch.left==0:pending.erase(batch)
  members=members.filter(func(ref):var e=ref.get_ref();return is_instance_valid(e) and e.alive)
  if active=="king" and members.is_empty() and pending.is_empty():active="";last_event=game.elapsed
 if game.elapsed>=next_check:
  next_check=(floorf(game.elapsed/float(config.check_seconds))+1)*float(config.check_seconds)
  if game.elapsed>=float(config.start) and active=="" and game.elapsed-last_event>=float(config.cooldown) and not blocked():
   attempts+=1;var roll:float=rng.randf()
   if roll<float(config.siege_chance):start("siege")
   elif roll<float(config.siege_chance)+float(config.king_chance):start("king")
 queue_redraw()
func _draw():
 for fx in death_fx:draw_texture_rect_region(preload("res://assets/v13/slime_king.png"),Rect2(fx.at-Vector2(36,66),Vector2(72,72)),Rect2((4+mini(3,int(fx.age/.65*4)))*72,0,72,72))

func stop():
 for owner in owners:game.enemy_projectiles.remove_owner(owner)
 for ref in members:
  var e=ref.get_ref()
  if is_instance_valid(e):game.despawn_enemy(e)
 for item in retiring:
  var e=item.ref.get_ref()
  if is_instance_valid(e):game.despawn_enemy(e)
 reset()
