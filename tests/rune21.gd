extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.start_run()
 var w=g.weapon_system;w.levels={"runetracer":1};w.rng.seed=2101
 var one=g.spawn_enemy("ghoul",Vector2(1000,630));var two=g.spawn_enemy("ghoul",Vector2(900,730));g.rebuild_grid()
 var selected:Dictionary={}
 for i in 100:
  w.additions.shots.clear();w.additions.launch("runetracer");var velocity:Vector2=w.additions.shots[0].velocity.normalized()
  assert(velocity.dot(Vector2.RIGHT)>.999 or velocity.dot(Vector2.DOWN)>.999)
  selected["x" if velocity.x>.9 else "y"]=true
 assert(selected.size()==2,"random valid targets include the farther target")
 w.additions.shots.clear();w.additions.projectile("runetracer",Vector2.RIGHT)
 var shot=w.additions.shots[0];shot.at=Vector2(1180,630);g.player.position=Vector2(1000,630)
 w.additions.tick(.016,false);assert(shot.bounds==Rect2(680,450,640,360),"bounds follow current owner camera")
 var old:Vector2=shot.at;g.player.position=Vector2(320,180);w.additions.tick(.016,false)
 assert(shot.at.distance_to(old)<=shot.velocity.length()*.016+1,"moving bounds do not teleport rune")
 assert(shot.velocity.x<0,"outside rune returns inward once")
 var v:Vector2=shot.velocity;w.additions.tick(.016,false);assert(shot.velocity==v,"no repeated inversion outside moving bounds")
 g.player.position=Vector2(900,730);shot.at=Vector2(1170,730);shot.velocity=Vector2(200,0);shot.bounds=g.camera_rect()
 w.additions.tick(.5,false);assert(shot.velocity.x<0,"right logical edge reflects")
 shot.at=Vector2(1000,730);shot.velocity=Vector2(200,0);g.arena.add_obstacle(Rect2(1040,710,10,40));w.additions.tick(.3,false);assert(shot.velocity.x<0,"obstacle reflects actual projectile size")
 one.queue_free();two.queue_free();g.enemies.clear();g.rebuild_grid();w.additions.shots.clear();assert(w.additions.launch("runetracer"),"random fallback without targets")
 assert(w.additions.shots[0].velocity.length()>0)
 var target=g.spawn_enemy("ghoul",Vector2(1000,630));target.hp=1000;g.rebuild_grid();w.additions.shots[0].at=target.position;w.additions.advance_shots(.01,false)
 assert(target.hp==1000,"client visual prediction never deals authoritative damage")
 print("RUNE21_PASS random targets, moving owner bounds, no teleport or flip loop, walls and fallback")
 g.queue_free();await process_frame;await create_timer(.3).timeout;quit()
