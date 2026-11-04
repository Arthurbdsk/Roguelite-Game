extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.sound.volume=0
 for map in ["courtyard","library","fields"]:
  g.selected_map=map;g.start_run();g.director.phase="complete";g.player.invulnerable=1000
  var barrier:Rect2=g.arena.obstacles[0]
  if map=="courtyard":barrier=Rect2(688,462,24,16)
  var target:Vector2=barrier.get_center()+Vector2(0,90);var start:Vector2=barrier.get_center()-Vector2(0,75)
  g.player.position=target
  for id in ["ghoul","beast"]:
   var e=g.spawn_enemy(id,start);e.attack_time=1000
   for i in 600:
    await physics_frame
    g.elapsed+=1.0/60;g.navigation.tick(1.0/60);g.rebuild_grid();e.tick(1.0/60)
    if e.position.distance_to(target)<40:break
   assert(e.position.distance_to(target)<40,map+" "+id+" stuck "+str(e.position))
   assert(g.arena.safe_position(e.position,e.radius-.5))
   g.despawn_enemy(e)
  print("NAV8_PASS "+map)
 g.queue_free();await process_frame;await create_timer(.3).timeout;quit()
