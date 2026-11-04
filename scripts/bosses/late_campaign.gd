class_name LateCampaign
extends RefCounted
var game
var config:Dictionary={}
var started:Dictionary={}
var completed:Dictionary={}
var history:Array[String]=[]
func setup(owner_game):
 game=owner_game
 config=JSON.parse_string(FileAccess.get_file_as_string("res://data/late_campaign.json"))
func reset():started.clear();completed.clear();history.clear()
func tick():
 if game.dev_boss_test or game.state!="running":return
 if game.enemies.any(func(e):return e is HordeBoss and e.alive) or not game.boss_arena.deaths.is_empty():return
 for encounter in config.encounters:
  if completed.has(encounter.id):continue
  if started.has(encounter.id) or game.elapsed<float(encounter.at):return
  if not game.enemy_data.has(encounter.id):return
  if encounter.id=="demon":game.boss_arena.begin_portal()
  elif not game.late_arena.begin_encounter(encounter.id):return
  started[encounter.id]=true;history.append(encounter.id)
  game.director.queue.clear();game.director.phase="boss"
  return
func encounter_finished(id:String):
 if completed.has(id):return
 completed[id]=true;started[id]=true
 if game.dev_boss_test:game.finish_run(true);return
 if id=="horror":game.finish_run(true);return
 game.director.phase="preparing";game.director.preparation_left=game.balance.preparation_seconds
 game.announce("ENCONTRO CONCLUÍDO | AS HORDAS CONTINUAM",3)
func wave(index:int)->WaveData:
 if index<9:return game.balance.waves[maxi(0,index)]
 var w:WaveData=game.balance.waves[8].duplicate(true)
 w.title="Horda %d"%(index+1);w.boss=false
 var factor:float=1+.08*mini(10,index-8)
 for id in w.composition:w.composition[id]=roundi(w.composition[id]*factor)
 return w
