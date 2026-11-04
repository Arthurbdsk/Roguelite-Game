extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.sound.volume=0;g.start_run();g.director.phase="complete";g.weapon_system.levels={"sludge":1}
 g.weapon_system.update_combat(.01);assert(g.weapon_system.ground.pools.is_empty())
 g.player.position+=Vector2(24,0);g.weapon_system.update_combat(.01)
 assert(g.weapon_system.ground.pools.size()==1)
 var pool=g.weapon_system.ground.pools[0]
 var e=g.spawn_enemy("guard",pool.at);e.hp=1000
 g.weapon_system.ground.add_pool("sludge",pool.at,pool.at)
 g.weapon_system.update_combat(.01);assert(e.hp==997)
 g.weapon_system.update_combat(.25);assert(e.hp==997)
 g.weapon_system.update_combat(.25);assert(e.hp==994)
 var hp:float=g.player.hp;g.weapon_system.update_combat(.5);assert(g.player.hp==hp)
 assert(g.weapon_system.ground.pools.size()==2)
 g.weapon_system.update_combat(3);assert(g.weapon_system.ground.pools.is_empty())
 g.weapon_system.reset();assert(g.weapon_system.ground.hit_times.is_empty())
 g.queue_free();await process_frame;await create_timer(.3).timeout
 print("LODO_PASS movement, three seconds, half-second ticks, no overlap stacking, no friendly damage");quit()
