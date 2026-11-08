extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.start_run();g.mastery.begin(false);g.run_challenge=0
 var rows:Array=[]
 for t in [0,60,120,180,240,299]:
  for id in EarlyBalance.HEALTH:
   g.elapsed=t;g.state="running";g.weapon_system.reset();var e=g.spawn_enemy(id,Vector2(1100,730));var hp:float=e.hp;var hits:int=0
   while e.alive and hits<20:g.weapon_system._hit(e,g.weapon_system._stat("bolt","damage"),Vector2.ZERO);hits+=1
   assert(hits==(3 if id in ["guard","orc_armored","skeleton_armored"] else 2),id+" at "+str(t))
   rows.append({"id":id,"seconds":t,"hp":hp,"hits":hits});g.clear_run()
 var f=FileAccess.open("res://build/early253.json",FileAccess.WRITE);f.store_string(JSON.stringify(rows,"  "));f.close()
 g.queue_free();await process_frame;await create_timer(.2).timeout;print("EARLY253_PASS 42 actual noncritical arrow-hit cases over first five minutes");quit()
