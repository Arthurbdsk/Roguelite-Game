extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.sound.volume=0;g.start_run();g.director.phase="complete"
 for id in ["courtyard","library","fields"]:
  g.arena.apply_map(id);await physics_frame
  assert(g.arena.safe_position(Vector2(900,630),30))
  for i in 8:assert(g.director.spawn("ghoul"))
  var visited:Dictionary={Vector2i(22,15):true};var todo:Array=[Vector2i(22,15)]
  while not todo.is_empty():
   var cell=todo.pop_back()
   for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
    var next:Vector2i=cell+offset
    if visited.has(next) or not g.arena.safe_position(Vector2(next)*40+Vector2(20,20),6):continue
    visited[next]=true;todo.append(next)
  for x in range(1,44):
   for y in range(1,29):
    if g.arena.safe_position(Vector2(x*40+20,y*40+20),6):assert(visited.has(Vector2i(x,y)))
  g.spawn_enemy("skeleton_sword",g.player.position+Vector2(100,10))
  g.spawn_enemy("beast",g.player.position-Vector2(100,10))
  for i in 12:g.gold_loot.drop(g.player.position+Vector2(i*12-60,40))
  g.weapon_system.levels.holy_water=2;g.weapon_system.ground.add_pool("holy_water",g.player.position+Vector2(60,50),g.player.position)
  g.weapon_system.ground.queue_redraw()
  await process_frame;await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://test_output/07-map-"+id+".png")
  g.boss_arena.begin_portal();g.boss_arena.tick(g.boss_balance.portal_duration()+.01)
  assert(g.boss_arena.cast("summon",g.boss,Vector2.UP,1))
  assert(g.boss_arena.pending_summons.size()==12)
  for mark in g.boss_arena.pending_summons:assert(g.arena.safe_position(mark.at,15))
  g.boss_arena.stop_combat()
  print("MAP_PASS "+id+" reachable="+str(visited.size()))
  for e in g.enemies.duplicate():g.despawn_enemy(e)
 g.queue_free();await process_frame;await create_timer(.3).timeout;quit()
