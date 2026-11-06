extends SceneTree
var errors:int=0
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
 if not ok:errors+=1;printerr("FAIL "+message)
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.set_physics_process(false);g.persistence_enabled=false;g.test_mode=true;g.sound.volume=0;g.start_run()
 var c=g.consumables
 check(c.spawn_item("food",g.player.position),"spawn food")
 var item=c.items[0]
 check(not c.collect(item,g.player) and c.items.size()==1,"full health leaves food")
 g.player.hp=80
 check(c.collect(item,g.player) and g.player.hp==100,"heals only missing 20")
 check(not c.collect(item,g.player),"duplicate collection rejected")
 check(g.profile.data.discoveries.has("consumable:food"),"individual discovery")
 g.player.hp=10;c.spawn_item("food",g.player.position);c.collect(c.items[0],g.player)
 check(g.player.hp==40,"exact heal 30")
 c.spawn_item("food",g.player.position+Vector2(80,0));g.state="paused";c.tick(95)
 check(c.items.size()==1,"pause stops expiration")
 g.state="running";c.tick(90)
 check(c.items.is_empty(),"expires without activation")
 g.mastery.bonuses.gold=.25
 c.spawn_item("gold_bag",g.player.position);item=c.items[0];var before_gold:int=g.gold
 check(c.collect(item,g.player) and g.gold-before_gold==125,"bag applies 25 percent once")
 check(not c.collect(item,g.player) and g.gold-before_gold==125,"bag cannot pay twice")
 g.pickups.clear();g.drop_xp(g.player.position,2.75);g.drop_xp(g.player.position,3.25)
 c.spawn_item("xp_magnet",g.player.position);c.collect(c.items[0],g.player)
 g.drop_xp(g.player.position+Vector2(200,0),1)
 var before_xp:float=g.xp;g.xp_needed=999999;c.tick_magnet(1)
 check(is_equal_approx(g.xp-before_xp,6) and g.pickups.size()==1,"magnet grants exact existing XP, excludes later drops")
 check(c.magnet_jobs.is_empty(),"magnet batches finish without new XP")
 var slime=g.spawn_enemy("slime_large",g.player.position+Vector2(60,0));var far=g.spawn_enemy("ghoul",Vector2(1700,1100));var necro=g.spawn_enemy("necromancer",g.player.position+Vector2(90,0))
 c.spawn_item("cleanse",g.player.position);c.collect(c.items[0],g.player)
 check(not slime.alive and not necro.alive and far.alive and g.slime_families.pending.is_empty(),"cleanse real deaths, no slime split, distant enemy remains")
 var e=g.spawn_enemy("skeleton_archer",g.player.position+Vector2(80,0));e.state="prepare";e.state_time=.1
 g.enemy_projectiles.fire(e.position,Vector2.RIGHT,e.data)
 c.spawn_item("stopwatch",g.player.position);c.collect(c.items[0],g.player)
 var at:Vector2=e.position;var arrow_at:Vector2=g.enemy_projectiles.arrows[0].at;e.tick(1);g.enemy_projectiles.tick(1)
 check(e.position==at and e.state_time==.1 and g.enemy_projectiles.arrows[0].at==arrow_at,"clock suspends movement, windup and projectile")
 var fresh=g.spawn_enemy("ghoul",g.player.position+Vector2(120,0));at=fresh.position;fresh.tick(1)
 check(fresh.position==at,"new enemy frozen during global clock")
 e.take_damage(1);check(e.hp<e.max_hp,"frozen enemy receives damage")
 c.freeze_left=4;c.spawn_item("stopwatch",g.player.position);c.collect(c.items[0],g.player);check(c.freeze_left==10,"second clock renews to ten")
 var boss=g.spawn_enemy("demon",g.player.position+Vector2(210,0));c.spawn_item("stopwatch",g.player.position);c.collect(c.items[0],g.player)
 check(boss.frozen_remaining==0 and boss.slow_remaining==3 and is_equal_approx(boss.slow_factor,.7),"boss receives only 30 percent slow for three seconds")
 c.freeze_left=0;c.last_spawn=-1000;c.next_check=60;g.mastery.ranks.luck=3
 check(is_equal_approx(c.chance(),.21),"luck adds two percentage points per rank")
 g.clear_run();g.queue_free();await process_frame;await process_frame;await create_timer(.3).timeout
 print("CONSUMABLES15_%s"%("PASS" if errors==0 else "FAIL"));quit(int(errors>0))
