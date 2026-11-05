extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.start_run();g.sound.volume=0
 var e=g.spawn_enemy("ghoul",Vector2(1000,650));var hp:float=e.hp;e.hp-=3
 g.elapsed=119.999;g.horde_progress.tick();assert(e.max_hp==hp)
 g.elapsed=120;g.horde_progress.tick();assert(e.max_hp==hp+35 and is_equal_approx(e.hp,hp+32));assert(g.horde_progress.resistance()==.05)
 for i in 20:g.horde_progress.tick()
 assert(e.max_hp==hp+35);assert(is_equal_approx(g.director.rate(),52.8))
 g.elapsed=3600;g.horde_progress.tick();assert(g.horde_progress.resistance()==.75 and e.max_hp==hp+1050)
 g.elapsed=0;g.clear_run();g.director.reset();g.elapsed=10;g.director.cooldown=0
 for i in 90:g.director.tick(1.0/60)
 assert(g.director.total_spawned>0 and not g.enemies.is_empty())
 var first:int=g.enemies.size()
 for i in 120:g.director.tick(1.0/60)
 assert(g.enemies.size()>first)
 var current:int=g.enemies.size();g.balance.max_enemies=current;g.director.tick(5);var debt:float=g.director.debt;assert(debt>=1 and g.director.deferred>0 and g.enemies.size()==current)
 for enemy in g.enemies.duplicate():g.despawn_enemy(enemy)
 g.rebuild_grid();g.director.tick(.01);assert(g.enemies.size()>0 and g.director.debt<debt)
 g.clear_run();g.queue_free();await process_frame;await create_timer(.2).timeout;print("CONTINUOUS13_PASS time boundaries, live health, stage once, resistance cap, rate additive, continuous generation with survivors");quit()
