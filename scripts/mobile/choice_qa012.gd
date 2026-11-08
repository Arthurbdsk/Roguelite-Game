extends Node
class Accepted extends RoomConnection:
 var choices:Array=[]
 func send_message(packet:Dictionary)->bool:
  if packet.get("type","")=="action" and packet.get("data",{}).has("choice"):choices.append(packet.data)
  return true
var game
var context:String
var phase:String="joystick"
var initial:int
var started:int=0
var clock:float=0
var release_armed:bool=false
var passed:bool=true
var connection:Accepted
func total()->int:
 var value:int=0
 for n in game.weapon_system.levels.values():value+=int(n)
 for n in game.weapon_system.passives.values():value+=int(n)
 return value
func setup(owner,request:Dictionary):
 game=owner;context=request.context;game.persistence_enabled=false;game.set_physics_process(false);game.sound.volume=0;game.updates.cancel();game.mobile.cancel_contacts()
 if context=="solo":game.start_run()
 else:
  game.coop.connection.queue_free();connection=Accepted.new();game.coop.connection=connection;game.coop.add_child(connection);connection.peer_id="a";connection.host_id="a";game.coop.hosting=true
  game.coop.begin({"run":"choice012-"+context,"players":[{"id":"a","name":"A","skills":{}},{"id":"b","name":"B","skills":{}},{"id":"c","name":"C","skills":{}},{"id":"d","name":"D","skills":{}}]})
 initial=total();started=Time.get_ticks_msec()
func _process(delta):
 clock-=delta
 if clock>0:return
 clock=.04
 if phase=="joystick" and game.mobile.joystick_finger>=0:
  if context=="solo":game.add_xp(game.xp_needed)
  else:
   var actor=game.coop.actors.a;actor.award_xp(actor.xp_needed)
   if context=="client":game.coop.received_personal=actor.personal();game.coop.hosting=false
   game.coop.open_upgrades()
  phase="held";started=Time.get_ticks_msec()
 elif phase=="held":
  passed=passed and game.ui.screen=="upgrading" and total()==initial and (connection==null or connection.choices.is_empty())
  if game.mobile.contacts.is_empty():phase="fresh_required"
  else:passed=passed and game.mobile.choice_blocked
 elif phase=="fresh_required":
  passed=passed and game.ui.screen=="upgrading" and total()==initial and (connection==null or connection.choices.is_empty())
  if FileAccess.file_exists("user://choice012-arm"):phase="fresh_tap";release_armed=true
 elif phase=="fresh_tap" and game.ui.screen=="running":
  if context=="client":passed=passed and total()==initial and connection.choices.size()==1
  else:passed=passed and total()==initial+1
  phase="complete"
 var transform:Transform2D=get_viewport().get_screen_transform();var at:Vector2=transform*game.mobile.stick_center
 var result:Dictionary={"context":context,"phase":phase,"passed":passed,"joystick":[roundi(at.x),roundi(at.y)],"contacts":game.mobile.contacts.size(),"blocked":game.mobile.choice_blocked,"screen":game.ui.screen,"levels":total(),"choices":connection.choices.size() if connection!=null else 0}
 if game.ui.screen=="upgrading":
  var b=game.ui.menu.find_child("UpgradeList",true,false).get_child(0);at=transform*b.get_global_rect().get_center();result.card=[roundi(at.x),roundi(at.y)];result.disabled=b.disabled;result.card_ready=b.size.x>50 and b.size.y>50 and b.get_global_rect().position.y>20
 var file=FileAccess.open("user://choice012-state.json",FileAccess.WRITE);file.store_string(JSON.stringify(result));file.close()
