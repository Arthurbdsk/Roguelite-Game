extends SceneTree
var errors:int=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 if not ok:errors+=1;printerr("FAIL "+label)
func touch(m,index:int,point:Vector2,pressed:bool=true,canceled:bool=false):
 var e:=InputEventScreenTouch.new();e.index=index;e.position=point;e.pressed=pressed;e.canceled=canceled;m._input(e)
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.set_physics_process(false);g.start_run();g.weapon_system.attacks_enabled=false
 var m=g.mobile;m.active=true;m._process(0)
 touch(m,0,m.stick_center+Vector2(44,0));check(m.direction==Vector2.RIGHT,"touch owns joystick")
 touch(m,1,m.stick_center);touch(m,1,Vector2.ZERO,false);check(m.joystick_finger==0 and m.direction==Vector2.RIGHT,"second finger cannot steal or release joystick")
 m.available.revive=true;touch(m,2,m.buttons.revive.get_center());check(m.revive_held and m.direction==Vector2.RIGHT,"simultaneous movement and held revive")
 touch(m,2,Vector2.ZERO,false);check(not m.revive_held and m.direction==Vector2.RIGHT,"release independent finger")
 touch(m,0,Vector2.ZERO,false,true);check(m.direction==Vector2.ZERO and m.joystick_finger==-1,"canceled contact resets")
 touch(m,0,m.stick_center+Vector2(0,-44));touch(m,3,m.buttons.pause.get_center());touch(m,3,m.buttons.pause.get_center(),false);await process_frame
 check(g.state=="paused" and m.direction==Vector2.ZERO and m.fingers.is_empty(),"pause clears all held input")
 g.toggle_pause();m._process(0);touch(m,4,m.stick_center);m.reset()
 check(not m.interact_held and not m.revive_held and m.direction==Vector2.ZERO,"interrupt-safe reset")
 m.reset();m.context_clock=0;m._process(0)
 var press:=InputEventScreenTouch.new();press.index=7;press.position=m.buttons.pause.get_center();press.pressed=true;root.push_input(press,true);await process_frame
 print("TOUCH_ENGINE_PRESS state=",g.state," fingers=",m.fingers)
 var lift:=InputEventScreenTouch.new();lift.index=7;lift.position=press.position;lift.pressed=false;root.push_input(lift,true);await process_frame;await process_frame
 print("TOUCH_ENGINE_RELEASE state=",g.state," fingers=",m.fingers)
 check(g.state=="paused","touch release opens only pause, no click on underlying Back")
 if g.state=="paused":g.toggle_pause()
 var p:Vector2=g.player.position;g.simulate(.1,Vector2.RIGHT);check(g.player.position.x>p.x,"same real movement simulation")
 g.queue_free();await process_frame;await create_timer(.3).timeout
 print("MOBILE_TOUCH_"+("PASS" if errors==0 else "FAIL"));quit(int(errors>0))
