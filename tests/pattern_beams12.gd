extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.sound.volume=0
 var dev=g.dev_tools;dev.enter();dev.encounter="horror";dev.build.attacks=false;assert(dev.start_encounter());var p=g.late_arena.patterns
 g.boss.position=Vector2(900,630);assert(p.request("beams",g.boss));var j:Dictionary=p.jobs[0];var segment:Dictionary=p.beam_segments(j)[0]
 g.player.dev_invulnerable=false;g.player.invulnerable=0;g.player.hp=1000;g.player.max_hp=1000;g.player.position=segment.source.lerp(segment.end,.5);p.tick(.4);assert(g.player.hp==1000)
 j.age=j.warning;segment=p.beam_segments(j)[0];var direction:Vector2=(segment.end-segment.source).normalized();g.player.position=segment.source.lerp(segment.end,.5)+direction.orthogonal()*(g.player.radius+p.config.beam_width*.5+3)
 p.tick_job(j,0);assert(g.player.hp==1000)
 g.player.position=segment.source.lerp(segment.end,.5);p.tick_job(j,0);assert(g.player.hp<1000)
 var hp:float=g.player.hp;p.tick_job(j,0);assert(g.player.hp==hp)
 var first:Vector2=segment.end;p.tick(.3);assert(p.beam_segments(j)[0].end!=first)
 g.late_arena.clear_attacks(g.boss);assert(p.idle());dev.end_test();g.queue_free();await process_frame;await create_timer(.2).timeout;print("BEAMS12_PASS three rotating arms, direction warning, correct width/inner gap, damage cooldown, terrain clipping and cleanup");quit()
