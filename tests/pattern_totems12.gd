extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.sound.volume=0
 var dev=g.dev_tools;dev.enter();dev.encounter="true";dev.build.attacks=false;assert(dev.start_encounter());var p=g.late_arena.patterns;p.cooldown=0
 assert(p.request("totems",g.boss));p.tick(1.4);var targets:Array=g.enemies.filter(func(e):return e is HazardTarget);assert(targets.size()==4)
 var first:int=p.jobs[0].targets[0].serial;var target=p.owner_node(first);assert(target.data.id=="channel_totem");target.take_damage(95)
 assert(p.jobs[0].targets[0].destroyed);p.tick(4.6);assert(p.emitted>30 and p.emitted<=48)
 for shot in p.shots:assert(absf(wrapf(shot.velocity.angle(),-PI,PI))>=PI/4)
 assert(g.enemies.filter(func(e):return e is HazardTarget).is_empty())
 g.late_arena.clear_attacks(g.boss);assert(p.idle());dev.end_test();g.queue_free();await process_frame;await create_timer(.2).timeout;print("TOTEMS12_PASS four destructible channelers, 4.5s charge, destroyed totem removes its 90-degree projectile sector, cleanup");quit()
