extends SceneTree
var errors:int=0
var checks:int=0
var directory:String
var g
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
 checks+=1
 if not ok:errors+=1;printerr("FAIL "+message)
func capture(name:String):
 g.ui.update_hud(g.snapshot());await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(directory+"/soldier-"+name+".png")
func run():
 directory=OS.get_environment("HORDAS_CAPTURE_DIR")
 if directory.is_empty():directory="res://test_output"
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.set_physics_process(false);g.test_mode=true;g.persistence_enabled=false;g.sound.volume=0;g.start_run();g.mastery.begin(false)
 var p=g.player;var w=g.weapon_system
 check(p.tiny_soldier and p.sprite.hframes==43,"official Soldier, 43 aligned frames")
 check(p.radius==7 and p.speed==96 and p.max_hp==100,"body and baseline attributes unchanged")
 check(p.sprite.position.is_equal_approx(Vector2(0,-13.2)),"fixed feet pivot at PC 1.1 visual scale")
 check(p.sprite.texture==TinyCharacters.texture("soldier"),"shared texture")
 for map_id in ["courtyard","library","fields"]:
  g.clear_run();g.arena.apply_map(map_id);g.state="running";g.player.position=Vector2(900,630);g.camera.position=Vector2.ZERO;p.display_name="Jogador 1";w.reset();g.ui.render("running")
  w.attacks_enabled=false
  var idle_frames:Dictionary={}
  for i in 12:p.tick(.1,Vector2.ZERO);idle_frames[p.sprite.frame]=true;check(TinyCharacters.contains("soldier","idle",p.sprite.frame),"idle contains no walk "+map_id)
  check(idle_frames.size()>1,"animated idle "+map_id);await capture(map_id+"-idle")
  for i in 12:p.tick(1.0/60,Vector2.RIGHT)
  check(p.actually_moving and TinyCharacters.contains("soldier","walk",p.sprite.frame),"actual walking "+map_id);await capture(map_id+"-walk")
  p.tick(.016,Vector2.ZERO);check(TinyCharacters.contains("soldier","idle",p.sprite.frame),"stop immediately returns idle")
  p.tick(.016,Vector2(.02,0));check(not p.actually_moving and TinyCharacters.contains("soldier","idle",p.sprite.frame),"noise does not animate walking")
  w.attacks_enabled=true
  var enemy=g.spawn_enemy("ghoul",p.position+Vector2(100,0));enemy.hp=1000;enemy.max_hp=1000
  var before:int=w.projectiles.size();check(w._fire_bolts(),"real initial bow fires")
  w.timers.bolt=w._interval("bolt")
  check(w.projectiles.size()==before+1,"one actual arrow, no animation-generated extra")
  check(w.projectiles.back().damage==w._stat("bolt","damage") and is_equal_approx(w.projectiles.back().velocity.length(),275),"unchanged arrow damage and speed")
  p.tick_visual(0,true);check(p.sprite.frame==33,"real firing event shows release frame")
  await capture(map_id+"-bow")
  p.tick_visual(.1,true);check(p.sprite.frame==34,"movement cannot interrupt bow recovery")
  var shot_count:int=w.projectiles.size();p.receive_visual_frame(33,true);p.tick_visual(.01,true)
  check(p.sprite.flip_h and p.sprite.frame in [33,34] and w.projectiles.size()==shot_count,"replicated bow is visual only")
  for i in 60:w._update_projectiles(.01)
  check(is_equal_approx(enemy.hp,1000-w._stat("bolt","damage")),"one collision damage decision")
  w.attacks_enabled=false;p.hurt_remaining=.2;p.tick_visual(.01,true)
  check(TinyCharacters.contains("soldier","hurt",p.sprite.frame),"hurt above movement/attack")
  await capture(map_id+"-hurt")
  p.down=true;p.hp=0;p.tick_visual(.2,false)
  check(TinyCharacters.contains("soldier","death",p.sprite.frame),"down uses death frames");await capture(map_id+"-down")
  p.tick_visual(.5,true);check(p.sprite.frame==42,"down holds last death frame")
  p.down=false;p.hp=40;p.hurt_remaining=0;p.revive_remaining=.45;p.tick_visual(.01,false)
  check(TinyCharacters.contains("soldier","death",p.sprite.frame),"revive uses reversed fall, no fabricated frames");await capture(map_id+"-revive")
  p.tick_visual(.5,false);check(TinyCharacters.contains("soldier","idle",p.sprite.frame),"revive returns idle")
  g.clear_run();w.reset();check(w.bow_visual_target==null,"restart clears weak target")
 g.queue_free();await process_frame;await create_timer(.3).timeout
 print("SOLDIER20_"+("PASS" if errors==0 else "FAIL")+" checks="+str(checks));quit(int(errors>0))
