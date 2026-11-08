extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false
 assert(OS.get_user_data_dir().contains("HordasUpdateQA"))
 assert(ProjectSettings.get_setting("application/config/version")=="0.26.1")
 g.profile.data.gold=321;g.profile.data.runs=7;g.profile.data.settings.volume=0;g.profile.data.settings.music=0;assert(g.profile.save())
 var u=g.updates;u.endpoint="https://paths-doctors-either-amended.trycloudflare.com/qa/stable.json";u.check()
 while u.busy:await process_frame
 assert(u.available(),u.status);print("E2E_DETECTED ",u.release.version)
 u.download()
 while u.busy:await process_frame
 assert(u.install_ready,u.status);print("E2E_DOWNLOADED ",u.release.version)
 var f:=FileAccess.open("user://e2e-before.json",FileAccess.WRITE);f.store_string(JSON.stringify({"gold":321,"save_hash":FileAccess.get_sha256(g.profile.path),"new":u.release.version}));f.close()
 u.install()
