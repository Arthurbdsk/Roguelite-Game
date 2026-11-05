extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.profile=GameProfile.new("user://endless13_fixture.json");g.profile.save();g.persistence_enabled=true;g.start_run();g.sound.volume=0
 g.elapsed=1230;g.gold=73;g.weapon_system.levels={"sword":8,"lightning":5};g.level=42;g.campaign.encounter_finished("horror")
 assert(g.state=="endless_choice" and not g.run_settled and g.campaign.cleared)
 g.campaign.vote(true);assert(g.state=="running" and g.campaign.endless and g.elapsed==1230 and g.gold==73 and g.level==42 and g.weapon_system.levels.sword==8)
 g.horde_progress.tick();assert(g.horde_progress.stage()==10)
 g.finish_run(false);assert(g.run_settled and g.banked_gold==73 and g.profile.data.wins==1 and g.profile.data.gold==73);g.finish_run(false);assert(g.banked_gold==73 and g.profile.data.gold==73)
 var loaded=GameProfile.new(g.profile.path);assert(loaded.load_profile() and loaded.data.wins==1 and loaded.data.gold==73)
 g.start_run();assert(not g.campaign.cleared);g.campaign.offer_endless();g.campaign.decision_tick(31);assert(g.state=="result")
 g.queue_free();await process_frame;await create_timer(.2).timeout;print("ENDLESS13_PASS post-boss choice, preserved run, time stage, victory retained on later death, timeout and single settlement");quit()
