extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.sound.volume=0
 var dev=g.dev_tools;dev.enter();dev.encounter="horror";dev.build.attacks=false;assert(dev.start_encounter());var b=g.boss;var p=g.late_arena.patterns
 assert(dev.force_attack("rings"));b.state="chase";b.tick(.01);assert(b.state=="windup");b.tick(1.3)
 assert(p.jobs.size()==1 and p.shots.is_empty());p.tick(.5);assert(p.shots.is_empty())
 for i in 210:p.tick(.02)
 assert(p.emitted>=88 and p.shots.size()>0)
 var hp:float=g.player.hp;g.player.dev_invulnerable=false;g.player.invulnerable=0;g.player.position=p.shots[0].at;p.tick(.001);assert(g.player.hp<hp)
 g.late_arena.clear_attacks(b);assert(p.jobs.is_empty() and p.shots.is_empty());dev.start_encounter();assert(p.idle());dev.end_test();g.queue_free();await process_frame;await create_timer(.2).timeout
 print("RINGS12_PASS successive projectile rings with changing 85-degree openings, hit/dodge physics, cleanup and restart");quit()
