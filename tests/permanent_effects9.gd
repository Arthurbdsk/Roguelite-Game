extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.sound.volume=0
 for d in g.skills.definitions:g.profile.data.upgrade_ranks[d.id]=d.max_rank()
 g.start_run();g.director.phase="complete";var p=g.player;var w=g.weapon_system
 assert(is_equal_approx(p.max_hp,125) and is_equal_approx(p.speed,110.4) and is_equal_approx(p.pickup_radius,63))
 assert(is_equal_approx(p.gold_collection_radius(),g.balance.coin_attraction_radius*1.5))
 assert(is_equal_approx(g.mastery.damage_multiplier,1.25) and is_equal_approx(g.mastery.interval_multiplier,.9))
 p.hp=100;g.mastery.tick(10,0);assert(is_equal_approx(p.hp,105));p.down=true;g.mastery.tick(10,0);assert(p.hp==105);p.down=false
 assert(is_equal_approx(p.received_damage(100),85));p.armor=1000;assert(p.received_damage(100)==20);p.armor=0
 w.levels={"holy_water":1,"bolt":1,"lightning":1,"clock":1,"sludge":1,"bombs":1}
 assert(is_equal_approx(pow(w._stat("holy_water","reach")/w.weapon_data.holy_water.reach[0],2),1.25))
 assert(is_equal_approx(w._stat("lightning","reach"),w.weapon_data.lightning.reach[0]))
 assert(w._stat("holy_water","count")==2 and w._stat("lightning","count")==w.weapon_data.lightning.count[0])
 assert(is_equal_approx(w._stat("holy_water","duration"),5));assert(is_equal_approx(w.projectile_factor(),1.25))
 w.passives.crown=8;g.xp_needed=10000;g.add_xp(100);assert(is_equal_approx(g.xp,166))
 for i in 20:g.mastery.on_gold(1)
 assert(g.mastery.gold_bonus==5)
 w.levels={"sword":1};w.passives.clear();w.rng.seed=4321;var fourth:int=0
 for i in 1000:
  var offers:Array=w.get_offers();var ids:Array=[]
  if offers.size()==4:fourth+=1
  for o in offers:assert(not ids.has(o.id));ids.append(o.id)
 assert(fourth>240 and fourth<360);print("LUCK9 fourth_options=",fourth," / 1000")
 g.start_run();assert(is_equal_approx(p.max_hp,125));g.director.phase="complete";p.hp=1;p.invulnerable=0;p.take_damage(100,p.position)
 assert(g.state=="revive_offer" and not g.mastery.last_stand_spent)
 g.use_solo_revive();assert(p.hp==50 and p.invulnerable==2 and g.mastery.last_stand_spent)
 p.invulnerable=0;p.take_damage(1000,p.position);assert(g.state=="result")
 g.queue_free();await process_frame;await create_timer(.3).timeout;print("PERMANENT_EFFECTS9_PASS base stats, regen, damage floor, area sqrt, projectiles, fractions, additive XP, luck, solo revive once, restart");quit()
