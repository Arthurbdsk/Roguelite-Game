extends SceneTree
func _initialize():call_deferred("run")
func capture(id:String):
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 save_capture("res://test_output/10-guardian-"+id+".png")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.start_run();g.sound.volume=0;g.director.phase="complete";g.weapon_system.levels.clear()
 g.campaign.completed.demon=true;g.elapsed=900;g.campaign.tick();assert(g.campaign.history==["guardian"])
 g.late_arena.tick(1.3);var boss=g.boss;assert(boss is LateBoss and boss.combat_enabled)
 assert(is_equal_approx(boss.max_hp,g.boss_balance.demon_health()*5*g.balance.enemy_health_multiplier*.8))
 var at:Vector2=g.player.position;boss.locked_target=at
 assert(g.late_arena.cast("cross",boss));assert(g.late_arena.areas.size()==2)
 await capture("cross-warning");g.player.position=at+Vector2(80,80);g.player.invulnerable=0;g.late_arena.tick(1.31);assert(g.player.hp==100)
 await capture("cross-active");g.late_arena.areas.clear()
 assert(g.late_arena.cast("feathers",boss));assert(g.late_arena.shots.size()==12)
 g.late_arena.tick(.7);var stopped:Vector2=g.late_arena.shots[0].at;g.late_arena.tick(.2);assert(g.late_arena.shots[0].at==stopped)
 await capture("feathers");g.late_arena.shots.clear()
 assert(g.late_arena.cast("light_ring",boss));g.late_arena.tick(1.4);await capture("ring")
 g.late_arena.areas.clear();var before:int=g.gold;boss.take_damage(999999)
 assert(g.state=="running" and g.gold==before+int(g.campaign.config.guardian_reward))
 g.late_arena.tick(2);assert(g.campaign.completed.guardian and g.state=="running")
 g.queue_free();await process_frame;await create_timer(.3).timeout;print("GUARDIAN10_PASS schedule, HP, cross safe quadrants, feather stop, ring, reward once and continuation");quit()

func save_capture(path:String):
 var output:String=ProjectSettings.globalize_path(path)
 DirAccess.make_dir_recursive_absolute(output.get_base_dir())
 assert(root.get_texture().get_image().save_png(output)==OK)
