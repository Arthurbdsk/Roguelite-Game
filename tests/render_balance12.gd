extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.start_run();g.sound.volume=0;g.director.phase="complete"
 g.weapon_system.levels={"holy_water":8};g.weapon_system.passives={"lens":8,"hourglass":8};g.profile.data.upgrade_ranks={"area":5,"duration":5};g.mastery.begin()
 for i in 12:
  var at:=Vector2(780+i%4*72,550+int(i/4)*55);g.drop_xp(at,.75)
  if i%2==0:g.gold_loot.drop(at+Vector2(20,12))
 g.weapon_system.ground.add_pool("holy_water",Vector2(940,680),g.player.position)
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 var path:String=ProjectSettings.globalize_path("res://test_output/12-crystals-water.png");root.get_texture().get_image().save_png(path)
 g.queue_free();await process_frame;await create_timer(.3).timeout;print("RENDER_BALANCE12_PASS actual arena crystal and max-build smaller water");quit()
