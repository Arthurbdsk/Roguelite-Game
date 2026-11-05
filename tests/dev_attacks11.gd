extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.sound.volume=0
 var dev=g.dev_tools;dev.enter();var count:int=0
 for id in dev.ENCOUNTERS:
  dev.encounter=id;dev.load_preset(dev.ENCOUNTERS[id][2]);dev.build.attacks=false;dev.start_encounter()
  var boss=g.boss
  for attack in dev.attacks():
   g.boss_arena.clear_for_transform();g.late_arena.clear_attacks(boss);g.enemy_projectiles.reset();g.specials.reset()
   boss.state="chase";boss.attack_time=0
   assert(dev.force_attack(attack));boss.tick(.01)
   assert(boss.state=="windup" and boss.attack_name==attack)
   boss.tick(boss.warning_duration()+.01)
   assert(boss.state in ["recovery","charge"])
   if boss.state=="charge":boss.tick(1.1);assert(boss.state=="recovery")
   count+=1
  if id in ["horror","true"]:
   g.late_arena.clear_attacks(boss);assert(dev.force_attack("fire",true));boss.state="chase";boss.attack_time=0;boss.tick(.01);boss.tick(1.3)
   assert(not g.late_arena.bursts.is_empty());dev.freeze(true);var pos:Vector2=boss.position;var time:float=boss.state_time
   boss.tick(.5);g.late_arena.tick(.5)
   assert(boss.position==pos and boss.state_time==time and not g.enemy_projectiles.arrows.is_empty())
   dev.freeze(false);dev.normal_sequence();assert(boss.dev_repeat.is_empty())
 dev.hordes=true;dev.participants=4;dev.encounter="guardian";dev.start_encounter()
 var wave:WaveData=g.campaign.wave(g.director.wave_index+1);var expected:int=0
 for amount in g.coop.rules.composition(wave.composition,4).values():expected+=amount
 g.director.begin_wave();assert(g.director.queue.size()==expected+g.coop.rules.wave_count(wave.elite_guards,4))
 assert(g.enemies.filter(func(e):return e is HordeBoss).size()==1)
 dev.hordes=false;dev.start_encounter();assert(g.director.phase=="complete" and g.director.queue.is_empty())
 dev.build={"level":80,"weapons":{"sword":8},"passives":{"heart":8},"permanent":true,"invulnerable":false,"attacks":false}
 g.profile.data.upgrade_ranks={"health":5,"damage":5};dev.apply_build();var hp:float=g.player.max_hp;dev.apply_build();assert(g.player.max_hp==hp and hp==205 and g.mastery.damage_multiplier==1.25)
 dev.build.permanent=false;dev.apply_build();assert(g.player.max_hp==180 and g.mastery.damage_multiplier==1)
 g.player.hp=10;dev.heal();assert(g.player.hp==180);assert(not g.player.dev_invulnerable)
 dev.end_test();g.queue_free();await process_frame;await create_timer(.3).timeout
 print("DEV_ATTACKS11_PASS attacks=",count," real windup/recovery, frozen boss/live effects, horde scale once, permanent toggle/idempotence and heal");quit()
