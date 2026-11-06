extends SceneTree
var errors:int=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 if not ok:errors+=1;printerr("FAIL "+label)
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.set_physics_process(false);g.persistence_enabled=false;g.test_mode=true;g.start_run();g.weapon_system.apply_upgrade("sword");g.record_discovery("consumable:food")
 var old_gold:int=g.profile.data.gold
 var save_path:String="user://collection15_fixture.json"
 g.profile.path=save_path;check(g.profile.save(),"save additive discoveries")
 var p:=GameProfile.new(save_path);check(p.load_profile() and p.data.discoveries.has("consumable:food") and p.data.gold==old_gold,"reload preserves discoveries and gold")
 for size_px in [Vector2i(640,360),Vector2i(480,360),Vector2i(800,450)]:
  root.size=size_px;g.ui.root.size=Vector2(size_px);g.ui.menu.size=Vector2(size_px);g.ui.render("collection")
  await process_frame;await process_frame
  var v=g.ui.menu.get_child(0)
  check(v.entries.size()==25 and v.buttons.size()==25,"only twelve weapons, eight passives and five consumables")
  check(v.counter.text=="Coleção: 3 de 25","exact discovery count")
  var scroll=v.find_child("CollectionScroll",true,false);var details=v.find_child("CollectionDetails",true,false)
  check(scroll.get_global_rect().end.y<=details.get_global_rect().position.y+1,"fixed details do not overlap scroll")
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://test_output/15-collection-%dx%d.png"%[size_px.x,size_px.y])
 root.size=Vector2i(640,360);g.ui.root.size=Vector2(640,360);g.ui.menu.size=Vector2(640,360);g.ui.render("title")
 await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://test_output/15-title.png")
 DirAccess.remove_absolute(save_path);DirAccess.remove_absolute(save_path+".bak")
 g.queue_free();await process_frame;await process_frame
 print("COLLECTION15_%s"%("PASS" if errors==0 else "FAIL"));quit(int(errors>0))
