extends SceneTree
class Accepted extends RoomConnection:
 var choices:Array=[]
 func send_message(packet:Dictionary)->bool:
  if packet.get("type","")=="action" and packet.get("data",{}).has("choice"):choices.append(packet.data)
  return true
var g
func _initialize():call_deferred("run")
func touch(index:int,point:Vector2,pressed:bool,canceled:bool=false):
 var e:=InputEventScreenTouch.new();e.index=index;e.position=point;e.pressed=pressed;e.canceled=canceled;root.push_input(e,true)
func mouse(point:Vector2,pressed:bool,device:int=-1):
 var e:=InputEventMouseButton.new();e.device=device;e.button_index=MOUSE_BUTTON_LEFT;e.position=point;e.pressed=pressed;root.push_input(e,true)
func point()->Vector2:return g.ui.menu.find_child("UpgradeList",true,false).get_child(0).get_global_rect().get_center()
func levels()->int:
 var total:int=0
 for n in g.weapon_system.levels.values():total+=int(n)
 for n in g.weapon_system.passives.values():total+=int(n)
 return total
func fresh_tap(index:int=9):
 var at:Vector2=point();touch(index,at,true);touch(index,at,false);await process_frame;await process_frame
func solo():
 g.mobile.cancel_contacts();g.start_run();await process_frame
func open_level():
 g.add_xp(g.xp_needed);await process_frame;await process_frame
func run():
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.start_run()
 touch(0,g.mobile.stick_center,true);assert(g.mobile.joystick_finger==0)
 g.add_xp(g.xp_needed);await process_frame;await process_frame
 var b:Button=g.ui.menu.find_child("UpgradeList",true,false).get_child(0)
 var point:Vector2=b.get_global_rect().get_center()
 var hover:=InputEventMouseMotion.new();hover.device=-1;hover.position=point;root.push_input(hover,true)
 mouse(point,true);touch(0,point,false);mouse(point,false);await process_frame
 print("OLD_JOYSTICK_RELEASE screen=",g.ui.screen)
 assert(g.ui.screen=="upgrading","old joystick gesture must never select an upgrade")
 touch(1,point,true);touch(1,point,false);await process_frame
 assert(g.ui.screen=="running","fresh tap must choose normally")
 await solo();var initial:int=levels()
 touch(0,g.mobile.stick_center,true);touch(1,Vector2(500,280),true);await open_level()
 touch(0,point(),false);touch(2,point(),true);touch(2,point(),false);await process_frame
 assert(g.ui.screen=="upgrading" and levels()==initial,"second old finger must keep selection blocked")
 touch(1,point(),false);await fresh_tap();assert(g.ui.screen=="running" and levels()==initial+1)
 await solo();initial=levels();touch(0,g.mobile.stick_center,true);g.add_xp(17);await process_frame;await process_frame
 touch(0,point(),false);await fresh_tap()
 assert(g.ui.screen=="upgrading" and g.level==3 and levels()==initial+1,"queued second level awaits another fresh tap")
 mouse(point(),false);touch(9,point(),false);await process_frame
 assert(g.ui.screen=="upgrading" and levels()==initial+1,"old releases cannot choose queued level")
 await fresh_tap(8);assert(g.ui.screen=="running" and levels()==initial+2)
 await solo();touch(0,g.mobile.stick_center,true);await open_level();touch(0,point(),false,true);await fresh_tap();assert(g.ui.screen=="running","canceled contact cannot leave UI locked")
 await solo();touch(0,g.mobile.stick_center,true);await open_level();g.mobile_suspend(false);g.mobile_resume();touch(0,point(),false)
 assert(g.ui.screen=="upgrading","focus return ignores orphan release");await fresh_tap();assert(g.ui.screen=="running")
 await solo();mouse(g.mobile.stick_center,true,0);await open_level();mouse(point(),false,0);assert(g.ui.screen=="upgrading","held physical mouse cannot choose")
 var over:=InputEventMouseMotion.new();over.position=point();root.push_input(over,true);mouse(point(),true,0);mouse(point(),false,0);await process_frame;assert(g.ui.screen=="running","fresh physical mouse click works")
 await solo();await open_level();g.ui.menu.find_child("UpgradeList",true,false).get_child(0).grab_focus()
 for pressed in [true,false]:
  var key:=InputEventKey.new();key.keycode=KEY_ENTER;key.physical_keycode=KEY_ENTER;key.pressed=pressed;root.push_input(key,true)
 await process_frame;assert(g.ui.screen=="running","fresh keyboard confirmation works")
 for hosting in [true,false]:
  await solo();g.coop.connection.queue_free();var connection:=Accepted.new();g.coop.connection=connection;g.coop.add_child(connection);connection.peer_id="a";connection.host_id="a";g.coop.hosting=true
  g.coop.begin({"run":"choice012","players":[{"id":"a","name":"A","skills":{}},{"id":"b","name":"B","skills":{}},{"id":"c","name":"C","skills":{}},{"id":"d","name":"D","skills":{}}]})
  initial=levels();touch(0,g.mobile.stick_center,true);var actor=g.coop.actors.a;actor.award_xp(actor.xp_needed)
  if not hosting:g.coop.received_personal=actor.personal();g.coop.hosting=false
  g.coop.open_upgrades();await process_frame;await process_frame;touch(0,point(),false)
  assert(g.ui.screen=="upgrading" and connection.choices.is_empty() and levels()==initial,"coop inherits no joystick choice")
  await fresh_tap();assert(g.ui.screen=="running")
  if hosting:assert(levels()==initial+1 and actor.offers.is_empty(),"host applies one choice")
  else:assert(connection.choices.size()==1 and connection.choices[0].generation==actor.generation and levels()==initial,"client sends one choice for host confirmation")
  g.coop.leave();await process_frame
 g.queue_free();await process_frame;await create_timer(.2).timeout;print("MOBILE_CHOICE012_PASS joystick, inherited mouse, multi-touch, queued levels, cancellation, resume, coop host and client");quit()
