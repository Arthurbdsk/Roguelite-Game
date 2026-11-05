extends SceneTree
class AcceptedConnection extends RoomConnection:
 func send_message(_packet:Dictionary)->bool:return true
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.sound.volume=0
 g.coop.connection.queue_free();g.coop.connection=AcceptedConnection.new();g.coop.add_child(g.coop.connection);g.coop.connection.peer_id="a";g.coop.connection.host_id="a";g.coop.hosting=true
 g.selected_map="fields";g.coop.begin({"run":"load13","map":"fields","players":[{"id":"a","name":"A","skills":{}},{"id":"b","name":"B","skills":{}},{"id":"c","name":"C","skills":{}},{"id":"d","name":"D","skills":{}}]})
 g.dev_boss_test=true;g.persistence_enabled=false;g.director.phase="complete";g.elapsed=240;g.horde_progress.tick();g.special_events.next_check=1000000;g.chests.next_check=1000000
 for actor in g.coop.actors.values():
  actor.player.dev_invulnerable=true;actor.weapon_system.levels={"sludge":8,"holy_water":8,"clock":8,"lightning":8,"bombs":8,"orbit":8}
  for i in 24:actor.weapon_system.ground.add_pool("sludge" if i%2 else "holy_water",Vector2(680+i%8*35,560+int(i/8)*35),actor.player.position)
 var ev=g.special_events;assert(ev.start("king"));g.enemies[0].take_damage(999999);ev.tick(.7)
 for e in g.enemies.duplicate():e.take_damage(999999)
 ev.tick(.7);assert(g.enemies.size()==225)
 var cpu:Array=[];var first:int=Engine.get_frames_drawn();var start:int=Time.get_ticks_usec();var peak_shots:int=0;var peak_pools:int=0
 for frame in 240:
  await physics_frame
  for e in g.enemies:e.hp=1000000;e.max_hp=e.hp
  var before:int=Time.get_ticks_usec();g.coop.host_tick(1.0/60,{"movement":Vector2.ZERO,"revive":false});cpu.append((Time.get_ticks_usec()-before)/1000.0)
  var pools:int=0
  for actor in g.coop.actors.values():pools+=actor.weapon_system.ground.pools.size()
  peak_pools=maxi(peak_pools,pools);peak_shots=maxi(peak_shots,g.enemy_projectiles.arrows.size()+g.weapon_system.arsenal.shots.size())
  if frame==120:await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://test_output/13-load.png")
 var seconds:float=(Time.get_ticks_usec()-start)/1000000.0;cpu.sort()
 print("LOAD_SURVIVAL13 225 bodies four actors six weapons each ticks240 wall_s=%.2f draw_fps=%.1f cpu_median_ms=%.2f cpu_p95_ms=%.2f pools=%d shots=%d"%[seconds,(Engine.get_frames_drawn()-first)/seconds,cpu[120],cpu[228],peak_pools,peak_shots])
 g.finish_run(false);assert(ev.active=="" and ev.pending.is_empty());g.queue_free();await process_frame;await create_timer(.3).timeout;print("LOAD_SURVIVAL13_PASS rendered full builds, collision, family and cleanup; not four humans or internet latency");quit()
