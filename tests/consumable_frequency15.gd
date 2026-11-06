extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.set_physics_process(false);g.test_mode=true;g.persistence_enabled=false;g.start_run()
 var results:Array=[]
 for luck in [0,3]:
  for retention in ["immediate","expiry"]:
   var total:int=0;var counts:Dictionary={}
   for seed_id in 200:
    g.consumables.reset();g.consumables.rng.seed=150000+seed_id;g.mastery.ranks.luck=luck
    for second in range(60,1201,30):
     g.elapsed=second;g.consumables.tick(30)
     for item in g.consumables.items:
      if item.age==0:counts[item.kind]=int(counts.get(item.kind,0))+1
     if retention=="immediate":g.consumables.items.clear()
    total+=g.consumables.generated
   results.append({"seeds":200,"luck":luck,"retention":retention,"mean":float(total)/200,"types":counts})
 var file=FileAccess.open("res://test_output/15-frequency.json",FileAccess.WRITE);file.store_string(JSON.stringify(results,"  "));file.close()
 print("FREQUENCY15_PASS ",JSON.stringify(results))
 g.queue_free();await process_frame;await process_frame;quit()
