extends SceneTree
func _initialize():call_deferred("run")
func capture(id:String):
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://test_output/08-boss-"+id+".png")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.sound.volume=0;g.start_run();g.set_physics_process(false);g.director.phase="boss";g.player.invulnerable=1000
 g.weapon_system.levels.clear();g.boss_arena.begin_portal();g.boss_arena.tick(4)
 var boss=g.boss;var first:float=boss.max_hp;var initial_gold:int=g.gold
 boss.position=g.player.position+Vector2(110,0)
 assert(boss.sprite.hframes==32 and boss.visual_form==1)
 boss.begin_attack("fire");boss.tick(.2);await capture("form1-cast")
 boss.take_damage(999999)
 assert(g.state=="running" and g.gold==initial_gold and boss.max_hp==first*5)
 for i in 105:
  g.simulate(1.0/60);await physics_frame
  if i in [18,60,100]:await capture("transform-"+str(i))
 assert(boss.targetable and boss.visual_form==2)
 assert(g.enemy_projectiles.arrows.is_empty() and g.boss_arena.areas.is_empty())
 boss.begin_attack("fire")
 for i in 90:
  g.simulate(1.0/60);await physics_frame
  if i in [20,70]:await capture("form2-cast-"+str(i))
 boss.take_damage(1);boss.tick(.01);assert(boss.sprite.frame in [24,25]);await capture("form2-hit")
 boss.take_damage(999999);g.boss_arena.tick(.3);await capture("death")
 g.boss_arena.tick(2);assert(g.state=="result" and g.boss_defeated)
 g.clear_run();assert(g.boss_arena.deaths.is_empty());g.queue_free();await process_frame
 print("BOSS_VISUAL8_PASS both atlases, transform, five times HP, death once, cleanup");quit()
