extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.sound.volume=0;g.start_run();var w=g.weapon_system
 for id in ["bolt","orbit","clock","lightning","sludge"]:assert(w.apply_upgrade(id))
 assert(w.get_loadout().size()==6 and not w.apply_upgrade("holy_water"))
 assert(w.apply_upgrade("sword") and w.get_loadout().size()==6)
 for id in ["crown","boots","ward","magnet"]:assert(w.apply_upgrade(id))
 assert(not w.apply_upgrade("heart") and w.apply_upgrade("boots"))
 g.queue_free();await process_frame;await create_timer(.3).timeout;print("LIMITS7_PASS");quit()
