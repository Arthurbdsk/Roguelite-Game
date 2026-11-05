extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.sound.volume=0
 var dev=g.dev_tools;dev.enter();dev.encounter="horror";dev.build.attacks=false;assert(dev.start_encounter());var p=g.late_arena.patterns
 assert(p.request("spears",g.boss));p.tick(.01);assert(p.marks.size()==5)
 var fixed:Vector2=p.marks[2].at;g.player.dev_invulnerable=false;g.player.invulnerable=0;g.player.position=fixed;var hp:float=g.player.hp
 p.tick(.4);assert(g.player.hp==hp);g.player.position=fixed+Vector2(0,38);p.tick_marks(p.marks[2].warning-.4);assert(g.player.hp==hp)
 g.player.position=fixed;p.marks[2].hits.clear();p.tick_marks(.01);assert(g.player.hp<hp)
 var after:float=g.player.hp;p.tick_marks(.01);assert(g.player.hp==after)
 g.late_arena.clear_attacks(g.boss);assert(p.marks.is_empty());dev.end_test();g.queue_free();await process_frame;await create_timer(.2).timeout;print("SPEARS12_PASS 5 sequential bands, real warning/width/damage, side escape, one hit and cleanup");quit()
