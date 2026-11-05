extends SceneTree
class AcceptedConnection extends RoomConnection:
 func send_message(_packet:Dictionary)->bool:return true
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.sound.volume=0
 g.coop.connection.queue_free();g.coop.connection=AcceptedConnection.new();g.coop.add_child(g.coop.connection);g.coop.connection.peer_id="a";g.coop.connection.host_id="a";g.coop.hosting=true
 g.coop.begin({"run":"spawn-cost14","map":"fields","players":[{"id":"a","name":"A","skills":{}},{"id":"b","name":"B","skills":{}},{"id":"c","name":"C","skills":{}},{"id":"d","name":"D","skills":{}}]});g.persistence_enabled=false;g.director.phase="complete";g.elapsed=240;g.horde_progress.tick();g.special_events.rng.seed=140031
 var start:int=Time.get_ticks_usec();assert(g.special_events.start("king"));var king_ms:float=(Time.get_ticks_usec()-start)/1000.0
 start=Time.get_ticks_usec();g.enemies[0].take_damage(1000000000);g.special_events.tick(.7);var blue_ms:float=(Time.get_ticks_usec()-start)/1000.0;assert(g.enemies.size()==15)
 start=Time.get_ticks_usec()
 for e in g.enemies.duplicate():e.take_damage(1000000000)
 g.special_events.tick(.7);var small_ms:float=(Time.get_ticks_usec()-start)/1000.0;assert(g.enemies.size()==225)
 print("SPAWN_COST14 ",JSON.stringify({"seed":140031,"players":4,"king_cpu_ms":king_ms,"fifteen_cpu_ms":blue_ms,"two_hundred_twenty_five_cpu_ms":small_ms,"alive":g.enemies.size(),"kind":"headless CPU setup spike, not FPS"}))
 g.clear_run();g.queue_free();await process_frame;await create_timer(.2).timeout;print("SPAWN_COST14_PASS");quit()
