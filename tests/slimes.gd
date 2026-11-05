extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.sound.volume=0;g.start_run();g.director.phase="active";g.director.queue.clear();g.director.wave_index=0;g.balance.gold_drop_chance=1
 var e=g.spawn_enemy("slime_large",Vector2(700,700));e.take_damage(99999);e.take_damage(99999)
 assert(g.slime_families.pending.size()==1)
 g.slime_families.tick(.64);assert(g.enemies.is_empty())
 g.slime_families.tick(.02);assert(g.enemies.size()==15)
 var gold:int=0;var xp:int=0
 for child in g.enemies:
  assert(child.data.id=="slime_small" and child.grace==.5)
  assert(g.arena.safe_position(child.position,4))
  assert(is_equal_approx(child.data.speed,g.enemy_data.ghoul.speed*1.8*g.balance.enemy_speed_multiplier))
  gold+=child.data.gold_value;xp+=child.data.experience
 assert(gold==3 and xp==6)
 for child in g.enemies.duplicate():child.take_damage(99999)
 assert(g.slime_families.pending.is_empty() and g.enemies.is_empty())
 assert(g.gold_loot.coins.size()==16 and g.gold_loot.death_rolls==16)
 var actual_xp:float=0
 for item in g.pickups:actual_xp+=float(item.xp)
 assert(is_equal_approx(actual_xp,6))
 g.balance.gold_drop_chance=.1;g.clear_run();assert(g.slime_families.reserved.is_empty())
 g.queue_free();await process_frame;await create_timer(.3).timeout
 print("SLIME_PASS exactly fifteen, valid positions, grace, no recursion, family reward budget");quit()
