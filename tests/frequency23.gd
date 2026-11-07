extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.start_run();g.mastery.begin(false)
 var w=g.weapon_system
 var rows:Array=[]
 for id in w.weapon_data:
  for level in [1,8]:
   for bonus in [false,true]:
    g.profile.data.upgrade_ranks={"cooldown":5} if bonus else {};g.mastery.begin(bonus)
    w.reset();w.levels={id:level};w.passives={"cadence":8} if bonus else {};w.timers[id]=.1
    var expected:float=w._interval(id)
    var samples:Array=[];var last:float=-1;var elapsed:float=0
    var e=g.spawn_enemy("guard",Vector2(940,630));e.hp=100000000
    for i in 1800:
     var previous:float=float(w.timers.get(id,0));w.update_combat(1.0/60);elapsed+=1.0/60
     var current:float=float(w.timers.get(id,0))
     if current>previous and current>.081:
      if last>=0:samples.append(elapsed-last)
      last=elapsed
    rows.append({"weapon":id,"level":level,"bonus":bonus,"configured":expected,"intervals":samples})
    g.clear_run();g.state="running"
 var f=FileAccess.open("res://build/fixes23/frequency-after.json",FileAccess.WRITE);f.store_string(JSON.stringify(rows,"  "));f.close()
 print("FREQUENCY23_PASS measured all configured weapons, levels 1/8, cadence 0/8");g.queue_free();await process_frame;quit()
