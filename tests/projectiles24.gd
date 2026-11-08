extends SceneTree
class Accepted extends RoomConnection:
 var latest:Dictionary={}
 func send_message(packet:Dictionary)->bool:
  if packet.type=="delta":latest=packet.data.duplicate(true)
  return true
var g
var checks:int=0
var failures:int=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL "+label)
func target(at:Vector2):
 var e=g.spawn_enemy("ghoul",at);e.position=at;e.motion_start=at;e.hp=10000;e.max_hp=e.hp;return e
func shot(start:Vector2,velocity:Vector2,pierce:int=1,bounce:int=0)->Dictionary:
 return {"id":100,"age":0.0,"life":2.0,"position":start,"velocity":velocity,"distance":0.0,"reach":500.0,"damage":10.0,"pierce":pierce,"bounce":bounce,"hits":[]}
func clear():
 g.clear_run();g.state="running";g.player.position=Vector2(900,630);g.mastery.begin(false)
func run():
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.start_run();g.mastery.begin(false)
 var w=g.weapon_system
 var e=target(Vector2(950,730));g.rebuild_grid();w.projectiles.append(shot(Vector2(900,730),Vector2(1000,0)));w._update_projectiles(.1)
 check(e.hp==9990 and w.projectiles.is_empty(),"first valid hit consumes normal arrow immediately")
 clear();var far=target(Vector2(1010,730));var near=target(Vector2(950,730));g.rebuild_grid();w.projectiles.append(shot(Vector2(900,730),Vector2(1000,0),2));w._update_projectiles(.15)
 check(near.hp==9990 and far.hp==9990 and w.projectiles.is_empty(),"piercing hits once per enemy and removes at limit")
 clear();e=target(Vector2(950,730));g.rebuild_grid();w.projectiles.append(shot(e.position,Vector2(1,0),3));w._update_projectiles(.01);w._update_projectiles(.01)
 check(e.hp==9990 and w.projectiles[0].pierce==2,"same target cannot consume twice")
 clear();e=target(Vector2(950,730));var next=target(Vector2(1050,730));g.rebuild_grid();w.projectiles.append(shot(Vector2(900,730),Vector2(100,0),1,1));w.projectiles[0].age=1.4;w.projectiles[0].life=2
 w._update_projectiles(.5)
 check(w.projectiles.size()==1 and w.projectiles[0].age==0 and w.projectiles[0].life>1,"ricochet refreshes visual flight deadline")
 w._update_projectiles(.5);check(next.hp==9990 and w.projectiles.is_empty(),"ricochet terminates after final permitted hit")
 clear();w.projectiles.append(shot(Vector2(900,730),Vector2(1000,0)));w.projectiles[0].reach=12;w._update_projectiles(.1);check(w.projectiles.is_empty(),"range exhaustion removes arrow")
 clear();e=target(Vector2(1100,730));g.arena.add_obstacle(Rect2(1030,710,10,40));g.rebuild_grid();w.projectiles.append(shot(Vector2(900,730),Vector2(4000,0)));w._update_projectiles(.1)
 check(w.projectiles.is_empty() and e.hp==10000,"swept wall blocks enemy behind it")
 clear();w.levels={"fire_wand":1};w.additions.projectile("fire_wand",Vector2.RIGHT);var serial:int=w.additions.shots[0].id;w.additions.impact("fire_wand",g.player.position);var impact_serial:int=w.additions.impact_serial;w.reset();w.levels={"fire_wand":1};w.additions.projectile("fire_wand",Vector2.RIGHT);w.additions.impact("fire_wand",g.player.position)
 check(w.additions.shots[0].id>serial and w.additions.impact_serial>impact_serial,"reset does not reuse projectile/effect IDs")
 clear();w.projectiles.append(shot(Vector2(900,730),Vector2.ZERO));w._update_projectiles(3)
 check(w.projectiles.is_empty(),"stationary arrow cannot survive its flight lifetime")
 # Exercise actual snapshots and client prediction without giving clients damage authority.
 clear();g.coop.connection.queue_free();g.coop.connection=Accepted.new();g.coop.add_child(g.coop.connection);g.coop.connection.peer_id="a";g.coop.connection.host_id="a";g.coop.hosting=true
 g.coop.begin({"run":"projectiles24","map":"fields","players":[{"id":"a","name":"A","skills":{}},{"id":"b","name":"B","skills":{}}]})
 w=g.coop.actors.a.weapon_system;w.projectiles.append(shot(Vector2(900,730),Vector2(100,0)));g.enemy_projectiles.fire(Vector2(900,730),Vector2.RIGHT,g.enemy_data.skeleton_archer);g.enemy_projectiles.arrows[0].life=.05
 g.specials.magic(Vector2(900,730),Vector2.RIGHT,10);g.specials.bolts[0].life=.05
 g.coop.broadcast_state(true);var first:Dictionary=g.coop.connection.latest.duplicate(true)
 w.projectiles.clear();g.enemy_projectiles.arrows.clear();g.specials.bolts.clear();g.coop.broadcast_state(true);var removed:Dictionary=g.coop.connection.latest.duplicate(true)
 g.coop.hosting=false;g.coop.apply_delta(first,true);check(w.projectiles.size()==1,"snapshot creates arrow replica")
 g.coop.client_tick(.1,{"movement":Vector2.ZERO,"revive":false});check(g.enemy_projectiles.arrows.is_empty() and g.specials.bolts.is_empty(),"hostile replicas expire without next snapshot")
 g.coop.apply_delta(removed,true);check(w.projectiles.is_empty(),"host removal replaces replicas")
 g.coop.apply_delta(first,true);check(w.projectiles.is_empty(),"late snapshot cannot resurrect removed projectile")
 w.projectiles.append(shot(Vector2(900,730),Vector2(100,0)));w.projectiles[0].life=.05;g.coop.client_tick(.1,{"movement":Vector2.ZERO,"revive":false});check(w.projectiles.is_empty(),"allied replica expires without next snapshot")
 g.coop.leave();g.clear_run();g.queue_free();await process_frame;await create_timer(.2).timeout
 print("PROJECTILES24_%s checks=%d failures=%d"%["PASS" if failures==0 else "FAIL",checks,failures]);quit(int(failures>0))
