extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.sound.volume=0;g.start_run();var w=g.weapon_system
 w.levels={"lightning":3,"holy_water":1,"clock":1}
 var selection:float=w._stat("lightning","reach");w.passives={"lens":8,"hourglass":8,"cadence":8}
 assert(w._stat("lightning","reach")==selection)
 assert(is_equal_approx(w._stat("holy_water","reach"),36*1.4))
 assert(is_equal_approx(w._stat("holy_water","duration"),4*1.64))
 for id in w.weapon_data:w.levels[id]=8;assert(w._interval(id)>=.15)
 var e=g.spawn_enemy("guard",Vector2(700,700));e.apply_time_control(3,2,.3,1);e.tick_control(3)
 for i in 4:e.apply_time_control(3,2,.3,1)
 assert(e.frozen_remaining==0 and e.freeze_resistance==2)
 g.player.armor=1000;g.player.invulnerable=0;g.player.take_damage(100,Vector2.ZERO);assert(g.player.hp==80)
 g.queue_free();await process_frame;await create_timer(.3).timeout;print("COMPAT7_PASS area compatibility, duration, minimum interval, freeze immunity and armor floor");quit()
