extends SceneTree
var errors:int=0
var output:String="res://test_output"
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 if not ok:errors+=1;printerr("FAIL "+label)
func run():
 if not OS.get_environment("HORDAS_CAPTURE_DIR").is_empty():output=OS.get_environment("HORDAS_CAPTURE_DIR")
 var selected:String="garlic"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--weapon="):selected=arg.trim_prefix("--weapon=")
 root.size=Vector2i(960,540)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.set_physics_process(false);g.persistence_enabled=false;g.test_mode=true;g.sound.volume=0;g.start_run();g.dev_boss_test=true
 var w=g.weapon_system;g.player.dev_invulnerable=true
 for rank in [1,8]:
  w.reset();w.levels={selected:rank};w.timers={};w.passives={}
  for e in g.enemies:e.queue_free()
  g.enemies.clear()
  for i in 22:
   var at:Vector2=g.player.position+Vector2.from_angle(i*TAU/22)*float(52+i%4*38)
   var e=g.spawn_enemy("ghoul",at)
   if e!=null:e.hp=1000000;e.max_hp=e.hp
  g.rebuild_grid();g.ui.update_hud(g.snapshot())
  check(not w.weapon_data[selected].icon.is_empty(),"public icon "+selected)
  for frame_index in 50:
   if frame_index%18==0:w.additions.launch(selected)
   w.combat_time+=1.0/60;w.additions.tick(1.0/60,true);w.queue_redraw()
   await process_frame
   if frame_index in [6,12,24,42]:
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png(output+"/17-%s-L%d-%d.png"%[selected,rank,frame_index])==OK,"arena capture")
  check(w.additions.visual.time>0,"animation advanced")
 w.reset();check(w.additions.visual.tracks.is_empty() and w.additions.visual.impacts.is_empty(),"visual reset clears trails and impact")
 g.queue_free();await process_frame;await process_frame
 print("VISUAL17_"+selected+"_"+("PASS" if errors==0 else "FAIL"));quit(int(errors>0))
