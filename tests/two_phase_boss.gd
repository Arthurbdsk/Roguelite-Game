extends SceneTree
func _initialize():call_deferred("run")
func run():
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
	g.sound.volume=0;g.start_run();g.director.phase="boss";g.boss_arena.begin_portal();g.boss_arena.tick(4)
	var boss=g.boss;var first=boss.max_hp;var gold=g.gold
	boss.take_damage(100000)
	assert(g.state=="running" and g.gold==gold and boss.form==2 and boss.hp==first*5)
	assert(not boss.targetable and g.enemy_projectiles.arrows.is_empty() and g.boss_arena.areas.is_empty())
	boss.tick(1.7);assert(boss.targetable)
	boss.take_damage(100000);g.boss_arena.tick(2)
	assert(g.state=="result" and g.boss_defeated)
	g.coop.connection.peer_id="a";g.coop.hosting=true
	g.coop.begin({"run":"scale_fixture","players":[{"id":"a","name":"A","skills":{}},{"id":"b","name":"B","skills":{}},{"id":"c","name":"C","skills":{}},{"id":"d","name":"D","skills":{}}]})
	boss=g.spawn_enemy("demon",Vector2(900,900));first=boss.max_hp;boss.take_damage(100000)
	assert(is_equal_approx(first,g.boss_balance.demon_health()*2.5*g.balance.enemy_health_multiplier) and boss.max_hp==first*5)
	g.queue_free();await process_frame;await create_timer(.2).timeout
	print("TWO_PHASE_BOSS_PASS transition, final reward and multiplayer scaling");quit()
