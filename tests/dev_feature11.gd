extends SceneTree
func _initialize():call_deferred("run")
func run():
 assert(OS.has_feature("dev_tools"))
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;assert(g.development_build() and g.dev_tools!=null)
 g.dev_tools.toggle();assert(g.dev_tools.active and g.dev_tools.panel.visible)
 g.dev_tools.encounter="true";assert(g.dev_tools.start_encounter() and g.boss.form==2)
 g.dev_tools.end_test();g.queue_free();await process_frame;await create_timer(.3).timeout;print("DEV_FEATURE11_PASS packed development feature, real F8 controller and True Form");quit()
