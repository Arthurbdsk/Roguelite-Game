extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false
 var u=g.updates;assert(u!=null)
 var good:=FileAccess.get_file_as_string("res://build/updates/stable.json")
 assert(not u.verify_manifest(good).is_empty());assert(u.verify_manifest(good.replace("payload","bad")).is_empty())
 var e:Dictionary=JSON.parse_string(good);e.signature="AAAA";assert(u.verify_manifest(JSON.stringify(e)).is_empty())
 u.cancel();assert(not u.busy and not u.install_ready)
 g.ui.render("updates");await process_frame;assert(g.ui.menu.get_child(0) is UpdateView)
 g.ui.render("title");g.queue_free();await process_frame;await create_timer(.2).timeout;print("UPDATES253_PASS signed manifest, invalid signature/schema, cancel, UI");quit()
