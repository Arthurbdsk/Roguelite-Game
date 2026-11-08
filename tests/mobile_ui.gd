extends SceneTree
var errors:int=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 if not ok:errors+=1;printerr("FAIL "+label)
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.set_physics_process(false);g.persistence_enabled=false;g.sound.volume=0;g.start_run();g.profile.data.gold=20000
 for item in g.weapon_system.weapon_data:g.profile.data.get_or_add("discoveries",{})["weapon:"+item]=true
 g.coop.connection.players=[{"id":"a","name":"Jogador1","ready":true},{"id":"b","name":"Jogador2","ready":false},{"id":"c","name":"Jogador3","ready":true},{"id":"d","name":"Jogador4","ready":true}];g.coop.connection.host_id="a";g.coop.connection.peer_id="a";g.coop.connection.code="ABC123"
 var path:String=OS.get_environment("HORDAS_CAPTURE_DIR")
 if path.is_empty():path="res://test_output"
 for safe in [Rect2(0,0,640,360),Rect2(20,8,600,344)]:
  g.mobile.safe=safe;g.mobile.layout()
  for which in ["title","maps","hub","tree","collection","bestiary","online","lobby","paused","mobile_build","settings","upgrading","result","revive_offer","endless_choice"]:
   g.ui.render(which,{"offers":g.weapon_system.get_offers(),"won":true,"gold":72,"total_gold":20072,"level":8});await process_frame;await process_frame
   check(g.ui.menu.get_child_count()>0,"screen has touch layout "+which)
   var panel=g.ui.menu.get_child(0)
   if panel is BestiaryView:panel=panel.get_child(0)
   check(panel.size.x<=safe.size.x+.1 and panel.size.y<=safe.size.y+.1,"layout within safe area "+which+" "+str(panel.size))
   for b in g.ui.menu.find_children("*","BaseButton",true,false):check(b.size.y>=43.9,"comfortable button "+which+" "+b.text)
   if which=="online":
    check(g.ui.menu.find_child("MobileName",true,false).max_length==8,"eight-character name")
    check(g.ui.menu.find_child("MobileRoomCode",true,false).virtual_keyboard_enabled,"keyboard on code")
   if which=="upgrading":check(g.ui.menu.find_child("BuildPanel",true,false)!=null,"build beside upgrades")
   await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(path+"/"+which+("-safe" if safe.position.x>0 else "")+".png")
 g.state="tree";g.profile.path="user://mobile_ui_fixture.json";g.ui.render("tree");g.ui.selected_skill="damage";g.ui.render("tree");await process_frame
 var before:int=g.profile.data.gold;g.ui.menu.find_child("BuyPermanent",true,false).pressed.emit();await process_frame
 check(g.skills.rank("damage")==1 and g.profile.data.gold==before-200,"real purchase via touch button")
 check(g.ui.time_text.get_theme_font("font")==GameFonts.timer_font() and g.ui.ui_theme.default_font==GameFonts.interface_font(),"timer-only gothic")
 g.queue_free();await process_frame;await create_timer(.3).timeout
 print("MOBILE_UI_"+("PASS" if errors==0 else "FAIL"));quit(int(errors>0))
