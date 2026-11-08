extends SceneTree
var errors:int=0
var checks:int=0
func check(ok:bool,message:String):
 checks+=1
 if not ok:errors+=1;printerr("FAIL "+message)
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.set_physics_process(false);g.test_mode=true;g.persistence_enabled=false;g.start_run();g.mastery.begin(false);g.weapon_system.attacks_enabled=false
 var kinds:Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/original_characters22.json")).keys()
 for map_id in ["courtyard","library","fields"]:
  g.clear_run();g.arena.apply_map(map_id);g.state="running";g.player.position=Vector2(900,630);g.camera.position=Vector2.ZERO;g.ui.render("running")
  var i:int=0
  for id in g.enemy_data:
   var d:EnemyData=g.enemy_data[id]
   if d.visual_family not in kinds:continue
   var e=g.spawn_enemy(id,g.free_enemy_position(Vector2(960+(i%5)*55,560+(i/5)*60),d.radius));i+=1
   if not is_instance_valid(e):continue
   check(e.tiny_kind==d.visual_family,"original atlas installed "+id)
   check(e.sprite.hframes==int(TinyCharacters.data(e.tiny_kind).frames) and e.sprite.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,"registered nearest frames "+id)
   check(e.sprite.texture==TinyCharacters.texture(e.tiny_kind),"shared texture "+id)
   for clip in ["idle","walk","attack","cast","hurt","death"]:
    for f in 4:check(TinyCharacters.frame(e.tiny_kind,clip,f/4.0)>=0,"clip "+id+" "+clip)
   e.tick(.016);check(e.sprite.frame<e.sprite.hframes,"valid animated frame "+id)
   var at:Vector2=e.position;var kills:int=g.kills
   e.take_damage(100000,Vector2.ZERO)
   check(g.kills==kills+1,"one reward "+id)
   if e is HordeBoss:check(g.boss_arena.deaths.any(func(d):return d.boss==e),"complete boss death renderer "+id)
   else:
    check(not g.character_remains.effects.is_empty(),"real death animation "+id)
    check(g.character_remains.effects.back().at==at,"death pivot "+id)
   g.spawn_enemy(id,g.free_enemy_position(at,d.radius))
  g.ui.update_hud(g.snapshot());await process_frame;await process_frame;await RenderingServer.frame_post_draw
  g.numbers.clear();g.gold_loot.reset();g.pickups.clear()
  root.get_texture().get_image().save_png("res://build/art22/arena-"+map_id+".png")
  g.clear_run();check(g.character_remains.effects.is_empty(),"clean restart")
 # Real attack preparation/release, summon release and cooldown visuals.
 g.state="running";g.player.position=Vector2(900,630);g.arena.apply_map("courtyard");g.rebuild_grid()
 for id in ["skeleton_sword","skeleton_archer","necromancer","beast"]:
  var e=g.spawn_enemy(id,g.free_enemy_position(Vector2(965,630),18));e.state="prepare";e.state_time=0;e.attack_time=10;e.charge_direction=Vector2.LEFT
  if id=="necromancer":e.summon_cooldown=100
  e.tick(e.data.windup*.4)
  check(TinyCharacters.contains(e.tiny_kind,"attack",e.sprite.frame) and e.sprite.frame%4<2,"real preparation frames "+id)
  e.tick(e.data.windup*.7)
  check(e.state=="recovery" and e.sprite.frame%4>=2,"real attack release frames "+id)
  g.clear_run();g.state="running"
 var necro=g.spawn_enemy("necromancer",Vector2(700,700));check(g.specials.summon(necro),"summon uses real seven-point system")
 g.specials.tick(1.1);check(g.specials.living(necro.get_instance_id())==7 and necro.visual_cast_release>0,"seven spawned at visual release")
 necro.tick(.01);check(TinyCharacters.contains(necro.tiny_kind,"cast",necro.sprite.frame),"cast release animation synchronized")
 g.clear_run();g.state="running"
 var siege=g.spawn_enemy("siege_archer",Vector2(1100,630));siege.take_damage(1);siege.tick(.2)
 check(siege.hit_flash==0 and TinyCharacters.contains(siege.tiny_kind,"idle",siege.sprite.frame),"siege hurt does not stick forever")
 g.clear_run();g.state="running"
 # Actual water flight, impact, loop and dissolution on every map.
 for map_id in ["courtyard","library","fields"]:
  g.arena.apply_map(map_id);g.player.position=Vector2(900,630);g.ui.render("running");g.weapon_system.levels={"holy_water":8}
  for age in [.25,.8,1.8,6.85]:
   g.weapon_system.ground.reset()
   for i in 3:
    g.weapon_system.ground.add_pool("holy_water",Vector2(940+i*65,650),g.player.position,.7);g.weapon_system.ground.pools.back().age=age
   g.weapon_system.ground.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://build/art22/water-"+map_id+"-"+str(int(age*100))+".png")
 g.clear_run();check(g.weapon_system.ground.pools.is_empty(),"water and effects cleaned")
 g.queue_free();await process_frame;await create_timer(.2).timeout
 print("ART22_"+("PASS" if errors==0 else "FAIL")+" checks="+str(checks));quit(int(errors>0))
