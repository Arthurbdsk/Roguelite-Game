extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.start_run();g.sound.volume=0
 g.elapsed=599;g.campaign.tick();assert(g.campaign.history.is_empty())
 var old=g.spawn_enemy("executioner",Vector2(1100,630));g.elapsed=610;g.campaign.tick();assert(g.campaign.history.is_empty())
 old.take_damage(999999);g.boss_arena.tick(2);g.campaign.tick();assert(g.campaign.history==["demon"])
 g.campaign.tick();assert(g.campaign.history.size()==1);g.boss_arena.tick(4)
 var boss=g.boss;var first:float=boss.max_hp;var before:int=g.gold;var level:int=g.level
 boss.take_damage(999999);assert(boss.form==2 and boss.max_hp==first*5 and g.gold==before)
 boss.tick(2);boss.take_damage(999999);g.boss_arena.tick(2)
 assert(g.state=="running" and g.campaign.completed.has("demon") and g.gold==before+g.boss_balance.demon_reward)
 assert(g.elapsed==610 and g.level==level and g.director.phase=="preparing")
 g.campaign.encounter_finished("demon");assert(g.gold==before+g.boss_balance.demon_reward)
 g.director.wave_index=14;g.director.begin_wave();assert(g.director.wave_index==15 and not g.director.queue.is_empty())
 g.elapsed=900;g.campaign.tick();assert(g.state=="running")
 g.queue_free();await process_frame;await create_timer(.3).timeout;print("CAMPAIGN10_PASS 600 deadline, prior boss pending, demon two phases, reward once, no early victory, continuing waves/build/time");quit()
