extends SceneTree
class Accepted extends RoomConnection:
 func send_message(_packet:Dictionary)->bool:return true
var checks:int=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 assert(ok,label)
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.start_run();g.mastery.begin(false);g.player.dev_invulnerable=true
 var catalog:Array=EnemyCatalog.ids(g);check(catalog.size()==23,"all implemented enemies and variants, excluding attack targets/alias")
 for id in catalog:
  var entry:Dictionary=EnemyCatalog.entry(g,id);var e=g.spawn_enemy(id,Vector2(1050,730))
  check(is_equal_approx(e.max_hp,entry.hp),"catalog matches combat initial HP "+id)
  check(is_equal_approx(e.data.speed,entry.speed),"catalog matches combat movement "+id)
  check(is_equal_approx(e.data.damage_resistance,entry.reduction),"catalog matches reduction "+id)
  for phase in entry.phases.size():
   var variant:Dictionary=EnemyCatalog.entry(g,id,phase);check(variant.hp>0 and variant.speed>=0 and not variant.attacks.is_empty(),"real phase attributes "+id)
   check(EnemyCatalog.preview(g,id,phase).texture!=null,"preview available "+id)
  g.clear_run();g.state="running"
 g.profile.data.bestiary_stats.clear();g.bestiary.begin("solo-test")
 var e=g.spawn_enemy("ghoul",Vector2(1000,630));g.bestiary.tick(.21)
 check(g.profile.bestiary_counts("ghoul").seen==1 and e.hp==e.max_hp,"sighting without damaging")
 for i in 10:g.bestiary.tick(.21)
 check(g.profile.bestiary_counts("ghoul").seen==1,"same appearance counted once")
 g.mastery.hit(e,1e9,Vector2.ZERO);g.enemy_killed(e)
 check(g.profile.bestiary_counts("ghoul").kills==1,"one responsible solo kill")
 var despawn=g.spawn_enemy("ghoul",Vector2(1000,630));g.despawn_enemy(despawn);check(g.profile.bestiary_counts("ghoul").kills==1,"cleanup not a kill")
 g.dev_boss_test=true;e=g.spawn_enemy("guard",Vector2(1000,630));g.mastery.hit(e,1e9,Vector2.ZERO);g.bestiary.tick(.21);check(g.profile.bestiary_counts("guard").kills==0,"DEV excluded");g.dev_boss_test=false
 check(g.profile.bestiary_dirty,"changes buffered")
 var p=GameProfile.new("user://bestiary25-legacy.json");p.data.gold=321;p.data.settings.volume=.31;p.data.erase("bestiary_stats");check(p.save(),"write isolated legacy fixture")
 var loaded=GameProfile.new(p.path);check(loaded.load_profile(),"load v4 without bestiary");check(loaded.data.gold==321 and is_equal_approx(loaded.data.settings.volume,.31) and loaded.data.bestiary_stats.is_empty(),"legacy progress preserved; no invented counts")
 loaded.add_bestiary("ghoul",2,1);check(loaded.save(),"checkpoint writes counters")
 var restored=GameProfile.new(p.path);check(restored.load_profile() and restored.bestiary_counts("ghoul")=={"seen":2,"kills":1},"counter roundtrip")
 g.clear_run();g.coop.connection.queue_free();g.coop.connection=Accepted.new();g.coop.add_child(g.coop.connection);g.coop.connection.peer_id="a";g.coop.connection.host_id="a";g.coop.hosting=true
 g.coop.begin({"run":"journal-network","players":[{"id":"a","name":"A","skills":{}},{"id":"b","name":"B","skills":{}}]});g.mastery.begin(false)
 var remote=g.coop.actors.b;remote.mastery.begin(false)
 e=g.spawn_enemy("skeleton_archer",Vector2(1000,730));g.coop.actors.a.weapon_system._hit(e,1,Vector2.ZERO);remote.weapon_system._hit(e,1e9,Vector2.ZERO)
 check(g.bestiary.totals.b.skeleton_archer.kills==1 and g.profile.bestiary_counts("skeleton_archer").kills==0,"host credits final blow to remote owner")
 g.bestiary.killed(e);check(g.bestiary.totals.b.skeleton_archer.kills==1,"duplicate confirmation ignored")
 remote.weapon_system.levels={"holy_water":1};e=g.spawn_enemy("orc_armored",Vector2(1000,730));e.hp=1;remote.weapon_system.ground.add_pool("holy_water",e.position,e.position);remote.weapon_system.ground.tick(.01)
 check(g.bestiary.totals.b.orc_armored.kills==1,"poison/pool pipeline preserves weapon owner and variant")
 var boss=g.spawn_enemy("demon",Vector2(1150,730));remote.weapon_system._hit(boss,1e9,Vector2.ZERO);check(g.bestiary.totals.b.get("demon",{}).get("kills",0)==0,"transformation not definitive death")
 boss.tick(2);remote.weapon_system._hit(boss,1e9,Vector2.ZERO);check(g.bestiary.totals.b.demon.kills==1,"final boss death counted once")
 var received:Dictionary={"shadow":{"seen":3,"kills":2}};g.bestiary.receive("journal-network",received);g.bestiary.receive("journal-network",received);g.bestiary.receive("old-run",{"shadow":{"seen":30,"kills":20}})
 check(g.profile.bestiary_counts("shadow")=={"seen":3,"kills":2},"cumulative confirmations idempotent; stale run rejected")
 g.bestiary.receive("journal-network",{"shadow":{"seen":2,"kills":1}});check(g.profile.bestiary_counts("shadow").kills==2,"older totals cannot regress counters")
 g.coop.leave();g.clear_run();g.queue_free();await process_frame;await create_timer(.2).timeout
 print("BESTIARY_DATA25_PASS checks=",checks," canonical stats, legacy saves, sightings, owner kills, pools, phases, dedup");quit()
