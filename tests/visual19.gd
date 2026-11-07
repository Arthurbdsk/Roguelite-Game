extends SceneTree
var errors:int=0
var checks:int=0
var game
var directory:String
var decimal:=RegEx.new()
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:errors+=1;printerr("FAIL "+label)
func inspect(node:Node):
 if node is Label or node is Button:
  check(node.get_theme_font("font")== (GameFonts.timer_font() if node==game.ui.time_text else GameFonts.interface_font()),"functional font "+node.name)
  check(decimal.search(node.text)==null,"integer text "+node.text)
 if node is RichTextLabel:check(node.get_theme_font("normal_font")==GameFonts.interface_font(),"readable rich text")
 for child in node.get_children():inspect(child)
func capture(name:String):
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(directory+"/19-"+name+".png")
func run():
 directory=OS.get_environment("HORDAS_CAPTURE_DIR")
 if directory.is_empty():directory="res://test_output"
 decimal.compile("[0-9]+[.,][0-9]+")
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.set_physics_process(false);game.persistence_enabled=false;game.test_mode=true;game.start_run()
 for id in game.weapon_system.weapon_data:game.profile.data.discoveries["weapon:"+id]=true
 for id in game.weapon_system.passive_data:game.profile.data.discoveries["passive:"+id]=true
 for d in game.consumables.config.items:game.profile.data.discoveries["consumable:"+str(d.id)]=true
 game.weapon_system.levels={"bolt":8,"axe":8,"fire_wand":8,"whip":8,"garlic":8,"magic_wand":8}
 game.weapon_system.passives={"regeneration":7,"crown":8,"boots":8,"hourglass":8}
 var offers:Array=[]
 for id in ["regeneration","ward","cadence","lens"]:
  var d=game.weapon_system.passive_data[id]
  offers.append({"id":id,"name":d.display_name,"icon":d.icon,"detail":"Nível 7 → 8" if id=="regeneration" else "Novo","description":d.level_descriptions[7] if id=="regeneration" else d.level_descriptions[0]})
 for screen in ["title","hub","settings","tree","collection","upgrading","online","maps","revive_offer","endless_choice","result"]:
  game.ui.render(screen,{"offers":offers});await process_frame;await process_frame;inspect(game.ui.root)
  if screen=="upgrading":
   for card in game.ui.menu.find_child("UpgradeList",true,false).get_children():check(card.get_child(0).get_combined_minimum_size().y<=card.size.y+1,"long description inside card")
  if screen=="collection":check(game.ui.menu.get_child(0).counter.text=="Coleção: 30 de 30","all real items including regeneration")
  await capture(screen)
 for size_px in [Vector2i(480,360),Vector2i(800,450)]:
  root.size=size_px;game.ui.root.size=Vector2(size_px);game.ui.menu.size=Vector2(size_px)
  for screen in ["tree","collection"]:
   game.ui.render(screen);await process_frame;await process_frame;inspect(game.ui.root)
   var view=game.ui.menu.get_child(game.ui.menu.get_child_count()-1)
   var scroll=view.find_child("PermanentScroll" if screen=="tree" else "CollectionScroll",true,false)
   var detail=view.find_child("PermanentDetails" if screen=="tree" else "CollectionDetails",true,false)
   check(scroll.get_global_rect().end.y<=detail.get_global_rect().position.y+1,"fixed detail separated from grid")
   await capture(screen+"-%dx%d"%[size_px.x,size_px.y])
 root.size=Vector2i(640,360);game.ui.root.size=Vector2(640,360);game.ui.menu.size=Vector2(640,360)
 for map_id in ["courtyard","library","fields"]:
  game.clear_run();game.arena.apply_map(map_id);game.state="running";game.player.position=Vector2(900,600);game.camera.position=Vector2.ZERO;game.elapsed=125
  game.player.apply_poison(9,2);game.player.root_remaining=.35;game.player.movement_multiplier=.7;game.consumables.freeze_left=8
  game.consumables.spawn_item("food",game.player.position+Vector2(-40,30));game.consumables.spawn_item("stopwatch",game.player.position+Vector2(40,30))
  game.drop_xp(game.player.position+Vector2(-55,-15),1);game.gold_loot.drop(game.player.position+Vector2(55,-15),1)
  for i in 12:game.spawn_enemy("ghoul",game.player.position+Vector2.from_angle(i*TAU/12)*130)
  game.ui.render("running");game.ui.update_hud(game.snapshot());inspect(game.ui.root)
  check(game.ui.hud.find_child("GoldIcon",true,false).size==Vector2(16,16),"gold icon actual scale")
  check(game.ui.hud.find_child("ExperienceIcon",true,false).size==Vector2(16,16),"experience icon actual scale")
  check(game.ui.status_labels.poison.panel.visible and game.ui.status_labels.root.label.text=="Preso: 350 ms","status icon and precise integer unit")
  check(game.ui.time_text.text=="02:05","gothic actual match timer")
  await capture("arena-"+map_id)
 game.chests.show_receipt({"chest":1900,"item":"Regeneração","before":7,"after":8,"gold":123,"icon":game.weapon_system.passive_data.regeneration.icon});await capture("receipt");check(game.chests.result_icon.texture!=null,"chest displays catalog icon")
 if game.dev_tools!=null:
  game.show_title();game.dev_tools.toggle();await process_frame;await process_frame;inspect(game.dev_tools.panel);await capture("dev");game.dev_tools.end_test()
 game.queue_free();await process_frame;await process_frame
 print("VISUAL19_"+("PASS" if errors==0 else "FAIL")+" checks="+str(checks));quit(int(errors>0))
