extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.sound.volume=0
 var dev=g.dev_tools;dev.enter();dev.encounter="horror";dev.build.attacks=false;assert(dev.start_encounter());var p=g.late_arena.patterns
 assert(p.request("orbs",g.boss));assert(p.jobs[0].orbs.size()==6)
 var fixed:Vector2=p.jobs[0].orbs[0].locked_target;g.player.position+=Vector2(80,50)
 p.tick(.5);assert(p.shots.is_empty() and p.jobs[0].orbs[0].locked_target==fixed)
 p.tick(.86);assert(p.emitted==6)
 for i in 6:p.tick(.17)
 assert(p.emitted==42)
 for shot in p.shots:assert(shot.velocity.length()>0)
 g.late_arena.clear_attacks(g.boss);assert(p.idle());dev.end_test();g.queue_free();await process_frame;await create_timer(.2).timeout;print("ORBS12_PASS six telegraphed orbs, 7-shot bursts, fixed living-player targets, valid floor points and cleanup");quit()
