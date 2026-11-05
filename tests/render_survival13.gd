extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.sound.volume=0
 g.dev_tools.enter();g.dev_tools.map_id="fields";g.dev_tools.start_survival();g.dev_tools.set_survival_time(240);g.special_events.next_check=1000000;g.chests.next_check=1000000
 g.player.position=Vector2(850,630);assert(g.special_events.start("king"));var king=g.enemies[0];king.position=Vector2(960,630);g.rebuild_grid();king.tick(.15);assert(g.chests.spawn_chest())
 await process_frame;await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://test_output/13-king-chest.png")
 g.player.position=g.chests.chest.at;assert(g.chests.try_open(g.player));g.chests.visual_tick(.45)
 await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://test_output/13-chest-open.png")
 g.dev_tools.panel.show();g.dev_tools.panel.rebuild();g.dev_tools.panel.tabs.current_tab=3
 await process_frame;await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://test_output/13-dev-survival.png")
 g.dev_tools.panel.hide();g.dev_tools.end_test();g.queue_free();await process_frame;await create_timer(.2).timeout;print("RENDER_SURVIVAL13_PASS real arena King sprite, chest opening, reward and DEV tab");quit()
