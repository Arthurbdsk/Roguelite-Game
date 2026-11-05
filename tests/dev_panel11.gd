extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.sound.volume=0;g.dev_tools.toggle()
 var dev=g.dev_tools;dev.encounter="horror";dev.load_preset("20");dev.start_encounter()
 for i in 3:
  dev.panel.tabs.current_tab=i;await process_frame;await process_frame;await RenderingServer.frame_post_draw
  assert(dev.panel.get_rect().end.x<=640 and dev.panel.get_rect().end.y<=360)
  var path:String=ProjectSettings.globalize_path("res://test_output/11-dev-panel-"+str(i)+".png");DirAccess.make_dir_recursive_absolute(path.get_base_dir());root.get_texture().get_image().save_png(path)
 assert(dev.panel.weapon_slots.size()==6 and dev.panel.passive_slots.size()==4 and dev.panel.attack_box.item_count==7)
 dev.panel.weapon_slots[1].item.selected=dev.panel.weapon_slots[0].item.selected;assert(not dev.panel.read_build())
 dev.end_test();g.queue_free();await process_frame;await create_timer(.3).timeout;print("DEV_PANEL11_PASS actual rendered tabs, slots, live boss controls, no clipping, duplicate rejection");quit()
