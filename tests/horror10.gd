extends SceneTree
func _initialize():call_deferred("run")
func capture(id:String):
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 save_capture("res://test_output/10-horror-"+id+".png")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.start_run();g.sound.volume=0;g.weapon_system.levels.clear();g.player.invulnerable=1000
 g.campaign.completed={"demon":true,"guardian":true};g.elapsed=1200;g.campaign.tick();g.late_arena.tick(1.3)
 var boss=g.boss;assert(boss.data.id=="horror")
 var expected:float=g.boss_balance.demon_health()*5*g.balance.enemy_health_multiplier*2.2
 assert(is_equal_approx(boss.max_hp,expected))
 assert(is_equal_approx(g.late_arena.damage("fire",boss),g.boss_balance.fire_damage*1.35*2))
 boss.locked_target=g.player.position;boss.charge_direction=Vector2.LEFT
 assert(g.late_arena.cast("fire",boss));g.late_arena.tick(.01);assert(g.enemy_projectiles.fire_count()==13)
 await capture("fire");g.late_arena.clear_attacks(boss);g.enemy_projectiles.reset()
 for map in ["courtyard","library","fields"]:
  g.arena.apply_map(map);g.player.position=Vector2(900,630);g.player.facing=Vector2.DOWN
  assert(g.late_arena.cast("ice",boss),map);g.late_arena.tick(1.6)
  assert(g.arena.dynamic_walls.size()==4);var revision:int=g.arena.wall_revision
  g.late_arena.tick(.01);assert(g.arena.wall_revision==revision)
  var a:Dictionary=g.late_arena.areas[0];var center:Vector2=a.at
  assert(not g.arena.safe_position(center,5))
  await capture("wall-"+map)
  g.late_arena.tick(5);assert(g.arena.dynamic_walls.is_empty())
 g.player.position=Vector2(900,630);boss.position=Vector2(1050,650)
 assert(g.late_arena.cast("summon",boss));assert(g.late_arena.seed_pending.size()==20)
 g.late_arena.tick(1.3);assert(g.enemies.filter(func(e):return e.data.id=="necromancer" and e.chain_generation==0).size()==20)
 var casters:Array=g.enemies.filter(func(e):return e.data.id=="necromancer")
 for caster in casters:caster.tick(.01)
 assert(not g.specials.marks.is_empty())
 g.specials.tick(1.1)
 assert(g.late_arena.chain.count(boss.serial)<=int(g.campaign.config.chain_budget))
 var descendant=g.spawn_enemy("necromancer",Vector2(700,650),false,{"root":boss.serial,"generation":1})
 for e in g.enemies.duplicate():
  if e.chain_root==boss.serial and e!=descendant:g.despawn_enemy(e)
 g.specials.marks.clear();assert(g.specials.summon(descendant))
 assert(g.specials.marks.size()==12 and not g.specials.marks.any(func(m):return m.species=="necromancer"))
 g.specials.tick(1.1);assert(g.enemies.filter(func(e):return e.chain_generation==2).size()==12)
 print("CHAIN10 ",g.late_arena.chain.snapshot())
 g.clear_run();assert(g.arena.dynamic_walls.is_empty() and g.specials.marks.is_empty())
 g.queue_free();await process_frame;await create_timer(.3).timeout;print("HORROR10_PASS ratios, 180 fan, twenty casters, twelve descendants, depth/budget, solid walls three maps, cleanup");quit()

func save_capture(path:String):
 var output:String=ProjectSettings.globalize_path(path)
 DirAccess.make_dir_recursive_absolute(output.get_base_dir())
 assert(root.get_texture().get_image().save_png(output)==OK)
