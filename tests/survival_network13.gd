extends SceneTree
var g
var index:int=0
var hosting:bool=false
var code_file:String=""
var started:bool=false
var failures:int=0
var checks:int=0
var done:bool=false
var original:GameProfile
var original_bytes:PackedByteArray
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL ",index," ",message)
func run():
 var code:String=""
 for a in OS.get_cmdline_user_args():
  if a=="--host":hosting=true
  if a.begins_with("--index="):index=int(a.trim_prefix("--index="))
  if a.begins_with("--code-file="):code_file=a.trim_prefix("--code-file=")
  if a.begins_with("--room="):code=a.trim_prefix("--room=")
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.sound.volume=0
 original=g.profile;original.data=original.defaults();original.data.gold=1234+index;original.data.upgrade_ranks={"damage":index+1,"gold":index+1};original.save();original_bytes=FileAccess.get_file_as_bytes(original.path)
 check(g.dev_tools!=null and g.dev_tools.enter(),"development mode available")
 g.dev_tools.build={"level":20+index,"weapons":{["sword","axe","bombs","clock"][index]:7},"passives":{"heart":8},"permanent":true,"invulnerable":true,"attacks":false}
 g.coop.connection.message_received.connect(receive)
 g.coop.connection.connection_failed.connect(func(reason):if not done:check(false,reason);finish())
 g.coop.connect_room(hosting,"Peer%d"%index,code)
 for i in 500:
  await create_timer(.1).timeout
  if not g.dev_tools.active and started:
   check(g.profile==original and FileAccess.get_file_as_bytes(original.path)==original_bytes,"original profile and file restored exactly")
   check(g.state=="title" and Engine.time_scale==1,"exit returns menu and restores time")
   finish();return
 if not done:check(false,"timeout");finish()
func receive(p:Dictionary):
 match p.get("type",""):
  "joined":
   if hosting:
    var file=FileAccess.open(code_file,FileAccess.WRITE);file.store_string(p.code);file.close()
  "lobby":
   if p.players.size()==4:
    var ready:bool=true
    for member in p.players:
     ready=ready and member.ready
     if member.id==g.coop.connection.peer_id and not member.ready:g.coop.connection.send_message({"type":"ready","ready":true})
    if hosting and ready and not started:g.coop.connection.send_message({"type":"start"})
  "start":
   started=true;check(g.state=="dev_preparing" and not g.persistence_enabled,"development preparation does not run normal campaign")
   if hosting:g.set_physics_process(false);scenario.call_deferred()
  "events":
   for e in p.data:
    if e.get("type","")=="fixture":command(e.command)
func send(name:String):
 g.coop.broadcast_state(true);await create_timer(.3).timeout
 g.coop.publish({"type":"fixture","command":name});g.coop.flush_events();await create_timer(.3).timeout
func command(name:String):
 match name:
  "chest":
   check(g.weapon_system.levels[["sword","axe","bombs","clock"][index]]==8,"own equipped item upgraded once")
   check(g.gold==100 and int(g.chests.receipt.get("gold",0))==100+5*(index+1),"shared base gold and individual bonus")
   check(g.chests.receipt.get("after",0)==8 and g.chests.receipt.get("before",0)==7,"private receipt")
  "blue":check(g.enemies.filter(func(e):return e.data.id=="event_blue").size()==15,"fifteen blue children replicated")
  "small":
   check(g.enemies.filter(func(e):return e.data.id=="event_small").size()==225,"225 small descendants replicated")
   check(g.horde_progress.stage()==3 and is_equal_approx(g.horde_progress.resistance(),.15),"time stage replicated")
  "moving":
   var overlap:int=0
   for a in g.enemies:
    for b in g.enemies:
     if a.serial<b.serial and a.position.distance_to(b.position)<a.radius+b.radius-.7:overlap+=1
   check(overlap==0,"replicas converge without persistent visual body overlap")
  "siege":check(g.enemies.filter(func(e):return e.data.id=="siege_archer").size()==20,"twenty siege archers replicated")
  "expired":check(g.enemies.is_empty() and g.enemy_projectiles.arrows.is_empty(),"siege expires without leftovers")
  "choice":
   check(g.state=="endless_choice" and g.campaign.cleared,"post-campaign choice shown to every peer")
   if index==3:g.dev_tools.end_test()
   elif index>0:g.campaign.vote(true)
  "continued":check(g.state=="running" and g.campaign.endless and g.elapsed>=1230 and g.weapon_system.levels[["sword","axe","bombs","clock"][index]]==8,"unanimous remaining participants continue, same time/build")
func scenario():
 await create_timer(.6).timeout
 var d=g.dev_tools;d.map_id="fields";d.start_survival(false);d.set_survival_time(360);g.special_events.next_check=1000000
 var c=g.chests;c.config.gold_min=100;c.config.gold_max=100;check(c.spawn_chest(),"spawn real chest")
 var local=g.coop.actors[g.coop.connection.peer_id];local.player.position=c.chest.at
 var other
 for actor in g.coop.actors.values():
  if actor.display_name=="Peer1":other=actor
 other.player.position=local.player.position+Vector2(15,0);other.down=true;other.player.down=true
 check(not c.try_open(local.player),"fallen ally has priority over chest")
 other.down=false;other.player.down=false;other.player.position+=Vector2(60,0)
 check(c.try_open(local.player) and not c.try_open(local.player),"host validates one opening")
 g.coop.host_tick(.001,{"movement":Vector2.ZERO,"revive":false});await send("chest")
 var ev=g.special_events;check(ev.start("king"),"king event starts")
 var king=g.enemies.filter(func(e):return e.data.id=="slime_king")[0];king.take_damage(999999);ev.tick(.7);await send("blue")
 for e in g.enemies.duplicate():e.take_damage(999999)
 ev.tick(.7);await send("small")
 g.director.phase="complete"
 var cpu:Array=[];var start:int=Time.get_ticks_usec()
 for frame in 180:
  await physics_frame
  var before:int=Time.get_ticks_usec();g.coop.host_tick(1.0/60,{"movement":Vector2.ZERO,"revive":false});cpu.append((Time.get_ticks_usec()-before)/1000.0)
  if frame%6==0:g.coop.broadcast_state(true);g.coop.flush_events()
 cpu.sort();print("NETWORK_COLLISION13 225 moving bodies frames180 wall_s=",(Time.get_ticks_usec()-start)/1000000.0," cpu_median_ms=",cpu[90]," p95=",cpu[171])
 var overlap:int=0
 for a in g.enemies:
  for b in g.enemies:
   if a.serial<b.serial and a.position.distance_to(b.position)<a.radius+b.radius-.7:overlap+=1
 print("MOVING_OVERLAPS ",overlap)
 check(overlap==0,"moving family has no persistent body overlaps")
 await send("moving")
 for e in g.enemies.duplicate():e.take_damage(999999)
 ev.tick(.1);g.pickups.clear();g.gold_loot.reset();g.rebuild_grid()
 check(ev.start("siege"),"siege event starts")
 for e in g.enemies:e.tick(3);e.tick(1)
 await send("siege");ev.tick(45);ev.tick(.4);await send("expired")
 g.elapsed=1230;g.campaign.completed={"demon":true,"guardian":true,"horror":true};g.campaign.offer_endless();await send("choice")
 g.campaign.vote(true)
 for i in 30:
  if g.campaign.endless:break
  await create_timer(.1).timeout
 check(g.campaign.endless and g.coop.actors.size()==3,"disconnect removed from unanimity and did not stall vote")
 await send("continued");d.end_test()
func finish():
 if done:return
 done=true;check(FileAccess.get_file_as_bytes(original.path)==original_bytes,"original save untouched")
 print("COOP_MATCH_PEER_", "PASS" if failures==0 else "FAIL"," index=",index," survival13 checks=",checks," failures=",failures)
 g.queue_free();await process_frame;await create_timer(.3,true,false,true).timeout;quit(0 if failures==0 else 1)
