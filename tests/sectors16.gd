extends SceneTree
var errors:int=0
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.test_mode=true
 var rows:Array=[]
 for map_id in ["courtyard","library","fields"]:
  g.selected_map=map_id;g.start_run();g.director.rng.seed=1601
  for i in 80:
   g.rebuild_grid();g.director.spawn("ghoul")
  var used:int=0
  for n in g.director.sector_counts:used+=int(n>0)
  if used<5:errors+=1;printerr("FAIL few sectors "+map_id)
  var initial:Array=[0,0,0,0,0,0,0,0]
  for e in g.enemies:
   if not g.hidden_spawn(e.position,g.balance.spawn_margin):errors+=1
   var angle:float=fposmod((e.position-g.player.position).angle()+TAU,TAU);initial[int(round(angle/TAU*8))%8]+=1
  for frame in 300:
   await physics_frame
   g.player.dev_invulnerable=true;g.player.tick(1.0/60,Vector2.UP)
   g.rebuild_grid();g.prepare_crowd()
   for e in g.enemies:e.tick(1.0/60)
  var after:Array=[0,0,0,0,0,0,0,0]
  for e in g.enemies:
   var angle:float=fposmod((e.position-g.player.position).angle()+TAU,TAU);after[int(round(angle/TAU*8))%8]+=1
  rows.append({"map":map_id,"spawn":g.director.sector_counts.duplicate(),"initial":initial,"after_5_seconds":after,"blocked":g.director.blocked_reasons.duplicate()})
 print("SECTORS16 ",JSON.stringify(rows))
 var f=FileAccess.open("res://test_output/16-sectors.json",FileAccess.WRITE);f.store_string(JSON.stringify(rows,"  "));f.close()
 g.queue_free();await process_frame;await create_timer(.3).timeout;print("SECTORS16_PASS" if errors==0 else "SECTORS16_FAIL");quit(int(errors>0))
