extends SceneTree
var g
var checks:int=0
var failures:int=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL "+label)
func axe(at:Vector2)->Dictionary:
 return {"kind":"axe","at":at,"origin":at,"direction":Vector2.RIGHT,"age":0.0,"flight":.9,"leg":0,"hits":{},"pierce":3,"speed_factor":1.0}
func run():
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.start_run();g.mastery.begin(false)
 var w=g.weapon_system;w.levels={"axe":1};var a=w.arsenal;g.player.position=Vector2(900,730)
 check(w._stat("axe","pierce")==3,"level one has three total targets")
 for level in range(1,9):
  w.levels={"axe":level};check(w._stat("axe","pierce")==[3,3,4,4,5,5,6,7][level-1],"explicit total target progression")
 w.levels={"axe":1}
 var enemies:Array=[]
 # Reverse spawn order exposes consuming pierce in array order rather than flight order.
 for i in range(4,0,-1):
  var e=g.spawn_enemy("guard",Vector2(900+i*15,730-i*7));e.position=Vector2(900+i*15,730-i*7);e.motion_start=e.position;e.hp=10000;enemies.push_front(e)
 g.rebuild_grid();var s=axe(g.player.position);a.shots.append(s);a.advance_shots(.4)
 check(a.shots.is_empty() and s.hits.size()==3,"third distinct target consumes axe")
 check(enemies[0].hp<10000 and enemies[1].hp<10000 and enemies[2].hp<10000 and enemies[3].hp==10000,"nearest swept collisions win")
 g.clear_run();g.state="running";w.levels={"axe":1};s=axe(g.player.position);s.flight=10;s.age=10;s.origin=g.player.position-Vector2(1700,0);s.at=g.player.position;a.shots.append(s);a.advance_shots(.001,false)
 check(a.shots.size()==1,"no short flight lifetime")
 a.shots.clear();s=axe(g.player.position);a.shots.append(s)
 for i in 240:a.advance_shots(1.0/60,false)
 check(a.shots.is_empty(),"client visual axe exits owner view without snapshots")
 check(not a.outside_owner_view(Vector2(1233,730)) and a.outside_owner_view(Vector2(1235,730)),"full rotating sprite clears logical right edge")
 g.player.position=Vector2(320,180);check(a.outside_owner_view(Vector2(900,730)),"bounds follow current owner rather than window")
 g.player.position=Vector2(900,730);a.shots.append(axe(g.player.position));g.clear_run();check(a.shots.is_empty(),"ending clears axes")
 w.levels={"boomerang":1};a.launch("boomerang")
 for i in 240:a.advance_shots(1.0/60,false)
 check(a.shots.is_empty(),"boomerang keeps outbound/return cleanup")
 g.queue_free();await process_frame;await create_timer(.2).timeout
 print("AXE24_%s checks=%d failures=%d"%["PASS" if failures==0 else "FAIL",checks,failures]);quit(int(failures>0))
