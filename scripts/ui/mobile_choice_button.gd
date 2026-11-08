class_name MobileChoiceButton
extends Button
var game
var controls:MobileControls
var offer_id:String
var epoch:int
var hint:Label
var fresh_press:bool=false
var pointer:String=""
var serial:int=0
func setup(owner,id:String,caption:Label):
 game=owner;controls=game.mobile;offer_id=id;epoch=controls.choice_epoch;hint=caption
 action_mode=BaseButton.ACTION_MODE_BUTTON_RELEASE
 gui_input.connect(track_press);pressed.connect(choose)
 controls.choice_input_changed.connect(refresh);refresh()
func refresh():
 fresh_press=false;pointer="";serial+=1
 disabled=true;disabled=controls.choice_blocked or epoch!=controls.choice_epoch
 if is_instance_valid(hint) and epoch==controls.choice_epoch:hint.text="Solte os dedos para escolher." if controls.choice_blocked else "Toque em uma melhoria."
func track_press(event:InputEvent):
 if disabled:return
 var source:String=""
 if event is InputEventScreenTouch:source="touch:"+str(event.index)
 elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:source="mouse"
 elif (event is InputEventKey or event is InputEventJoypadButton) and event.is_action("ui_accept"):
  if event is InputEventKey and event.echo:return
  source="accept"
 if source.is_empty():return
 if event.is_pressed() and pointer.is_empty():
  pointer=source;fresh_press=true;serial+=1
 elif not event.is_pressed() and source==pointer:clear_press.call_deferred(serial)
func clear_press(sequence:int):
 if sequence==serial:fresh_press=false;pointer=""
func _notification(what:int):
 if what==Control.NOTIFICATION_SCROLL_BEGIN:fresh_press=false
func choose():
 if not fresh_press or controls.choice_blocked or epoch!=controls.choice_epoch:return
 fresh_press=false;game.choose_upgrade(offer_id)
