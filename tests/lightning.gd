extends SceneTree
func _initialize():call_deferred("run")
func run():
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
	g.sound.volume=0;g.start_run();g.director.phase="complete";g.weapon_system.levels.lightning=5
	var a=g.spawn_enemy("ghoul",g.player.position+Vector2(50,0));a.hp=1000
	var b=g.spawn_enemy("ghoul",g.player.position+Vector2(100,0));b.hp=1000
	var c=g.spawn_enemy("ghoul",g.player.position+Vector2(400,0));c.hp=1000
	g.weapon_system._lightning()
	assert(a.hp==905 and b.hp==905 and c.hp==1000)
	assert(g.weapon_system.lightning_fx.size()==2)
	g.queue_free();await process_frame;await create_timer(.2).timeout
	print("LIGHTNING_PASS unique targets and range");quit()
