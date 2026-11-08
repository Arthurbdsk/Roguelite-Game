extends SceneTree
func _initialize():call_deferred("run")
func pointer(at:Vector2,pressed:bool):
 var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed;e.position=at;root.push_input(e,true)
func run():
 assert(load("res://scripts/mobile/scroll_qa011.gd")!=null)
 Input.emulate_touch_from_mouse=true
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.set_physics_process(false);g.persistence_enabled=false;g.start_run();g.state="upgrading"
 var offers:Array=g.weapon_system.get_offers();g.ui.render("upgrading",{"offers":offers})
 await process_frame;await process_frame
 var s:ScrollContainer=g.ui.menu.find_child("ChoiceScroll",true,false)
 assert(s!=null and s.get_v_scroll_bar().max_value>s.size.y,"real upgrade choices overflow")
 var point:Vector2=s.get_global_rect().position+Vector2(60,95)
 var hover:=InputEventMouseMotion.new();hover.position=point;root.push_input(hover,true)
 pointer(point,true);await process_frame
 for i in 22:
  point.y-=3;var e:=InputEventMouseMotion.new();e.position=point;e.relative=Vector2(0,-3);e.button_mask=MOUSE_BUTTON_MASK_LEFT;root.push_input(e,true);await process_frame
 var moved:int=s.scroll_vertical
 pointer(point,false);await process_frame;await process_frame
 print("SCROLL_ENGINE moved=",moved," screen=",g.ui.screen," touchscreen=",DisplayServer.is_touchscreen_available())
 assert(moved>=30,"drag over upgrade card must move scroll content")
 assert(g.ui.screen=="upgrading","drag release must not choose an upgrade")
 g.queue_free();await process_frame;await create_timer(.2).timeout;print("MOBILE_SCROLL011_PASS real GUI propagation, card drag and release cancellation");quit()
