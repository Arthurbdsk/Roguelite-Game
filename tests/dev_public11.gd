extends SceneTree
func _initialize():call_deferred("run")
func run():
 assert(not OS.has_feature("dev_tools"))
 assert(not ResourceLoader.exists("res://scripts/dev/boss_lab.gd") and not FileAccess.file_exists("res://data/dev/presets.json"))
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 assert(g.dev_tools==null and not g.development_build() and g.state=="title")
 var event:=InputEventKey.new();event.physical_keycode=KEY_F8;event.pressed=true;Input.parse_input_event(event);await process_frame
 assert(g.dev_tools==null and g.state=="title")
 g.start_late_test("true");g.start_boss_test("demon");assert(g.state=="title" and g.enemies.is_empty())
 g.queue_free();await process_frame;await create_timer(.3).timeout;print("DEV_PUBLIC11_PASS exported release pack, no dev resources, no F8, no legacy shortcuts or flags");quit()
