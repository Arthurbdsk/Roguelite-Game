extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.sound.volume=0;g.start_run();g.director.phase="complete"
 g.gold_loot.death_rng.seed=1212
 for i in 10000:g.gold_loot.roll_death(Vector2(900,630))
 var drops:int=g.gold_loot.death_drops;assert(drops>900 and drops<1100 and g.gold_loot.death_rolls==10000)
 for coin in g.gold_loot.coins:assert(coin.value==1)
 print("GOLD12 sample deaths=10000 drops=",drops)
 g.gold_loot.reset();g.balance.gold_drop_chance=1
 for id in g.enemy_data:
  if id in ["boss","ice_crystal","channel_totem"]:continue
  var enemy=g.spawn_enemy(id,Vector2(1100,630));var n:int=g.gold_loot.death_rolls
  g.enemy_killed(enemy);g.enemy_killed(enemy);assert(g.gold_loot.death_rolls==n+1 and g.gold_loot.coins[-1].value==1)
 g.balance.gold_drop_chance=0;g.gold_loot.reset();assert(not g.gold_loot.roll_death(Vector2.ZERO) and g.gold_loot.coins.is_empty())
 g.gold=0;g.profile.data.upgrade_ranks={"gold":5};g.mastery.begin();g.gold_loot.refund(g.player.position,13)
 g.gold_loot.tick(.01);assert(g.gold==13 and g.mastery.gold_bonus==0 and g.gold_loot.coins.is_empty())
 g.gold_loot.drop(Vector2(80,80));g.gold_loot.tick(59);g.state="paused";g.gold_loot.tick(2);assert(g.gold_loot.coins.size()==1)
 g.state="running";g.gold_loot.tick(1);assert(g.gold_loot.coins.is_empty() and g.gold==13)
 g.balance.gold_drop_chance=.10;g.clear_run();g.queue_free();await process_frame;await create_timer(.3).timeout
 print("GOLD12_PASS one host roll/death, 10% sample, value 1, all species, no duplicate death, exact unbonused refund, sixty seconds and pause");quit()
