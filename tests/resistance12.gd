extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.start_run();g.sound.volume=0;g.director.phase="complete"
 var e=g.spawn_enemy("ghoul",Vector2(1100,630));var base:float=e.max_hp;e.take_damage(3);var lost:float=e.max_hp-e.hp
 g.horde_progress.complete(0);assert(g.horde_progress.resistance()==0 and e.max_hp==base)
 g.horde_progress.complete(1);assert(is_equal_approx(g.horde_progress.resistance(),.05) and e.max_hp==base+35 and e.max_hp-e.hp==lost)
 g.horde_progress.complete(1);g.horde_progress.apply(e);assert(e.max_hp==base+35)
 var before:float=e.hp;e.take_damage(10);assert(is_equal_approx(before-e.hp,9.5))
 e.apply_time_control(3,2,.3,1);assert(e.frozen_remaining==3)
 var b=g.spawn_enemy("demon",Vector2(1000,700));var first:float=b.max_hp;b.take_damage(999999);assert(is_equal_approx(b.max_hp,(first-35)*5+35))
 for wave in range(2,40):g.horde_progress.complete(wave)
 assert(g.horde_progress.resistance()==.75 and e.max_hp==base+20*35)
 before=e.hp;e.take_damage(-10);assert(e.hp==before);e.take_damage(10);assert(e.hp==before-2.5)
 var fresh=g.spawn_enemy("beast",Vector2(1200,650));assert(fresh.horde_health_bonus==700)
 g.clear_run();assert(g.horde_progress.completed==0 and g.horde_progress.resistance()==0)
 g.queue_free();await process_frame;await create_timer(.3).timeout;print("RESISTANCE12_PASS every two cleared hordes, 5 points, cap 75%, +35 absolute max/current HP preserving damage, no repeated stages, live/new enemies, phase base and reset");quit()
