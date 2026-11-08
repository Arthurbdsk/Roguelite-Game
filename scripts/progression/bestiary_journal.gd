class_name BestiaryJournal
extends RefCounted
var game
var run:String=""
var totals:Dictionary={}
var applied:Dictionary={}
var observe_clock:float=0
var save_clock:float=0
func setup(owner):game=owner
func begin(id:String):
 flush();run=id;totals.clear();applied.clear();observe_clock=0;save_clock=0
func allowed()->bool:
 return game!=null and not game.dev_boss_test and not (game.dev_tools!=null and game.dev_tools.active)
func valid_species(id:String)->bool:return game.enemy_data.has(id) and id not in ["boss","ice_crystal","channel_totem"]
func local_owner()->String:return game.coop.connection.peer_id if game.coop!=null and game.coop.active else "solo"
func add(owner:String,id:String,seen:int,kills:int):
 if not valid_species(id):return
 if not totals.has(owner):totals[owner]={}
 if not totals[owner].has(id):totals[owner][id]={"seen":0,"kills":0}
 totals[owner][id].seen+=seen;totals[owner][id].kills+=kills
 if owner==local_owner():receive(run,totals[owner])
func receive(run_id:String,raw:Dictionary):
 if run_id!=run or not allowed():return
 var clean:Dictionary=game.profile.sanitize_bestiary(raw)
 for id in clean:
  if not valid_species(id):continue
  var previous:Dictionary=applied.get(id,{"seen":0,"kills":0})
  var seen:int=maxi(0,int(clean[id].seen)-int(previous.seen));var kills:int=maxi(0,int(clean[id].kills)-int(previous.kills))
  game.profile.add_bestiary(id,seen,kills)
  applied[id]={"seen":maxi(previous.seen,clean[id].seen),"kills":maxi(previous.kills,clean[id].kills)}
func encounter(owner:String,enemy):
 if not valid_species(enemy.data.id):return
 if enemy.bestiary_seen.has(owner):return
 enemy.bestiary_seen[owner]=true;add(owner,enemy.data.id,1,0)
func killed(enemy):
 if not allowed() or (game.coop.active and not game.coop.hosting) or not valid_species(enemy.data.id) or enemy.bestiary_kill_registered:return
 enemy.bestiary_kill_registered=true
 var owner:String=enemy.last_hit_owner
 if game.coop.active:
  if not game.coop.actors.has(owner):return
 elif owner!="solo":return
 # A legitimate lethal hit also proves an encounter, even between observation ticks.
 encounter(owner,enemy);add(owner,enemy.data.id,0,1)
func tick(delta:float):
 if not allowed():return
 save_clock+=delta
 if save_clock>=30:save_clock=0;flush()
 if game.coop.active and not game.coop.hosting:return
 observe_clock-=delta
 if observe_clock>0:return
 observe_clock=.2
 var viewers:Dictionary={}
 if game.coop.active:
  for id in game.coop.actors:viewers[id]=game.coop.actors[id].player.position
 else:viewers.solo=game.player.position
 for owner in viewers:
  var center:Vector2=Vector2(viewers[owner]).clamp(Vector2(320,180),Vector2(1480,1020))
  var view:=Rect2(center-Vector2(320,180),Vector2(640,360))
  for enemy in game.enemies:
   if is_instance_valid(enemy) and enemy.alive and enemy.sprite.visible and view.grow(enemy.radius).has_point(enemy.position):encounter(owner,enemy)
func personal(owner:String)->Dictionary:return {"run":run,"totals":totals.get(owner,{})}
func flush():
 if game!=null and game.persistence_enabled and allowed() and game.profile.bestiary_dirty:game.profile.save()
