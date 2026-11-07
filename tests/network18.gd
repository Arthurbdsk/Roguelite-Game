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
 if name=="weapons16":
  for actor in g.coop.actors.values():
   check(actor.weapon_system.additions.shots.size()>0,"new projectiles replicated")
   for shot in actor.weapon_system.additions.shots:
    if shot.kind=="runetracer":check(shot.bounds.size==Vector2(640,360),"same immutable rune region on all clients")
 if name=="adjustments18":
  for actor in g.coop.actors.values():
   check(actor.player.hp==80,"host-authoritative independent attacker damage replicated")
   check(not actor.weapon_system.weapon_data.has("blades"),"retired weapon absent on every peer")
   if not hosting:check(not actor.player.take_damage(10,actor.player.position,9999),"client cannot authorize damage")
  check(GameFonts.primary_available(),"requested font embedded")
  check(g.music.get_child_count()==1,"one music player per process")
func scenario():
 await create_timer(.6).timeout
 var d=g.dev_tools;d.start_survival(false);g.director.phase="complete";g.special_events.next_check=100000;g.chests.next_check=100000;g.consumables.next_check=100000
 for actor in g.coop.actors.values():actor.weapon_system.levels={"garlic":8,"whip":8,"fire_wand":8,"runetracer":8,"magic_wand":8,"bolt":8};actor.weapon_system.attacks_enabled=true
 for i in 80:
  var e=g.spawn_enemy("ghoul",g.player.position+Vector2.from_angle(i*TAU/80)*(100+i%5*20))
  if e!=null:e.hp=1000000;e.max_hp=e.hp
 var cpu:Array=[]
 for frame in 120:
  await physics_frame
  var before:int=Time.get_ticks_usec();g.coop.host_tick(1.0/60,{"movement":Vector2.ZERO,"revive":false});cpu.append((Time.get_ticks_usec()-before)/1000.0)
  if frame%6==0:g.coop.broadcast_state(true);g.coop.flush_events()
 cpu.sort();print("NETWORK18_CPU median=",cpu[60]," p95=",cpu[114]," tx_bytes=",g.coop.connection.metrics.tx_bytes)
 await send("weapons16")
 for actor in g.coop.actors.values():
  var p=actor.player;p.dev_invulnerable=false;p.invulnerable=0;p.clear_status();p.hp=100;p.max_hp=100;p.armor=0;p.damage_reduction=0
  check(p.take_damage(5,p.position,18001) and p.take_damage(5,p.position,18002),"different attackers same host step")
  check(not p.take_damage(5,p.position,18001),"same attacker gate shared")
  p.tick_status(.4);check(p.take_damage(10,p.position,18001),"host gate expires at 400 ms")
 await send("adjustments18");d.end_test()
func finish():
 if done:return
 done=true;check(FileAccess.get_file_as_bytes(original.path)==original_bytes,"original save untouched")
 print("COOP_MATCH_PEER_", "PASS" if failures==0 else "FAIL"," index=",index," survival13 checks=",checks," failures=",failures)
 g.queue_free();await process_frame;await create_timer(.3,true,false,true).timeout;quit(0 if failures==0 else 1)
