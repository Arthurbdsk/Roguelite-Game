extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.sound.volume=0;g.start_run();g.director.phase="complete";g.banner="";g.weapon_system.levels={"sludge":1}
 for i in 6:g.weapon_system.ground.add_pool("sludge",g.player.position+Vector2(i*24-100,30),g.player.position)
 g.weapon_system.levels.holy_water=2
 g.weapon_system.ground.add_pool("holy_water",g.player.position+Vector2(60,30),g.player.position,.7)
 g.weapon_system.ground.add_pool("holy_water",g.player.position+Vector2(120,10),g.player.position,.7)
 g.weapon_system.ground.tick(.85,false)
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://test_output/water-arena.png")
 g.queue_free();await process_frame;await create_timer(.2).timeout;print("LODO_ARENA_RENDERED");quit()
