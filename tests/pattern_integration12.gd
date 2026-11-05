extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.sound.volume=0
 var dev=g.dev_tools;dev.enter();dev.encounter="true";dev.build.attacks=false
 for map in ["courtyard","library","fields"]:
  dev.map_id=map;assert(dev.start_encounter());var p=g.late_arena.patterns
  for kind in FinalPatterns.IDS:
   g.late_arena.clear_attacks(g.boss);p.tick(.7);assert(dev.force_attack(kind));g.boss.state="chase";g.boss.attack_time=0
   g.boss.tick(.01);assert(g.boss.state=="windup");g.boss.tick(1.3);assert(p.jobs.size()==1)
   for i in 350:p.tick(.02)
   assert(p.jobs.is_empty() and p.marks.is_empty() and g.enemies.filter(func(e):return e is HazardTarget).is_empty())
  print("PATTERNS12 all eight real attacks on ",map)
 dev.map_id="fields";dev.start_encounter();var p=g.late_arena.patterns
 for pair in p.config.combination_pairs:
  g.late_arena.clear_attacks(g.boss);p.tick(.7);assert(dev.force_combination(pair[0],pair[1]));g.boss.state="chase";g.boss.attack_time=0;g.boss.tick(.01);g.boss.tick(1.3)
  assert(p.jobs.size()==1 and p.queue.size()==1)
  for i in 40:p.tick(.02)
  assert(p.jobs.size()==2 and p.queue.is_empty())
  for i in 420:p.tick(.02)
  assert(p.jobs.is_empty() and p.queue.is_empty() and p.marks.is_empty())
  print("PATTERNS12 combined ",pair)
 g.late_arena.clear_attacks(g.boss);p.tick(.7);assert(not p.request("beams",g.boss,"orbs"))
 # Full-volley queuing: no partial ring when its capacity is temporarily exhausted.
 p.emitted=0;p.config.max_projectiles=4;assert(p.request("rings",g.boss));p.tick(1.4);assert(p.emitted==0 and p.jobs[0].step==0 and p.blocked>0)
 p.config.max_projectiles=384;p.tick(.02);assert(p.emitted>20 and p.jobs[0].step==1)
 var wire:Dictionary=CoopWire.decode(CoopWire.encode({"jobs":p.jobs,"shots":p.shots,"marks":p.marks}))
 assert(wire.jobs[0].at is Vector2 and wire.jobs[0].lanes[0].end is Vector2 and wire.shots[0].velocity is Vector2)
 dev.start_encounter();assert(p.idle() and g.enemies.size()==1 and g.arena.dynamic_walls.is_empty());dev.end_test();g.queue_free();await process_frame;await create_timer(.2).timeout
 print("PATTERN_INTEGRATION12_PASS 3 maps, eight attacks, four allowed combinations, safe routes, complete-volley limits, wire vectors and clean restart");quit()
