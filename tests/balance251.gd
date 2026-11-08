extends SceneTree
class Meter extends HordeDirector:
 func spawn(_id:String,_elite:bool=false)->bool:
  total_spawned+=1
  return true
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.start_run()
 var mobile:bool=PlatformTuning.mobile_visuals()
 assert(is_equal_approx(g.director.rate(),90.0))
 assert(is_equal_approx(g.player.sprite.get_parent().scale.x,1.0))
 var meter=Meter.new();meter.setup(g);meter.cooldown=0
 for i in 3600:meter.tick(1.0/60)
 assert(absi(meter.total_spawned-90)<=1)
 for id in EnemyCatalog.ids(g):
  var e=g.spawn_enemy(id,Vector2(1100,730));assert(e!=null)
  assert(e.sprite.get_parent().name=="EnemyVisual")
  assert(is_equal_approx(e.sprite.get_parent().scale.x,1.0))
  var radius:float=e.radius
  if e is Devourer:
   e.meals=3;e.growth_visual();assert(is_equal_approx(e.sprite.get_parent().scale.x,1.0))
  if e is HordeBoss:e.form=2;e.apply_visual_form();assert(is_equal_approx(e.sprite.get_parent().scale.x,1.0))
  assert(is_equal_approx(e.get_child(0).shape.radius,e.radius),id)
  g.clear_run();g.state="running"
 g.coop.active=true;g.coop.hosting=true
 for count in [2,3,4]:
  g.coop.initial_size=count
  var s:Dictionary=g.enemy_scale()
  assert(is_equal_approx(s.health,1) and is_equal_approx(s.speed,1))
  assert(is_equal_approx(s.damage,1+(.7/3)*(count-1)))
  assert(is_equal_approx(g.director.rate(),90*(1+(count-1)/3.0)))
 g.coop.active=false;g.queue_free();await process_frame;await create_timer(.2).timeout
 print("BALANCE251_PASS mobile=",mobile," measured solo spawns=",meter.total_spawned," all species visuals, growth, boss forms, unchanged collision, coop damage/count")
 quit()
