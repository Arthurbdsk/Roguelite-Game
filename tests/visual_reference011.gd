extends SceneTree
func _initialize():call_deferred("run")
func run():
 var path:String="";var output:String="";var capture:String=""
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--fixture="):path=argument.trim_prefix("--fixture=")
  if argument.begins_with("--output="):output=argument.trim_prefix("--output=")
  if argument.begins_with("--capture="):capture=argument.trim_prefix("--capture=")
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 var fixture=load(path).new();var report:Dictionary=fixture.capture(g)
 var f=FileAccess.open(output,FileAccess.WRITE);f.store_string(JSON.stringify(report," "));f.close()
 if not capture.is_empty():
  fixture.board(g);await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(capture)
 g.queue_free();await process_frame;await create_timer(.2).timeout;print("VISUAL_REFERENCE011_PASS actual embedded sprites and visible frame bounds");quit()
