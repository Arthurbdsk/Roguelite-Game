extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.sound.volume=0
 var rows:Array=[]
 # Reproducible full-wave clear/collection measurement through real death and loot systems.
 # This is an optimistic collection fixture, not a human playthrough or survival claim.
 for run_index in 5:
  g.profile.data=g.profile.defaults();g.start_run();g.director.phase="complete";g.gold_loot.death_rng.seed=1200+run_index
  var kills:int=0;var elapsed:float=0
  for wave_index in 18:
   var wave:WaveData=g.campaign.wave(wave_index)
   if wave.boss:continue
   var composition:Dictionary=g.wave_composition(wave.composition)
   for id in composition:
    for i in int(composition[id]):
     var e=g.spawn_enemy(id,Vector2(1000,700));g.enemy_killed(e);g.despawn_enemy(e);kills+=1
   for coin in g.gold_loot.coins:coin.at=g.player.position
   g.gold_loot.tick(.01)
   # Split family rewards must be measured too, using the actual scheduled children.
   g.slime_families.tick(1)
   for e in g.enemies.duplicate():
    if e.data.id=="slime_small":g.enemy_killed(e);g.despawn_enemy(e);kills+=1
   for coin in g.gold_loot.coins:coin.at=g.player.position
   g.gold_loot.tick(.01)
   elapsed+=wave.spawn_interval*g.wave_composition(wave.composition).values().reduce(func(a,b):return a+b,0)+g.balance.preparation_seconds
   g.horde_progress.complete(wave_index)
   if wave_index in [2,7,17]:
    var row:Dictionary={"seed":1200+run_index,"waves":wave_index+1,"deaths":kills,"common_gold":g.gold,"spawn_time_lower_bound_s":snappedf(elapsed,.1)};rows.append(row);print("INCOME12 ",JSON.stringify(row))
  g.clear_run()
 var f=FileAccess.open("res://test_output/12-income.json",FileAccess.WRITE);f.store_string(JSON.stringify(rows," "));f.close()
 g.queue_free();await process_frame;await create_timer(.2).timeout;print("INCOME12_PASS five seeded full-wave death/collection fixtures; boss fixed rewards separate; no human timing claim");quit()
