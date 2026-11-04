extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.sound.volume=0;g.start_run();g.set_physics_process(false)
 for index in 3:
  var wave=g.balance.waves[index];var count:int=0;var before:int=g.gold
  for id in wave.composition:
   for i in int(wave.composition[id]):
    var e=g.spawn_enemy(id,g.player.position+Vector2(70,0));e.take_damage(999999);count+=1
  for coin in g.gold_loot.coins:coin.at=g.player.position
  g.gold_loot.tick(.01)
  print("INCOME9 wave=%d enemies=%d gold_collected=%d cumulative=%d ideal complete collection, automated fixture"%[index+1,count,g.gold-before,g.gold])
 g.queue_free();await process_frame;await create_timer(.3).timeout;quit()
