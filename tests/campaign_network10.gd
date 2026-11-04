extends SceneTree
var g
var index:int=0
var hosting:bool=false
var code_file:String=""
var started:bool=false
var failures:int=0
var checks:int=0
var done:bool=false
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
 g.profile.data=g.profile.defaults()
 g.coop.connection.message_received.connect(receive)
 g.coop.connection.connection_failed.connect(func(reason):check(false,reason);finish())
 g.coop.connect_room(hosting,"Peer%d"%index,code)
 await create_timer(40).timeout
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
    if hosting and ready and not started:started=true;g.coop.connection.send_message({"type":"start"})
  "start":
   check(g.coop.actors.size()==4,"four separate player contexts")
   if hosting:g.set_physics_process(false);scenario.call_deferred()
  "events":
   for e in p.data:
    if e.get("type","")=="fixture":command(e.command)
func send(name:String):
 g.coop.broadcast_state(true)
 await create_timer(.3).timeout
 g.coop.publish({"type":"fixture","command":name});g.coop.flush_events()
 await create_timer(.3).timeout
func command(name:String):
 match name:
  "continued":check(g.state=="running" and g.gold==120 and g.elapsed==760,"demon reward once, clock and match continue")
  "guardian":
   check(g.boss is LateBoss and g.boss.data.id=="guardian","guardian replica")
   check(is_equal_approx(g.boss.max_hp,g.boss_balance.demon_health()*5*1.6*.8*2.5),"guardian health scaled once")
   check(g.late_arena.shots.size()==12 and g.late_arena.shots[0].stop is Vector2,"feather stops decoded as vector")
   check(g.late_arena.shots[0].at.distance_to(g.late_arena.shots[0].stop)<1,"feather visibly stopped during warning")
  "wall":
   check(g.boss.data.id=="horror" and g.boss.form==1,"horror replica")
   check(is_equal_approx(g.boss.max_hp,g.boss_balance.demon_health()*5*1.6*2.2*2.5),"horror health scaled once")
   check(g.arena.dynamic_walls.size()==4,"solid segmented wall replicated")
   check(g.boss.locked_target is Vector2,"locked dash target decoded")
  "chain":
   check(g.enemies.filter(func(e):return e.data.id=="necromancer").size()==20,"twenty initial necromancers replicated")
   check(g.specials.marks.size()==192,"sixteen complete batches reserved within 220 budget")
  "true":
   check(g.boss.form==2 and g.boss.state=="transform" and not g.boss.targetable,"True Form transition replicated")
   check(is_equal_approx(g.boss.max_hp,g.boss_balance.demon_health()*5*1.6*2.2*2.5*1.5),"True Form multiplies current max HP only")
   check(g.arena.dynamic_walls.is_empty() and g.specials.marks.is_empty() and g.late_arena.shots.is_empty(),"owned hazards and wall collision cleared")
   check(g.gold==210 and g.state=="running","no early final reward or victory")
  "finish":
   check(g.state=="result" and g.coop.ended,"final victory settled")
   check(g.profile.data.gold==510,"final reward received once by each player")
   var loaded:=GameProfile.new(g.profile.path);check(loaded.load_profile() and loaded.data.gold==510,"own balance persisted")
   g.coop.settle({});check(g.profile.data.gold==510,"repeat result cannot duplicate gold")
   finish()
func scenario():
 for actor in g.coop.actors.values():
  actor.weapon_system.levels.clear();actor.player.invulnerable=1000
 g.director.phase="complete";g.elapsed=760
 g.campaign.tick();g.boss_arena.tick(4)
 var demon=g.boss;demon.take_damage(999999);demon.tick(2);demon.take_damage(999999);g.boss_arena.tick(2)
 check(g.campaign.completed.has("demon") and g.state=="running","host demon continues")
 await send("continued")
 g.elapsed=900;g.campaign.tick();g.late_arena.tick(1.3)
 var guardian=g.boss;guardian.locked_target=g.player.position;g.late_arena.cast("feathers",guardian);g.late_arena.tick(.6)
 await send("guardian")
 guardian.take_damage(999999);g.late_arena.tick(2)
 check(g.campaign.completed.has("guardian") and g.gold==210,"guardian reward once and continuation")
 g.elapsed=1200;g.campaign.tick();g.late_arena.tick(1.3)
 var horror=g.boss;horror.locked_target=g.player.position;horror.charge_direction=Vector2.LEFT
 check(g.late_arena.cast("ice",horror),"safe wall planned for four players")
 g.late_arena.tick(1.6)
 await send("wall")
 g.late_arena.clear_attacks(horror)
 check(g.late_arena.cast("summon",horror),"twenty seed marks accepted")
 g.late_arena.tick(1.3)
 for enemy in g.enemies.duplicate():
  if enemy.data.id=="necromancer":enemy.tick(.01)
 check(g.specials.marks.size()==192 and g.late_arena.chain.deferred()==48,"budget defers four complete batches")
 await send("chain")
 horror.take_damage(999999)
 check(g.late_arena.chain.count(horror.serial)==0,"transition removes owned descendants")
 await send("true")
 horror.tick(1.7);horror.take_damage(999999);horror.take_damage(999999);g.late_arena.tick(2)
 check(g.campaign.completed.has("horror") and g.state=="result" and g.profile.data.gold==510,"host final settlement once")
 await send("finish")
 finish()
func finish():
 if done:return
 done=true;print("COOP_MATCH_PEER_", "PASS" if failures==0 else "FAIL"," index=",index," campaign10 checks=",checks," failures=",failures)
 g.queue_free();await process_frame;await create_timer(.3).timeout;quit(0 if failures==0 else 1)
