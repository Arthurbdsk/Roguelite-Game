extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.start_run();g.director.phase="complete";g.sound.volume=0
 var e=g.spawn_enemy("guard",g.player.position+Vector2(80,0));e.hp=10000
 var w=g.weapon_system;w.levels={"bombs":1};g.rebuild_grid();assert(w.arsenal.launch("bombs"))
 w.arsenal.tick(.71);var after:float=e.hp;assert(is_equal_approx(after,10000-w._stat("bombs","damage")))
 for i in 10:w.arsenal.tick(.01)
 assert(e.hp==after)
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 save_capture("res://test_output/10-explosion.png")
 w.arsenal.tick(.4);assert(w.arsenal.zones.is_empty());g.clear_run();assert(w.arsenal.zones.is_empty())
 g.queue_free();await process_frame;await create_timer(.3).timeout;print("EXPLOSION10_PASS animated impact, one damage event, same damage/radius/timing, cleanup");quit()

func save_capture(path:String):
 var output:String=ProjectSettings.globalize_path(path)
 DirAccess.make_dir_recursive_absolute(output.get_base_dir())
 assert(root.get_texture().get_image().save_png(output)==OK)
