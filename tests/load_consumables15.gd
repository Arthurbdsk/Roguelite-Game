extends SceneTree
class Accepted extends RoomConnection:
 func send_message(_packet:Dictionary)->bool:return true
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.set_physics_process(false);g.persistence_enabled=false;g.test_mode=true;g.sound.volume=0;g.perf_enabled=true
 g.coop.connection.queue_free();g.coop.connection=Accepted.new();g.coop.add_child(g.coop.connection);g.coop.connection.peer_id="a";g.coop.connection.host_id="a";g.coop.hosting=true
 g.coop.begin({"run":"load15","players":[{"id":"a","name":"A","skills":{}},{"id":"b","name":"B","skills":{}},{"id":"c","name":"C","skills":{}},{"id":"d","name":"D","skills":{}}]})
 g.dev_boss_test=true;g.campaign.cleared=true;g.campaign.endless=true;g.director.phase="complete";g.special_events.next_check=100000;g.chests.next_check=100000;g.consumables.next_check=100000
 for actor in g.coop.actors.values():actor.player.dev_invulnerable=true;actor.weapon_system.levels={"sludge":8,"holy_water":8,"clock":8,"lightning":8,"bombs":8,"orbit":8}
 for i in 200:
  var at:Vector2=g.free_enemy_position(Vector2(650+i%20*25,470+int(i/20)*27),8)
  if at!=Vector2.INF:
   var e=g.spawn_enemy("ghoul",at)
   if e!=null:e.hp=1000000;e.max_hp=e.hp
 for i in 3000:g.pickups.append({"id":10000+i,"at":g.player.position+Vector2.from_angle(i*.4)*100,"xp":.125,"attracted":false})
 g.consumables.spawn_item("xp_magnet",g.player.position);g.consumables.collect(g.consumables.items[0],g.player)
 var frames:Array=[];var batches:Array=[];var previous:int=Time.get_ticks_usec();var peak:int=g.enemies.size()
 for frame in 180:
  await process_frame
  var now:int=Time.get_ticks_usec();frames.append((now-previous)/1000.0);previous=now
  g.coop.host_tick(1.0/60,{"movement":Vector2.ZERO,"revive":false});batches.append(g.consumables.magnet_batch_us/1000.0)
 g.consumables.config.limit=5
 for i in 5:g.consumables.spawn_item(g.consumables.config.items[i].id,g.player.position+Vector2(-110+i*55,65))
 g.ui.update_hud(g.snapshot())
 await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://test_output/15-load.png")
 g.consumables.config.limit=2
 frames.sort();batches.sort()
 print("LOAD15 ",JSON.stringify({"rendered":DisplayServer.get_name()!="headless","frame_ms":{"median":frames[90],"p95":frames[171],"p99":frames[178]},"magnet_batch_ms":{"median":batches[90],"p95":batches[171],"p99":batches[178]},"initial_enemies":peak,"pending_crystals":g.consumables.magnet_jobs.size(),"four_players":g.coop.actors.size()}))
 for i in 40:g.consumables.tick_magnet(100)
 var exact:bool=g.consumables.magnet_jobs.is_empty() and is_equal_approx(g.consumables.magnet_credited,375)
 print("LOAD15_EXACT_XP ",g.consumables.magnet_credited," remaining=",g.consumables.magnet_jobs.size())
 g.queue_free();await process_frame;await process_frame;print("LOAD_CONSUMABLES15_PASS" if exact else "LOAD_CONSUMABLES15_FAIL");quit(0 if exact else 1)
