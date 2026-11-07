extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.set_physics_process(false);g.persistence_enabled=false;g.test_mode=true;g.sound.volume=0;g.start_run();g.player.dev_invulnerable=true
 var e=g.spawn_enemy("ghoul",g.player.position+Vector2(160,0));e.hp=100000;g.rebuild_grid()
 g.weapon_system.levels={"axe":8};g.weapon_system.arsenal.launch("axe")
 assert(g.weapon_system.arsenal.textures.axe.get_size()==Vector2(32,32))
 for i in 40:
  g.weapon_system.arsenal.tick(1.0/60);await process_frame
  if i==20:
   await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png((OS.get_environment("HORDAS_CAPTURE_DIR") if not OS.get_environment("HORDAS_CAPTURE_DIR").is_empty() else "res://test_output")+"/18-axe.png")
 g.queue_free();await process_frame;await process_frame;print("RENDER_ADJUSTMENTS18_PASS");quit()
