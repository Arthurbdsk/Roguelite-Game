extends SceneTree
func _initialize():call_deferred("run")
func run():
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
	g.sound.volume=0;g.start_run();g.director.phase="complete";g.weapon_system.levels.clock=1
	var enemy=g.spawn_enemy("guard",g.player.position+Vector2(0,-80));enemy.hp=1000
	g.weapon_system._clock();assert(is_equal_approx(enemy.hp,999.1) and enemy.frozen_remaining==3)
	var at=enemy.position;var cooldown=enemy.attack_time;enemy.tick(1)
	assert(enemy.position==at and enemy.attack_time==cooldown)
	enemy.tick(2);assert(enemy.freeze_resistance==g.weapon_system.weapon_data.clock.freeze_resistance)
	enemy.apply_time_control(3,1,.3,1);assert(enemy.frozen_remaining==0)
	for i in 11:g.weapon_system._clock()
	assert(g.weapon_system.clock_index==0 and g.weapon_system.beams.size()==12)
	var boss=g.spawn_enemy("demon",g.player.position+Vector2(60,0));boss.apply_time_control(3,1,.3,1)
	assert(boss.frozen_remaining==0 and is_equal_approx(boss.slow_factor,.7))
	g.queue_free();await process_frame;await create_timer(.5).timeout
	print("CLOCK_PASS twelve directions, unique hit, freeze, resistance and boss slow");quit()
