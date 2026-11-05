extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.start_run();g.sound.volume=0;g.director.phase="complete"
 var c=g.chests;g.profile.data.upgrade_ranks={"gold":5};g.mastery.begin();g.weapon_system.levels={"sword":7,"bolt":8};g.weapon_system.passives={"crown":8};c.rng.seed=1313
 assert(c.spawn_chest() and not c.spawn_chest());assert(g.arena.safe_position(c.chest.at,16));g.player.position=c.chest.at;assert(c.try_open(g.player));assert(g.weapon_system.levels.sword==8 and c.receipt.before==7 and c.receipt.after==8)
 var gold:int=g.gold;assert(gold>=62 and gold<=250 and not c.try_open(g.player));assert(g.gold==gold and c.opened==1)
 c.tick(1.1);assert(c.spawn_chest());g.player.position=c.chest.at;assert(c.try_open(g.player));assert(c.receipt.item=="" and c.result_label.text.find("Todos os itens")>=0)
 g.state="paused";var attempts:int=c.attempts;c.tick(150);assert(c.attempts==attempts)
 g.clear_run();assert(c.chest.is_empty() and c.received.is_empty());g.queue_free();await process_frame;await create_timer(.2).timeout;print("CHESTS13_PASS equipped-only upgrade, cap8, shared base50..200, individual gold bonus once, maxed fallback, no duplicate open, pause and cleanup");quit()
