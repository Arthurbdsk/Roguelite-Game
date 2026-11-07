extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.set_physics_process(false);g.test_mode=true;g.persistence_enabled=false;g.sound.volume=0;g.start_run()
 var directory:String=OS.get_environment("HORDAS_CAPTURE_DIR")
 for map_id in ["courtyard","library","fields"]:
  g.clear_run();g.arena.apply_map(map_id);g.state="running";g.player.position=Vector2(900,630);g.camera.position=Vector2.ZERO;g.player.display_name="Jogador 1";g.player.tick_visual(.1,false)
  for i in 12:
   var at:Vector2=g.free_enemy_position(g.player.position+Vector2.from_angle(i*TAU/12)*100,8)
   if at!=Vector2.INF:g.spawn_enemy("ghoul",at)
  g.ui.render("running");g.ui.update_hud(g.snapshot());await process_frame;await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(directory+"/"+map_id+".png")
 g.queue_free();await process_frame;await create_timer(.3).timeout;print("BODIES_BASELINE20_PASS");quit()
