extends SceneTree
func _initialize():call_deferred("run")
func run():
 assert(not ResourceLoader.exists("res://scripts/dev/boss_lab.gd"))
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false
 assert(g.dev_tools==null);assert(TinyCharacters.available("soldier"))
 print("ISOLATED_PUBLIC_PACK_PASS ",ProjectSettings.get_setting("application/config/version"));g.queue_free();await process_frame;await create_timer(.3).timeout;quit()
