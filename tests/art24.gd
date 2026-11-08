extends SceneTree
var checks:int=0
func check(ok:bool,label:String):
 checks+=1
 assert(ok,label)
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.start_run()
 for map_id in ["courtyard","library","fields"]:
  g.clear_run();g.state="running";g.arena.apply_map(map_id);g.player.position=Vector2(900,630);g.camera.position=Vector2.ZERO;g.ui.render("running")
  for i in 3:
   var id:String=["plague","devourer","guard"][i];var e=g.spawn_enemy(id,Vector2(920+i*65,550));check(e.tiny_kind=="original_"+id,"correct atlas "+id);e.tick(.01)
   for clip in ["idle","walk","attack","cast","hurt","death"]:
    var frames:Dictionary={}
    for frame in 4:frames[TinyCharacters.frame(e.tiny_kind,clip,frame/4.0)]=true
    check(frames.size()==4,"four real frames for "+id+" "+clip)
   e.take_damage(1);e.tick(.01);check(TinyCharacters.contains(e.tiny_kind,"hurt",e.sprite.frame),"hurt animation "+id)
   e.hit_flash=0
   if id=="plague":
    e.state="prepare";e.state_time=0;e.charge_direction=Vector2.DOWN;e.ambush_at=Vector2(1050,680);e.tick(e.data.windup*.4)
    check(TinyCharacters.contains(e.tiny_kind,"attack",e.sprite.frame),"plague prepares flask")
    e.tick(e.data.windup*.7);check(e.state=="recovery" and g.specials.areas.size()==1,"flask released by real combat")
   elif id=="devourer":
    var before:float=e.max_hp;g.gold_loot.drop(e.position,1);g.food_index.tick(1);e.search_clock=0;e.tick(.01)
    check(e.meals==1 and e.eating_left>0 and e.max_hp==before+g.balance.devour_health_gain,"real feeding preserves growth")
    check(TinyCharacters.contains(e.tiny_kind,"cast",e.sprite.frame),"feeding clip")
    check(is_equal_approx(e.sprite.scale.x,(1+g.balance.devour_growth_step)*1.1),"sharp growth at nearest filtering")
   else:
    check(e.data.behavior=="charge","exact dash entity guard")
    e.state="prepare";e.state_time=0;e.charge_direction=Vector2.LEFT;e.tick(.4);check(e.sprite.flip_h and TinyCharacters.contains(e.tiny_kind,"attack",e.sprite.frame),"dash preparation follows locked direction")
    e.tick(.46);check(e.state=="attack" and e.sprite.flip_h,"dash uses locked direction")
  g.weapon_system.levels={"holy_water":1};g.weapon_system.ground.add_pool("holy_water",Vector2(960,680),g.player.position);g.weapon_system.ground.pools[0].age=1
  check(not g.specials.areas.is_empty(),"poison from actual plague throw");g.specials.areas[0].age=g.specials.balance.flask_warning+1;g.specials.queue_redraw()
  await process_frame;await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://build/art24/"+map_id+".png")
 for e in g.enemies.duplicate():
  var at:Vector2=e.position;e.take_damage(1000000);check(g.character_remains.effects.back().at==at,"death pivot "+e.data.id)
 g.clear_run();check(g.specials.areas.is_empty(),"cleanup");g.queue_free();await process_frame;await create_timer(.2).timeout;print("ART24_PASS checks=",checks," three characters and actual attacks/feeding, three maps, cleanup");quit()
