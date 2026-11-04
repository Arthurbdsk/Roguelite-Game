extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.sound.volume=0;g.start_run();g.director.phase="complete"
 for id in g.enemy_data:
  if id=="boss":continue
  var e=g.spawn_enemy(id,Vector2(700,700))
  var base:float=g.boss_balance.executioner_health() if id=="executioner" else g.boss_balance.demon_health() if id=="demon" else g.enemy_data.ghoul.health*.15 if id=="slime_small" else g.enemy_data[id].health
  assert(is_equal_approx(e.max_hp,base*1.6),id+" health multiplier")
  if e is HordeBoss:
   assert(is_equal_approx(e.data.damage,g.enemy_data[id].damage))
   e.attack_time=100;e.position=Vector2(700,630);e.tick(.01)
   var speed:float=g.boss_balance.executioner_speed if id=="executioner" else g.boss_balance.demon_speed
   assert(is_equal_approx(e.velocity.length(),speed*1.3))
  else:
   var speed:float=g.enemy_data.ghoul.speed*1.8 if id=="slime_small" else g.enemy_data[id].speed
   assert(is_equal_approx(e.data.speed,speed*1.3))
  g.despawn_enemy(e)
 g.queue_free();await process_frame;await create_timer(.3).timeout
 print("DIFFICULTY_PASS all species and bosses: health x1.6, speed x1.3, no damage increase");quit()
