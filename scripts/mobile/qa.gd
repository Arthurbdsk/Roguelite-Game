extends Node
class Accepted extends RoomConnection:
 func send_message(_packet:Dictionary)->bool:return true
var game
var mode:String="load"
var failed:int=0
func check(ok:bool,message:String):
 if not ok:failed+=1;printerr("ANDROID_QA_FAIL "+message)
func setup(owner):
 game=owner;game.persistence_enabled=false
 check(OS.has_feature("mobile_qa"),"QA feature required")
 check(game.dev_tools==null and not game.development_build(),"no DEV panel in Android")
 check(not ResourceLoader.exists("res://scripts/dev/boss_lab.gd"),"no DEV resources")
 var request:Dictionary={}
 if FileAccess.file_exists("user://qa_request.json"):request=JSON.parse_string(FileAccess.get_file_as_string("user://qa_request.json"))
 mode=request.get("mode","load")
 print("ANDROID_QA_READY "+JSON.stringify({"mode":mode,"user_dir":OS.get_user_data_dir(),"compatibility":ProjectSettings.get_setting("network/compatible_game_version")}))
 if mode=="network":network(request)
 else:load_test(request)
func load_test(request:Dictionary):
 game.start_run();game.coop.connection.queue_free();game.coop.connection=Accepted.new();game.coop.add_child(game.coop.connection);game.coop.connection.peer_id="a";game.coop.connection.host_id="a";game.coop.hosting=true
 game.coop.begin({"run":"mobile-qa-load","players":[{"id":"a","name":"A","skills":{}},{"id":"b","name":"B","skills":{}},{"id":"c","name":"C","skills":{}},{"id":"d","name":"D","skills":{}}]})
 game.dev_boss_test=true;game.campaign.cleared=true;game.campaign.endless=true;game.director.phase="complete";game.special_events.next_check=100000;game.chests.next_check=100000;game.consumables.next_check=100000
 var results:Array=[]
 for map_id in ["courtyard","library","fields"]:
  for e in game.enemies:e.queue_free()
  game.enemies.clear();await get_tree().physics_frame;game.rebuild_grid();game.arena.apply_map(map_id)
  var actor_index:int=0
  for actor in game.coop.actors.values():
   actor.weapon_system.reset();actor.weapon_system.rng.seed=18001+actor_index;actor_index+=1;actor.player.dev_invulnerable=true
   actor.weapon_system.levels={"garlic":8,"whip":8,"fire_wand":8,"runetracer":8,"magic_wand":8,"holy_water":8}
   actor.weapon_system.passives={"lens":8,"hourglass":8,"cadence":8,"boots":8}
  seed(18018)
  for i in 200:
   var at:Vector2=game.free_enemy_position(Vector2(650+i%20*25,470+int(i/20)*27),8)
   if at!=Vector2.INF:
    var e=game.spawn_enemy("ghoul",at)
    if e!=null:e.hp=1000000;e.max_hp=e.hp
  check(game.enemies.size()==200,"exact benchmark enemy count "+map_id)
  var warm_until:int=Time.get_ticks_msec()+5000
  while Time.get_ticks_msec()<warm_until:await get_tree().process_frame
  game.mobile_performance.reset()
  var until:int=Time.get_ticks_msec()+int(25000 if map_id!="fields" else float(request.get("soak_seconds",180))*1000)
  while Time.get_ticks_msec()<until:await get_tree().process_frame
  var report:Dictionary=game.mobile_performance.report();report.map=map_id;results.append(report);print("ANDROID_QA_MAP "+JSON.stringify(report))
 var data:Dictionary={"passed":failed==0,"failures":failed,"engine":Engine.get_version_info().string,"scenario":"Seed18018, 200 enemies, four simulated actors, six weapons8, four passives8, default mobile visuals. Emulator only.","results":results}
 var file=FileAccess.open("user://qa_result.json",FileAccess.WRITE);file.store_string(JSON.stringify(data));file.close()
 print("ANDROID_QA_LOAD_"+("PASS" if failed==0 else "FAIL")+" "+JSON.stringify(data))
 game.coop.leave();game.show_title()
func network(request:Dictionary):
 game.coop.connection.endpoint=request.get("relay","wss://hordas-relay.onrender.com")
 game.coop.connection.message_received.connect(receive)
 game.coop.connection.connection_failed.connect(func(reason):printerr("ANDROID_QA_NETWORK_ERROR "+reason))
 game.coop.connect_room(false,"Android",request.room)
func receive(packet:Dictionary):
 if packet.get("type","")=="lobby":
  for p in packet.players:
   if p.id==game.coop.connection.peer_id and not p.ready:game.coop.connection.send_message({"type":"ready","ready":true})
 if packet.get("type","")=="start":print("ANDROID_QA_NETWORK_STARTED players=",game.coop.actors.size())
 if packet.get("type","")=="events":
  for event in packet.data:
   if event.get("type","")!="mobile_fixture":continue
   match event.command:
    "check":
     check(game.coop.actors.size()==4,"four mixed-platform peers")
     check(game.enemies.size()>0,"host enemies replicated")
     check(game.player.tiny_soldier,"Soldier visual")
     check(game.coop.connection.last_snapshot_ms>0,"binary snapshots received")
     check(game.state=="running" and game.mobile.active,"real Android running")
     print("ANDROID_QA_NETWORK_"+("PASS" if failed==0 else "FAIL")+" "+JSON.stringify({"actors":game.coop.actors.size(),"enemies":game.enemies.size(),"network":game.coop.connection.metrics}))
    "choose":
     var choices:Array=game.coop.received_personal.get("offers",[])
     check(not choices.is_empty(),"individual level choice received")
     if not choices.is_empty():game.coop.choose(choices[0].id)
    "reset_metrics":game.mobile_performance.reset()
    "weapons_check":
     check(game.weapon_system.levels.size()==6,"six local weapons from frozen PC host")
     var shots:int=0
     for actor in game.coop.actors.values():shots+=actor.weapon_system.additions.shots.size()
     check(shots>0,"real weapon projectiles replicated")
     print("ANDROID_QA_WEAPONS_"+("PASS" if failed==0 else "FAIL")+" "+JSON.stringify({"shots":shots,"performance":game.mobile_performance.report()}))
    "pause_menu":
     game.toggle_pause();check(game.coop.menu_open and game.state=="running","individual menu preserves online simulation");game.coop.close_menu()
    "hold_revive":game.mobile.revive_held=true;release_revive_later()
    "background":game.mobile_suspend(true);print("ANDROID_QA_BACKGROUND_LEFT")
func release_revive_later():
 await get_tree().create_timer(6.5).timeout;game.mobile.revive_held=false
