extends Node
class Accepted extends RoomConnection:
 func send_message(_packet:Dictionary)->bool:return true
class Meter extends HordeDirector:
 func spawn(_id:String,_elite:bool=false)->bool:
  total_spawned+=1
  return true
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
 if mode=="cross25":
  var fixture=load("res://scripts/mobile/crossplay25_qa.gd").new();add_child(fixture);fixture.setup(game,request)
 elif mode=="balance251":balance_test()
 elif mode=="parity252":parity_test()
 elif mode=="updates026":updates_test(request)
 elif mode=="early026":early_test()
 elif mode=="inspect_apk":inspect_apk()
 elif mode=="network":network(request)
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
  var warm_until:int=Time.get_ticks_msec()+int(float(request.get("warmup_seconds",5))*1000)
  while Time.get_ticks_msec()<warm_until:await get_tree().process_frame
  game.mobile_performance.reset()
  var until:int=Time.get_ticks_msec()+int(float(request.get("sample_seconds",25) if map_id!="fields" else request.get("soak_seconds",180))*1000)
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

func balance_test():
 game.set_physics_process(false);game.start_run()
 check(OS.has_feature("android"),"native Android")
 check(is_equal_approx(game.director.rate(),90.0),"solo 90 enemies per minute")
 var meter=Meter.new();meter.setup(game);meter.cooldown=0
 for i in 3600:meter.tick(1.0/60)
 check(absi(meter.total_spawned-90)<=1,"real director debt produces 90 enemies in simulated minute")
 var species:int=0
 for id in EnemyCatalog.ids(game):
  var e=game.spawn_enemy(id,Vector2(1100,730));check(e!=null,id)
  if e==null:continue
  species+=1
  check(is_equal_approx(e.sprite.get_parent().scale.x,.8 if id=="ghoul" else 1.0),"smaller "+id)
  check(is_equal_approx(e.get_child(0).shape.radius,e.radius),"collision "+id)
  if e is Devourer:e.meals=3;e.growth_visual();check(is_equal_approx(e.sprite.get_parent().scale.x,.8 if id=="ghoul" else 1.0),"growth keeps visual multiplier")
  if e is HordeBoss:e.form=2;e.apply_visual_form();check(is_equal_approx(e.sprite.get_parent().scale.x,.8 if id=="ghoul" else 1.0),"boss phase keeps visual multiplier")
  game.clear_run();game.state="running"
 game.coop.active=true;game.coop.hosting=true
 var scales:Array=[]
 for count in [2,3,4]:
  game.coop.initial_size=count
  var scale:Dictionary=game.enemy_scale();scales.append(scale)
  check(is_equal_approx(scale.damage,1+(.7/3)*(count-1)),"cooperative damage")
  check(is_equal_approx(game.director.rate(),90*(1+(count-1)/3.0)),"online never receives solo reduction")
 game.coop.active=false
 game.state="running"
 var i:int=0
 for id in ["ghoul","shadow","executioner","devourer"]:
  var e=game.spawn_enemy(id,game.player.position+Vector2(-120+i*80,-35));i+=1
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("user://balance251.png")
 var result:Dictionary={"passed":failed==0,"failures":failed,"android_native":true,"species":species,"simulated_minute_spawns":meter.total_spawned,"solo_rate":90,"visual_multiplier":.8,"coop_scales":scales,"identity":GameCompatibility.identity()}
 var f=FileAccess.open("user://balance251-result.json",FileAccess.WRITE);f.store_string(JSON.stringify(result));f.close()
 print("ANDROID_BALANCE251_"+("PASS" if failed==0 else "FAIL")+" "+JSON.stringify(result))

func parity_test():
 var data:Dictionary=await load("res://scripts/diagnostics/combat_parity252.gd").capture(game)
 var visuals:Dictionary={"hero":game.player.sprite.get_parent().scale.x}
 check(is_equal_approx(float(visuals.hero),.8),"only hero visual reduced")
 for id in EnemyCatalog.ids(game):
  var e=game.spawn_enemy(id,Vector2(1100,730));check(e!=null,id)
  if e==null:continue
  visuals[id]=e.sprite.get_parent().scale.x
  check(is_equal_approx(float(visuals[id]),.8 if id=="ghoul" else 1.0),"selective size "+id)
  if e is Devourer:e.meals=3;e.growth_visual();check(e.sprite.get_parent().scale.x==1,"devourer size restored")
  if e is HordeBoss:e.form=2;e.apply_visual_form();check(e.sprite.get_parent().scale.x==1,"boss size restored")
  game.clear_run();game.state="running"
 var i:int=0
 for id in ["ghoul","skeleton_sword","hound","skeleton_archer","shadow"]:
  game.spawn_enemy(id,game.player.position+Vector2(-160+i*80,-40));i+=1
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("user://parity252.png")
 var result:Dictionary={"passed":failed==0,"failures":failed,"android_native":true,"identity":GameCompatibility.identity(),"combat":data,"visuals":visuals}
 var f=FileAccess.open("user://parity252-result.json",FileAccess.WRITE);f.store_string(JSON.stringify(result));f.close()
 print("ANDROID_PARITY252_"+("PASS" if failed==0 else "FAIL"))

func updates_test(request:Dictionary):
 var u=game.updates
 u.cancel()
 var cert:=X509Certificate.new();check(cert.load("user://test-ca.pem")==OK,"test certificate")
 u.endpoint="https://127.0.0.1:8443/stable.json";u.request.set_tls_options(TLSOptions.client(cert));u.check()
 while u.busy:await get_tree().process_frame
 check(u.available(),"detect newer APK")
 if not u.available():printerr("UPDATE_QA_ERROR "+u.status);return
 u.download()
 while u.busy:await get_tree().process_frame
 check(u.install_ready,"authenticated APK downloaded")
 if not u.install_ready:printerr("UPDATE_QA_ERROR "+u.status);return
 game.ui.render("updates");u.install();print("UPDATE_QA_INSTALL "+u.status)

func early_test():
 game.set_physics_process(false);game.start_run();game.mastery.begin(false);game.run_challenge=0
 var rows:Array=[]
 for t in [0,60,120,180,240,299]:
  for id in EarlyBalance.HEALTH:
   game.elapsed=t;game.state="running";game.weapon_system.reset();var e=game.spawn_enemy(id,Vector2(1100,730));var hp:float=e.hp;var hits:int=0
   while e.alive and hits<20:game.weapon_system._hit(e,game.weapon_system._stat("bolt","damage"),Vector2.ZERO);hits+=1
   check(hits==(3 if id in ["guard","orc_armored","skeleton_armored","slime_large"] else 2),id+" at "+str(t))
   rows.append({"id":id,"seconds":t,"hp":hp,"hits":hits});game.clear_run()
 var visuals:Dictionary={"hero":game.player.sprite.get_parent().scale.x}
 for id in EnemyCatalog.ids(game):
  game.elapsed=0;game.state="running";var e=game.spawn_enemy(id,Vector2(1100,730));visuals[id]=e.sprite.get_parent().scale.x;check(e.sprite.get_parent().scale==Vector2.ONE,"PC proportions "+id);game.clear_run()
 var f=FileAccess.open("user://early026.json",FileAccess.WRITE);f.store_string(JSON.stringify({"passed":failed==0,"rows":rows,"visuals":visuals,"identity":GameCompatibility.identity()}));f.close();print("EARLY_ANDROID026_"+("PASS" if failed==0 else "FAIL"))
 game.show_title()
func inspect_apk():
 var activity=Engine.get_singleton("AndroidRuntime").getActivity();var pm=activity.getPackageManager()
 var incoming=pm.getPackageArchiveInfo(OS.get_user_data_dir()+"/inspect.apk",64);var current=pm.getPackageInfo(activity.getPackageName(),64)
 var values:Dictionary={"incoming":NativeAndroidPackage.read(incoming),"current":NativeAndroidPackage.read(current),"installed":game.updates.installed()}
 if not values.incoming.is_empty() and not values.current.is_empty():
  var Objects=JavaClassWrapper.wrap("java.util.Objects")
  values.signatures_equal=Objects.deepEquals(values.incoming.certificates,values.current.certificates)
  check(values.signatures_equal,"original APK certificate matches installed signer")
  JavaClassWrapper.wrap("java.lang.reflect.Array").call("set",values.current.certificates,0,JavaClassWrapper.wrap("android.content.pm.Signature").Signature("00"))
  values.rejects_modified_signature=not Objects.deepEquals(values.incoming.certificates,values.current.certificates)
  check(values.rejects_modified_signature,"different APK certificate rejected")
  values.incoming.erase("certificates");values.current.erase("certificates")
 else:check(false,"native package fields available")
 values.passed=failed==0
 var f=FileAccess.open("user://apk-inspection.json",FileAccess.WRITE);f.store_string(JSON.stringify(values));f.close();print("APK_INSPECTION "+JSON.stringify(values));game.show_title()
