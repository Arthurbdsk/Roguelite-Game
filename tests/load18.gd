extends SceneTree
class Accepted extends RoomConnection:
 func send_message(_packet:Dictionary)->bool:return true
var errors:int=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 if not ok:errors+=1;printerr("FAIL "+label)
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.set_physics_process(false);g.persistence_enabled=false;g.test_mode=true;g.sound.volume=0;g.perf_enabled=true
 g.start_run();g.dev_boss_test=false
 for id in NewWeapons16.IDS:
  check(g.weapon_system._weapon_available(id),"weapon available outside DEV "+id)
  var icon:Texture2D=load(g.weapon_system.weapon_data[id].icon)
  check(icon.get_size()==Vector2(32,32),"aligned icon "+id)
  g.weapon_system.levels[id]=8
  check(not g.weapon_system._weapon_available(id),"max level excluded "+id)
  g.weapon_system.levels.erase(id)
 var a=g.weapon_system.additions
 a.receive_impacts([{"id":1,"kind":"magic_wand","at":Vector2(20,20)}]);a.receive_impacts([{"id":1,"kind":"magic_wand","at":Vector2(20,20)}])
 check(a.visual.impacts.size()==1,"repeated snapshot cannot duplicate impact")
 a.visual.tick(.4);check(a.visual.impacts.is_empty(),"impact expires locally")
 a.reset();g.weapon_system.levels={"runetracer":1};a.projectile("runetracer",Vector2.RIGHT);var first:int=a.shots[0].id;a.shots.clear();a.projectile("runetracer",Vector2.RIGHT)
 check(a.shots[0].id>first,"no projectile identity reuse during run")
 g.coop.connection.queue_free();g.coop.connection=Accepted.new();g.coop.add_child(g.coop.connection);g.coop.connection.peer_id="a";g.coop.connection.host_id="a";g.coop.hosting=true
 g.coop.begin({"run":"load18","players":[{"id":"a","name":"A","skills":{}},{"id":"b","name":"B","skills":{}},{"id":"c","name":"C","skills":{}},{"id":"d","name":"D","skills":{}}]})
 g.dev_boss_test=true;g.campaign.cleared=true;g.campaign.endless=true;g.director.phase="complete";g.special_events.next_check=100000;g.chests.next_check=100000;g.consumables.next_check=100000
 for actor in g.coop.actors.values():
  actor.player.dev_invulnerable=true
  actor.weapon_system.levels={"garlic":8,"whip":8,"fire_wand":8,"runetracer":8,"magic_wand":8,"bolt":8}
  actor.weapon_system.passives={"lens":8,"hourglass":8,"cadence":8,"boots":8}
 var muted:bool=AudioServer.is_bus_mute(0);AudioServer.set_bus_mute(0,true)
 g.music.suppress_test_audio=false;g.music.player.play();g.music.player.seek(10)
 var results:Array=[]
 for map_id in ["courtyard","library","fields"]:
  seed(18018);g.elapsed=0;g.arena.apply_map(map_id)
  var actor_index:int=0
  for actor in g.coop.actors.values():
   actor.weapon_system.reset();actor.weapon_system.rng.seed=18001+actor_index;actor_index+=1
   actor.weapon_system.levels={"garlic":8,"whip":8,"fire_wand":8,"runetracer":8,"magic_wand":8,"bolt":8}
   actor.weapon_system.passives={"lens":8,"hourglass":8,"cadence":8,"boots":8}
  for e in g.enemies:e.queue_free()
  g.enemies.clear();await physics_frame
  g.rebuild_grid()
  for i in 200:
   var at:Vector2=g.free_enemy_position(Vector2(650+i%20*25,470+int(i/20)*27),8)
   if at!=Vector2.INF:
    var e=g.spawn_enemy("ghoul",at)
    if e!=null:e.hp=1000000;e.max_hp=e.hp
  var frames:Array=[];var cpu:Array=[];var previous:int=Time.get_ticks_usec();var peak_shots:int=0
  for frame in 240:
   await process_frame
   var now:int=Time.get_ticks_usec()
   var before:int=Time.get_ticks_usec();g.coop.host_tick(1.0/60,{"movement":Vector2.ZERO,"revive":false})
   if frame>=60:frames.append((now-previous)/1000.0);cpu.append((Time.get_ticks_usec()-before)/1000.0)
   previous=now
   var count:int=0
   for actor in g.coop.actors.values():count+=actor.weapon_system.additions.shots.size()
   peak_shots=maxi(peak_shots,count)
  g.ui.update_hud(g.snapshot());await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://test_output/18-load-"+map_id+".png")
  frames.sort();cpu.sort()
  results.append({"map":map_id,"rendered":DisplayServer.get_name()!="headless","frames":180,"frame_ms":{"median":frames[90],"p95":frames[171],"p99":frames[178]},"host_tick_ms":{"median":cpu[90],"p95":cpu[171],"p99":cpu[178]},"enemies":g.enemies.size(),"peak_new_projectiles":peak_shots,"players":g.coop.actors.size(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"memory_bytes":OS.get_static_memory_usage()})
 var file=FileAccess.open("res://test_output/18-rendered-load.json",FileAccess.WRITE);file.store_string(JSON.stringify(results,"  "));file.close()
 print("LOAD18 ",JSON.stringify(results))
 for actor in g.coop.actors.values():
  actor.weapon_system.reset();check(actor.weapon_system.additions.visual.tracks.is_empty(),"four-player visual cleanup")
 g.queue_free();await process_frame;await create_timer(.3).timeout;AudioServer.set_bus_mute(0,muted)
 print("LOAD18_"+("PASS" if errors==0 else "FAIL"));quit(int(errors>0))
