extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.sound.volume=0;g.start_run();g.director.phase="complete";g.weapon_system.attacks_enabled=false;g.player.dev_invulnerable=true
 for i in 120:g.spawn_enemy("beast" if i%15==0 else "ghoul",Vector2(1100+i%10*5,600+int(i/10)*5))
 for frame in 120:
  await physics_frame;g.navigation.tick(1.0/60);g.rebuild_grid();g.prepare_crowd()
  var contacts:int=0
  for list in g.crowd_near.values():contacts+=list.size()
  assert(contacts==g.crowd_pairs*2)
  for e in g.enemies:e.tick(1.0/60)
 for a in g.enemies:
  assert(g.arena.safe_position(a.position,a.radius-.3))
  for b in g.enemies:
   if a.serial<b.serial:assert(a.position.distance_to(b.position)>=a.radius+b.radius-.7)
 var rng:=RandomNumberGenerator.new();rng.seed=140031
 for i in 100:
  var at:=Vector2(rng.randf_range(40,1760),rng.randf_range(45,1150));var radius:float=rng.randf_range(4,90)
  var fast:Array=g.query_enemies(at,radius);var expected:int=0
  for e in g.enemies:
   if e.alive and at.distance_squared_to(e.position)<=pow(radius+e.radius,2):expected+=1;assert(fast.has(e))
  assert(fast.size()==expected)
 for map in ["library","fields"]:
  g.arena.apply_map(map)
  for i in 500:
   var at:=Vector2(rng.randf_range(40,1760),rng.randf_range(45,1150));var r:float=rng.randf_range(4,48);var slow:bool=true
   for rect in g.arena.obstacles:
    if rect.grow(r).has_point(at):slow=false
   assert(g.arena.safe_position(at,r)==slow)
 g.arena.sync_dynamic_walls({"ice":Rect2(850,450,40,300)});assert(not g.navigation.clear_segment(Vector2(790,600),Vector2(960,600),6));g.arena.sync_dynamic_walls({});assert(g.navigation.clear_segment(Vector2(790,600),Vector2(960,600),6))
 g.clear_run();g.state="running";g.arena.apply_map("courtyard");g.player.position=Vector2(900,630);g.weapon_system.levels={"clock":8};g.weapon_system.clock_index=0
 for i in 12:
  var direction:Vector2=Vector2.UP.rotated(i*TAU/12)
  var e=g.spawn_enemy("ghoul",g.player.position+direction*g.weapon_system._stat("clock","reach")*.995)
  assert(e!=null);g.rebuild_grid();g.weapon_system._clock();assert(e.frozen_remaining>0)
  g.despawn_enemy(e)
 print("SPATIAL14_PASS mixed radii, cell edges, 120 moving physical bodies, obstacle oracle and dynamic ice invalidation");g.queue_free();await process_frame;quit()
