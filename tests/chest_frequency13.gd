extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.start_run();g.sound.volume=0
 var c=g.chests;var counts:Array=[];var total:int=0;var blocked_boss=HordeBoss.new();var collect=RandomNumberGenerator.new();collect.seed=313
 for run_index in 2000:
  c.reset();c.rng.seed=13000+run_index;var due:float=INF
  for second in range(0,1201,5):
   g.elapsed=second
   var blocked:bool=(second>=300 and second<345) or (second>=600 and second<690) or (second>=900 and second<960)
   g.enemies.assign([blocked_boss] if blocked else [])
   if second>=due:c.chest.clear();due=INF
   var previous:int=c.generated;c.tick(5)
   if c.generated>previous:due=second+collect.randi_range(15,90)
  counts.append(c.generated);total+=c.generated
 var average:float=total/2000.0;print("MEASURED_MEAN ",average);assert(average>=4 and average<=5)
 print("CHEST_FREQUENCY13 runs=2000 chance=21% mean=",average," min=",counts.min()," max=",counts.max()," boss blocked seconds=195 collection delay15..90 seconds")
 g.enemies.clear();blocked_boss.free();g.queue_free();await process_frame;await create_timer(.2).timeout;print("CHEST_FREQUENCY13_PASS actual scheduler, blocked windows, collection delays, one closed, no fixed five limit");quit()
