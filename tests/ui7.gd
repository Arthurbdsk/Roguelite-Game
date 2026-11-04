extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.sound.volume=0;g.start_run();g.weapon_system.levels={"axe":8,"boomerang":6,"bombs":4,"blades":3,"ice_wave":2,"holy_water":5};g.weapon_system.passives={"crown":8,"lens":3,"hourglass":4,"cadence":2}
 var choices=g.weapon_system.get_offers();g.ui.render("upgrading",{"offers":choices});await process_frame;await process_frame
 var build=g.ui.menu.find_child("BuildPanel",true,false)
 assert(build.get_parent().get_global_rect().end.y<=333,"build viewport overflow")
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://test_output/07-build.png")
 g.open_map_select();await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://test_output/07-map-menu.png")
 g.queue_free();await process_frame;await create_timer(.3).timeout;print("UI7_PASS six weapons four passives and map menu");quit()
