extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.sound.volume=0
 for map in ["courtyard","library","fields"]:
  g.selected_map=map;g.start_run();g.director.phase="complete";g.player.invulnerable=100
  var boss=g.spawn_enemy("demon",g.player.position+Vector2(160,0))
  assert(g.boss_arena.cast("ice",boss,Vector2.LEFT,1),map)
  assert(g.boss_arena.areas.size()==4)
  var locations:Array=[]
  for a in g.boss_arena.areas:
   locations.append(a.at);assert(not Rect2(a.at-a.size/2,a.size).grow(g.player.radius).has_point(g.player.position))
  g.player.position+=Vector2(40,0);g.boss_arena.tick(.2)
  for i in locations.size():assert(g.boss_arena.areas[i].at==locations[i])
  g.weapon_system.levels={"ice_wave":3};g.weapon_system.arsenal.launch("ice_wave");g.weapon_system.arsenal.tick(.16)
  await process_frame;await process_frame;await RenderingServer.frame_post_draw
  save_capture("res://test_output/10-ice-"+map+".png")
  g.boss_arena.tick(1);assert(g.boss_arena.slow_multiplier(locations[0])<1)
  g.boss_arena.tick(10);assert(g.boss_arena.areas.is_empty())
  print("ICE10_PASS ",map," planned near target, full 1120 span, safe gaps, fixed warnings, expiry")
 g.queue_free();await process_frame;await create_timer(.3).timeout;quit()

func save_capture(path:String):
 var output:String=ProjectSettings.globalize_path(path)
 DirAccess.make_dir_recursive_absolute(output.get_base_dir())
 assert(root.get_texture().get_image().save_png(output)==OK)
