extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.start_run()
 var bases:Dictionary={}
 for id in g.enemy_data:
  if id in ["boss","ice_crystal","channel_totem"]:continue
  var e=g.spawn_enemy(id,Vector2(1100,730));bases[id]={"hp":e.max_hp,"speed":e.data.speed};g.clear_run();g.state="running"
 g.coop.active=true;g.coop.hosting=true
 for count in [2,3,4]:
  g.coop.initial_size=count
  var scale:Dictionary=g.enemy_scale();assert(scale.health==1 and scale.speed==1 and is_equal_approx(scale.damage,1+.5*(count-1)))
  assert(is_equal_approx(g.director.rate(),90*(1+.8*(count-1))*.8),"twenty percent removed once from total spawn")
  for id in bases:
   var e=g.spawn_enemy(id,Vector2(1100,730));assert(is_equal_approx(e.max_hp,bases[id].hp) and is_equal_approx(e.data.speed,bases[id].speed),"solo health/speed "+id);g.clear_run();g.state="running"
 g.coop.active=false;g.queue_free();await process_frame;await create_timer(.2).timeout;print("MULTIPLAYER25_PASS all species match solo HP/speed for 2/3/4 players; total spawn -20%, damage unchanged");quit()
