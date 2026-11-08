extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.start_run();g.mastery.begin(false)
 var w=g.weapon_system
 for level in [1,8]:
  w.levels={"magic_wand":level};assert(is_equal_approx(w._interval("magic_wand"),2 if level==1 else 1.85))
  w.levels={"fire_wand":level};assert(is_equal_approx(w._stat("fire_wand","damage"),67.2 if level==1 else 141.6))
 w.levels={"axe":1};assert(w._stat("axe","pierce")==3)
 var at:Vector2=g.player.position;w.arsenal.launch("axe");var shot:Dictionary=w.arsenal.shots[0];shot.flight=1
 for i in 3:
  var e=g.spawn_enemy("guard",at+Vector2(17*(i+1),-10.8*(i+1)));e.position=at+Vector2(17*(i+1),-10.8*(i+1));e.hp=100000
 g.rebuild_grid();shot.direction=Vector2.RIGHT;w.arsenal.tick(.4);assert(w.arsenal.shots.is_empty(),"third valid hit removes axe")
 g.clear_run();g.state="running";w.levels={"axe":1};w.arsenal.launch("axe");w.arsenal.shots[0].at=at+Vector2(1000,0);w.arsenal.shots[0].age=10;w.arsenal.tick(.01);assert(w.arsenal.shots.is_empty())
 var e=g.spawn_enemy("slime_small",Vector2(1100,630));assert(is_equal_approx(e.max_hp,(3.6+30)*g.balance.enemy_health_multiplier*g.enemy_scale().health))
 assert(is_equal_approx(g.player.sprite.scale.x,1.1) and is_equal_approx(e.sprite.scale.x,1.1))
 g.clear_run();assert(w.projectiles.is_empty() and w.arsenal.shots.is_empty());g.queue_free();await process_frame;print("FIXES23_PASS cooldown, fire, three axe hits, cleanup, small slime health, sprite scale");quit()
