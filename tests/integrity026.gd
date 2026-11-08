extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false
 var u=g.updates;u.envelope=FileAccess.get_file_as_string("res://build/updates/stable.json");var m:Dictionary=u.verify_manifest(u.envelope);u.release=m.platforms.pc
 var out:=FileAccess.open(u.path,FileAccess.WRITE);out.store_buffer(FileAccess.get_file_as_bytes("res://build/Hordas-0.25.2/Hordas-0.25.2.exe"));out.close();assert(u.validate_download())
 out=FileAccess.open(u.path,FileAccess.READ_WRITE);out.seek(10);out.store_8(255);out.close();assert(not u.validate_download())
 out=FileAccess.open(u.path,FileAccess.WRITE);out.store_string("partial");out.close();assert(not u.validate_download());u.cancel();assert(not FileAccess.file_exists(u.path))
 u.release={"online_required":true,"compatibility":"different"};g.open_online();assert(g.ui.screen=="updates");g.start_run();assert(g.state=="running")
 u.install_ready=true;u.install();assert(g.state=="running" and u.status.contains("partida"))
 g.queue_free();await process_frame;await create_timer(.2).timeout;print("INTEGRITY026_PASS authentic binary, corrupted/truncated rejected, cancel cleanup, required online routes updates, solo works, live game cannot install");quit()
