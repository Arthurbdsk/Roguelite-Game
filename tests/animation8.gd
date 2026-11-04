extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.start_run();g.set_physics_process(false);g.sound.volume=0;var p=g.player
 g.weapon_system.levels.clear();p.tick_visual(.1);assert(p.sprite.frame in range(0,4))
 p.tick_visual(.1,true);assert(p.sprite.frame in range(16,24))
 p.begin_swing(Vector2.RIGHT);p.tick_visual(.1);assert(p.sprite.frame in range(10,16))
 p.hurt_remaining=.2;p.tick_visual(.01);assert(p.sprite.frame in [24,25])
 p.down=true;p.visual_clock=0
 p.tick_visual(.6);assert(p.sprite.frame==28);p.tick_visual(1);assert(p.sprite.frame==28)
 p.down=false;p.revive_remaining=.45;p.tick_visual(.01);assert(p.sprite.frame in range(29,32))
 p.clear_status();assert(p.hurt_remaining==0 and p.swing_remaining==0 and p.revive_remaining==0)
 assert(p.radius==7 and p.max_hp==100)
 g.queue_free();await process_frame;await create_timer(.3).timeout;print("ANIMATION8_PASS idle, walk, sword, damage, down hold, revive, reset; physical radius preserved");quit()
