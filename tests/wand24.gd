extends SceneTree
var checks:int=0
var failures:int=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL "+label)
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.start_run()
 var w=g.weapon_system
 var far=g.spawn_enemy("guard",Vector2(1100,730));far.hp=100000
 var near=g.spawn_enemy("guard",Vector2(900,700));near.hp=100000
 g.player.position=Vector2(900,730);g.rebuild_grid()
 for level in range(1,9):
  for bonus in [false,true]:
   g.profile.data.upgrade_ranks={"cooldown":5} if bonus else {};g.mastery.begin(bonus);w.reset();w.levels={"magic_wand":level};w.passives={"cadence":8} if bonus else {}
   var base:float=2.0 if level<=2 else 1.85
   check(is_equal_approx(w._interval("magic_wand"),base*(.468 if bonus else 1)),"base +1 exactly once before bonuses level %d"%level)
   var count:int=int(w._stat("magic_wand","count"));w.additions.launch("magic_wand")
   var serial:int=w.additions.shot_serial;var fired:Array=[]
   for i in 120:
    w.combat_time+=.01;w.additions.tick(.01,true)
    if w.additions.shot_serial>serial:
     fired.append((i+1)*.01);serial=w.additions.shot_serial
     var s=w.additions.shots.back();check(Vector2(s.velocity).normalized().dot((near.position-g.player.position).normalized())>.999,"nearest target retained")
   check(fired.size()==count,"all burst projectiles fire level %d"%level)
   for i in range(1,fired.size()):check(absf(fired[i]-fired[i-1]-.12)<.01001,"burst interval remains 120 ms independently of cooldown")
 g.clear_run();g.queue_free();await process_frame;await create_timer(.2).timeout
 print("WAND24_%s checks=%d failures=%d"%["PASS" if failures==0 else "FAIL",checks,failures]);quit(int(failures>0))
