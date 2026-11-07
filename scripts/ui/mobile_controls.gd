class_name MobileControls
extends CanvasLayer

class Surface extends Control:
 var controls
 func _draw():controls.paint(self)

var game
var active:bool=OS.has_feature("android") or "--mobile-preview" in OS.get_cmdline_user_args()
var surface:Control
var fingers:Dictionary={}
var joystick_finger:int=-1
var direction:=Vector2.ZERO
var interact_held:bool=false
var revive_held:bool=false
var safe:=Rect2(0,0,640,360)
var stick_center:=Vector2(76,274)
var stick_radius:float=44
var buttons:Dictionary={}
var available:Dictionary={}
var context_clock:float=0
func setup(owner_game):
 game=owner_game;layer=40
 surface=Surface.new();surface.controls=self;surface.mouse_filter=Control.MOUSE_FILTER_IGNORE;surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(surface)
 set_process(active);set_process_input(active);surface.visible=active
 layout()
 get_viewport().size_changed.connect(update_safe_area)
 update_safe_area()
 if active:
  game.ui.pause_hint.hide();game.ui.pressure_text.hide()
  game.ui.status_row.position=Vector2(175,62)
  game.ui.counts_text.position=Vector2(180,12);game.ui.counts_text.size=Vector2(78,34);game.ui.counts_text.add_theme_font_size_override("font_size",10)
  for panel in game.ui.hud.get_children():
   if panel is Panel and panel.position.x>400:panel.hide()
  game.ui.life_text.add_theme_font_size_override("font_size",12)
  game.ui.life_text.position.y=11;game.ui.life_text.size.y=22
  var gold_icon=game.ui.hud.find_child("GoldIcon",true,false)
  if gold_icon!=null:gold_icon.hide()
func update_safe_area():
 var logical:=get_viewport().get_visible_rect().size
 safe=Rect2(Vector2.ZERO,logical)
 if OS.has_feature("android"):
  var window:=Vector2(DisplayServer.window_get_size());var area:=Rect2(DisplayServer.get_display_safe_area());var factor:float=minf(window.x/logical.x,window.y/logical.y)
  var offset:Vector2=(window-logical*factor)*.5
  area=area.intersection(Rect2(offset,logical*factor))
  if area.has_area():safe=Rect2((area.position-offset)/factor,area.size/factor)
 layout()
 if game!=null and game.ui!=null:
  game.ui.hud.position=safe.position
  game.ui.hud.scale=Vector2.ONE*minf(safe.size.x/640,safe.size.y/360)
  if not game.ui.screen.is_empty():game.ui.render(game.ui.screen,game.ui.previous_data)
func layout():
 stick_center=Vector2(safe.position.x+76,safe.end.y-78)
 buttons={"pause":Rect2(safe.end.x-55,safe.position.y+10,46,42),"build":Rect2(safe.end.x-113,safe.position.y+10,52,42),"settings":Rect2(safe.end.x-181,safe.position.y+10,62,42),"interact":Rect2(safe.end.x-119,safe.end.y-72,110,54),"revive":Rect2(safe.end.x-135,safe.end.y-136,126,54),"self_revive":Rect2(safe.end.x-135,safe.end.y-72,126,54)}
func running()->bool:return game!=null and game.state=="running" and game.ui.screen=="running" and not game.coop.menu_open
func reset():
 var changed:bool=not fingers.is_empty() or joystick_finger>=0 or interact_held or revive_held
 fingers.clear();joystick_finger=-1;direction=Vector2.ZERO;interact_held=false;revive_held=false
 if changed and is_instance_valid(surface):surface.queue_redraw()
func _process(delta):
 if not running():reset();surface.hide();return
 context_clock-=delta
 if context_clock>0:return
 context_clock=.1
 surface.show()
 var local=game.player
 var corpse:bool=game.coop.active and not game.coop.nearby_body(game.coop.connection.peer_id).is_empty()
 available={"pause":true,"build":true,"settings":true,"revive":corpse,"self_revive":local.down and (game.coop.actors[game.coop.connection.peer_id].mastery.can_revive() if game.coop.hosting else game.coop.received_personal.get("revive_available",false)),"interact":not local.down and not game.chests.chest.is_empty() and local.position.distance_to(game.chests.chest.at)<=game.chests.config.range and not corpse}
 surface.queue_redraw()
func movement(fallback:Vector2)->Vector2:return direction if joystick_finger>=0 else fallback
func _input(event:InputEvent):
 if not active:return
 if event is InputEventScreenTouch:
  if not event.pressed or event.canceled:
   if fingers.has(event.index):
    var action:String=fingers[event.index]
    var activate:bool=not event.canceled and action in ["pause","build","settings","self_revive"] and buttons[action].has_point(event.position)
    release(event.index);get_viewport().set_input_as_handled()
    if activate:call_deferred("activate_ui",action)
   return
  if not running():return
  for action in buttons:
   if available.get(action,false) and buttons[action].has_point(event.position):
    fingers[event.index]=action
    if action=="interact":interact_held=true;if_solo_interact()
    elif action=="revive":revive_held=true
    get_viewport().set_input_as_handled();return
  if Rect2(Vector2(safe.position.x,safe.end.y-168),Vector2(174,168)).has_point(event.position):
   fingers[event.index]="stick"
   if joystick_finger<0:joystick_finger=event.index;update_stick(event.position)
   get_viewport().set_input_as_handled()
 elif event is InputEventScreenDrag and fingers.has(event.index):
  if event.index==joystick_finger:update_stick(event.position)
  get_viewport().set_input_as_handled()
func activate_ui(action:String):
 if not running():return
 reset()
 if action=="pause":game.toggle_pause()
 elif action=="self_revive":game.coop.request_self_revive()
 else:game.open_mobile_panel(action)
func if_solo_interact():
 if not game.coop.active:game.chests.try_open(game.player)
func update_stick(point:Vector2):
 direction=((point-stick_center)/stick_radius).limit_length()
 if direction.length()<.15:direction=Vector2.ZERO
 surface.queue_redraw()
func release(index:int):
 fingers.erase(index)
 if index==joystick_finger:joystick_finger=-1;direction=Vector2.ZERO
 interact_held=fingers.values().has("interact");revive_held=fingers.values().has("revive")
func paint(canvas:Control):
 if not running():return
 canvas.draw_circle(stick_center,stick_radius,Color("142238b3"));canvas.draw_arc(stick_center,stick_radius,0,TAU,48,Color("bca15d"),2)
 canvas.draw_circle(stick_center+direction*28,17,Color("bca15dcc"))
 var names={"pause":"Pausa","build":"Build","settings":"Opções","interact":"Interagir","revive":"Segure: ajudar","self_revive":"Reviver"}
 for action in buttons:
  if not available.get(action,false):continue
  var rect:Rect2=buttons[action]
  canvas.draw_rect(rect,Color("142238eb"));canvas.draw_rect(rect,Color("bca15d"),false,1)
  canvas.draw_string(GameFonts.interface_font(),rect.position+Vector2(0,rect.size.y*.5+5),names[action],HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,13,Color("f2ecda"))
