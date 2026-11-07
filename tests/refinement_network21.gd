extends SceneTree
var g
var hosting:bool=false
var index:int=0
var code_file:String=""
var started:bool=false
var failures:int=0
var done:bool=false
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 if not ok:failures+=1;printerr("FAIL "+label)
func run():
 var code:String=""
 for arg in OS.get_cmdline_user_args():
  if arg=="--host":hosting=true
  if arg.begins_with("--index="):index=int(arg.trim_prefix("--index="))
  if arg.begins_with("--code-file="):code_file=arg.trim_prefix("--code-file=" )
  if arg.begins_with("--room="):code=arg.trim_prefix("--room=")
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false
 g.coop.connection.message_received.connect(receive);g.coop.connection.connection_failed.connect(func(reason):check(false,reason);finish.call_deferred())
 g.coop.connect_room(hosting,"PC%d"%index,code)
 get_tree_timeout()
func get_tree_timeout():
 await create_timer(120).timeout
 if not done:check(false,"network fixture timeout");finish()
func _process(delta:float):
 if g!=null and g.coop!=null and g.coop.active and not hosting:g.coop.tick(delta,Vector2.ZERO)
 return false
func receive(packet:Dictionary):
 match packet.get("type",""):
  "joined":
   if hosting:var f=FileAccess.open(code_file,FileAccess.WRITE);f.store_string(packet.code);f.close()
  "lobby":
   var ready:bool=packet.players.size()==4
   if ready:
    for p in packet.players:
     ready=ready and p.ready
     if p.id==g.coop.connection.peer_id and not p.ready:g.coop.connection.send_message({"type":"ready","ready":true})
   if hosting and ready and not started:started=true;g.coop.connection.send_message({"type":"start"})
  "start":
   check(g.coop.actors.size()==4,"four real contexts")
   if hosting:scenario.call_deferred()
  "events":
   for event in packet.data:
    if event.get("type","")=="fixture21":inspect_state(event)
  "error":check(false,packet.reason);finish.call_deferred()
func step(seconds:float):
 for i in int(seconds*60):await physics_frame;g.coop.host_tick(1.0/60,{"movement":Vector2.ZERO,"revive":false});g.coop.flush_events()
func inspect_state(event:Dictionary):
 if event.command=="load":g.arena.apply_map(event.map);return
 if event.command=="death":
  check(g.character_remains.seen.has(int(event.id)),"real network death received once")
  var found:bool=false
  for fx in g.character_remains.effects:
   if int(fx.id)==int(event.id):found=true;check(Vector2(fx.at).distance_to(CoopWire.vector(event.at))<.01,"death remains at host physical position")
  check(found,"death animation present when event is received");return
 if event.command=="done":finish.call_deferred();return
 check(g.arena.map_id==event.map,"same map")
 for id in ["orc_armored","orc_elite","skeleton_armored"]:check(g.enemies.any(func(e):return e.data.id==id),"variant replicated "+id)
 for actor in g.coop.actors.values():
  check(actor.weapon_system.levels.size()==6,"six weapons per owner")
  var center:Vector2=actor.player.position.clamp(Vector2(320,180),Vector2(1480,1020))
  for shot in actor.weapon_system.additions.shots:
   if shot.kind=="runetracer":check(Rect2(shot.bounds).get_center().distance_to(center)<3,"owner camera bounds, independent of local window")
 check(g.horde_progress.resistance()==0,"time resistance remains removed")
 print("REFINEMENT21_CLIENT_STATE index=",index," map=",event.map," failures=",failures)
func scenario():
 g.director.phase="complete";g.dev_boss_test=true;g.special_events.next_check=100000;g.chests.next_check=100000;g.consumables.next_check=100000
 for map_id in ["courtyard","library","fields"]:
  for e in g.enemies:e.queue_free()
  g.enemies.clear();await process_frame;g.rebuild_grid();g.arena.apply_map(map_id)
  g.coop.publish({"type":"fixture21","command":"load","map":map_id});g.coop.flush_events()
  var n:int=0
  for actor in g.coop.actors.values():
   actor.player.dev_invulnerable=true;actor.player.position=Vector2(850+n*60,610+n*18);actor.weapon_system.reset();actor.weapon_system.levels={"bolt":8,"runetracer":8,"garlic":8,"holy_water":8,"lightning":8,"clock":8};actor.weapon_system.passives={"lens":8,"cadence":8,"boots":8,"crown":8};n+=1
  for id in ["orc_armored","orc_elite","skeleton_armored"]:
   var e=g.spawn_enemy(id,g.free_enemy_position(Vector2(970+n*15,740),8));e.hp=100000;e.max_hp=e.hp;n+=1
  for i in 50:
   var e=g.spawn_enemy("ghoul",g.free_enemy_position(Vector2(650+i%10*22,480+int(i/10)*22),8));e.hp=100000;e.max_hp=e.hp
  await step(3)
  # Move another owner while its runes exist; all clients use that owner's bounds.
  g.coop.actors.values()[1].player.position+=Vector2(45,0);await step(1)
  g.coop.broadcast_state(true);g.coop.flush_events();await step(.7)
  g.coop.publish({"type":"fixture21","command":"check","map":map_id});g.coop.flush_events();await step(1)
  var victim=g.enemies.filter(func(e):return e.data.id=="ghoul")[0];var at:Vector2=victim.position;var serial:int=victim.serial;victim.take_damage(100000000)
  g.coop.publish({"type":"fixture21","command":"death","id":serial,"at":at});g.coop.flush_events();await step(.7)
 g.coop.publish({"type":"fixture21","command":"done"});g.coop.flush_events();await step(1.5);finish()
func finish():
 if done:return
 done=true;print("COOP_MATCH_PEER_PASS refinement21 index=",index," failures=",failures) if failures==0 else printerr("COOP_MATCH_PEER_FAIL refinement21 index=",index)
 g.queue_free();await process_frame;await create_timer(.2).timeout;quit(int(failures>0))
