extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.start_run();g.sound.volume=0;g.player.dev_invulnerable=true;g.director.cooldown=10000
 g.elapsed=299.9;g.director.tick(.1);assert(not g.director.elite_spawned)
 g.elapsed=300;g.horde_progress.tick();g.director.tick(.1);assert(g.director.elite_spawned and g.boss.is_executioner);g.boss.take_damage(1e9);g.boss_arena.tick(2)
 g.elapsed=599.9;g.campaign.tick();assert(g.campaign.history.is_empty())
 g.elapsed=600;g.horde_progress.tick();g.campaign.tick();g.boss_arena.tick(g.boss_balance.portal_duration()+.01);var b=g.boss;var first:float=b.max_hp;var before:int=g.gold
 b.take_damage(1e9);assert(b.form==2 and is_equal_approx(b.max_hp,(first-175)*5+175) and g.gold==before)
 b.tick(1.8);b.take_damage(1e9);g.boss_arena.tick(2);assert(g.state=="running" and g.campaign.completed.demon)
 g.elapsed=899.9;g.campaign.tick();assert(g.campaign.history.size()==1)
 g.elapsed=900;g.horde_progress.tick();g.campaign.tick();g.late_arena.tick(1.3);assert(g.boss.data.id=="guardian");g.boss.take_damage(1e9);g.late_arena.tick(2)
 g.elapsed=1199.9;g.campaign.tick();assert(g.campaign.history.size()==2)
 g.elapsed=1200;g.horde_progress.tick();g.campaign.tick();g.late_arena.tick(1.3);assert(g.boss.data.id=="horror");b=g.boss;first=b.max_hp;before=g.gold
 b.take_damage(1e9);assert(b.form==2 and is_equal_approx(b.max_hp,(first-350)*1.5+350) and g.gold==before and g.state=="running")
 b.tick(1.8);b.take_damage(1e9);g.late_arena.tick(2);assert(g.state=="endless_choice" and g.campaign.cleared)
 g.campaign.vote(true);g.campaign.tick();assert(g.campaign.history==["demon","guardian","horror"] and g.elapsed==1200 and g.state=="running")
 var count:int=g.director.total_spawned;g.director.cooldown=0;g.director.tick(3);assert(g.director.total_spawned>count)
 g.finish_run(false);assert(g.ui.previous_data.won);g.queue_free();await process_frame;await create_timer(.2).timeout;print("CAMPAIGN13_PASS exact 5/10/15/20 deadlines, actual boss phases, flat bonus once, no early victory, post-True choice, continuous infinite and victory on later defeat");quit()
