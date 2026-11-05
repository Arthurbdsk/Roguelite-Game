extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.sound.volume=0
 var dev=g.dev_tools;dev.enter();dev.encounter="true";dev.map_id="fields";dev.build.attacks=false
 for kind in FinalPatterns.IDS:
  assert(dev.start_encounter());var p=g.late_arena.patterns;p.cooldown=0;g.boss.position=Vector2(950,630);g.player.position=Vector2(780,630)
  assert(p.request(kind,g.boss))
  for i in 100:p.tick(.02)
  for e in g.enemies:
   if e is HazardTarget:e.tick(.2)
  await process_frame;await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://test_output/12-pattern-"+kind+".png")
 dev.panel.show();dev.panel.rebuild();dev.panel.tabs.current_tab=2
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://test_output/12-dev-panel.png")
 dev.end_test();g.queue_free();await process_frame;await create_timer(.2).timeout;print("RENDER_PATTERNS12_PASS eight patterns in real arena and DEV controls");quit()
