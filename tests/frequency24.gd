extends SceneTree
var failures:int=0
var checks:int=0
var rows:Array=[]
const STEP:float=1.0/60
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL "+label)
func record(id:String,level:int,bonus:bool,expected:float,samples:Array,kind:String):
 check(samples.size()>=2,"enough samples "+id)
 for sample in samples:check(sample+0.00001>=expected and sample<=expected+STEP+.00001,"interval %s %.5f expected %.5f"%[id,sample,expected])
 rows.append({"weapon":id,"level":level,"bonus":bonus,"configured":expected,"kind":kind,"intervals":samples})
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.start_run()
 var w=g.weapon_system
 for id in w.weapon_data:
  for level in [1,8]:
   for bonus in [false,true]:
    g.clear_run();g.state="running";g.player.position=Vector2(900,630)
    g.profile.data.upgrade_ranks={"cooldown":5} if bonus else {};g.mastery.begin(bonus)
    w.reset();w.levels={id:level};w.passives={"cadence":8} if bonus else {};w.timers[id]=.1
    var expected:float=w._interval(id);var samples:Array=[];var last:float=-1
    var e=g.spawn_enemy("guard",Vector2(940,630));e.hp=100000000;e.max_hp=e.hp;g.rebuild_grid()
    # Continuous weapons have their own contact or creation clocks.
    if id=="sludge":expected=w.weapon_data.sludge.tick_interval;w.ground.add_pool(id,e.position,e.position)
    for i in 1800:
     var elapsed:float=(i+1)*STEP;var before:float=float(w.timers.get(id,0));var hp:float=e.hp
     if id=="garlic":e.position=g.player.position+Vector2(10,0)
     if id=="orbit":e.position=g.player.position+Vector2.from_angle(w.orbit_phase+(2+.18*level)*STEP)*w._stat(id,"reach")
     if id=="sludge" and w.ground.pools.is_empty():w.ground.add_pool(id,e.position,e.position)
     g.rebuild_grid();w.update_combat(STEP)
     var activated:bool=e.hp<hp if id in ["garlic","orbit","sludge"] else float(w.timers.get(id,0))>before and float(w.timers[id])>.081
     if activated:
      if last>=0:samples.append(elapsed-last)
      last=elapsed
    record(id,level,bonus,expected,samples,"damage tick" if id in ["garlic","orbit","sludge"] else "activation")
    var original:float=w._interval(id)
    for repeat in 3:
     g.mastery.begin(bonus);w.reset();w.levels={id:level};w.passives={"cadence":8} if bonus else {}
     check(is_equal_approx(w._interval(id),original),"rebuild/reset cannot accumulate "+id)
 check(rows.size()==64,"all sixteen weapons, levels 1/8, with/without bonuses")
 var f=FileAccess.open("res://build/audit24/frequency.json",FileAccess.WRITE);f.store_string(JSON.stringify(rows,"  "));f.close()
 g.clear_run();g.queue_free();await process_frame;await create_timer(.2).timeout
 print("FREQUENCY24_%s checks=%d failures=%d combinations=%d"%["PASS" if failures==0 else "FAIL",checks,failures,rows.size()]);quit(int(failures>0))
