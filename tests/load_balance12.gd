extends SceneTree
class AcceptedConnection extends RoomConnection:
 func send_message(_packet:Dictionary)->bool:return true
func _initialize():call_deferred("run")
func run():
 var representative:bool="--representative" in OS.get_cmdline_user_args()
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.sound.volume=0
 g.coop.connection.queue_free();g.coop.connection=AcceptedConnection.new();g.coop.add_child(g.coop.connection)
 g.coop.connection.peer_id="a";g.coop.connection.host_id="a";g.coop.hosting=true
 g.coop.begin({"run":"campaign_load10","players":[{"id":"a","name":"A","skills":{}},{"id":"b","name":"B","skills":{}},{"id":"c","name":"C","skills":{}},{"id":"d","name":"D","skills":{}}]})
 g.arena.apply_map("fields");g.selected_map="fields"
 g.dev_boss_test=true;g.persistence_enabled=false;g.elapsed=1200;g.director.phase="complete"
 seed(1010)
 var actor_index:int=0
 for actor in g.coop.actors.values():
  actor.weapon_system.rng.seed=1010+actor_index;actor_index+=1
  actor.player.invulnerable=1000
  actor.weapon_system.levels={"sludge":8,"holy_water":8,"clock":8,"lightning":8,"bombs":8,"orbit":8}
  for i in 24:
   var at:=Vector2(650+i%8*45,510+int(i/8)*65)
   actor.weapon_system.ground.add_pool("sludge" if i%2 else "holy_water",at,actor.player.position)
 g.late_arena.begin_encounter("horror");g.late_arena.tick(1.3)
 var boss=g.boss;boss.dev_frozen=true;boss.position=Vector2(1100,690);boss.locked_target=g.player.position;boss.charge_direction=Vector2.LEFT
 assert(g.late_arena.cast("summon",boss));g.late_arena.tick(1.3)
 for e in g.enemies.duplicate():
  if e.data.id=="necromancer":e.tick(.01)
 g.specials.tick(1.1)
 assert(g.late_arena.chain.count(boss.serial)==212)
 for i in (0 if representative else 28):
  var at:=Vector2(500+i%20*32,450+int(i/20)*38)
  if g.arena.safe_position(at,12):g.spawn_enemy("ghoul",at)
 for i in (100 if representative else 2000):g.gold_loot.drop(Vector2(100+i%50,100+int(i/50)))
 for i in 240:g.drop_xp(Vector2(100+i%40,200+int(i/40)),1)
 var patterns=g.late_arena.patterns;patterns.cooldown=0
 assert(patterns.request("rings",boss,"orbs"))
 var cpu:Array[float]=[];var peak_enemies:int=0;var peak_shots:int=0;var peak_pools:int=0;var peak_deferred:int=0;var combo_started:bool=false;var safe_deferrals:int=0
 var start:int=Time.get_ticks_usec();var first_frame:int=Engine.get_frames_drawn()
 for frame in 360:
  await physics_frame
  for e in g.enemies:e.hp=1000000;e.max_hp=e.hp
  var before:int=Time.get_ticks_usec();g.coop.host_tick(1.0/60,{"movement":Vector2.ZERO,"revive":false});cpu.append((Time.get_ticks_usec()-before)/1000.0)
  if frame==180:patterns.clear_owner(boss.serial);patterns.cooldown=0
  if frame>=180 and frame%30==0 and not combo_started:
   combo_started=patterns.request("beams",boss,"totems")
   if not combo_started:safe_deferrals+=1
  peak_enemies=maxi(peak_enemies,g.enemies.size());peak_shots=maxi(peak_shots,g.enemy_projectiles.arrows.size()+g.specials.bolts.size()+patterns.shots.size())
  var pools:int=0
  for actor in g.coop.actors.values():pools+=actor.weapon_system.ground.pools.size()
  peak_pools=maxi(peak_pools,pools);peak_deferred=maxi(peak_deferred,g.late_arena.chain.deferred())
  assert(g.late_arena.chain.count(boss.serial)<=220)
  if frame==120:
   await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://test_output/12-load-arena.png")
 var seconds:float=(Time.get_ticks_usec()-start)/1000000.0;cpu.sort()
 print("LOAD_BALANCE12 ticks=360 wall_s=%.2f draw_fps=%.1f cpu_median_ms=%.2f cpu_p95_ms=%.2f peak_enemies=%d peak_shots=%d peak_pools=%d deferred=%d chain=%s"%[seconds,(Engine.get_frames_drawn()-first_frame)/seconds,cpu[180],cpu[342],peak_enemies,peak_shots,peak_pools,peak_deferred,g.late_arena.chain.snapshot()])
 print("LOAD_BALANCE12 safe_deferrals=",safe_deferrals," second_combination_started=",combo_started)
 g.finish_run(false);assert(g.arena.dynamic_walls.is_empty() and g.late_arena.chain.count(boss.serial)==0)
 for actor in g.coop.actors.values():assert(actor.weapon_system.ground.pools.is_empty())
 g.queue_free();await process_frame;await create_timer(.3).timeout;print("LOAD_BALANCE12_PASS four local actors, twenty necromancers, 220 chain budget, six weapons each, render and cleanup; not human balance or network latency");quit()
