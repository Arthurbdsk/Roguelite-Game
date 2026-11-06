extends SceneTree
var errors:int=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 if not ok:errors+=1;printerr("FAIL "+label)
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.test_mode=true;g.sound.volume=0;g.start_run()
 check(g.weapon_system.levels=={"bolt":1},"new run starts with bow only")
 check(g.weapon_system.weapon_data.has("sword"),"sword remains available")
 var audit:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance16_audit.json"))
 for i in 8:check(is_equal_approx(g.weapon_system.weapon_data.bolt.damage[i],float(audit.global_20_percent.bolt.after[i])),"bow exact compounded increase level "+str(i+1))
 var e=g.spawn_enemy("ghoul",g.player.position+Vector2(60,0));var hp:float=e.hp
 g.weapon_system._fire_bolts()
 for i in 60:g.weapon_system._update_projectiles(1.0/60)
 check(e.hp<hp,"initial bow hits basic enemy without permanent upgrades")
 if e.alive:
  g.rebuild_grid();g.weapon_system._fire_bolts()
  for i in 60:g.weapon_system._update_projectiles(1.0/60)
 check(not e.alive,"starting bow kills basic enemy with no second weapon")
 g.elapsed=600;g.horde_progress.tick();check(g.horde_progress.resistance()==0,"no timed resistance for living or new enemies")
 var living=g.spawn_enemy("ghoul",g.player.position+Vector2(100,0))
 check(is_equal_approx(living.received_damage(100),100),"no residual reduction")
 check(g.balance.continuous_per_minute==60,"base generation raised from 48 to 60 only once")
 g.queue_free();await process_frame;await create_timer(.3).timeout;print("EXPANSION16_%s"%("PASS" if errors==0 else "FAIL"));quit(int(errors>0))
