extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.start_run()
 for spec in [[239,"orc_armored",false],[240,"orc_armored",true],[359,"skeleton_armored",false],[360,"skeleton_armored",true],[479,"orc_elite",false],[480,"orc_elite",true]]:
  g.elapsed=spec[0];assert(g.director.composition().has(spec[1])==spec[2])
 for id in g.variant_data:
  var d:Dictionary=g.variant_data[id];var e=g.spawn_enemy(id,Vector2(1000,630))
  assert(e.data.id==id and e.elite==false)
  assert(is_equal_approx(e.received_damage(100),100*(1-float(d.resistance))))
  assert(e.data.damage==g.enemy_data[d.base].damage*g.enemy_scale().damage)
  var initial:float=e.hp;e.take_damage(10);assert(is_equal_approx(initial-e.hp,10*(1-float(d.resistance))))
 g.elapsed=600;var weights:Dictionary=g.director.composition()
 assert(is_equal_approx(weights.ghoul+weights.orc_armored+weights.orc_elite,70))
 assert(is_equal_approx(weights.orc_armored/70,.1) and is_equal_approx(weights.orc_elite/70,.05))
 assert(is_equal_approx(weights.skeleton_armored/(weights.skeleton_sword+weights.skeleton_armored),.1))
 g.director.rng.seed=2105;var counts:Dictionary={"ghoul":0,"orc_armored":0,"orc_elite":0}
 for i in 50000:
  var id:String=g.director.draw_species()
  if counts.has(id):counts[id]+=1
 var total:float=counts.values().reduce(func(a,b):return a+b,0)
 assert(absf(counts.orc_armored/total-.1)<.01 and absf(counts.orc_elite/total-.05)<.01)
 assert(g.horde_progress.resistance()==0,"no automatic time resistance")
 if g.dev_tools!=null:
  g.show_title()
  assert(g.dev_tools.enter())
  g.dev_tools.force_variant("orc_armored")
  assert(g.enemies.any(func(e):return e.data.id=="orc_armored"))
  g.dev_tools.end_test()
 print("VARIANTS21_PASS reductions 5/10/15%, gates 4/6/8 minutes, preserved budget; 50000 draws ",counts)
 g.queue_free();await process_frame;await create_timer(.3).timeout;quit()
