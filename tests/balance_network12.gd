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
 original=g.profile;original.data=original.defaults();original.data.gold=1234+index;original.data.upgrade_ranks={"damage":index+1};original.save();original_bytes=FileAccess.get_file_as_bytes(original.path)
 check(g.dev_tools!=null and g.dev_tools.enter(),"development mode available")
 g.dev_tools.build={"level":20+index,"weapons":{["sword","axe","bombs","clock"][index]:8},"passives":{"heart":index+1},"permanent":true,"invulnerable":true,"attacks":false}
 g.coop.connection.message_received.connect(receive)
 g.coop.connection.connection_failed.connect(func(reason):if not done:check(false,reason);finish())
 g.coop.connect_room(hosting,"Peer%d"%index,code)
 for i in 200:
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
  "started":
   check(g.ui.pressure_text.text=="TESTE DEV","development HUD pressure replicated")
   check(g.arena.map_id=="library" and g.boss.data.id=="horror" and g.boss.form==1,"shared encounter/map")
   check(is_equal_approx(g.boss.max_hp,82368),"shared scale applied once")
   check(g.weapon_system.levels.has(["sword","axe","bombs","clock"][index]) and g.level==20+index,"own prepared build")
   if index==1:
    check(not g.dev_tools.start_encounter() and not g.dev_tools.force_attack("fire") and not g.dev_tools.next_phase(),"client cannot control encounter")
    g.dev_tools.set_time(2);check(Engine.time_scale==1,"client cannot alter room time")
    g.dev_tools.request({"kind":"start","encounter":"executioner"})
    g.dev_tools.set_player_flag("invulnerable",false)
  "heal":
   if index==1:g.dev_tools.heal()
  "orbs":
   var p=g.late_arena.patterns;check(p.jobs.size()==1 and p.jobs[0].orbs.size()==6 and p.shots.size()>0 and p.shots.size()<=6,"six orbs and first real volley replicated")
   check(p.jobs[0].orbs[0].locked_target is Vector2 and p.jobs[0].lanes[0].end is Vector2,"fixed targets and safe routes decoded")
  "crystals":check(g.enemies.filter(func(e):return e.data.id=="ice_crystal").size()==6,"six destructible attack objects replicated")
  "crystal_broken":check(g.enemies.filter(func(e):return e.data.id=="ice_crystal").size()==5,"host-authorized destruction replicated once")
  "resistance":check(g.horde_progress.completed==2 and is_equal_approx(g.horde_progress.resistance(),.05) and is_equal_approx(g.boss.max_hp,82403),"completed horde resistance and absolute health replicated once")
  "wall":check(g.arena.dynamic_walls.size()==4,"solid wall replicated")
  "summons":check(g.boss.dev_summons_alive==20 and g.enemies.filter(func(e):return e.data.id=="necromancer").size()==20,"live summons counter replicated")
  "true":
   check(g.boss.form==2 and not g.boss.targetable and g.arena.dynamic_walls.is_empty(),"real transformation and cleanup replicated")
   check(is_equal_approx(g.boss.max_hp,123552),"transformation does not reapply multiplayer")
  "restart":
   check(g.boss.form==1 and is_equal_approx(g.boss.max_hp,82368),"restart resets phase and HP")
   check(g.arena.dynamic_walls.is_empty() and g.enemies.size()==1,"restart removes old entities")
   check(g.weapon_system.levels.has(["sword","axe","bombs","clock"][index]),"restart preserves individual configuration")
  "time":check(Engine.time_scale==.5,"host time synchronized")
func scenario():
 await create_timer(.5).timeout
 var dev=g.dev_tools;check(dev.online_builds.size()==4,"four private builds submitted")
 for actor in g.coop.actors.values():
  var n:int=int(actor.display_name.trim_prefix("Peer"));check(is_equal_approx(actor.mastery.damage_multiplier,1+.05*(n+1)),"own permanent ranks on host")
 dev.map_id="library";dev.encounter="horror";dev.participants=4;check(dev.start_encounter(),"host starts")
 await send("started");check(g.boss.data.id=="horror","forged remote command rejected")
 var remote
 for actor in g.coop.actors.values():
  if actor.display_name=="Peer1":remote=actor
 check(not remote.player.dev_invulnerable and g.coop.actors[g.coop.connection.peer_id].player.dev_invulnerable,"own flags do not change another player")
 remote.player.hp=1;await send("heal");check(remote.player.hp==remote.player.max_hp,"remote heal validated on host")
 var patterns=g.late_arena.patterns
 check(dev.force_attack("orbs"),"host orb command");g.boss.state="chase";g.boss.attack_time=0;g.boss.tick(.01);g.boss.tick(1.3);patterns.tick(1.36)
 await send("orbs")
 g.late_arena.clear_attacks(g.boss);patterns.tick(.7);check(dev.force_attack("crystals"),"host crystal command");g.boss.state="chase";g.boss.attack_time=0;g.boss.tick(.01);g.boss.tick(1.3);patterns.tick(1.4)
 await send("crystals")
 var target=g.enemies.filter(func(e):return e is HazardTarget)[0];target.take_damage(99999)
 await send("crystal_broken")
 g.late_arena.clear_attacks(g.boss);patterns.tick(.7)
 check(dev.force_attack("ice"),"real ice command")
 g.boss.state="chase";g.boss.attack_time=0;g.boss.tick(.01);g.boss.tick(1.3);g.late_arena.tick(1.6)
 await send("wall")
 g.late_arena.clear_attacks(g.boss);g.boss.state="chase";g.boss.attack_time=0;dev.force_attack("summon");g.boss.tick(.01);g.boss.tick(1.3);g.late_arena.tick(1.3)
 check(g.late_arena.chain.count(g.boss.serial)==20,"real twenty-necromancer summon")
 await send("summons");check(dev.next_phase(),"advance with real damage transition")
 await send("true");check(dev.start_encounter(),"host restart")
 await send("restart");g.horde_progress.complete(0);g.horde_progress.complete(1);await send("resistance");dev.set_time(.5);await send("time")
 dev.end_test()
func finish():
 if done:return
 done=true;check(FileAccess.get_file_as_bytes(original.path)==original_bytes,"no test rewards written")
 print("COOP_MATCH_PEER_", "PASS" if failures==0 else "FAIL"," index=",index," balance12 checks=",checks," failures=",failures)
 g.queue_free();await process_frame;await create_timer(.3,true,false,true).timeout;quit(0 if failures==0 else 1)
