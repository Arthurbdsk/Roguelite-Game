extends SceneTree
var checks:int=0
var failures:int=0
var rows:Array=[]
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL "+label)
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.start_run();g.mastery.begin(false)
 for challenge in [0,5]:
  g.run_challenge=challenge
  for id in g.enemy_data:
   if id=="boss":continue
   g.elapsed=0
   var e=g.spawn_enemy(id,Vector2(900,730));check(e!=null,"spawn "+id)
   if e==null:continue
   var hazard:bool=e is HazardTarget
   var base:float=g.enemy_base_health(id)
   var event_factor:float=g.survival_config.events.siege_health if id=="siege_archer" else g.survival_config.events.blue_health if id=="event_blue" else g.survival_config.events.small_health if id=="event_small" else 1
   var expected:float=(base+30)*g.balance.enemy_health_multiplier*g.enemy_scale().health*event_factor
   if not hazard:check(is_equal_approx(e.max_hp,expected),"+30 before difficulty once "+id)
   rows.append({"enemy":id,"challenge":challenge,"base_before_bonus":base,"initial_hp":e.max_hp,"time_bonus":0})
   var initial:float=e.max_hp;g.elapsed=240;g.horde_progress.tick();var grown:float=e.max_hp
   for i in 3:g.horde_progress.apply(e)
   check(is_equal_approx(e.max_hp,grown),"time bonus idempotent "+id)
   if not hazard:check(is_equal_approx(grown-initial,70*event_factor),"existing timed health preserved "+id)
   if id in ["demon","horror"]:
    e.take_damage(1e9)
    var factor:float=g.boss_balance.second_health_multiplier if id=="demon" else g.campaign.config.true_health_ratio
    check(e.form==2 and is_equal_approx(e.max_hp,(grown-e.horde_health_bonus-e.spawn_health_bonus)*factor+e.horde_health_bonus+e.spawn_health_bonus),"transformation does not multiply or regrant +30 "+id)
   g.clear_run();g.state="running"
 g.run_challenge=0;g.elapsed=0
 var w=g.weapon_system
 var original:Array=[33.6,38.4,43.2,48,52.8,57.6,63.6,70.8]
 for level in range(1,9):
  w.reset();w.levels={"fire_wand":level};check(is_equal_approx(w._stat("fire_wand","damage"),original[level-1]*2),"fire double exactly once level %d"%level)
  check(is_equal_approx(w._interval("fire_wand"),9.8),"fire cooldown preserved")
  w.rng.seed=level;w.additions.launch("fire_wand");check(w.additions.shots.size()==int(w._stat("fire_wand","count")),"fire projectile count preserved")
 g.enemy_projectiles.fire_ball(Vector2(900,730),Vector2.RIGHT,123,1);check(is_equal_approx(g.enemy_projectiles.arrows.back().damage,g.boss_balance.fire_damage),"hostile fire damage unchanged")
 var f=FileAccess.open("res://build/audit24/enemy-health.json",FileAccess.WRITE);f.store_string(JSON.stringify(rows,"  "));f.close()
 g.clear_run();g.queue_free();await process_frame;await create_timer(.2).timeout
 print("HEALTH_FIRE24_%s checks=%d failures=%d"%["PASS" if failures==0 else "FAIL",checks,failures]);quit(int(failures>0))
