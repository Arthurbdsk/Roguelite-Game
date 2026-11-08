extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false
 var u=g.updates;u.cancel();var cert:=X509Certificate.new();assert(cert.load("C:/Users/Arthur/Documents/Projetos/Hordas Android/build/update026/test-ca.pem")==OK)
 u.endpoint="https://127.0.0.1:8443/stable.json";u.request.set_tls_options(TLSOptions.client(cert));u.test_tls_pin=FileAccess.get_file_as_string("C:/Users/Arthur/Documents/Projetos/Hordas Android/build/update026/test-pin.txt");u.check()
 while u.busy:await process_frame
 assert(not u.release.is_empty(),u.status);u.release.version="99.0.0" # availability only; replace with authenticated record before validation
 var manifest:Dictionary=u.verify_manifest(u.envelope);u.release=manifest.platforms.pc
 u.download()
 while u.busy:await process_frame
 assert(u.install_ready,u.status)
 var f:=FileAccess.open(u.path,FileAccess.READ_WRITE);f.seek(10);f.store_8(255);f.close();assert(not u.validate_download());u.cancel();assert(not FileAccess.file_exists(u.path))
 u.download()
 while u.busy and u.progress<1:await process_frame
 u.cancel();assert(not u.busy and not FileAccess.file_exists(u.path))
 print("UPDATE_DOWNLOAD026_PASS real HTTPS download, signature/hash, corrupted file rejected, cancellation cleanup")
 g.queue_free();await process_frame;await create_timer(.2).timeout;quit()

