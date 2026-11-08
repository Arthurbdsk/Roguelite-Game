extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false
 for screen in ["title","updates"]:
  g.ui.render(screen);await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://build/update-ui-"+screen+".png")
  if screen=="title":
   for b in g.ui.menu.find_children("*","Button",true,false):assert(b.get_global_rect().end.x<=g.get_viewport_rect().end.x+1,"title button outside viewport: "+b.text)
 g.queue_free();await process_frame;await create_timer(.2).timeout;print("UPDATE_UI026_PASS rendered menu and updates");quit()
