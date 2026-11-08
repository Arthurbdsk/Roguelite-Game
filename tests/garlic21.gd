extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.start_run()
 var w=g.weapon_system;var old:Array=[28,38,38,43,43,49,49,55]
 for i in 8:
  w.levels={"garlic":i+1};assert(is_equal_approx(w._stat("garlic","reach"),old[i]*1.15))
  assert(is_equal_approx(w.weapon_data.garlic.damage[i],[7.92,9.24,10.56,13.2,15.84,19.8,21.12,26.4][i]))
 w.passives={"lens":8};g.mastery.bonuses.area=.25
 var reach:float=w._stat("garlic","reach");assert(reach>63.25)
 var e=g.spawn_enemy("ghoul",g.player.position+Vector2(reach+7,0));e.hp=1000;g.rebuild_grid();w.additions.tick(.01,true)
 assert(e.hp<1000 and e.movement_control_multiplier()==.85)
 var hp:float=e.hp;w.additions.tick(.01,true);assert(e.hp==hp,"per target interval preserved")
 print("GARLIC21_PASS radius +15% once in eight levels, damage and slow preserved; max radius=",reach)
 g.queue_free();await process_frame;await create_timer(.3).timeout;quit()
