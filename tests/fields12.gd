extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.selected_map="fields";g.start_run();g.sound.volume=0;g.director.phase="complete"
 assert(g.arena.props.size()==54 and g.arena.obstacles.size()==64)
 assert(g.arena.floor_layer.tile_set.get_source(0).texture.resource_path=="res://assets/v12/grass.png")
 for radius in [8,16,32,48]:
  var valid:Dictionary=g.navigation.grid(radius);var reached:Dictionary=g.navigation.distances(radius,Vector2(900,630))
  for cell in valid:
   if not reached.has(cell):print("ISOLATED ",radius," ",g.navigation.center(cell))
  assert(reached.size()==valid.size())
  print("FIELDS12 navigation radius=",radius," reachable=",reached.size(),"/",valid.size())
 for x in range(620,1200,40):
  for y in range(420,860,40):assert(g.arena.safe_position(Vector2(x,y),36))
 for prop in g.arena.props:
  assert(not g.arena.safe_position(prop.position-Vector2(0,3),4))
  var at:Vector2=prop.position-Vector2(0,3);g.drop_xp(at,.75);g.gold_loot.drop(at)
  assert(g.arena.safe_position(g.pickups.back().at,4) and g.arena.safe_position(g.gold_loot.coins.back().at,4))
 for i in 20:assert(g.director.spawn("ghoul"))
 for e in g.enemies:assert(g.arena.safe_position(e.position,16) and g.hidden_spawn(e.position,g.balance.spawn_margin))
 g.weapon_system.levels={"holy_water":8};assert(g.weapon_system.ground.launch_water())
 for pool in g.weapon_system.ground.pools:assert(g.arena.safe_position(pool.at,pool.radius))
 var prop=g.arena.props[0];g.player.position=prop.position-Vector2(0,70);g.arena.fade_clock=0;g.arena._process(.1);assert(prop.modulate.a<.4)
 g.player.position=Vector2(900,630);g.arena.fade_clock=0;g.arena._process(.1);assert(prop.modulate.a==1)
 g.boss_arena.begin_portal();g.boss_arena.tick(g.boss_balance.portal_duration()+.01);assert(g.boss_arena.cast("summon",g.boss,Vector2.UP,1))
 assert(g.boss_arena.pending_summons.size()==12)
 for m in g.boss_arena.pending_summons:assert(g.arena.safe_position(m.at,15))
 g.boss_arena.stop_combat()
 for e in g.enemies.duplicate():g.despawn_enemy(e)
 g.pickups.clear();g.gold_loot.reset();g.player.position=Vector2(500,400);g.camera.reset_smoothing()
 for i in 8:g.drop_xp(Vector2(430+i*22,430),.75);g.gold_loot.drop(Vector2(440+i*22,450))
 g.spawn_enemy("skeleton_sword",Vector2(570,430));g.spawn_enemy("necromancer",Vector2(620,380));g.weapon_system.ground.add_pool("holy_water",Vector2(510,440),g.player.position)
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://test_output/12-fields.png")
 g.clear_run();g.arena.apply_map("library");assert(g.arena.props.is_empty());g.arena.apply_map("fields");assert(g.arena.props.size()==54)
 g.queue_free();await process_frame;await create_timer(.2).timeout;print("FIELDS12_PASS trees/houses base collisions, all paths, spawn, loot, pools, boss summons, opacity, deterministic reload");quit()
