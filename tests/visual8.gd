extends SceneTree
func _initialize():call_deferred("run")
func run():
 var stage="necromancer"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("stage="):stage=arg.trim_prefix("stage=")
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.sound.volume=0;g.start_run();g.director.phase="complete";g.set_physics_process(false)
 g.player.invulnerable=1000
 var weapon:bool=stage in ["bombs","boomerang","holy_water"]
 var e=g.spawn_enemy("guard" if weapon else stage,g.player.position+Vector2(100,0));e.hp=100000
 if weapon:
  g.weapon_system.levels={stage:1};e.data.speed=0;e.attack_time=1000
  if stage=="holy_water":g.weapon_system.ground.add_pool("holy_water",g.player.position+Vector2(70,0),g.player.position,.6)
 var frames_seen:Dictionary={}
 for i in 240:
  g.simulate(1.0/60);frames_seen[e.sprite.frame]=true
  await physics_frame
  if i in [35,90,170]:
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://test_output/08-"+stage+"-"+str(i)+".png")
 assert(frames_seen.size()>=4)
 print("VISUAL8_PASS "+stage+" frames_seen="+str(frames_seen.keys()))
 g.clear_run();assert(g.enemies.is_empty());g.queue_free();await process_frame;await create_timer(.3).timeout;quit()
