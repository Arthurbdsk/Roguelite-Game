extends SceneTree
var errors:int=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 if not ok:errors+=1;printerr("FAIL "+label)
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.ui.render("online");await process_frame
 var name_field:LineEdit=g.ui.menu.find_child("MobileName",true,false)
 g.open_mobile_keyboard(name_field,"Seu nome");await process_frame
 var keyboard=g.mobile_keyboard
 for character in "JOÃO1234567":keyboard.append(character)
 check(name_field.text=="JOÃO1234" and g.coop.local_name==name_field.text,"eight Unicode characters synchronized")
 keyboard.erase();check(name_field.text=="JOÃO123","erase changes target")
 keyboard.accents=true;keyboard.make_keys();await process_frame
 check(keyboard.keys.get_child_count()==4,"accent keys available")
 g.mobile_back();await process_frame;check(not is_instance_valid(g.mobile_keyboard),"Android Back closes internal keyboard")
 var code_field:LineEdit=g.ui.menu.find_child("MobileRoomCode",true,false);g.open_mobile_keyboard(code_field,"Código da sala");await process_frame
 for character in "abc123456":g.mobile_keyboard.append(character)
 check(code_field.text=="ABC123","six-character uppercase code")
 for rect in [Rect2(0,0,640,360),Rect2(20,8,600,320)]:
  g.mobile_keyboard.close();await process_frame;g.mobile.safe=rect;g.open_mobile_keyboard(code_field,"Código da sala");await process_frame;await process_frame
  check(g.mobile_keyboard.get_child(0).size==rect.size,"safe keyboard with scroll on short screen")
 g.queue_free();await process_frame;await create_timer(.3).timeout
 print("MOBILE_KEYBOARD_"+("PASS" if errors==0 else "FAIL"));quit(int(errors>0))
