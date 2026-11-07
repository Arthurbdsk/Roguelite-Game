extends SceneTree
class Accepted extends RoomConnection:
 func send_message(_packet:Dictionary)->bool:return true
var g
var records:Array=[]
func _initialize():call_deferred("run")
func stats(values:Array)->Dictionary:
 values.sort();return {"median":values[int(values.size()*.5)],"p95":values[mini(values.size()-1,int(values.size()*.95))],"p99":values[mini(values.size()-1,int(values.size()*.99))]}
func run():
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.sound.volume=0
 DisplayServer.window_set_size(Vector2i(1280,720));DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED);Engine.max_fps=60
 g.coop.connection.queue_free();g.coop.connection=Accepted.new();g.coop.add_child(g.coop.connection);g.coop.connection.peer_id="a";g.coop.connection.host_id="a";g.coop.hosting=true
 for map_id in ["courtyard","library","fields"]:
  if g.coop.active:g.coop.leave();await process_frame
  g.coop.connection.peer_id="a";g.coop.connection.host_id="a";g.coop.hosting=true
  g.coop.begin({"run":"bench22","map":map_id,"players":[{"id":"a","name":"A","skills":{}},{"id":"b","name":"B","skills":{}},{"id":"c","name":"C","skills":{}},{"id":"d","name":"D","skills":{}}]})
  g.dev_boss_test=true;g.elapsed=480;g.director.phase="complete";g.special_events.next_check=100000;g.chests.next_check=100000;g.consumables.next_check=100000;g.perf_enabled=true
  seed(21007)
  for actor in g.coop.actors.values():
   actor.player.dev_invulnerable=true;actor.weapon_system.rng.seed=21007;actor.weapon_system.levels={"bolt":8,"runetracer":8,"garlic":8,"holy_water":8,"clock":8,"lightning":8};actor.weapon_system.passives={"lens":8,"cadence":8,"boots":8,"crown":8}
  for i in 150:
   var at:Vector2=g.free_enemy_position(Vector2(640+i%15*24,470+int(i/15)*23),8,null,160);assert(at!=Vector2.INF)
   var species:Array=["ghoul","hound","skeleton_sword","skeleton_archer","necromancer","beast","slime_small","orc_armored","orc_elite","skeleton_armored"]
   var id:String="slime_large" if i<2 else str(species[i%species.size()])
   var e=g.spawn_enemy(id,at)
   assert(e!=null,"fixture must spawn all 150; respect reserved slime divisions")
   e.hp=1000000;e.max_hp=e.hp
  assert(g.enemies.size()==150)
  var sample:Array=[];var cpu:Array=[];var previous:int=Time.get_ticks_usec();var until:int=Time.get_ticks_msec()+12000;var warm:int=Time.get_ticks_msec()+2000;var peaks:Dictionary={"draw_calls":0,"nodes":0,"projectiles":0,"pools":0}
  while Time.get_ticks_msec()<until:
   await process_frame
   var now:int=Time.get_ticks_usec();var elapsed:float=(now-previous)/1000000.0;previous=now
   var start:int=Time.get_ticks_usec();g.coop.host_tick(minf(elapsed,.05),{"movement":Vector2.ZERO,"revive":false})
   if Time.get_ticks_msec()<warm:continue
   cpu.append((Time.get_ticks_usec()-start)/1000.0);sample.append(elapsed*1000)
   var shots:int=0;var pools:int=0
   for actor in g.coop.actors.values():shots+=actor.weapon_system.projectiles.size()+actor.weapon_system.additions.shots.size();pools+=actor.weapon_system.ground.pools.size()
   peaks.draw_calls=maxf(peaks.draw_calls,Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME));peaks.nodes=maxf(peaks.nodes,Performance.get_monitor(Performance.OBJECT_NODE_COUNT));peaks.projectiles=maxi(peaks.projectiles,shots);peaks.pools=maxi(peaks.pools,pools)
  var total:float=sample.reduce(func(a,b):return a+b,0.0)
  records.append({"map":map_id,"enemies":g.enemies.size(),"players":4,"frames":sample.size(),"fps":1000*sample.size()/total,"frame_ms":stats(sample),"simulation_ms":stats(cpu),"peaks":peaks})
  await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(OS.get_environment("BENCH22_OUTPUT")+"-"+map_id+".png")
 var report:Dictionary={"seed":21007,"version":ProjectSettings.get_setting("application/config/version"),"windowed":DisplayServer.get_name()!="headless","resolution":"1280x720, logical640x360","renderer":RenderingServer.get_current_rendering_method(),"gpu":RenderingServer.get_video_adapter_name(),"cpu":OS.get_processor_name(),"warmup_seconds":2,"sample_seconds":10,"results":records}
 var f=FileAccess.open(OS.get_environment("BENCH22_OUTPUT")+".json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close();print("BENCH22_PASS ",JSON.stringify(report));g.coop.leave();g.queue_free();await process_frame;await create_timer(.3).timeout;quit()
