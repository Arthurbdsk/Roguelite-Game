extends Node
# Exported only in the isolated QA APK; desktop peers load this external fixture.
var game
var request:Dictionary={}
var hosting:bool=false
var started:bool=false
var done:bool=false
var failures:int=0
var background_requested:bool=false
var index:int=0
func check(ok:bool,label:String):
 if not ok:failures+=1;printerr("CROSS25_FAIL "+label)
func setup(owner,options:Dictionary):
 game=owner;request=options;hosting=bool(request.get("host",false));index=int(request.get("index",0))
 game.set_physics_process(false);game.persistence_enabled=true
 game.profile=GameProfile.new("user://cross25_"+str(request.get("session","qa")).validate_filename()+"_"+str(index)+".json");game.profile.data.gold=200;game.profile.save();game.skills.setup(game);game.mastery.setup(game);game.sound.volume=0
 game.coop.connection.endpoint=request.get("relay","wss://hordas-relay.onrender.com")
 game.coop.connection.message_received.connect(receive);game.coop.connection.connection_failed.connect(func(reason):check(false,reason);finish.call_deferred())
 game.coop.connect_room(hosting,request.get("name","Android"),request.get("room",""))
 timeout()
func timeout():
 await get_tree().create_timer(180).timeout
 if not done:check(false,"fixture timeout");finish()
func _process(delta:float):
 if game==null or done:return
 if game.coop.active and not hosting:
  var movement:Vector2=game.mobile.movement(Vector2.ZERO) if game.get("mobile")!=null and game.mobile.active else Vector2.ZERO
  game.coop.tick(delta,movement)
 if background_requested and not game.coop.active and game.get("mobile")!=null and not game.mobile_backgrounded:
  check(game.profile.data.runs==1 and game.profile.data.gold==219,"background settlement once");finish()
func receive(packet:Dictionary):
 match packet.get("type",""):
  "joined":
   if hosting:
    var path:String=request.get("code_file","user://cross25-room.json");var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify({"room":packet.code}));f.close();print("CROSS25_ROOM ",packet.code)
  "lobby":
   var ready:bool=packet.players.size()==4
   for player in packet.players:
    if player.id==game.coop.connection.peer_id and not player.ready:game.coop.connection.send_message({"type":"ready","ready":true})
    ready=ready and player.ready
   if hosting and ready and not started:started=true;game.coop.connection.send_message({"type":"start"})
  "start":
   check(game.coop.actors.size()==4,"four mixed-platform contexts")
   if hosting:scenario.call_deferred()
  "events":
   for event in packet.data:
    if event.get("type","")=="fixture25":command(event)
    elif event.get("type","")=="end":final_check.call_deferred()
  "error":check(false,str(packet.reason));finish.call_deferred()
func send(which:String,data:Dictionary={}):
 var packet:Dictionary={"type":"fixture25","command":which};packet.merge(data);game.coop.publish(packet);game.coop.flush_events()
func step(seconds:float):
 for i in ceili(seconds*60):
  await get_tree().physics_frame
  game.coop.host_tick(1.0/60,game.coop.local_action(Vector2.ZERO));game.coop.flush_events()
func inspect_world(map_id:String):
 check(game.arena.map_id==map_id,"same replicated map")
 for id in ["shadow","executioner"]:
  var enemies:Array=game.enemies.filter(func(e):return e.data.id==id)
  check(not enemies.is_empty(),"new design replicated "+id)
  if not enemies.is_empty():check(enemies[0].tiny_kind=="original_"+id and enemies[0].sprite.hframes==(32 if id=="shadow" else 36),"same animation atlas "+id)
 for actor in game.coop.actors.values():check(actor.weapon_system.levels.size()==6,"six weapons per owner")
 check(game.profile.bestiary_counts("shadow").seen>0,"host confirmed bestiary discovery")
 print("CROSS25_WORLD_PASS index=",index," map=",map_id," actors=",game.coop.actors.size())
func command(event:Dictionary):
 match event.command:
  "map":game.arena.apply_map(event.map)
  "world":inspect_world(event.map)
  "stats":check(game.profile.bestiary_counts(event.species).kills==(1 if event.owner==game.coop.connection.peer_id else 0),"owner final blow without duplication "+event.species)
  "choose":
   var choices:Array=game.coop.actors[game.coop.connection.peer_id].offers if hosting else game.coop.received_personal.get("offers",[])
   check(not choices.is_empty(),"personal level choice")
   if not choices.is_empty():game.coop.choose(choices[0].id)
  "touch":print("CROSS25_TOUCH_READY")
  "revived":check(not game.coop.actors[event.target].down and game.coop.actors[event.target].player.hp==40,"host-confirmed held-touch revive")
  "background":
   if game.coop.connection.peer_id==event.target:background_requested=true
   print("CROSS25_BACKGROUND_READY")
func scenario():
 game.director.phase="complete";game.dev_boss_test=false;game.special_events.next_check=100000;game.chests.next_check=100000;game.consumables.next_check=100000;game.balance.gold_drop_chance=0
 var android_id:String=""
 for actor in game.coop.actors.values():
  actor.player.dev_invulnerable=true
  if actor.display_name=="Android":android_id=actor.id
 check(not android_id.is_empty(),"real Android participant identified")
 for map_id in ["courtyard","library","fields"]:
  for e in game.enemies.duplicate():game.despawn_enemy(e)
  game.boss_arena.reset();game.late_arena.reset();game.specials.reset();game.slime_families.reset();game.boss=null;game.gold_loot.reset();game.pickups.clear();await get_tree().process_frame;game.rebuild_grid();game.arena.apply_map(map_id);send("map",{"map":map_id})
  var n:int=0
  for actor in game.coop.actors.values():
   actor.player.position=Vector2(870+n*30,630);actor.weapon_system.reset();actor.weapon_system.levels={"bolt":8,"axe":8,"magic_wand":8,"fire_wand":8,"holy_water":8,"runetracer":8};actor.weapon_system.passives={"lens":8,"cadence":8,"boots":8,"crown":8};n+=1
  for id in ["shadow","executioner","plague","devourer","guard","necromancer","beast","skeleton_archer","orc_armored","slime_small"]:
   var e=game.spawn_enemy(id,Vector2(1000+(n%4)*25,590+int(n/4)*25));check(e!=null,"fixture spawn "+id)
   if e!=null:e.hp=1000000;e.max_hp=e.hp
   n+=1
  for i in 40:
   var e=game.spawn_enemy("ghoul",Vector2(700+i%10*22,500+int(i/10)*24));check(e!=null,"fixture common spawn")
   if e!=null:e.hp=1000000;e.max_hp=e.hp
  await step(2.5);game.coop.broadcast_state(true);await step(.5);inspect_world(map_id);send("world",{"map":map_id});await step(.5)
  var species:String="plague" if map_id=="courtyard" else "devourer" if map_id=="library" else "guard"
  var victim=game.enemies.filter(func(e):return e.data.id==species)[0];game.coop.actors[android_id].weapon_system._hit(victim,1e9,Vector2.ZERO)
  await step(.5);send("stats",{"species":species,"owner":android_id});await step(.3)
 for actor in game.coop.actors.values():actor.weapon_system.attacks_enabled=false;actor.weapon_system.clear_attacks()
 game.coop.share_xp(6);await step(.7);send("choose");command({"command":"choose"});await step(.8)
 for actor in game.coop.actors.values():check(actor.offers.is_empty() and actor.level>=2,"individual choice accepted")
 var target_id:String=""
 for id in game.coop.actors:
  if id!=android_id:target_id=id;break
 game.coop.actors[target_id].player.position=game.coop.actors[android_id].player.position+Vector2(15,0);game.coop.mark_down(target_id);await step(.7)
 send("touch",{"target":target_id});print("CROSS25_TOUCH_READY");await step(8)
 check(not game.coop.actors[target_id].down and game.coop.actors[target_id].player.hp==40,"real Android held touch revives PC")
 send("revived",{"target":target_id});await step(.5)
 var demon=game.spawn_enemy("demon",Vector2(1100,730));game.coop.actors[android_id].weapon_system._hit(demon,1e9,Vector2.ZERO)
 check(game.bestiary.totals.get(android_id,{}).get("demon",{}).get("kills",0)==0,"boss transformation not final kill")
 await step(2);game.coop.actors[android_id].weapon_system._hit(demon,1e9,Vector2.ZERO);await step(.7);send("stats",{"species":"demon","owner":android_id});await step(.5)
 game.gold_loot.reset();game.pickups.clear();game.gold=19;game.coop.broadcast_state(true);await step(.6)
 if bool(request.get("background",false)):
  send("background",{"target":android_id});print("CROSS25_BACKGROUND_READY");var before:float=game.elapsed;await step(4)
  check(game.coop.actors.size()==3 and game.elapsed>before+3,"Android client background does not pause remaining PCs")
 game.coop.finish(false);await get_tree().process_frame;final_check()
func final_check():
 if done:return
 check(game.profile.data.gold==219 and game.profile.data.runs==1,"individual reward settles once")
 var loaded:=GameProfile.new(game.profile.path);check(loaded.load_profile() and loaded.data.gold==219,"stats/reward persisted in isolated local profile")
 game.coop.settle({"won":false,"gold":19,"elapsed":0,"kills":0,"earned":0,"wave":0});check(game.profile.data.gold==219 and game.profile.data.runs==1,"duplicate end cannot pay twice")
 finish()
func finish():
 if done:return
 done=true;var result:Dictionary={"passed":failures==0,"failures":failures,"host":hosting,"android":OS.has_feature("android"),"identity":GameCompatibility.identity(),"gold":game.profile.data.gold,"runs":game.profile.data.runs,"bestiary":game.profile.data.bestiary_stats}
 var f=FileAccess.open("user://cross25-result.json",FileAccess.WRITE);f.store_string(JSON.stringify(result));f.close()
 print("CROSS25_PEER_", "PASS" if failures==0 else "FAIL"," index=",index," ",JSON.stringify(result));await get_tree().create_timer(1).timeout;get_tree().quit(int(failures>0))
