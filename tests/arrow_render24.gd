extends SceneTree
func _initialize():call_deferred("run")
func capture(view):
 await process_frame;await RenderingServer.frame_post_draw
 return view.get_texture().get_image()
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.start_run();g.mastery.begin(false)
 var view:=SubViewport.new();view.size=Vector2i(160,120);view.transparent_bg=true;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
 var w=g.weapon_system;w.reparent(view);w.levels={"bolt":1};w.clear_attacks();g.player.position=Vector2(900,730)
 view.canvas_transform=Transform2D(0,Vector2(80,80)-g.player.position)
 var e=g.spawn_enemy("ghoul",Vector2(930,730));e.position=Vector2(930,730);e.motion_start=e.position;e.hp=100000;e.max_hp=e.hp;g.rebuild_grid()
 var empty=await capture(view);var checks:int=0
 for iteration in 60:
  w.projectiles.append({"id":iteration,"age":0.0,"life":2.0,"position":g.player.position,"velocity":Vector2(200,0),"distance":0.0,"reach":400.0,"damage":1.0,"pierce":1,"bounce":0,"hits":[]});w.queue_redraw()
  var visible=await capture(view);assert(visible.get_data()!=empty.get_data(),"arrow actually drawn before impact");checks+=1
  w._update_projectiles(.2);assert(w.projectiles.is_empty(),"collision consumes arrow");checks+=1
  var gone=await capture(view);assert(gone.get_data()==empty.get_data(),"no cached arrow pixels after impact");checks+=1
  if iteration==0:visible.save_png("res://build/audit24/arrow-before-impact.png");gone.save_png("res://build/audit24/arrow-after-impact.png")
 w.projectiles.append({"id":61,"age":0.0,"life":2.0,"position":g.player.position,"velocity":Vector2.ZERO,"distance":0.0,"reach":400.0,"damage":1.0,"pierce":1,"bounce":0,"hits":[]});w.queue_redraw();await capture(view);w._update_projectiles(.01)
 var gone=await capture(view);assert(gone.get_data()==empty.get_data(),"stationary arrow leaves no pixels");checks+=1
 g.clear_run();view.queue_free();g.queue_free();await process_frame;await create_timer(.2).timeout
 print("ARROW_RENDER24_PASS checks=",checks," sixty render/impact cycles and stationary cleanup");quit()
