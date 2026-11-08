extends SceneTree
func _initialize():call_deferred("run")
func run():
 var options:Dictionary={"host":false,"name":"PC","index":0,"session":"cross25"};var fixture_path:String=""
 for arg in OS.get_cmdline_user_args():
  if arg=="--host":options.host=true
  if arg.begins_with("--index="):options.index=int(arg.trim_prefix("--index="));options.name="PC"+str(options.index)
  if arg.begins_with("--room="):options.room=arg.trim_prefix("--room=")
  if arg.begins_with("--code-file="):options.code_file=arg.trim_prefix("--code-file=")
  if arg.begins_with("--fixture="):fixture_path=arg.trim_prefix("--fixture=")
  if arg.begins_with("--session="):options.session=arg.trim_prefix("--session=")
  if arg=="--background":options.background=true
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 var fixture=load(fixture_path).new();root.add_child(fixture);fixture.setup(game,options)
