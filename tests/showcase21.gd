extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.start_run();g.weapon_system.attacks_enabled=false
 for map_id in ["courtyard","library","fields"]:
  g.clear_run();g.arena.apply_map(map_id);g.state="running";g.elapsed=480;g.player.position=Vector2(900,630);g.ui.render("running")
  var i:int=0
  for id in g.variant_data:
   var e=g.spawn_enemy(id,Vector2(780+i*120,640));e.hp=e.max_hp*.8;e.refresh_visual();i+=1
  await process_frame;await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://build/refinement21/variants-"+map_id+".png")
 print("SHOWCASE21_PASS three maps, armor badge and health bars")
 g.queue_free();await process_frame;await create_timer(.3).timeout;quit()
