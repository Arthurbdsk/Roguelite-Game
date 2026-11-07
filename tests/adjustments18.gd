extends SceneTree
var errors:int=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 if not ok:errors+=1;printerr("FAIL "+label)
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.set_physics_process(false);g.persistence_enabled=false;g.test_mode=true;g.sound.volume=0;g.start_run()
 var w=g.weapon_system
 check(not w.weapon_data.has("blades"),"retired weapon absent")
 w.levels={"blades":8,"orbit":3,"bolt":1}
 check(not w.levels.has("blades") and w.get_loadout().size()==2 and w.levels.orbit==3,"old build drops invisible slot, fire orbit preserved")
 check(not w.apply_upgrade("blades"),"retired weapon cannot be bought or awarded")
 for offer in w.get_offers():check(offer.id!="blades","no retired offers")
 var audit:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance18_audit.json"))
 for level in 8:
  w.levels={"fire_wand":level+1};w.passives={"cadence":4}
  check(is_equal_approx(w.weapon_data.fire_wand.cooldown[level],float(audit.fire_wand.cooldown[level])+7),"fire base +7 once")
  check(is_equal_approx(w._interval("fire_wand"),(float(audit.fire_wand.cooldown[level])+7)*.76),"fire increase before cooldown modifier")
 w.passives={};w.levels={"fire_wand":1};w.rng.seed=1802
 var sectors:Array=[0,0,0,0,0,0,0,0]
 for i in 256:
  w.additions.reset();check(w.additions.launch("fire_wand"),"fire without any enemies")
  check(w.additions.shots.size()==3,"same three-ball fan")
  var angle:float=fposmod(Vector2(w.additions.shots[1].velocity).angle(),TAU)
  sectors[int(angle/TAU*8)]+=1
 check(sectors.all(func(n):return n>10),"random direction covers 360 degrees")
 for level in 8:
  w.levels={"runetracer":level+1};w.passives={"cadence":4}
  check(is_equal_approx(w.weapon_data.runetracer.cooldown[level],float(audit.runetracer.cooldown[level])+4),"rune base +4 once")
  check(is_equal_approx(w._interval("runetracer"),(float(audit.runetracer.cooldown[level])+4)*.76),"rune increase before cooldown modifier")
 for level in 8:check(is_equal_approx(w.weapon_data.garlic.damage[level],float(audit.garlic.damage[level])*1.1),"garlic damage +10 only")
 w.reset();w.levels={"garlic":1};g.rebuild_grid()
 var e=g.spawn_enemy("ghoul",g.player.position+Vector2(10,0));e.hp=10000;g.rebuild_grid()
 w.additions.tick(.01,true)
 check(is_equal_approx(e.movement_control_multiplier(),.85),"garlic slows inside")
 check(e.knockback.x>0,"garlic initial outward push")
 e.knockback=Vector2.ZERO;e.position+=Vector2(100,0)
 check(e.movement_control_multiplier()==1,"garlic slow removed immediately outside")
 e.position-=Vector2(100,0);g.rebuild_grid();w.additions.tick(.01,true)
 check(e.knockback==Vector2.ZERO,"reentry cannot repeat initial push")
 e.garlic_sources[999]=weakref(w);check(is_equal_approx(e.movement_control_multiplier(),.85),"multiple garlic sources do not stack")
 e.slow_remaining=1;e.slow_factor=.7;check(is_equal_approx(e.movement_control_multiplier(),.7),"stronger existing slow preserved")
 check(DisplayNumbers.seconds(.4)=="400 ms" and DisplayNumbers.seconds(1.2)=="1200 ms","integer time units")
 check(DisplayNumbers.regeneration(.1)=="1 de vida a cada 10 s","fractional regeneration preserved in description")
 check(DisplayNumbers.change("Dano",10.1,10.2,1).contains("1%"),"same rounded values show actual change")
 var decimal:=RegEx.new();decimal.compile("[0-9]+[.,][0-9]+")
 for id in w.weapon_data:
  for rank in 8:check(decimal.search(w.upgrade_values(id,rank))==null,"no decimal upgrade "+id)
 check(decimal.search(w.build_stats())==null,"no decimals in final stats")
 check(e.hp!=roundf(e.hp),"damage fractions remain internal")
 var p=g.player;p.clear_status();p.invulnerable=0;p.armor=0;p.damage_reduction=0;p.hp=100;p.max_hp=100
 check(p.take_damage(10,p.position,101) and p.take_damage(10,p.position,102) and p.hp==80,"different enemies hit in same instant")
 check(not p.take_damage(10,p.position,101) and p.hp==80,"same enemy shares cooldown across attacks")
 p.tick_status(.399);check(not p.take_damage(10,p.position,101),"same enemy blocked at 399 ms")
 p.tick_status(.001);check(p.take_damage(10,p.position,101),"same enemy accepted at 400 ms")
 p.invulnerable=2;check(not p.take_damage(10,p.position,103),"explicit revive protection preserved")
 p.invulnerable=0;p.dev_invulnerable=true;check(not p.take_damage(10,p.position,104),"DEV protection preserved");p.dev_invulnerable=false
 p.clear_status();p.hp=100;p.apply_poison(10,2,200);p.tick_status(10)
 check(p.hp==80 and p.poison_remaining==0,"ten seconds of poison retain twenty fractional-capable damage")
 p.hp=100;p.clear_status();p.apply_poison(10,2,201);p.take_damage(1,p.position,201);p.tick_status(.1)
 check(not p.take_damage(1,p.position,201),"poison caster identity shared with other attacks")
 for species in ["skeleton_archer","skeleton_sword","beast","necromancer","plague","shadow"]:
  var enemy=g.spawn_enemy(species,g.player.position+Vector2(300,200))
  if enemy!=null:check(is_equal_approx(enemy.data.attack_interval,g.enemy_data[species].attack_interval*.85),"enemy interval -15 only "+species)
 var boss=g.spawn_enemy("executioner",Vector2(1400,900))
 check(is_equal_approx(boss.data.attack_interval,g.enemy_data.executioner.attack_interval),"boss attack interval preserved")
 p.clear_status();p.invulnerable=0;p.hp=100;g.enemy_projectiles.reset()
 var stats=g.enemy_data.skeleton_archer
 g.enemy_projectiles.fire(p.position-Vector2(2,0),Vector2.RIGHT,stats,900,300)
 g.enemy_projectiles.fire(p.position-Vector2(2,0),Vector2.RIGHT,stats,900,300)
 g.enemy_projectiles.tick(.02)
 check(p.hp==100-stats.damage,"two projectiles of same enemy share 400 ms gate")
 check(not p.take_damage(1,p.position,300) and p.take_damage(1,p.position,301),"projectile and melee share identity, other enemy remains independent")
 var legacy:=GameProfile.new("user://adjustments18_fixture.json");legacy.data.gold=891;legacy.data.settings.erase("music");check(legacy.save(),"legacy profile fixture saved")
 var migrated:=GameProfile.new(legacy.path);check(migrated.load_profile() and migrated.data.gold==891 and is_equal_approx(migrated.data.settings.music,.35),"old save gains music default without losing gold")
 migrated.data.settings.music=.25;check(migrated.save(),"new preference saved")
 var reloaded:=GameProfile.new(legacy.path);check(reloaded.load_profile() and reloaded.data.gold==891 and reloaded.data.settings.music==.25,"music preference survives reload")
 DirAccess.remove_absolute(legacy.path);DirAccess.remove_absolute(legacy.path+".bak")
 g.queue_free();await process_frame;await process_frame
 print("ADJUSTMENTS18_"+("PASS" if errors==0 else "FAIL"));quit(int(errors>0))
