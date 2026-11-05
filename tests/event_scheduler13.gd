extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.start_run();g.sound.volume=0
 var e=g.special_events;e.config.siege_chance=0;e.config.king_chance=0
 g.elapsed=179.99;e.tick(.01);assert(e.attempts==0)
 g.elapsed=180
 for i in 600:e.tick(1.0/60)
 assert(e.attempts==1)
 g.elapsed=240;e.tick(.01);assert(e.attempts==2)
 var boss=g.spawn_enemy("executioner",Vector2(1100,630));g.elapsed=300;e.tick(.01);assert(e.attempts==2 and e.next_check==360);g.despawn_enemy(boss)
 g.state="paused";g.elapsed=360;e.tick(60);assert(e.attempts==2);g.state="running";e.tick(.01);assert(e.attempts==3)
 assert(e.start("siege"));assert(not e.start("king"));e.tick(45);e.tick(.4);e.config.siege_chance=1;e.last_event=g.elapsed
 g.elapsed=480;e.tick(.01);assert(e.active=="")
 g.elapsed=540;e.tick(.01);assert(e.active=="siege")
 g.queue_free();await process_frame;await create_timer(.2).timeout;print("EVENT_SCHEDULER13_PASS first3min, single roll per60s, pause, bosses, no simultaneous events, cooldown3min after end");quit()
