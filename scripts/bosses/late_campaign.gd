class_name LateCampaign
extends RefCounted
var game
var config:Dictionary={}
var started:Dictionary={}
var completed:Dictionary={}
var history:Array[String]=[]
var cleared:bool=false
var endless:bool=false
var deciding:bool=false
var votes:Dictionary={}
var decision_left:float=30
func setup(owner_game):
 game=owner_game
 config=JSON.parse_string(FileAccess.get_file_as_string("res://data/late_campaign.json"))
func reset():started.clear();completed.clear();history.clear();cleared=false;endless=false;deciding=false;votes.clear();decision_left=30
func tick():
 if game.dev_boss_test or game.state!="running":return
 if game.enemies.any(func(e):return e is HordeBoss and e.alive) or not game.boss_arena.deaths.is_empty():return
 for encounter in config.encounters:
  if completed.has(encounter.id):continue
  if started.has(encounter.id) or game.elapsed<float(encounter.at):return
  if not game.enemy_data.has(encounter.id):return
  if encounter.id=="demon":
   if not game.boss_arena.begin_portal():return
  elif not game.late_arena.begin_encounter(encounter.id):return
  started[encounter.id]=true;history.append(encounter.id)
  game.director.queue.clear();game.director.phase="boss"
  return
func encounter_finished(id:String):
 if completed.has(id):return
 completed[id]=true;started[id]=true
 if game.dev_boss_test:game.finish_run(true);return
 if id=="horror":offer_endless();return
 game.director.phase="preparing";game.director.preparation_left=game.balance.preparation_seconds
 game.announce("ENCONTRO CONCLUÍDO",3)
func wave(index:int)->WaveData:
 # Historical catalog retained for editor tools only. Runtime spawns use time.
 return game.balance.waves[clampi(index,0,8)]

func remember_clear():
 if cleared:return
 cleared=true
 if game.persistence_enabled and not game.dev_boss_test:
  game.profile.data.campaign_cleared=true;game.profile.save()
 if game.coop.active and game.coop.hosting:game.coop.publish({"type":"campaign_won"});game.coop.flush_events()
func offer_endless():
 remember_clear();deciding=true;votes.clear();decision_left=30;game.state="endless_choice"
 game.ui.render("endless_choice")
 if game.coop.active and game.coop.hosting:game.coop.publish({"type":"endless_offer"});game.coop.flush_events()
func vote(continue_run:bool):
 if not deciding:return
 if not game.coop.active:resolve(continue_run);return
 if game.coop.hosting:accept_vote(game.coop.connection.peer_id,continue_run)
 else:game.coop.connection.send_message({"type":"action","data":{"endless_vote":continue_run}})
func accept_vote(id:String,answer:bool):
 if not deciding or not game.coop.hosting or not game.coop.actors.has(id) or votes.has(id):return
 votes[id]=answer
 if not answer:resolve(false);return
 check_votes()
func check_votes():
 if not deciding or not game.coop.hosting:return
 if game.coop.actors.is_empty():resolve(false);return
 for id in game.coop.actors:
  if not votes.get(id,false):return
 resolve(true)
func decision_tick(delta:float):
 if not deciding or (game.coop.active and not game.coop.hosting):return
 decision_left-=delta
 if decision_left<=0:resolve(false)
func resolve(continue_run:bool):
 if not deciding:return
 deciding=false
 if continue_run:
  endless=true;game.state="running";game.director.phase="active";game.ui.render("running")
  if game.coop.active:game.coop.publish({"type":"endless_continue"});game.coop.flush_events()
 else:
  game.state="running";game.finish_run(true)
