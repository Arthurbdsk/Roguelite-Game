class_name PermanentSkills
extends RefCounted

var game
var definitions: Array[SkillDefinition] = []
var by_id: Dictionary = {}
var last_error: String = ""

func setup(owner_game) -> void:
 game=owner_game
 definitions.clear();by_id.clear()
 for row in JSON.parse_string(FileAccess.get_file_as_string("res://data/permanent.json")):
  var d:=SkillDefinition.new();d.id=row.id;d.title=row.name;d.description=row.description;d.icon=row.icon
  d.costs=PackedInt32Array(row.costs)
  for i in int(row.cap):d.values.append(float(row.step)*(i+1))
  definitions.append(d);by_id[d.id]=d

func rank(id:String)->int:
 if not by_id.has(id):return 0
 return clampi(int(game.profile.data.upgrade_ranks.get(id,0)),0,by_id[id].max_rank())
func value(id:String)->float:
 return float(by_id[id].values[rank(id)-1]) if rank(id)>0 else 0.0
func state(id:String)->Dictionary:
 if not by_id.has(id):return {"can_buy":false,"cost":0,"status":"locked","reason":"Desconhecido"}
 var n:int=rank(id);var d:SkillDefinition=by_id[id]
 if n==d.max_rank():return {"can_buy":false,"cost":0,"status":"maxed","reason":"Nível máximo"}
 var cost:int=d.costs[n]
 return {"can_buy":game.profile.data.gold>=cost,"cost":cost,"status":"available" if game.profile.data.gold>=cost else "unaffordable","reason":"" if game.profile.data.gold>=cost else "Ouro insuficiente"}
func purchase(id:String,expected_rank:int=-1)->bool:
 last_error=""
 if game.state not in ["title","hub","tree"] or not state(id).can_buy:return false
 if expected_rank>=0 and rank(id)!=expected_rank:return false
 var before:Dictionary=game.profile.data.duplicate(true)
 var cost:int=state(id).cost
 game.profile.data.gold-=cost
 game.profile.data.upgrade_ranks[id]=rank(id)+1
 game.profile.data.upgrade_spent[id]=int(game.profile.data.upgrade_spent.get(id,0))+cost
 game.profile.data.upgrade_revision+=1
 if not game.profile.save():game.profile.data=before;last_error=game.profile.last_error;return false
 return true
func refund_total()->int:
 var total:int=0
 for amount in game.profile.data.upgrade_spent.values():total+=int(amount)
 return total
func refund(expected_revision:int)->bool:
 if game.state not in ["title","hub","tree"] or expected_revision!=int(game.profile.data.upgrade_revision) or refund_total()<=0:return false
 var before:Dictionary=game.profile.data.duplicate(true)
 game.profile.data.gold+=refund_total();game.profile.data.upgrade_ranks.clear();game.profile.data.upgrade_spent.clear();game.profile.data.challenge_active=0;game.profile.data.upgrade_revision+=1
 if not game.profile.save():game.profile.data=before;return false
 return true
func set_challenge(level:int)->bool:
 if game.state not in ["title","hub","tree"]:return false
 var before:int=int(game.profile.data.challenge_active)
 game.profile.data.challenge_active=clampi(level,0,rank("challenge"))
 if not game.profile.save():game.profile.data.challenge_active=before;return false
 return true
func effect(id:String,n:int)->String:
 var v:float=float(by_id[id].values[n-1]) if n>0 else 0.0
 if id=="regen":return "+%.1f vida/s"%v
 if id=="amount":return "+%d projétil"%int(v)
 if id=="revive":return "%d retorno por partida"%int(v)
 if id=="luck":return "Quarta opção: %.0f%% | Consumível: %.0f%%"%[v*100,15+n*2]
 return "%s%.0f%%"%["-" if id=="cooldown" else "+",v*100]
