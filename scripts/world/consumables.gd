class_name ImmediateConsumables
extends Node2D
var game
var config:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/consumables.json"))
var items:Array=[]
var rng:=RandomNumberGenerator.new()
var serial:int=0
var next_check:float=60
var last_spawn:float=-1000
var attempts:int=0
var generated:int=0
var freeze_left:float=0
var magnet_jobs:Array=[]
var magnet_cursor:int=0
var magnet_visual:Array=[]
var feedback:Array=[]
var textures:Dictionary={}
var toast:Label
var toast_left:float=0
var magnet_batch_us:int=0
var magnet_credited:float=0
func setup(owner):
 game=owner;rng.randomize();z_index=4
 for d in config.items:textures[d.id]=load("res://assets/v15/"+d.id+".png")
 var layer:=CanvasLayer.new();layer.layer=24;add_child(layer)
 toast=Label.new();toast.position=Vector2(160,274);toast.size=Vector2(320,40);toast.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;toast.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;toast.mouse_filter=Control.MOUSE_FILTER_IGNORE;toast.add_theme_font_override("font",GameFonts.interface_font());toast.add_theme_font_size_override("font_size",11);layer.add_child(toast);toast.hide()
func reset():
 magnet_visual.clear();magnet_cursor=0
 magnet_credited=0
 items.clear();magnet_jobs.clear();feedback.clear();freeze_left=0;next_check=config.first;last_spawn=-1000;attempts=0;generated=0;toast_left=0
 if is_instance_valid(toast):toast.hide()
 queue_redraw()
func spawn_item(kind:String,at:Vector2=Vector2.INF)->bool:
 if game.coop.active and not game.coop.hosting:return false
 if not textures.has(kind) or items.size()>=int(config.limit):return false
 if at==Vector2.INF:
  var players:Array=game.team_players()
  if players.is_empty():return false
  var target=players[generated%players.size()]
  for i in 100:
   var candidate:Vector2=target.position+Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(70,210)
   if game.arena.safe_position(candidate,10) and not game.players_near(candidate,40) and game.navigation.reachable(candidate,10):at=candidate;break
 if at==Vector2.INF or not game.arena.safe_position(at,8):return false
 serial+=1;generated+=1;last_spawn=game.elapsed;items.append({"id":serial,"kind":kind,"at":at,"age":0.0});queue_redraw();return true
func tick(delta:float):
 if game.state!="running":return
 visual_tick(delta)
 freeze_left=maxf(0,freeze_left-delta)
 tick_magnet(delta)
 for item in items.duplicate():
  item.age+=delta
  if item.age>=float(config.lifetime):items.erase(item);continue
  for player in game.team_players():
   if not player.down and player.position.distance_squared_to(item.at)<=pow(float(config.collect_radius),2):
    if collect(item,player):break
 if game.elapsed>=next_check:
  next_check=(floorf(game.elapsed/float(config.interval))+1)*float(config.interval)
  if freeze_left<=0 and items.size()<int(config.limit) and game.elapsed-last_spawn>=float(config.cooldown):
   attempts+=1
   if rng.randf()<chance():spawn_item(roll_kind())
func chance()->float:
 var ranks:float=game.mastery.rank("luck")
 if game.coop.active:
  ranks=0
  for actor in game.coop.actors.values():ranks+=actor.mastery.rank("luck")
  ranks/=maxi(1,game.coop.actors.size())
 return float(config.chance)+float(config.luck_per_rank)*ranks
func roll_kind()->String:
 var roll:float=rng.randf()*100
 for d in config.items:
  roll-=float(d.weight)
  if roll<0:return d.id
 return "food"
func collect(item:Dictionary,player)->bool:
 if not items.has(item) or player.down or game.coop.active and not game.coop.hosting:return false
 var amount:float=0
 if item.kind=="food":
  if player.hp>=player.max_hp:return false
  amount=minf(30,player.max_hp-player.hp)
  items.erase(item);player.hp+=amount
 elif item.kind=="gold_bag":
  items.erase(item);amount=100;game.gold+=100
  if game.coop.active:
   var before:int=player.game.mastery.gold_bonus
   game.coop.on_gold(100);amount+=player.game.mastery.gold_bonus-before
  else:
   var before:int=game.mastery.gold_bonus
   game.mastery.on_gold(100);game.gold+=game.mastery.gold_bonus-before;amount+=game.mastery.gold_bonus-before
 elif item.kind=="xp_magnet":
  items.erase(item)
  magnet_jobs.append_array(game.pickups)
  game.pickups.clear()
 elif item.kind=="stopwatch":
  items.erase(item);freeze_left=10
  for enemy in game.enemies:
   if enemy is HordeBoss:enemy.apply_time_control(10,0,.3,3)
 elif item.kind=="cleanse":
  items.erase(item)
  cleanse(player)
 else:return false
 emit_feedback(item,player,amount)
 return true
func region(player)->Rect2:
 var size_px:Vector2=Vector2(game.get_viewport_rect().size)/game.camera.zoom
 var center:Vector2=player.position.clamp(size_px*.5,Vector2(1800,1200)-size_px*.5)
 return Rect2(center-size_px*.5,size_px)
func cleanse(player):
 var area:Rect2=region(player)
 for enemy in game.enemies.duplicate():
  if not is_instance_valid(enemy) or not enemy.alive or enemy is HordeBoss or enemy.data.behavior in ["boss","hazard_target"] or not area.has_point(enemy.position):continue
  enemy.suppress_split=true;enemy.alive=false
  game.enemy_killed(enemy);enemy.queue_free()
 game.enemy_projectiles.arrows=game.enemy_projectiles.arrows.filter(func(p):return not area.has_point(p.at))
 game.specials.bolts=game.specials.bolts.filter(func(p):return not area.has_point(p.at))
 game.late_arena.shots=game.late_arena.shots.filter(func(p):return not area.has_point(p.at))
 game.late_arena.patterns.shots=game.late_arena.patterns.shots.filter(func(p):return not area.has_point(p.at))
func paused_projectile(projectile:Dictionary)->bool:
 if freeze_left<=0:return false
 var owner:int=int(projectile.get("owner",0))
 var e=game.boss
 if is_instance_valid(e) and e is HordeBoss and (e.get_instance_id()==owner or e.serial==owner):return false
 return true
func emit_feedback(item:Dictionary,player,amount:float=0):
 var collector:String=player.game.id if game.coop.active else ""
 var event:Dictionary={"type":"consumable_feedback","kind":item.kind,"at":player.position,"amount":amount,"collector":collector}
 if item.kind=="cleanse":event.area_at=region(player).position;event.area_size=region(player).size
 show_feedback(event)
 if game.coop.active:game.coop.publish(event)
func show_feedback(event:Dictionary):
 feedback.append({"kind":event.kind,"at":event.at,"life":.6,"area_at":CoopWire.vector(event.get("area_at",Vector2.ZERO)),"area_size":CoopWire.vector(event.get("area_size",Vector2.ZERO))})
 if feedback.size()>8:feedback.pop_front()
 if not game.coop.active or event.collector==game.coop.connection.peer_id:
  game.record_discovery("consumable:"+str(event.kind))
  var names={"food":"+%s de vida"%str(event.amount),"gold_bag":"+%s de ouro"%str(event.amount),"xp_magnet":"Experiência atraída","stopwatch":"Tempo parado: 10 s","cleanse":"Área limpa"}
  toast.text=names.get(event.kind,event.kind);toast_left=2;toast.show();game.sound.play_cue("gold" if event.kind=="gold_bag" else "pickup")
 queue_redraw()
func visual_tick(delta:float):
 toast_left=maxf(0,toast_left-delta)
 if toast_left==0:toast.hide()
 if freeze_left>0 and toast_left==0:
  toast.text="Tempo parado: %.1f s"%freeze_left;toast.show()
 for fx in feedback:fx.life-=delta
 feedback=feedback.filter(func(f):return f.life>0)
 queue_redraw()
func tick_magnet(delta:float):
 var started:int=Time.get_ticks_usec() if game.perf_enabled else 0
 var total:float=0
 var budget:int=mini(int(config.magnet_batch),magnet_jobs.size())
 for i in budget:
  if magnet_jobs.is_empty():break
  magnet_cursor=magnet_cursor%magnet_jobs.size()
  var gem:Dictionary=magnet_jobs[magnet_cursor]
  var target=game.collection_player(gem.at)
  if target==null:break
  gem.at=Vector2(gem.at).move_toward(target.position,delta*440)
  if Vector2(gem.at).distance_squared_to(target.position)<=100:
   total+=float(gem.xp);magnet_jobs[magnet_cursor]=magnet_jobs.back();magnet_jobs.pop_back()
  else:magnet_cursor+=1
 if total>0:magnet_credited+=total;game.add_xp(total)
 if game.perf_enabled:magnet_batch_us=Time.get_ticks_usec()-started
func _draw():
 if game==null or game.state not in ["running","upgrading","paused"]:return
 var bounds:Rect2=game.render_rect().grow(25)
 for item in items:
  if not bounds.has_point(item.at):continue
  if item.age>float(config.lifetime)-float(config.warning) and int(item.age*4)%2==0:continue
  draw_rect(Rect2(item.at-Vector2(8,0),Vector2(16,3)),Color(0,0,0,.4))
  draw_texture_rect(textures[item.kind],Rect2(item.at.round()-Vector2(13,21),Vector2(26,26)),false)
 for fx in feedback:
  if fx.kind=="cleanse":
   var area:=Rect2(fx.area_at,fx.area_size)
   draw_rect(area.grow(-int((1-fx.life/.6)*12)),Color(.8,.9,.65,fx.life),false,1)
  var color:Color=Color("b4e5c5") if fx.kind=="food" else Color("e8d083")
  for i in 8:
   var at:Vector2=fx.at+Vector2.from_angle(i*TAU/8)*(1-fx.life/.6)*24
   draw_rect(Rect2(at.round(),Vector2(2,2)),color)
 var gems:Array=magnet_visual if game.coop.active and not game.coop.hosting else magnet_jobs
 for i in mini(48,gems.size()):
  var gem:Dictionary=gems[i]
  if bounds.has_point(gem.at):draw_texture_rect(game.experience_texture,Rect2(Vector2(gem.at)-Vector2(4,8),Vector2(8,12)),false)
