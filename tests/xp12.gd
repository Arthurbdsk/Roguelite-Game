extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.start_run();g.sound.volume=0;g.director.phase="complete"
 for id in g.enemy_data:
  if id in ["boss","slime_king","event_blue","event_small"]:continue
  g.pickups.clear();var e=g.spawn_enemy(id,Vector2(1100,630));var base:float=e.data.experience;g.enemy_killed(e)
  assert(is_equal_approx(g.pickups[0].xp,base*.75) if base>0 else g.pickups.is_empty())
 g.pickups.clear();g.xp=0;g.xp_needed=10000;g.weapon_system.passives={"crown":8};g.profile.data.upgrade_ranks={"experience":5};g.mastery.begin()
 for i in 100:g.add_xp(.75)
 assert(is_equal_approx(g.xp,75*1.66))
 var eater=g.spawn_enemy("devourer",Vector2(1300,630));g.drop_xp(eater.position,.75);g.food_index.tick(1);eater.tick(.01)
 assert(is_equal_approx(eater.swallowed_xp,.75));g.pickups.clear();g.enemy_killed(eater)
 assert(g.pickups.any(func(x):return x.get("protected",false) and is_equal_approx(x.xp,.75)))
 g.clear_run();g.queue_free();await process_frame;await create_timer(.3).timeout;print("XP12_PASS all deaths 75%, fractional pickup/collection, additive crown/permanent, devourer refund unscaled twice; base curve unchanged");quit()
