extends SceneTree
class AcceptedConnection extends RoomConnection:
 func send_message(_packet:Dictionary)->bool:return true
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.sound.volume=0;g.start_run();g.director.phase="complete"
 g.coop.connection.queue_free();g.coop.connection=AcceptedConnection.new();g.coop.add_child(g.coop.connection)
 g.coop.connection.peer_id="a";g.coop.connection.host_id="a";g.coop.hosting=true
 g.coop.begin({"run":"renderload06","players":[{"id":"a","name":"A","skills":{}},{"id":"b","name":"B","skills":{}},{"id":"c","name":"C","skills":{}},{"id":"d","name":"D","skills":{}}]})
 g.director.phase="complete"
 for i in 3:
  var caster=g.spawn_enemy("necromancer",Vector2(650+i*110,820))
  assert(g.specials.summon(caster))
 g.specials.tick(1.1)
 assert(g.enemies.size()==24)
 for i in 216:g.spawn_enemy("ghoul",Vector2(650+i%20*24,520+i/20*24))
 for e in g.enemies:e.hp=1000000;e.max_hp=e.hp
 for i in 2000:g.gold_loot.drop(Vector2(100+i%50,100+i/50))
 for i in 240:g.drop_xp(Vector2(100+i%40,200+i/40),1)
 for i in 320:g.enemy_projectiles.fire(Vector2(1400,800+i%100),Vector2.RIGHT,g.enemy_data.skeleton_archer)
 for actor in g.coop.actors.values():
  actor.player.invulnerable=1000;actor.weapon_system.levels={"sludge":8,"holy_water":8,"clock":8,"axe":8,"boomerang":8,"blades":8}
  for i in 24:
   var at:Vector2=Vector2(680+i%8*45,520+i/8*55)
   actor.weapon_system.ground.add_pool("sludge" if i%2 else "holy_water",at,actor.player.position)
 var start:int=Time.get_ticks_usec();var cpu:int=0
 for i in 180:
  await physics_frame
  var before:int=Time.get_ticks_usec();g.simulate(1.0/60);cpu+=Time.get_ticks_usec()-before
  if i==60:
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://test_output/07-necro-load.png")
 var fps:float=180.0/((Time.get_ticks_usec()-start)/1000000.0)
 print("RENDER_LOAD06 frames=180 enemies=%d cpu_ms=%.1f wall_fps=%.1f four local actors, actual rendering; not four humans"%[g.enemies.size(),cpu/1000.0,fps])
 g.finish_run(false)
 assert(g.slime_families.pending.is_empty())
 for actor in g.coop.actors.values():assert(actor.weapon_system.ground.pools.is_empty())
 g.queue_free();await process_frame;await create_timer(.4).timeout;print("RENDER_LOAD06_PASS cleanup and four actor load");quit()
