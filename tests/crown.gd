extends SceneTree
func _initialize():call_deferred("run")
func run():
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
	g.sound.volume=0;g.start_run();g.director.phase="complete";g.xp_needed=10000
	g.add_xp(1);g.weapon_system.apply_upgrade("crown");assert(g.xp==1)
	for i in 100:g.add_xp(1)
	assert(is_equal_approx(g.xp,108))
	assert(not g.weapon_system.apply_upgrade("crown"))
	g.coop.connection.peer_id="a";g.coop.connection.host_id="a";g.coop.hosting=true
	g.coop.begin({"run":"crown_fixture","players":[{"id":"a","name":"A","skills":{}},{"id":"b","name":"B","skills":{}}]})
	for actor in g.coop.actors.values():actor.xp_needed=10000
	g.coop.actors.a.weapon_system.apply_upgrade("crown")
	for i in 100:g.coop.share_xp(1)
	assert(is_equal_approx(g.coop.actors.a.xp,107) and g.coop.actors.b.xp==100)
	g.queue_free();await process_frame;await create_timer(.2).timeout
	print("CROWN_PASS fractional XP, individual bonus and no retroactive XP");quit()
