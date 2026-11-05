extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.sound.volume=0
 var original=g.profile;var before:Dictionary=original.data.duplicate(true);var d=g.dev_tools;d.enter();d.start_survival(true)
 assert(g.campaign.endless and g.elapsed==1200 and g.enemies.is_empty());d.set_survival_time(360);assert(g.horde_progress.stage()==3)
 d.force_event("siege");assert(g.enemies.size()==20);d.force_chest();assert(not g.chests.chest.is_empty());d.show_colliders=true;d._process(.1);assert(d.collider_overlay.visible)
 d.start_survival();assert(g.special_events.active=="" and g.enemies.is_empty() and g.chests.chest.is_empty());d.end_test();assert(g.profile==original and g.profile.data==before)
 g.queue_free();await process_frame;await create_timer(.2).timeout;print("DEV_SURVIVAL13_PASS time/stage, direct infinite, real event/chest, collider overlay, restart and original profile intact");quit()
