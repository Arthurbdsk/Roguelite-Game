extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.profile.data.gold=500;g.open_skill_tree();await process_frame;await process_frame
 var view
 for child in g.ui.menu.get_children():
  if child is SkillTreeView:view=child
 assert(view is SkillTreeView and view.buttons.size()==16)
 g.profile.path="user://permanent_ui9.json"
 view.select("damage");await process_frame
 view.find_child("BuyPermanent",true,false).pressed.emit();await process_frame
 assert(g.skills.rank("damage")==1 and g.profile.data.gold==490)
 view.find_child("BuyPermanent",true,false).pressed.emit();await process_frame
 assert(g.skills.rank("damage")==1)
 view.confirm_refund();await process_frame
 var dialog:ConfirmationDialog
 for child in view.get_children():
  if child is ConfirmationDialog:dialog=child
 assert(dialog!=null and dialog.dialog_text.contains("10"));dialog.confirmed.emit();await process_frame
 assert(g.skills.rank("damage")==0 and g.profile.data.gold==500)
 for id in view.buttons:
  assert(ResourceLoader.exists(g.skills.by_id[id].icon))
  view.select(id);await process_frame
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://test_output/09-permanent-grid.png")
 var fixed:Control=view.find_child("PermanentDetails",true,false)
 assert(fixed.get_global_rect().end.y<=360)
 view.scroll.scroll_vertical=500;await process_frame
 assert(fixed.get_global_rect().end.y<=360)
 root.content_scale_size=Vector2i(360,540);root.size=Vector2i(720,1080)
 view.size=Vector2(360,540);await process_frame;await process_frame
 assert(view.grid.columns==2)
 assert(view.find_child("PermanentDetails",true,false).get_global_rect().end.y<=540)
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://test_output/09-permanent-narrow.png")
 root.content_scale_size=Vector2i(640,360);root.size=Vector2i(1280,720)
 view.size=Vector2(640,360);await process_frame;await process_frame
 g.start_run();g.mastery.bonuses.luck=1
 var offers:Array=g.weapon_system.get_offers();assert(offers.size()==4)
 g.ui.render("upgrading",{"offers":offers});await process_frame;await process_frame
 assert(g.ui.menu.find_child("UpgradeList",true,false).get_child_count()==4)
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://test_output/09-four-options.png")
 g.queue_free();await process_frame;await create_timer(.3).timeout;print("PERMANENT_UI9_PASS sixteen icons, selection, fixed details, purchase, double-click, refund dialog, scroll, four/two columns and fourth option");quit()
