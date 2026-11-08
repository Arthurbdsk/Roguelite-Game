extends SceneTree
var failures:int=0
var checks:int=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL "+label)
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.start_run();g.mastery.begin(false)
 check(g.player.sprite.scale.is_equal_approx(Vector2.ONE*1.1),"hero visual +10 percent")
 check(g.player.radius==7 and g.player.speed==96,"hero body and speed preserved")
 check(not TinyCharacters.data("soldier").shadow,"official Soldier atlas recorded without baked shadow")
 for id in g.enemy_data:
  if id=="boss":continue
  var e=g.spawn_enemy(id,Vector2(900,730));check(e!=null,"spawn "+id)
  if e==null:continue
  check(is_equal_approx(e.sprite.scale.x,1.1),"visual scale "+id)
  check(is_equal_approx(e.radius,e.data.radius),"body radius unchanged "+id)
  if not e.tiny_kind.is_empty():check(e.sprite.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,"nearest pixels "+id)
  g.clear_run();g.state="running"
 var view:=SubViewport.new();view.size=Vector2i(128,96);view.transparent_bg=true;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
 for remote in [false,true]:
  var player:=Sentinel.new();player.game=g;player.position=Vector2(64,64);view.add_child(player);player.sprite.hide();player.queue_redraw()
  await process_frame;await RenderingServer.frame_post_draw
  var image:=view.get_texture().get_image();var opaque:int=0
  for x in image.get_width():
   for y in image.get_height():opaque+=int(image.get_pixel(x,y).a>0)
  check(opaque==0,"no shadow or hidden separate node with sprite hidden, remote="+str(remote));player.queue_free();await process_frame
 view.queue_free();g.clear_run();g.queue_free();await process_frame;await create_timer(.2).timeout
 print("SCALE24_%s checks=%d failures=%d"%["PASS" if failures==0 else "FAIL",checks,failures]);quit(int(failures>0))
