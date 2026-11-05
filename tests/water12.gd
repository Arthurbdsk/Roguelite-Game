extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.sound.volume=0;g.start_run();g.director.phase="complete"
 var w=g.weapon_system
 for maximum in [false,true]:
  g.profile.data.upgrade_ranks={"area":5,"duration":5} if maximum else {};g.mastery.begin()
  w.passives={"lens":8,"hourglass":8} if maximum else {}
  for rank in [1,8]:
   w.levels={"holy_water":rank};w.ground.reset();w.combat_time=0
   var old:float=36 if rank==1 else 60.21
   var factor:float=1.4*sqrt(1.25) if maximum else 1
   var expected:float=old*.55*factor
   assert(is_equal_approx(w._stat("holy_water","reach"),expected))
   var center:=Vector2(900,630);w.ground.add_pool("holy_water",center,center)
   assert(is_equal_approx(w.ground.pools[0].radius,expected))
   var inside=g.spawn_enemy("guard",center+Vector2(expected-.02,0));var outside=g.spawn_enemy("guard",center+Vector2(expected+.02,0));inside.hp=1000;outside.hp=1000
   w.ground.tick(.1,false);assert(inside.hp<1000 and outside.hp==1000)
   g.despawn_enemy(inside);g.despawn_enemy(outside)
   assert(is_equal_approx(w.ground.pools[0].duration,(4 if rank==1 else 6.5)*(1.89 if maximum else 1)))
 w.ground.reset();w.levels={"holy_water":8}
 for i in 24:assert(w.ground.add_pool("holy_water",Vector2(800+i%6*40,540+int(i/6)*35),g.player.position))
 w.ground.tick(13,false);assert(w.ground.pools.is_empty())
 g.queue_free();await process_frame;await create_timer(.3).timeout;print("WATER12_PASS diameter 55%, levels 1/8, max area/duration, damage boundary, simultaneous pool cleanup");quit()
