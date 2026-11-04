extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.sound.volume=0;g.start_run();var w=g.weapon_system
 for id in w.weapon_data:
  w.levels.clear()
  for n in 8:
   print("CHECK ",id," ",n)
   assert(w.apply_upgrade(id));assert(w.levels[id]==n+1);assert(not w.upgrade_values(id,n).is_empty())
  assert(not w.apply_upgrade(id))
 for id in w.passive_data:
  w.passives.clear()
  for n in 8:assert(w.apply_upgrade(id))
  assert(not w.apply_upgrade(id))
 w.passives={"crown":8};g.xp_needed=10000;g.xp=0;g.add_xp(100);assert(is_equal_approx(g.xp,156))
 w.levels={"sword":8,"bolt":8,"orbit":8,"clock":8,"lightning":8,"sludge":8};w.passives={"crown":8,"boots":8,"magnet":8,"ward":8}
 var choices=w.get_offers();assert(choices.size()==2 and choices[0].id in ["heal","supplies"])
 g.queue_free();await process_frame;await create_timer(.3).timeout;print("PROGRESSION8_PASS all items capped, additive crown and fallback");quit()
