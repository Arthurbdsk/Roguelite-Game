extends SceneTree
func _initialize():call_deferred("run")
func run():
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
	g.sound.volume=0;g.start_run();g.director.phase="boss";g.boss_arena.begin_portal();g.boss_arena.tick(4)
	var boss=g.boss
	assert(g.boss_arena.cast("summon",boss,Vector2.LEFT,1))
	assert(g.boss_arena.pending_summons.size()==12)
	for mark in g.boss_arena.pending_summons:assert(not g.players_near(mark.at,95))
	g.boss_arena.tick(1.1);assert(g.boss_arena.summons.size()==12)
	boss.take_damage(100000);boss.tick(1.7)
	assert(g.boss_arena.cast("summon",boss,Vector2.LEFT,1))
	assert(g.boss_arena.pending_summons.size()==20 and not g.boss_arena.can_cast("summon"))
	g.boss_arena.clear_for_transform();g.boss_arena.cast("lightning",boss,Vector2.LEFT,1)
	assert(g.boss_arena.areas.size()==10 and not g.boss_arena.can_cast("ice"))
	g.boss_arena.areas.clear();g.boss_arena.cast("ice",boss,Vector2.LEFT,1)
	assert(g.boss_arena.areas.size()==4)
	assert(g.boss_arena.slow_multiplier(g.boss_arena.center)==1)
	g.boss_arena.tick(1)
	assert(g.boss_arena.slow_multiplier(g.boss_arena.areas[0].at)<1)
	g.boss_arena.clear_for_transform();g.boss_arena.cast("ring",boss,Vector2.LEFT,1)
	assert(g.boss_arena.areas.size()==10)
	var origin:Vector2=g.player.position
	g.player.hp=100;g.player.armor=0;g.player.invulnerable=0
	for i in 240:g.boss_arena.tick(1.0/60)
	assert(g.player.hp<100,"remaining in closing ring takes actual damage")
	g.boss_arena.areas.clear();g.player.position=origin;g.player.hp=100;g.player.invulnerable=0
	g.boss_arena.cast("ring",boss,Vector2.LEFT,1)
	var escape:Vector2=Vector2.from_angle((boss.attack_index%12+.5)*TAU/12)
	for i in 240:
		g.player.position=origin+escape*minf(200,i*96.0/60)
		g.boss_arena.tick(1.0/60)
	assert(g.player.hp==100,"walking through marked opening escapes ring")
	g.queue_free();await process_frame;await create_timer(.2).timeout
	print("BOSS_PATTERNS_PASS group sizes, warning shapes, corridor and ring gap");quit()
