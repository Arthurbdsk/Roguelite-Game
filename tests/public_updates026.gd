extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false
 var u=g.updates;u.check()
 while u.busy:await process_frame
 assert(not u.release.is_empty(),u.status);assert(u.verify_manifest(u.envelope).platforms.has("android"));print("PUBLIC_MANIFEST_PASS ",u.status)
 if "--download" in OS.get_cmdline_user_args():
  ProjectSettings.set_setting("application/config/version","0.26.0");assert(u.available());u.download()
  while u.busy:await process_frame
  assert(u.install_ready,u.status);print("PUBLIC_WINDOWS_DOWNLOAD_PASS ",u.release.version," bytes=",FileAccess.open(u.path,FileAccess.READ).get_length());u.cancel()
 g.queue_free();await process_frame;await create_timer(.2).timeout;quit()
