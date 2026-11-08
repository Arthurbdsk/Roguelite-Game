extends SceneTree
func _initialize():call_deferred("run")
func run():
 var helper:String="res://scripts/diagnostics/combat_parity252.gd"
 var output:String="res://build/parity252-pc.json"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--audit-helper="):helper=arg.trim_prefix("--audit-helper=")
  if arg.begins_with("--audit-output="):output=arg.trim_prefix("--audit-output=")
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 var data:Dictionary=await load(helper).capture(g)
 var f=FileAccess.open(output,FileAccess.WRITE);assert(f!=null);f.store_string(JSON.stringify(data,"  "));f.close()
 print("PARITY252_PASS weapons=",data.weapons.size()," enemy cases=",data.enemies.size()," rates=",data.rates.size())
 g.queue_free();await process_frame;await create_timer(.2).timeout;quit()
