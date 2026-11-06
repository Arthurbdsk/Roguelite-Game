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
  "food":
   var actor=g.coop.actors.values().filter(func(a):return a.display_name=="Peer1")[0]
   check(is_equal_approx(actor.player.hp,80),"food heals collector only and replicates health")
  "bag":check(g.gold==100,"one shared base award")
  "clock":check(g.consumables.freeze_left>9 and g.enemies.size()>0 and g.enemies[0].frozen_remaining>9,"clock synchronized with enemy state")
  "clean":check(g.enemies.is_empty() and g.slime_families.pending.is_empty(),"cleanse removes enemies without children")
  "floor":check(g.consumables.items.size()==1 and g.consumables.items[0].kind=="xp_magnet","ground item replicated")
  "xp":check(g.consumables.magnet_visual.is_empty() and g.pickups.is_empty(),"magnet batch completed without ghosts")
func scenario():
 await create_timer(.6).timeout
 var d=g.dev_tools;d.start_survival(false);g.director.phase="complete";g.special_events.next_check=1000000
 g.consumables.next_check=1000000;g.chests.next_check=1000000
 var c=g.consumables
 for actor in g.coop.actors.values():actor.mastery.ranks.luck=int(actor.display_name.right(1))
 check(is_equal_approx(c.chance(),.18),"shared consumable chance uses average luck, not sum")
 var other=g.coop.actors.values().filter(func(a):return a.display_name=="Peer1")[0]
 other.player.hp=50
 check(c.spawn_item("food",other.player.position),"host spawns food")
 var item=c.items[0]
 check(c.collect(item,other.player) and not c.collect(item,g.player),"competing collection pays once")
 g.coop.host_tick(.001,{"movement":Vector2.ZERO,"revive":false});await send("food")
 c.spawn_item("gold_bag",g.player.position);c.collect(c.items[0],g.player)
 for actor in g.coop.actors.values():check(actor.mastery.gold_bonus==5*int(actor.display_name.right(1))+5,"individual gold bonus applied once")
 await send("bag")
 var e=g.spawn_enemy("slime_large",g.player.position+Vector2(85,0))
 c.spawn_item("stopwatch",g.player.position);c.collect(c.items[0],g.player);e.tick(.001);await send("clock")
 c.spawn_item("cleanse",g.player.position);c.collect(c.items[0],g.player);await send("clean")
 g.pickups.clear()
 for i in 500:g.pickups.append({"id":10000+i,"at":g.player.position,"xp":.125,"attracted":false})
 c.spawn_item("xp_magnet",g.player.position+Vector2(100,0));await send("floor")
 var sum_before:float=0
 for actor in g.coop.actors.values():actor.xp_needed=999999;sum_before+=actor.xp
 d.active=false;c.collect(c.items[0],g.player)
 for i in 6:c.tick_magnet(100)
 var total:float=0
 for actor in g.coop.actors.values():total+=actor.xp
 d.active=true
 check(is_equal_approx(total-sum_before,250),"500 fractional crystals preserve full existing XP sharing for each player")
 check(c.magnet_jobs.is_empty(),"bounded batches finished")
 await send("xp");d.end_test()
func finish():
 if done:return
 done=true;check(FileAccess.get_file_as_bytes(original.path)==original_bytes,"original save untouched")
 print("COOP_MATCH_PEER_", "PASS" if failures==0 else "FAIL"," index=",index," survival13 checks=",checks," failures=",failures)
 g.queue_free();await process_frame;await create_timer(.3,true,false,true).timeout;quit(0 if failures==0 else 1)
