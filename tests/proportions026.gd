extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.start_run()
 for size in [Vector2i(1280,720),Vector2i(2340,1080),Vector2i(1280,800),Vector2i(1080,2340)]:
  root.size=size;await process_frame
  assert(g.camera_rect().size==Vector2(640,360));assert(g.player.sprite.get_parent().scale==Vector2.ONE)
  for id in EnemyCatalog.ids(g):
   var e=g.spawn_enemy(id,Vector2(1100,730));assert(e.sprite.get_parent().scale==Vector2.ONE,id);assert(e.sprite.scale.x==e.sprite.scale.y,id);g.clear_run();g.state="running"
 g.queue_free();await process_frame;await create_timer(.2).timeout;print("PROPORTIONS026_PASS four aspects, logical framing, 23 species, player, uniform world scale");quit()
