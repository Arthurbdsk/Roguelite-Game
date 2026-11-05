extends Node2D
var game
var rng:=RandomNumberGenerator.new()
var config:Dictionary={"first":120.0,"interval":30.0,"chance":.21,"cooldown":90.0,"range":34.0,"gold_min":50,"gold_max":200}
var chest:Dictionary={}
var next_check:float=120
var last_spawn:float=-1000
var serial:int=0
var attempts:int=0
var generated:int=0
var opened:int=0
var received:Dictionary={}
var receipt:Dictionary={}
var receipt_left:float=0
var presentation:CanvasLayer
var result_label:Label
var texture=preload("res://assets/v13/chest.png")
func setup(owner_game):
 game=owner_game;config=game.survival_config.chests.duplicate(true);rng.randomize();z_index=2
 presentation=CanvasLayer.new();presentation.layer=25;add_child(presentation)
 result_label=Label.new();result_label.position=Vector2(170,64);result_label.size=Vector2(300,70);result_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;result_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 result_label.add_theme_font_override("font",GameFonts.interface_font());result_label.add_theme_font_size_override("font_size",12)
 var box:=StyleBoxFlat.new();box.bg_color=Color("142238");box.border_color=Color("bda05e");box.set_border_width_all(1);box.set_content_margin_all(8)
 result_label.add_theme_stylebox_override("normal",box);presentation.add_child(result_label);result_label.hide()
func reset():
 chest.clear();next_check=120;last_spawn=-1000;serial=0;attempts=0;generated=0;opened=0;received.clear();receipt.clear();receipt_left=0
 if is_instance_valid(result_label):result_label.hide()
 queue_redraw()
func spawn_chest()->bool:
 if not chest.is_empty() and not chest.get("opened",false):return false
 var players:Array=game.team_players()
 if players.is_empty():return false
 var center:Vector2=players[rng.randi_range(0,players.size()-1)].position
 for i in 150:
  var at:Vector2=center+Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(90,220)
  if not game.enemy_space_free(at,16) or game.players_near(at,45) or not game.navigation.reachable(at,12):continue
  serial+=1;generated+=1;last_spawn=game.elapsed;chest={"id":serial,"at":at,"opened":false,"age":0.0};queue_redraw();return true
 return false
func eligible(weapons)->Array:
 var result:Array=[]
 for id in weapons.levels:
  if int(weapons.levels[id])>0 and int(weapons.levels[id])<8:result.append(id)
 for id in weapons.passives:
  if int(weapons.passives[id])>0 and int(weapons.passives[id])<8:result.append(id)
 return result
func award(owner,base_gold:int)->Dictionary:
 var pool:Array=eligible(owner.weapon_system)
 var result:Dictionary={"chest":chest.id,"item":"","before":0,"after":0,"gold":base_gold,"icon":""}
 if not pool.is_empty():
  var id:String=pool[rng.randi_range(0,pool.size()-1)]
  var weapon:bool=owner.weapon_system.weapon_data.has(id)
  var data=owner.weapon_system.weapon_data[id] if weapon else owner.weapon_system.passive_data[id]
  result.item=data.display_name;result.icon=data.icon;result.before=int(owner.weapon_system.levels.get(id,0) if weapon else owner.weapon_system.passives.get(id,0))
  if owner.weapon_system.apply_upgrade(id):result.after=result.before+1
 var before:int=owner.mastery.gold_bonus;owner.mastery.on_gold(base_gold);result.gold+=owner.mastery.gold_bonus-before
 return result
func try_open(player)->bool:
 if game.state!="running" or chest.is_empty() or chest.opened or player.down or (game.coop.active and not game.coop.hosting):return false
 if player.position.distance_to(chest.at)>float(config.range):return false
 if game.coop.active:
  for actor in game.coop.actors.values():
   if actor.down and actor.player.position.distance_to(player.position)<=game.coop.rules.revive_range:return false
 chest.opened=true;chest.age=0;opened+=1
 var amount:int=rng.randi_range(int(config.gold_min),int(config.gold_max));game.gold+=amount
 if game.coop.active:
  for id in game.coop.actors:
   var actor=game.coop.actors[id];var result:Dictionary=award(actor,amount)
   if not actor.offers.is_empty():actor.generation+=1;actor.offers=actor.weapon_system.get_offers()
   if id==game.coop.connection.peer_id:show_receipt(result)
   else:game.coop.publish({"type":"reward_chest","data":result},id)
  game.coop.flush_events()
 else:
  var result:Dictionary=award(game,amount);game.gold+=int(result.gold)-amount;show_receipt(result)
 queue_redraw();return true
func show_receipt(result:Dictionary):
 if received.has(int(result.chest)):return
 received[int(result.chest)]=true;receipt=result;receipt_left=4
 result_label.text=("Todos os itens estão no nível máximo" if str(result.item).is_empty() else "%s | Nível %d → %d"%[result.item,result.before,result.after])+"\n+%d de ouro"%int(result.gold)
 result_label.show();game.sound.play_cue("gold")
func tick(delta:float):
 if game.state!="running":return
 visual_tick(delta)
 if not chest.is_empty():
  if chest.opened and chest.age>1:chest.clear()
 if game.elapsed>=next_check:
  next_check=(floorf(game.elapsed/float(config.interval))+1)*float(config.interval)
  if game.elapsed>=float(config.first) and game.elapsed-last_spawn>=float(config.cooldown) and chest.is_empty() and not game.special_events.blocked():
   attempts+=1
   if rng.randf()<float(config.chance):spawn_chest()
func visual_tick(delta:float):
 if not chest.is_empty():chest.age+=delta
 receipt_left=maxf(0,receipt_left-delta)
 if receipt_left<=0:result_label.hide()
 queue_redraw()
func _draw():
 if chest.is_empty():return
 var frame:int=mini(3,int(chest.age*7)) if chest.opened else 0
 draw_texture_rect_region(texture,Rect2(chest.at-Vector2(18,30),Vector2(36,36)),Rect2(frame*36,0,36,36))
 if not chest.opened:
  var distance:float=game.player.position.distance_to(chest.at)
  if distance<=float(config.range):draw_string(GameFonts.interface_font(),chest.at+Vector2(-25,-36),"E: Abrir",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("edd286"))
  if int(game.elapsed*2)%3==0:draw_rect(Rect2(chest.at+Vector2(12,-28),Vector2(2,2)),Color("edd286"))
