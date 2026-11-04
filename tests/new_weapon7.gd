extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.sound.volume=0;g.start_run();g.director.phase="complete";var w=g.weapon_system
 w.levels={"ice_wave":1}
 var e=g.spawn_enemy("ghoul",g.player.position+Vector2(24,0));e.hp=1000
 w.update_combat(.01)
 for i in 150:w.update_combat(.02)
 assert(e.hp<1000,"weapon damages target")
 w.reset();assert(w.arsenal.shots.is_empty() and w.arsenal.zones.is_empty())
 g.queue_free();await process_frame;await create_timer(.3).timeout;print("WEAPON_ice_wave_PASS");quit()
