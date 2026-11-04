extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.start_run();g.sound.volume=0;g.director.phase="complete"
 g.late_arena.begin_encounter("horror");g.late_arena.tick(1.3);var boss=g.boss
 var first:float=boss.max_hp;var gold:int=g.gold;boss.take_damage(999999)
 assert(g.state=="running" and g.gold==gold and boss.form==2 and is_equal_approx(boss.max_hp,first*1.5))
 assert(not boss.targetable and g.late_arena.areas.is_empty() and g.arena.dynamic_walls.is_empty())
 boss.tick(.9);assert(boss.visual_form==2);boss.tick(.8);assert(boss.targetable)
 g.ui.update_hud(g.snapshot());assert(g.ui.true_health.visible and not g.ui.boss_bar.visible and g.ui.life_bar.visible)
 var before_size:Vector2=g.ui.true_health.ornament.size;boss.take_damage(first*.25);g.ui.update_hud(g.snapshot())
 assert(g.ui.true_health.ornament.size==before_size and g.ui.true_health.fill.value<g.ui.true_health.fill.max_value)
 await process_frame;await process_frame;await RenderingServer.frame_post_draw;save_capture("res://test_output/10-true-form.png")
 boss.take_damage(999999);assert(g.gold==gold+int(g.campaign.config.horror_reward));var paid:int=g.gold;boss.take_damage(999999);assert(g.gold==paid)
 g.late_arena.tick(2);assert(g.state=="result" and g.campaign.completed.horror)
 g.campaign.encounter_finished("horror");assert(g.gold==paid)
 g.start_late_test("guardian");assert(g.dev_boss_test and not g.persistence_enabled)
 g.queue_free();await process_frame;await create_timer(.3).timeout;print("TRUE10_PASS 1.5 HP transform, no early reward, separate HUD, victory/reward once, development shortcut");quit()

func save_capture(path:String):
 var output:String=ProjectSettings.globalize_path(path)
 DirAccess.make_dir_recursive_absolute(output.get_base_dir())
 assert(root.get_texture().get_image().save_png(output)==OK)
