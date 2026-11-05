extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.sound.volume=0
 var original=g.profile;var original_data:Dictionary=g.profile.data.duplicate(true);assert(g.dev_tools.enter());var dev=g.dev_tools
 for map in ["courtyard","library","fields"]:
  dev.map_id=map
  for id in dev.ENCOUNTERS:
   dev.encounter=id;dev.participants=3;dev.load_preset(dev.ENCOUNTERS[id][2]);dev.build.attacks=false
   assert(dev.start_encounter(),map+" "+id);var boss=g.boss
   assert(g.enemies.filter(func(e):return e is HordeBoss).size()==1 and g.elapsed==dev.ENCOUNTERS[id][1])
   assert(g.arena.safe_position(g.player.position,7) and g.arena.safe_position(boss.position,boss.radius))
   if id in ["demon1","demon2"]:assert(is_equal_approx(boss.max_hp,g.boss_balance.demon_health()*1.6*2*(5 if id=="demon2" else 1)))
   if id in ["horror","true"]:assert(is_equal_approx(boss.max_hp,14976*2.2*2*(1.5 if id=="true" else 1)))
   g.campaign.tick();assert(g.enemies.filter(func(e):return e is HordeBoss).size()==1)
   var life:float=g.player.hp;g.player.take_damage(900,g.player.position);g.player.apply_poison(10,2);g.player.tick_status(2);assert(g.player.hp==life)
   var weapons:Dictionary=g.weapon_system.levels.duplicate();g.weapon_system.update_combat(.5);assert(g.weapon_system.projectiles.is_empty() and g.weapon_system.lightning_fx.is_empty())
   var stats:String=g.weapon_system.build_stats();assert(dev.start_encounter());assert(g.weapon_system.build_stats()==stats and g.weapon_system.levels==weapons)
   assert(g.arena.dynamic_walls.is_empty() and g.enemy_projectiles.arrows.is_empty() and g.specials.marks.is_empty())
   print("DEV_ENCOUNTER11 ",map," ",id)
 dev.set_time(.5);assert(Engine.time_scale==.5);dev.set_time(2);assert(Engine.time_scale==2)
 dev.encounter="demon1";dev.start_encounter();assert(dev.next_phase() and g.boss.form==2 and g.boss.state=="transform")
 dev.freeze(true);var clock:float=g.boss.state_time;g.boss.tick(.5);assert(g.boss.state_time==clock);dev.freeze(false);g.boss.tick(2);assert(g.boss.targetable)
 assert(dev.force_attack("fire",true));g.boss.state="chase";g.boss.attack_time=0;g.boss.tick(.01);assert(g.boss.state=="windup" and g.boss.attack_name=="fire")
 g.boss.tick(1);assert(g.boss.state=="recovery");dev.normal_sequence();assert(g.boss.dev_repeat.is_empty())
 dev.health_percent(25);assert(is_equal_approx(g.boss.hp,g.boss.max_hp*.25))
 dev.end_test();assert(Engine.time_scale==1 and g.profile==original and g.profile.data==original_data and not g.player.dev_invulnerable)
 g.queue_free();await process_frame;await create_timer(.3).timeout;print("DEV_ENCOUNTERS11_PASS 18 map/encounter cases, scaling once, real transitions, build idempotence, invulnerability, attacks toggle, freeze, clean restart and original restored");quit()
