class_name HordeDirector
extends RefCounted
var game
var cooldown:float=2.5
var elite_spawned:bool=false
var boss_spawned:bool=false
var total_spawned:int=0
var skipped_spawns:int=0
var deferred:int=0
var rng:=RandomNumberGenerator.new()
var wave_index:int=-1
var phase:String="active"
var preparation_left:float=0
var queue:Array[Dictionary]=[]
var wave_spawned:int=0
var last_sector:int=0
var debt:float=0
var sector_last:Array=[-8,-7,-6,-5,-4,-3,-2,-1]
var sector_counts:Array=[0,0,0,0,0,0,0,0]
var blocked_reasons:Dictionary={}
var player_cursor:int=0
func setup(owner_game):game=owner_game;rng.randomize()
func reset():
 sector_last=[-8,-7,-6,-5,-4,-3,-2,-1];sector_counts=[0,0,0,0,0,0,0,0];blocked_reasons.clear();player_cursor=0
 cooldown=2.5;phase="active";queue.clear();debt=0;deferred=0;total_spawned=0;skipped_spawns=0;elite_spawned=false;boss_spawned=false;wave_index=-1
func composition()->Dictionary:
 var t:float=game.elapsed
 var weights:Dictionary={"ghoul":70,"hound":10}
 if t>=60:weights.skeleton_sword=15
 if t>=120:weights.skeleton_archer=10;weights.guard=7
 if t>=180:weights.slime_large=3;weights.devourer=2
 if t>=240:weights.necromancer=3;weights.plague=3;weights.shadow=2;weights.beast=2
 var extra:float=minf(2,game.horde_progress.stage()*.06)
 for id in weights:
  if id not in ["ghoul","hound","skeleton_sword","skeleton_archer"]:weights[id]*=1+extra
 var bases:Dictionary={}
 for id in game.variant_data:
  var v:Dictionary=game.variant_data[id]
  if t>=float(v.starts_at) and weights.has(v.base):
   if not bases.has(v.base):bases[v.base]=weights[v.base]
   var portion:float=float(bases[v.base])*float(v.share)
   weights[v.base]-=portion;weights[id]=portion
 return weights
func rate()->float:
 return game.balance.continuous_per_minute*(1+game.balance.continuous_stage_rate*game.horde_progress.stage())*game.enemy_scale().count
func draw_species()->String:
 var weights:Dictionary=composition();var total:float=0
 for weight in weights.values():total+=weight
 var chosen:float=rng.randf()*total
 for id in weights:
  chosen-=weights[id]
  if chosen<=0:return id
 return "ghoul"
func tick(delta:float):
 if phase=="complete" or phase=="boss":return
 if game.campaign.started.keys().any(func(id):return not game.campaign.completed.has(id)):return
 phase="active"
 if not game.dev_boss_test and not elite_spawned and game.elapsed>=game.boss_balance.executioner_arrival:
  if spawn("executioner"):elite_spawned=true
 cooldown=maxf(0,cooldown-delta)
 if cooldown>0:return
 debt+=rate()*delta/60
 var budget:int=4
 while debt>=1 and budget>0:
  if game.enemies.size()>=game.balance.max_enemies or not game.slime_families.pending.is_empty() or not game.special_events.pending.is_empty():deferred+=1;break
  if queue.is_empty():queue.append({"id":draw_species(),"elite":false})
  if not spawn(queue[0].id):deferred+=1;break
  queue.pop_front();debt-=1;budget-=1
func begin_wave():phase="active"
func spawn(id: String, elite: bool = false) -> bool:
 if game.enemies.size() >= game.balance.max_enemies:
  return false
 var view: Rect2 = game.camera_rect().grow(game.balance.spawn_margin)
 # Rotate through sectors. Jitter changes the precise entrance without
 # allowing every reinforcement to join the same single-file direction.
 var ordered:Array=range(8)
 ordered.sort_custom(func(a,b):return sector_last[a]<sector_last[b])
 var members: Array = game.team_players()
 if members.is_empty(): return false
 for attempt in 24:
  var sector: int = ordered[int(attempt/3)]
  var angle: float = sector * TAU / 8 + rng.randf_range(-0.22, 0.22)
  var anchor: Vector2 = members[(player_cursor+int(attempt/8))%members.size()].position
  var point: Vector2 = anchor + Vector2.from_angle(angle) * rng.randf_range(game.balance.spawn_distance_min, game.balance.spawn_distance_max)
  var reason:String=""
  if not game.hidden_spawn(point, game.balance.spawn_margin):reason="visible"
  elif not game.arena.safe_position(point,maxf(20,game.enemy_data[id].radius)):reason="terrain"
  elif not game.navigation.reachable(point,game.enemy_data[id].radius):reason="navigation"
  elif not game.enemy_space_free(point,game.enemy_data[id].radius):reason="body"
  if not reason.is_empty():
   var key:String=str(sector)+":"+reason;blocked_reasons[key]=int(blocked_reasons.get(key,0))+1;continue
  if game.spawn_enemy(id, point, elite)==null:return false
  total_spawned += 1
  sector_last[sector]=total_spawned;sector_counts[sector]+=1;player_cursor=(player_cursor+1)%members.size()
  last_sector = sector
  if id == "executioner":
   elite_spawned = true
   game.announce("CARRASCO", 3)
   game.sound.play_cue("elite")
  if id == "boss":
   boss_spawned = true
   game.announce("DEMÔNIO", 4)
   game.sound.play_cue("boss")
  return true
 skipped_spawns += 1
 return false

func pressure()->String:
 return "ENCONTRO EM ANDAMENTO" if phase=="boss" else "ESTÁGIO %d"%game.horde_progress.stage()
func wave_number()->int:return game.horde_progress.stage()
