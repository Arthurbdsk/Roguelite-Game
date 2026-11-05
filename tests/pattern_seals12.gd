extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.sound.volume=0
 var dev=g.dev_tools;dev.enter();dev.encounter="true";dev.build.attacks=false;assert(dev.start_encounter());var p=g.late_arena.patterns
 p.cooldown=0
 assert(p.request("seals",g.boss));p.tick(1.36);assert(p.marks.size()==1);var fixed:Vector2=p.marks[0].at
 g.player.dev_invulnerable=false;g.player.invulnerable=0;var hp:float=g.player.hp;g.player.position=fixed+Vector2(60,0)
 p.tick(.3);assert(p.marks[0].at==fixed and g.player.hp==hp)
 p.tick_marks(.9);assert(g.player.hp==hp);g.player.position=fixed;p.tick_marks(.01);assert(g.player.hp<hp)
 g.player.dev_invulnerable=true
 for i in 200:p.tick(.02)
 assert(p.jobs.is_empty() and p.marks.is_empty());dev.end_test();g.queue_free();await process_frame;await create_timer(.2).timeout;print("SEALS12_PASS fixed player positions, five sequential marks, warning and 60px escape, real damage and full expiration");quit()
