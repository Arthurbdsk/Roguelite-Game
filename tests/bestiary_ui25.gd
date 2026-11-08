extends SceneTree
var checks:int=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 assert(ok,label)
func capture(name:String):
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/bestiary25/"+name+".png")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false
 check(g.ui.menu.find_children("*","Button",true,false).any(func(b):return b.text=="Bestiário"),"main menu access")
 g.enter_hub();check(g.ui.menu.find_children("*","Button",true,false).any(func(b):return b.text=="Bestiário"),"base access")
 g.ui.bestiary_return="hub";g.ui.render("bestiary");await process_frame
 var view=g.ui.menu.get_child(0);check(view is BestiaryView,"shared responsive view")
 check(view.find_children("*","Button",true,false).filter(func(b):return b.name.begins_with("Creature_")).size()==23,"all twenty-three species listed")
 check(view.find_children("*","Label",true,false).any(func(l):return l.text=="Desconhecido"),"unknown name")
 check(view.find_child("AnimatedCreature",true,false).material!=null,"unknown preview silhouette")
 check(not view.find_children("*","Label",true,false).any(func(l):return l.text.begins_with("Vida-base")),"unknown stats hidden")
 await capture("bestiary-unknown")
 for id in EnemyCatalog.ids(g):g.profile.add_bestiary(id,3,2)
 for id in ["shadow","executioner","demon","horror","slime_small","orc_armored"]:
  view.selected=id;view.phase=EnemyCatalog.phases(id).size()-1;view.build();await process_frame
  var preview=view.find_child("AnimatedCreature",true,false);var before:float=preview.clock
  await process_frame;check(preview.clock>before and preview.spec.texture!=null,"animated preview "+id)
  check(view.find_children("*","Label",true,false).any(func(l):return l.text.contains("Eliminada por você: 2")),"individual counters "+id)
  for label in view.find_children("*","Label",true,false):check(label.get_theme_font("font")==GameFonts.interface_font(),"plain readable font")
  var scroller=view.find_child("CreatureDetails",true,false);scroller.scroll_vertical=10000
  await process_frame;check(scroller.scroll_vertical>0,"detail scroll reaches final information")
  await capture("bestiary-"+id)
 view.filter="Chefes";view.build();await process_frame
 check(view.find_children("*","Button",true,false).filter(func(b):return b.name.begins_with("Creature_")).size()==5,"boss filter with event boss")
 g.ui.root.set_anchors_preset(Control.PRESET_TOP_LEFT);g.ui.root.size=Vector2(480,360);await process_frame;view.size=Vector2(480,360);view.narrow_detail=true;view.build();await capture("bestiary-narrow")
 check(not view.list_scroll.visible and view.find_child("CreatureDetails",true,false).visible,"narrow detail navigation")
 g.ui.render("hub",g.profile.data);check(g.ui.screen=="hub","return preserves menu")
 g.queue_free();await process_frame;await create_timer(.2).timeout;print("BESTIARY_UI25_PASS checks=",checks," menus, unknowns, phases, animation, scroll, narrow layout and plain font");quit()
