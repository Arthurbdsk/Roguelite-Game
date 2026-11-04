extends SceneTree
class BotProxy extends RefCounted:
 var serial:int=-10
 var radius:float=7
 var position:Vector2
var proxy:=BotProxy.new()
var g
var recorded:bool=false
func _initialize():call_deferred("run")
func movement()->Vector2:
 var target:Vector2=g.player.position;var nearest:float=INF
 for xp in g.pickups:
  var d:float=g.player.position.distance_squared_to(xp.at)
  if d<nearest:target=xp.at;nearest=d
 if nearest==INF:
  var enemy=g.nearest_enemy(g.player.position,1500)
  if enemy!=null:target=enemy.position
 proxy.position=g.player.position
 return g.navigation.steer(proxy,(target-proxy.position).normalized()*96,target).normalized()
func choose():
 var selected:Dictionary=g.offers[0];var best:int=-999
 for offer in g.offers:
  var score:int=0
  if offer.id=="crown":score=100
  elif offer.id in ["sword","bolt","lightning","orbit","holy_water","clock"]:score=80+int(g.weapon_system.levels.get(offer.id,0))
  elif offer.id in ["boots","heart","ward"]:score=40
  if score>best:best=score;selected=offer
 g.choose_upgrade(selected.id)
func run():
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.sound.volume=0;g.start_run();g.director.rng.seed=35117;g.weapon_system.rng.seed=2813
 var before:Dictionary=g.profile.data.duplicate(true);var steps:int=0;var peak:int=0;var report:int=0;var start:int=Time.get_ticks_msec()
 while steps<144000 and g.state in ["running","upgrading"]:
  while g.state=="upgrading":choose()
  g.player.invulnerable=10000;g.player.hp=g.player.max_hp;g.player.clear_status()
  g.simulate(1.0/60,movement());steps+=1;peak=maxi(peak,g.enemies.size())
  if g.elapsed>=900 and not recorded:
   recorded=true;print("BUILD15 level=",g.level," weapons=",g.weapon_system.levels," passives=",g.weapon_system.passives," stats=",g.weapon_system.build_stats().replace("\n","; "))
  if int(g.elapsed/120)>report:
   report=int(g.elapsed/120);print("CAMPAIGN_PROGRESS seconds=",int(g.elapsed)," foes=",g.enemies.size()," kills=",g.kills," level=",g.level," completed=",g.campaign.completed)
  if steps%30==0:await process_frame
 assert(g.state=="result" and g.campaign.completed.has("horror"))
 assert(g.campaign.history==["demon","guardian","horror"])
 assert(g.profile.data==before and recorded)
 for id in g.weapon_system.levels:assert(g.weapon_system.levels[id]<=8)
 for id in g.weapon_system.passives:assert(g.weapon_system.passives[id]<=8)
 print("FULL_CAMPAIGN10_PASS elapsed=",g.elapsed," level=",g.level," kills=",g.kills," gold=",g.gold," peak=",peak," wall_ms=",Time.get_ticks_msec()-start," invulnerable accelerated systems traversal; not human balance/FPS")
 g.queue_free();await process_frame;await create_timer(.3).timeout;quit()
