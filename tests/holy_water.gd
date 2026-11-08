extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.set_physics_process(false);g.sound.volume=0;g.start_run();g.mastery.begin(false);g.director.phase="complete";g.weapon_system.levels={"holy_water":1};g.weapon_system.timers.holy_water=100
 var w=g.weapon_system;w.rng.seed=71
 for corner in [Vector2(900,630),Vector2(60,60),Vector2(1740,1140)]:
  g.player.position=corner
  for i in 12:
   assert(w.ground.launch_water());var p=w.ground.pools[-1]
   assert(g.camera_rect().has_point(p.at) and g.arena.safe_position(p.at,p.radius) and p.at.distance_to(g.player.position)<=235)
   w.ground.reset()
 g.player.position=Vector2(900,630);assert(w.ground.launch_water())
 var p=w.ground.pools[0];var fixed:Vector2=p.at
 var e=g.spawn_enemy("guard",p.at);e.hp=1000
 w.update_combat(.69);assert(e.hp==1000)
 g.player.position+=Vector2(60,0);w.update_combat(.02)
 var damage:float=w._stat("holy_water","damage")
 assert(is_equal_approx(e.hp,1000-damage) and p.at==fixed)
 w.ground.add_pool("holy_water",p.at,p.at)
 w.update_combat(.25);assert(is_equal_approx(e.hp,1000-damage))
 w.update_combat(.25);assert(is_equal_approx(e.hp,1000-2*damage))
 w.update_combat(5);assert(w.ground.pools.is_empty())
 g.queue_free();await process_frame;await create_timer(.3).timeout
 print("WATER_PASS random visible valid positions, fixed flight, damage timing, no stacking and expiry");quit()
