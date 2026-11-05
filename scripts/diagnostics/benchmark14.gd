extends Node
class AcceptedConnection extends RoomConnection:
 func send_message(_packet:Dictionary)->bool:return true
var g
var label:String
var scenarios:Array=["initial","four_builds","boss_necro","king_225","siege","infinite30"]
var scenario:int=-1
var age:float=0
var samples:Array=[]
var cpu:Array=[]
var sections:Dictionary={}
var results:Array=[]
var peaks:Dictionary={}
var previous:int=0
var ready_sample:bool=false
func setup(game,tag:String):
 g=game;label=tag;g.set_physics_process(false);g.perf_enabled=true;g.sound.volume=0;DisplayServer.window_set_size(Vector2i(1280,720));DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED);Engine.max_fps=120;RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true)
 g.coop.connection.queue_free();g.coop.connection=AcceptedConnection.new();g.coop.add_child(g.coop.connection);g.coop.connection.peer_id="a";g.coop.connection.host_id="a";g.coop.hosting=true
 next_scenario()
func next_scenario():
 scenario+=1
 if scenario>=scenarios.size():
  var report={"tag":label,"seed":140031,"resolution":"1280x720 viewport640x360","renderer":RenderingServer.get_current_rendering_method(),"gpu":RenderingServer.get_video_adapter_name(),"cpu":OS.get_processor_name(),"windowed":DisplayServer.get_name()!="headless","warmup_seconds":2,"sample_seconds":10,"frame_cap":120,"results":results}
  var f=FileAccess.open(OS.get_environment("HORDAS_BENCH_OUTPUT").path_join("benchmark14_"+label+".json"),FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));print("BENCHMARK14 ",JSON.stringify(report));get_tree().quit();return
 seed(140031);g.selected_map="fields";g.coop.begin({"run":"benchmark14","map":"fields","players":[{"id":"a","name":"A","skills":{}},{"id":"b","name":"B","skills":{}},{"id":"c","name":"C","skills":{}},{"id":"d","name":"D","skills":{}}]});g.persistence_enabled=false;g.dev_boss_test=true;g.campaign.cleared=true;g.campaign.endless=true;g.special_events.next_check=1000000;g.chests.next_check=1000000
 g.elapsed=1800 if scenarios[scenario]=="infinite30" else (240 if scenario>0 else 0);g.horde_progress.tick();g.director.rng.seed=140031;g.special_events.rng.seed=140031;g.gold_loot.death_rng.seed=140031;g.director.phase="complete"
 for actor in g.coop.actors.values():
  actor.player.dev_invulnerable=true;actor.weapon_system.rng.seed=140031
  actor.weapon_system.levels={"sludge":8,"holy_water":8,"clock":8,"lightning":8,"bombs":8,"orbit":8} if scenario>0 else {"sword":1}
  if scenario>0:
   for i in 24:actor.weapon_system.ground.add_pool("sludge" if i%2 else "holy_water",Vector2(680+i%8*35,560+int(i/8)*35),actor.player.position)
 if scenarios[scenario]=="king_225":
  g.special_events.start("king");g.enemies[0].take_damage(99999999);g.special_events.tick(.7)
  for e in g.enemies.duplicate():e.take_damage(99999999)
  g.special_events.tick(.7)
 elif scenarios[scenario]=="siege":g.special_events.start("siege")
 else:
  for i in (12 if scenario==0 else 225):
   var at:Vector2=g.free_enemy_position(Vector2(560+i%25*22,400+int(i/25)*23),6,null,160)
   if at!=Vector2.INF:g.spawn_enemy("ghoul",at)
 if scenarios[scenario]=="boss_necro":
  for i in 5:g.spawn_enemy("necromancer",Vector2(600+i*90,430))
  g.late_arena.begin_encounter("horror");g.campaign.cleared=true;g.campaign.endless=true;g.dev_boss_test=true
 if scenarios[scenario]=="infinite30":g.director.phase="active";g.director.debt=60
 var marker=FileAccess.open(OS.get_environment("HORDAS_BENCH_OUTPUT").path_join("benchmark14_"+label+".current"),FileAccess.WRITE);marker.store_string(scenarios[scenario]);marker.close()
 age=0;samples.clear();cpu.clear();sections.clear();peaks.clear();previous=Time.get_ticks_usec();ready_sample=true
func _process(_delta):
 if not ready_sample:return
 var now:int=Time.get_ticks_usec();var frame_ms:float=(now-previous)/1000.0;previous=now
 age+=frame_ms/1000
 if age>=2:
  samples.append(frame_ms)
  var vrid:RID=get_viewport().get_viewport_rid()
  for pair in [["render_cpu",RenderingServer.viewport_get_measured_render_time_cpu(vrid)],["render_gpu",RenderingServer.viewport_get_measured_render_time_gpu(vrid)]]:
   if not sections.has(pair[0]):sections[pair[0]]=[]
   sections[pair[0]].append(pair[1])
  var pools:int=0;var effects:int=g.numbers.size()+g.specials.areas.size();var shots:int=g.enemy_projectiles.arrows.size()+g.late_arena.patterns.shots.size()
  for actor in g.coop.actors.values():pools+=actor.weapon_system.ground.pools.size();effects+=actor.weapon_system.lightning_fx.size()+actor.weapon_system.beams.size();shots+=actor.weapon_system.projectiles.size()+actor.weapon_system.arsenal.shots.size()
  for pair in [["enemies",g.enemies.size()],["pools",pools],["projectiles",shots],["effects",effects],["crowd_pairs",g.get("crowd_pairs") if g.get("crowd_pairs")!=null else 0]]:peaks[pair[0]]=maxf(float(peaks.get(pair[0],0)),pair[1])
  for k in ["nodes","draw_calls","objects","memory_mb"]:
   var value:float=0
   match k:
    "nodes":value=Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
    "objects":value=Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
    "draw_calls":value=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
    "memory_mb":value=OS.get_static_memory_usage()/1048576.0
   peaks[k]=maxf(float(peaks.get(k,0)),value)
 if age>=12:
  ready_sample=false;samples.sort();cpu.sort()
  var data={"scenario":scenarios[scenario],"frames":samples.size(),"frame_ms":stats(samples),"simulation_ms":stats(cpu),"sections_ms":{},"peaks":peaks.duplicate(true),"enemies":g.enemies.size(),"projectiles":g.enemy_projectiles.arrows.size(),"xp":g.pickups.size(),"coins":g.gold_loot.coins.size(),"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000,"physics_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000}
  for k in sections:sections[k].sort();data.sections_ms[k]=stats(sections[k])
  results.append(data);print("SCENARIO14 ",JSON.stringify(data));await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png(OS.get_environment("HORDAS_BENCH_OUTPUT").path_join("benchmark14_"+label+"_"+scenarios[scenario]+".png"))
  call_deferred("next_scenario")
func _physics_process(delta):
 if not ready_sample:return
 for e in g.enemies:e.hp=1000000;e.max_hp=e.hp
 g.perf_us.clear()
 var t:int=Time.get_ticks_usec();g.coop.host_tick(delta,{"movement":Vector2.ZERO,"revive":false})
 if age>=2:
  cpu.append((Time.get_ticks_usec()-t)/1000.0)
  for k in g.perf_us:
   if not sections.has(k):sections[k]=[]
   sections[k].append(g.perf_us[k]/1000.0)
func stats(a:Array)->Dictionary:
 if a.is_empty():return {}
 return {"median":a[int(a.size()*.5)],"p95":a[mini(a.size()-1,int(a.size()*.95))],"p99":a[mini(a.size()-1,int(a.size()*.99))]}
