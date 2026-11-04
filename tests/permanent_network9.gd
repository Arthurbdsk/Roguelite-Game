extends SceneTree
var g
var index:int=0
var hosting:bool=false
var code_file:String=""
var started:bool=false
var failures:int=0
var done:bool=false
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
 if not ok:failures+=1;printerr("FAIL ",index," ",message)
func run():
 var code:String=""
 for a in OS.get_cmdline_user_args():
  if a=="--host":hosting=true
  if a.begins_with("--index="):index=int(a.trim_prefix("--index="))
  if a.begins_with("--code-file="):code_file=a.trim_prefix("--code-file=")
  if a.begins_with("--room="):code=a.trim_prefix("--room=")
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.sound.volume=0
 g.profile.data=g.profile.defaults();g.profile.data.upgrade_ranks={"damage":index+1,"experience":index+1,"gold":index+1,"revive":1,"challenge":3 if hosting else 5}
 g.profile.data.challenge_active=2 if hosting else 5
 g.profile.data.gold_remainder=.75
 g.coop.connection.message_received.connect(receive)
 g.coop.connection.connection_failed.connect(func(reason):check(false,reason);finish())
 g.coop.connect_room(hosting,"Peer%d"%index,code)
 await create_timer(30).timeout
 if not done:check(false,"timeout");finish()
func receive(p:Dictionary):
 match p.get("type",""):
  "joined":
   if hosting:
    var file=FileAccess.open(code_file,FileAccess.WRITE);file.store_string(p.code);file.close()
  "lobby":
   if p.players.size()==4:
    check(int(p.challenge)==2,"shared challenge from host only")
    var ready:bool=true
    for member in p.players:
     ready=ready and member.ready
     if member.id==g.coop.connection.peer_id and not member.ready:g.coop.connection.send_message({"type":"ready","ready":true})
    if hosting and ready and not started:started=true;g.coop.connection.send_message({"type":"start"})
  "start":
   check(g.coop.actors.size()==4 and g.run_challenge==2,"four actors and challenge snapshot")
   check(is_equal_approx(g.coop.actors[g.coop.connection.peer_id].mastery.damage_multiplier,1+.05*(index+1)),"own bonus not host bonus")
   if hosting:g.director.phase="complete";scenario.call_deferred()
  "events":
   for e in p.data:
    if e.get("type","")=="fixture":command(e.command)
func send(command_name:String):g.coop.publish({"type":"fixture","command":command_name});g.coop.flush_events()
func command(name:String):
 if name=="verify":
  check(int(g.coop.received_personal.get("gold_bonus",-1))==index+1,"individual gold fraction")
  check(g.player.down,"all players down while return available")
  if index==1:g.coop.request_self_revive()
 if name=="returned":
  var b
  for actor in g.coop.actors.values():
   if actor.display_name=="Peer1":b=actor
  check(b!=null and not b.player.down,"host-validated remote return replicated")
  if index==1:check(not g.coop.received_personal.get("revive_available",true),"return consumed once")
 if name=="finish":
  check(g.state=="result","result received")
  check(g.profile.data.gold==20+index+1,"own gold bonus banked exactly once")
  var loaded:=GameProfile.new(g.profile.path);check(loaded.load_profile() and loaded.data.gold==20+index+1,"reloaded persisted reward")
  check(is_equal_approx(loaded.data.gold_remainder,.75),"fraction preserved between sessions")
  finish()
func scenario():
 g.gold=20
 for i in 20:g.coop.on_gold(1)
 for id in g.coop.actors:g.coop.mark_down(id)
 await create_timer(.5).timeout;send("verify")
 await create_timer(.6).timeout
 var b
 for actor in g.coop.actors.values():
  if actor.display_name=="Peer1":b=actor
 check(b!=null and not b.down and b.mastery.last_stand_spent,"remote self revive used once on host")
 send("returned");await create_timer(.3).timeout
 g.coop.finish(false);await create_timer(.2).timeout;send("finish")
 check(g.profile.data.gold==21,"host gold paid individually")
 await create_timer(.3).timeout;finish()
func finish():
 if done:return
 done=true;print("COOP_MATCH_PEER_", "PASS" if failures==0 else "FAIL"," index=",index," permanent9 failures=",failures)
 g.queue_free();await process_frame;await create_timer(.3).timeout;quit(0 if failures==0 else 1)
