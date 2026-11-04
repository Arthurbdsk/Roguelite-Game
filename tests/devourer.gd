extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.sound.volume=0;g.start_run();g.director.phase="complete"
 var e=g.spawn_enemy("devourer",Vector2(500,500));var base:float=e.max_hp;var damage:float=e.data.damage
 e.hp-=8
 g.gold_loot.drop(e.position,30);g.drop_xp(e.position,11);g.food_index.tick(1)
 e.tick(.01);e.tick(.01)
 assert(e.meals==2 and e.max_hp==base+10 and e.hp==base+2 and e.data.damage==damage+1)
 assert(g.gold==0 and g.pickups.is_empty() and g.gold_loot.coins.is_empty())
 g.gold_loot.drop(e.position,3);g.gold_loot.coins[-1].attracted=true;g.food_index.tick(1);e.tick(1)
 assert(e.meals==2)
 e.take_damage(99999)
 var returned:int=0
 for c in g.gold_loot.coins:
  if c.get("protected",false):returned+=c.value
 assert(returned==30)
 var xp:int=0
 for x in g.pickups:
  if x.get("protected",false):xp+=x.xp
 assert(xp==11)
 var other=g.spawn_enemy("devourer",Vector2(500,500));g.food_index.tick(1);other.tick(.01)
 assert(other.swallowed_gold==1 and other.swallowed_xp==0)
 g.clear_run();assert(g.food_index.grid.is_empty())
 g.queue_free();await process_frame;await create_timer(.3).timeout
 print("DEVOURER_PASS growth, decimals, attraction lock, exact protected refunds and cleanup");quit()
