extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.start_run();g.sound.volume=0;g.director.phase="complete";g.elapsed=240;g.horde_progress.tick()
 var ev=g.special_events;assert(ev.start("siege"));assert(g.enemies.size()==20 and g.banner.find("cerco")==-1)
 var normal=g.spawn_enemy("skeleton_archer",Vector2(1100,600));var siege=g.enemies[0];assert(is_equal_approx(siege.max_hp,normal.max_hp*4));assert(siege.data.attack_interval==normal.data.attack_interval+2 and siege.data.arrow_range>=760)
 var at:Vector2=siege.position;g.player.position+=Vector2(70,0);siege.tick(.2);assert(siege.position==at)
 ev.tick(45);assert(g.gold_loot.death_rolls==0);ev.tick(.36);assert(g.enemies.size()==1)
 g.clear_run();g.elapsed=240;g.state="running";g.horde_progress.tick();assert(ev.start("king"));var king=g.enemies[0];assert(king.max_hp>1000)
 king.take_damage(999999);ev.tick(.7);assert(g.enemies.size()==15)
 var large=g.spawn_enemy("slime_large",Vector2(1200,400));assert(is_equal_approx(g.enemies[0].max_hp,large.max_hp*.5));g.despawn_enemy(large)
 for e in g.enemies.duplicate():e.take_damage(999999)
 ev.tick(.7);assert(g.enemies.size()==225)
 var small=g.spawn_enemy("slime_small",Vector2(1200,400));assert(is_equal_approx(g.enemies[0].max_hp,small.max_hp*2) and is_equal_approx(g.enemies[0].data.speed,small.data.speed*1.25));g.despawn_enemy(small)
 for e in g.enemies.duplicate():e.take_damage(999999)
 ev.tick(.1);assert(ev.active=="" and ev.pending.is_empty());var gold:int=0;var xp:float=0
 for c in g.gold_loot.coins:gold+=c.value
 for p in g.pickups:xp+=p.xp
 assert(gold==20 and is_equal_approx(xp,90))
 g.queue_free();await process_frame;await create_timer(.2).timeout;print("EVENTS13_PASS 20 fixed archers, x4 current health, +2s cadence, 45s no-reward expiry; king ->15 blue ->225 small, exact ratios and family budget 20 gold/90 XP");quit()
