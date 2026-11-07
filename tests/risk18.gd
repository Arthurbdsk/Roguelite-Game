extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.set_physics_process(false);g.persistence_enabled=false;g.test_mode=true;g.sound.volume=0
 var rows:Array=[]
 for scenario in ["siege","swarm"]:
  seed(18018);g.start_run();g.dev_boss_test=true;g.director.phase="complete";g.special_events.next_check=100000;g.chests.next_check=100000;g.consumables.next_check=100000
  g.weapon_system.levels={};g.player.clear_status();g.player.invulnerable=0;g.player.hp=10000;g.player.max_hp=10000;g.player.armor=0;g.player.damage_reduction=0
  if scenario=="siege":assert(g.special_events.start("siege"))
  else:
   for i in 225:
    var at:Vector2=g.player.position+Vector2.from_angle(i*2.4)*(38+int(i/14)*7)
    g.spawn_enemy("slime_small",at)
  var count:int=g.enemies.size();var hits:int=g.player.damage_revision
  for frame in 360:
   await physics_frame;g.simulate(1.0/60)
  rows.append({"scenario":scenario,"seconds":6,"starting_enemies":count,"damage_to_stationary_unarmored_fixture":10000-g.player.hp,"accepted_hits":g.player.damage_revision-hits,"remaining_projectiles":g.enemy_projectiles.arrows.size()})
  assert(g.player.attacker_until.size()<=count)
 print("RISK18 ",JSON.stringify(rows))
 var file=FileAccess.open("res://test_output/18-risk.json",FileAccess.WRITE);file.store_string(JSON.stringify(rows,"  "));file.close()
 g.clear_run();assert(g.enemy_projectiles.arrows.is_empty() and g.specials.bolts.is_empty())
 g.queue_free();await process_frame;await create_timer(.3).timeout;print("RISK18_PASS actual siege and 225 small enemies, no balancing compensation");quit()
