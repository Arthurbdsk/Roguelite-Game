extends SceneTree
var g
var hosting:bool=false
var index:int=0
var code_file:String=""
var started:bool=false
var done:bool=false
var failures:int=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 if not ok:failures+=1;printerr("FAIL "+label)
func run():
 var room:String=""
 for arg in OS.get_cmdline_user_args():
  if arg=="--host":hosting=true
  if arg.begins_with("--index="):index=int(arg.trim_prefix("--index="))
  if arg.begins_with("--code-file="):code_file=arg.trim_prefix("--code-file=")
  if arg.begins_with("--room="):room=arg.trim_prefix("--room=" )
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.persistence_enabled=false;g.test_mode=false;g.sound.volume=0
 g.profile.path="user://mobile_cross_pc_fixture_%d.json"%index;g.profile.data=g.profile.defaults()
 if hosting:g.set_physics_process(false)
 g.coop.connection.message_received.connect(receive)
 g.coop.connection.connection_failed.connect(func(reason):if not done:check(false,reason);finish())
 g.coop.connect_room(hosting,"PC%d"%index,room)
 for i in 1800:
  await create_timer(.1).timeout
  if not hosting and started and g.state=="result":finish();return
  if done:return
 check(false,"mixed match timeout");finish()
func receive(packet:Dictionary):
 match packet.get("type",""):
  "joined":
   if hosting:
    var f=FileAccess.open(code_file,FileAccess.WRITE);f.store_string(packet.code);f.close()
  "lobby":
   var ready:bool=packet.players.size()==4
   for member in packet.players:
    ready=ready and member.ready
    if member.id==g.coop.connection.peer_id and not member.ready:g.coop.connection.send_message({"type":"ready","ready":true})
   if hosting and ready and not started:g.coop.connection.send_message({"type":"start"})
  "start":
   started=true
   if hosting:scenario.call_deferred()
func step(seconds:float):
 for frame in int(seconds*60):
  await physics_frame;g.coop.host_tick(1.0/60,{"movement":Vector2.ZERO,"revive":false});g.coop.flush_events()
func send(command:String):
 g.coop.broadcast_state(true);g.coop.flush_events();await step(.5)
 g.coop.publish({"type":"mobile_fixture","command":command});g.coop.flush_events();await step(.5)
func scenario():
 check(g.coop.actors.size()==4,"four mixed-platform actors")
 g.director.phase="complete";g.special_events.next_check=100000;g.chests.next_check=100000;g.consumables.next_check=100000
 var android:String="";var fallen:String=""
 for actor in g.coop.actors.values():
  actor.player.dev_invulnerable=true;actor.weapon_system.attacks_enabled=false
  if actor.display_name=="Android":android=actor.id
  elif actor.display_name=="PC1":fallen=actor.id
 check(not android.is_empty() and not fallen.is_empty(),"Android and PC identities")
 if android.is_empty() or fallen.is_empty():finish();return
 for i in 80:
  var e=g.spawn_enemy("ghoul",Vector2(600+i%20*26,460+int(i/20)*28))
  if e!=null:e.hp=100000;e.max_hp=e.hp
 await step(3);await send("check")
 var mobile=g.coop.actors[android];mobile.award_xp(6);await send("choose");await step(2)
 check(mobile.level==2 and mobile.offers.is_empty(),"Android individual upgrade accepted by PC host")
 g.coop.actors[fallen].player.position=Vector2(924,630);mobile.player.position=Vector2(900,630);g.coop.mark_down(fallen)
 g.coop.broadcast_state(true);g.coop.flush_events();await step(1)
 print("MOBILE_REVIVE_READY");await step(9)
 check(not g.coop.actors[fallen].down,"real Android held touch revives PC ally")
 for actor in g.coop.actors.values():
  actor.weapon_system.levels={"garlic":8,"whip":8,"fire_wand":8,"runetracer":8,"magic_wand":8,"holy_water":8};actor.weapon_system.passives={"lens":8,"hourglass":8,"cadence":8,"boots":8};actor.weapon_system.attacks_enabled=true
 await send("reset_metrics");await step(12);await send("weapons_check")
 await send("pause_menu");check(g.state=="running","mobile menu does not pause PC session")
 print("MOBILE_BACKGROUND_READY");await step(5)
 check(g.coop.actors.size()==3 and g.state=="running","Android background disconnect leaves three PCs running")
 g.coop.finish(false);g.coop.flush_events();await create_timer(.7).timeout;finish()
func finish():
 if done:return
 done=true;print("MOBILE_CROSS_PC_"+("PASS" if failures==0 else "FAIL")+" index="+str(index)+" failures="+str(failures))
 g.queue_free();await process_frame;await create_timer(.3).timeout;quit(int(failures>0))
