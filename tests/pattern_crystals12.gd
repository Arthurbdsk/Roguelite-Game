extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.sound.volume=0
 var dev=g.dev_tools;dev.enter();dev.encounter="horror";dev.build.attacks=false;assert(dev.start_encounter());var p=g.late_arena.patterns
 assert(p.request("crystals",g.boss));p.tick(.5);assert(g.enemies.filter(func(e):return e is HazardTarget).is_empty())
 p.tick(.9);var targets:Array=g.enemies.filter(func(e):return e is HazardTarget);assert(targets.size()==6)
 var gold:int=g.gold;var kills:int=g.kills;var rolls:int=g.gold_loot.death_rolls
 targets[0].take_damage(65);targets[0].take_damage(65);assert(g.kills==kills and g.gold==gold and g.gold_loot.death_rolls==rolls)
 p.tick(4.1);assert(p.emitted==5*16 and g.enemies.filter(func(e):return e is HazardTarget).is_empty())
 g.late_arena.clear_attacks(g.boss);p.cooldown=0;assert(p.request("crystals",g.boss));p.tick(1.4);g.late_arena.clear_attacks(g.boss);assert(g.enemies.filter(func(e):return e is HazardTarget).is_empty() and p.idle())
 dev.end_test();g.queue_free();await process_frame;await create_timer(.2).timeout;print("CRYSTALS12_PASS six marked destructible targets, 4s charge, destruction prevents 16-shot burst, no loot/kills, phase cleanup");quit()
