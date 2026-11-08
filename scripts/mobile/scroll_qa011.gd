extends Node
var game
var target:ScrollContainer
var stage:Dictionary={}
var trace:Array=[]
var presses:int=0
var started:int=0
var ended:int=0
var previous_command:String=""
var writing:float=0
var preparing:bool=false
func setup(owner,_request):
 game=owner;game.set_physics_process(false);game.persistence_enabled=false
 game.updates.cancel();game.sound.volume=0
 for id in EnemyCatalog.ids(game):game.profile.data.bestiary_stats[id]={"seen":1,"kills":0}
 for id in game.weapon_system.weapon_data:game.profile.data.get_or_add("discoveries",{})["weapon:"+id]=true
 for id in game.weapon_system.passive_data:game.profile.data.get_or_add("discoveries",{})["passive:"+id]=true
 game.start_run();game.set_physics_process(false)
func _process(delta):
 writing-=delta
 if writing>0:return
 writing=.05
 if FileAccess.file_exists("user://scroll011-command.json"):
  var text:String=FileAccess.get_file_as_string("user://scroll011-command.json")
  if text!=previous_command and not preparing:
   previous_command=text;prepare.call_deferred(JSON.parse_string(text))
 if stage.is_empty() or preparing:return
 if is_instance_valid(target):
  trace.append([Time.get_ticks_msec(),target.scroll_vertical]);if trace.size()>160:trace.pop_front()
 var result:Dictionary=stage.duplicate();result.trace=trace;result.presses=presses;result.started=started;result.ended=ended;result.screen=game.ui.screen
 result.value=target.scroll_vertical if is_instance_valid(target) else -1
 var f=FileAccess.open("user://scroll011-state.json",FileAccess.WRITE);f.store_string(JSON.stringify(result));f.close()
func prepare(command:Dictionary):
 preparing=true;target=null;trace.clear();presses=0;started=0;ended=0
 if is_instance_valid(game.mobile_keyboard):game.mobile_keyboard.close()
 game.ui.render("title");game.ui.mobile_screens.scrolls.clear()
 game.weapon_system.reset()
 game.weapon_system.rng.seed=1100262;game.xp=0
 var offers:Array=game.weapon_system.get_offers()
 game.offers=offers
 if command.target=="BuildScroll":
  game.weapon_system.levels={"bolt":8,"axe":8,"magic_wand":8,"fire_wand":8,"garlic":8,"holy_water":8}
  game.weapon_system.passives={"lens":8,"hourglass":8,"cadence":8,"boots":8}
 game.state="upgrading" if command.page=="upgrading" else "title"
 if command.page=="updates":
  game.updates.release={"version":"99.0.0","size":10000,"notes":"Notas de teste de rolagem.\n".repeat(18)}
 game.ui.render("online" if command.page=="keyboard" else command.page,{"offers":offers})
 if command.page=="keyboard":game.open_mobile_keyboard(game.ui.menu.find_child("MobileName",true,false),"Seu nome")
 if command.page=="bestiary":
  var view=game.ui.menu.get_child(0);view.selected="executioner";view.build()
 await get_tree().process_frame;await get_tree().process_frame;await get_tree().process_frame
 var controls=game.mobile_keyboard if command.page=="keyboard" else game.ui.menu
 target=controls.find_child(command.target,true,false)
 if target==null and command.page=="keyboard":target=controls.find_children("*","ScrollContainer",true,false)[0]
 if target==null and command.page=="updates":target=game.ui.menu.find_children("*","ScrollContainer",true,false)[0]
 assert(target!=null,"native target "+str(command))
 target.scroll_started.connect(func():started+=1);target.scroll_ended.connect(func():ended+=1)
 for b in target.find_children("*","BaseButton",true,false):b.pressed.connect(func():presses+=1)
 var rect:Rect2=target.get_global_rect()
 var point:Vector2=rect.position+Vector2(minf(75,rect.size.x*.4),minf(100,rect.size.y*.65))
 var physical:Transform2D=get_viewport().get_screen_transform()
 var start:Vector2=physical*point;var finish:Vector2=physical*(point-Vector2(0,minf(80,rect.size.y*.5)))
 stage={"nonce":command.nonce,"page":command.page,"expected_screen":game.ui.screen,"target":command.target,"max":target.get_v_scroll_bar().max_value-target.get_v_scroll_bar().page,"point":[roundi(start.x),roundi(start.y)],"end":[roundi(finish.x),roundi(finish.y)]}
 preparing=false
