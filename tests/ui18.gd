extends SceneTree
var errors:int=0
var decimal:=RegEx.new()
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 if not ok:errors+=1;printerr("FAIL "+label)
func inspect(node:Node):
 if node is Label or node is Button or node is RichTextLabel:
  check(decimal.search(node.text)==null,"integer UI text: "+node.text)
 if node is OptionButton:
  for i in node.item_count:check(decimal.search(node.get_item_text(i))==null,"integer option text")
 for child in node.get_children():inspect(child)
func run():
 decimal.compile("[0-9]+[.,][0-9]+")
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.set_physics_process(false);g.persistence_enabled=false;g.test_mode=true;g.sound.volume=0;g.start_run()
 for c in "ÁáÇçãéíóúêôõ0123456789%+→":check(GameFonts.interface_font().has_char(c.unicode_at(0)),"font glyph or missing-character fallback "+c)
 g.weapon_system.levels={"garlic":1,"fire_wand":1,"runetracer":1,"axe":8,"bolt":8,"orbit":8}
 var offers:Array=[]
 for id in ["garlic","fire_wand","runetracer"]:offers.append({"id":id,"name":g.weapon_system.weapon_data[id].display_name,"description":g.weapon_system.upgrade_values(id,1),"detail":"Nível 1 → 2","icon":g.weapon_system.weapon_data[id].icon})
 for screen in ["title","settings","tree","collection","upgrading","online","maps","revive_offer","endless_choice","result"]:
  g.ui.render(screen,{"offers":offers});await process_frame;await process_frame;await process_frame
  inspect(g.ui.menu)
  if screen=="settings":
   var slider=g.ui.menu.find_child("MusicVolume",true,false);slider.value=.25
   check(is_equal_approx(g.music.volume,.25),"actual music slider connected")
  if screen=="upgrading":
   var title=g.ui.menu.get_child(2)
   check(title.get_character_bounds(0).size.x>0,"accented title fits font line height")
   var choices=g.ui.menu.find_child("UpgradeList",true,false)
   for card in choices.get_children():check(card.get_child(0).get_combined_minimum_size().y<=card.size.y+1,"long upgrade fits its card")
  await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png((OS.get_environment("HORDAS_CAPTURE_DIR") if not OS.get_environment("HORDAS_CAPTURE_DIR").is_empty() else "res://test_output")+"/18-ui-"+screen+".png")
 if g.dev_tools!=null:
  g.show_title();g.dev_tools.toggle();await process_frame;await process_frame;inspect(g.dev_tools.panel);g.dev_tools.end_test()
 g.queue_free();await process_frame;await process_frame
 print("UI18_"+("PASS" if errors==0 else "FAIL"));quit(int(errors>0))
