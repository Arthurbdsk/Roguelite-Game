class_name GameProfile
extends RefCounted

const VERSION := 4
var path: String = "user://profile.json"
var data: Dictionary
var last_error: String = ""
var load_failed:bool=false

func _init(save_path: String = "user://profile.json") -> void:
 path = save_path
 data = defaults()

func defaults() -> Dictionary:
 return {"version": VERSION, "skill_ranks": {}, "upgrade_ranks": {}, "upgrade_spent": {}, "upgrade_revision": 0, "challenge_active": 0, "upgrades_migrated": true, "gold": 0, "gold_remainder": 0.0, "last_settled_run": "", "best_wave": 0, "seals": 0, "buildings": {"arsenal": false, "library": false}, "best_time": 0.0, "wins": 0, "runs": 0, "settings": {"volume": 0.55,"music":.35, "effects": 0.7, "shake": true, "fullscreen": false}}

func load_profile() -> bool:
 if not FileAccess.file_exists(path):
  return false
 load_failed=true
 var file := FileAccess.open(path, FileAccess.READ)
 if file == null:
  last_error = "Não foi possível ler o progresso."
  return false
 var parser := JSON.new()
 var content:String=file.get_as_text()
 file.close()
 if parser.parse(content) != OK:
  last_error = "Progresso inválido. Arquivo preservado."
  return false
 var parsed = parser.data
 if not parsed is Dictionary:
  last_error = "Progresso inválido. Arquivo preservado."
  return false
 var saved_version = parsed.get("version", 0)
 if not (saved_version is float or saved_version is int) or (saved_version != 1 and saved_version != 2 and saved_version != 3 and saved_version != VERSION):
  last_error = "Progresso inválido ou versão incompatível. Arquivo preservado."
  return false
 for key in ["seals", "best_time", "runs", "wins", "gold", "best_wave"]:
  if parsed.has(key) and not (parsed[key] is float or parsed[key] is int):
   last_error = "Progresso com campos inválidos. Arquivo preservado."
   return false
 if parsed.has("buildings") and not parsed.buildings is Dictionary:
  last_error = "Progresso com construções inválidas. Arquivo preservado."
  return false
 if parsed.has("settings") and not parsed.settings is Dictionary:
  last_error = "Preferências inválidas. Arquivo preservado."
  return false
 var check_options: Dictionary = parsed.get("settings", {})
 for key in ["volume", "effects","music"]:
  if check_options.has(key) and not (check_options[key] is float or check_options[key] is int):
   last_error = "Preferências com campos inválidos. Arquivo preservado."
   return false
 data = defaults()
 for key in parsed:
  if not data.has(key):data[key]=parsed[key]
 data.discoveries={}
 if parsed.get("discoveries",{}) is Dictionary:
  for id in parsed.get("discoveries",{}):
   if id is String and id.length()<=80 and parsed.discoveries[id]==true:data.discoveries[id]=true
 for key in ["upgrade_ranks","upgrade_spent"]:
  if parsed.has(key) and not parsed[key] is Dictionary:
   last_error="Aprimoramentos inválidos. Arquivo preservado.";return false
 data.seals = clampi(int(parsed.get("seals", 0)), 0, 999999)
 data.gold = clampi(int(parsed.get("gold", 0)), 0, 9999999999)
 data.gold_remainder=clampf(float(parsed.get("gold_remainder",0)),0,.999999) if parsed.get("gold_remainder",0) is float or parsed.get("gold_remainder",0) is int else 0.0
 var ranks = parsed.get("skill_ranks", {})
 if ranks is Dictionary:
  for id in ranks:
   if id is String and (ranks[id] is float or ranks[id] is int):
    data.skill_ranks[id] = clampi(int(ranks[id]), 0, 10)
 data.best_wave = clampi(int(parsed.get("best_wave", 0)), 0, 99999)
 data.last_settled_run = str(parsed.get("last_settled_run", "")) if parsed.get("last_settled_run", "") is String else ""
 data.best_time = clampf(float(parsed.get("best_time", 0)), 0, 100000)
 data.runs = clampi(int(parsed.get("runs", 0)), 0, 999999)
 data.wins = clampi(int(parsed.get("wins", 0)), 0, data.runs)
 var buildings = parsed.get("buildings", {})
 if buildings is Dictionary:
  for key in data.buildings:
   data.buildings[key] = buildings.get(key, false) == true
 var options = parsed.get("settings", {})
 if options is Dictionary:
  data.settings.volume = clampf(float(options.get("volume", 0.55)), 0, 1)
  data.settings.music = clampf(float(options.get("music",.35)),0,1)
  data.settings.effects = clampf(float(options.get("effects", 0.7)), 0, 1)
  data.settings.shake = options.get("shake", true) == true
  data.settings.fullscreen = options.get("fullscreen", false) == true
 load_failed=false
 if int(saved_version)<4:
  var backup:String=path+".pre_upgrades_v4.bak"
  if not FileAccess.file_exists(backup) and DirAccess.copy_absolute(path,backup)!=OK:
   load_failed=true;last_error="Falha no backup. Migração cancelada.";return false
  migrate_upgrades(parsed)
  if not save():load_failed=true;return false
 else:
  var catalog:Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/permanent.json"))
  for d in catalog:
   data.upgrade_ranks[d.id]=clampi(int(parsed.get("upgrade_ranks",{}).get(d.id,0)),0,int(d.cap))
   data.upgrade_spent[d.id]=maxi(0,int(parsed.get("upgrade_spent",{}).get(d.id,0)))
  data.upgrade_revision=maxi(0,int(parsed.get("upgrade_revision",0)))
  data.challenge_active=clampi(int(parsed.get("challenge_active",0)),0,int(data.upgrade_ranks.get("challenge",0)))

 return true

func save() -> bool:
 if load_failed:
  last_error="O save não foi carregado. Arquivo original preservado.";return false
 # Write new data first. Keep a readable previous version on replacement.
 var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
 if file == null:
  last_error = "Não foi possível salvar o progresso."
  return false
 file.store_string(JSON.stringify(data, "\t"))
 file.close()
 if FileAccess.file_exists(path):
  DirAccess.copy_absolute(path, path + ".bak")
 var result := DirAccess.rename_absolute(path + ".tmp", path)
 if result != OK:
  last_error = "Falha ao concluir o salvamento."
 return result == OK

func purchase(id: String) -> bool:
 if not data.buildings.has(id) or data.buildings[id] or data.seals < 8:
  return false
 data.seals -= 8
 data.buildings[id] = true
 return save()

func reward(seconds: float, kills: int, victory: bool, collected: int, run_gold: int = 0, run_id: String = "", wave: int = 0, run_fraction:float=-1) -> int:
 if not run_id.is_empty() and data.last_settled_run == run_id:
  return 0
 var total := floori(seconds / 30.0) + floori(kills / 30.0) + collected + (10 if victory else 0)
 data.seals += total
 data.gold += maxi(0, run_gold)
 if run_fraction>=0:data.gold_remainder=clampf(run_fraction,0,.999999)
 data.best_wave = maxi(data.best_wave, wave)
 data.last_settled_run = run_id
 data.runs += 1
 data.wins += int(victory)
 data.best_time = maxf(data.best_time, seconds)
 save()
 return total

func migrate_upgrades(parsed:Dictionary):
 var legacy:Resource=load("res://data/skills/catalog.tres")
 var mapping:Dictionary={"edge":["damage",[1,2]],"tempo":["cooldown",[2,5]],"vigor":["health",[3,5]],"stride":["move",[2,4]],"magnet":["pickup",[3,5]]}
 data.legacy_skill_ranks=data.skill_ranks.duplicate(true)
 var refunded:int=0
 for d in legacy.nodes:
  var n:int=clampi(int(data.legacy_skill_ranks.get(d.id,0)),0,d.max_rank())
  if n==0:continue
  var spent:int=0
  for i in n:spent+=d.costs[i]
  if parsed.get("skill_spent",{}) is Dictionary and parsed.get("skill_spent",{}).has(d.id):spent=maxi(0,int(parsed.skill_spent[d.id]))
  if mapping.has(d.id):
   var dest:String=mapping[d.id][0]
   data.upgrade_ranks[dest]=mapping[d.id][1][n-1];data.upgrade_spent[dest]=spent
  else:refunded+=spent
 data.gold+=refunded;data.migration_refund=refunded;data.skill_ranks.clear()
