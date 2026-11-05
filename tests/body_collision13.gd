extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.sound.volume=0
 for map in ["courtyard","library","fields"]:
  g.selected_map=map;g.start_run();g.director.phase="complete";g.player.dev_invulnerable=true;g.weapon_system.attacks_enabled=false
  for i in 65:
   var e=g.spawn_enemy("beast" if i%12==0 else "ghoul",Vector2(1100,630));assert(e!=null and e.collision_mask==6)
  for frame in 90:
   await physics_frame;g.rebuild_grid()
   for e in g.enemies:e.tick(1.0/60)
  var overlaps:int=0
  for a in g.enemies:
   assert(g.arena.safe_position(a.position,a.radius-.3))
   for b in g.enemies:
    if a.serial<b.serial and a.position.distance_to(b.position)<a.radius+b.radius-.7:overlaps+=1
  assert(overlaps==0)
  print("BODY_COLLISION13 ",map," bodies=",g.enemies.size()," overlaps=",overlaps)
 g.clear_run();g.state="running";g.player.position=Vector2(790,630);g.arena.sync_dynamic_walls({"test_ice":Rect2(890,400,35,420)})
 for i in 40:assert(g.spawn_enemy("ghoul",Vector2(1050,630))!=null)
 for frame in 90:
  await physics_frame;g.navigation.tick(1.0/60);g.rebuild_grid()
  for e in g.enemies:e.tick(1.0/60)
 for e in g.enemies:assert(g.arena.safe_position(e.position,e.radius-.3))
 print("BODY_COLLISION13 active ice wall, forty pursuing bodies, no wall penetration")
 g.clear_run();g.queue_free();await process_frame;await create_timer(.2).timeout;print("BODY_COLLISION13_PASS physical masks, free spawn, mixed sizes, terrain and dense moving bodies");quit()
