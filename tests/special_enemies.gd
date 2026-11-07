extends SceneTree
var g
var n=0
func check(v,label):
	n+=1
	assert(v,label)
func _initialize():call_deferred("run")
func run():
	g=load("res://scenes/main.tscn").instantiate();root.add_child(g)
	await process_frame
	g.sound.volume=0;g.start_run();g.director.phase="complete"
	var necro=g.spawn_enemy("necromancer",Vector2(700,700))
	check(g.specials.summon(necro),"seven-point conjuration begins")
	check(g.specials.marks.size()==7,"exactly seven warnings")
	g.specials.tick(1.1)
	check(g.specials.living(necro.get_instance_id())==7,"exactly seven live skeletons")
	check(not g.specials.summon(necro),"no second batch while children live")
	necro.take_damage(9999)
	check(g.enemies.size()==7,"caster death preserves children")
	var beast=g.spawn_enemy("beast",Vector2(500,500))
	check(is_equal_approx(beast.max_hp,g.enemy_data.ghoul.health*5*g.balance.enemy_health_multiplier),"beast HP")
	check(is_equal_approx(beast.data.speed,g.enemy_data.ghoul.speed*1.9*g.balance.enemy_speed_multiplier),"beast speed")
	g.player.hp=100;g.player.armor=0;g.player.invulnerable=0;g.player.apply_poison(10,2)
	for i in 600:g.player.tick_status(1.0/60)
	check(is_equal_approx(g.player.hp,80),"poison ten ticks = twenty damage")
	g.player.apply_poison(10,2);g.player.tick_status(1);g.player.apply_poison(10,2)
	check(g.player.poison_remaining==10,"exposure refreshes single timer")
	g.player.poison_remaining=0
	var shadow=g.spawn_enemy("shadow",g.player.position+Vector2(100,0));shadow.attack_time=0;shadow.tick(0)
	var mark=shadow.ambush_at
	g.player.position+=Vector2(100,0);var hp=g.player.hp
	shadow.tick(1.6)
	check(shadow.position.distance_to(mark)<1,"shadow marker fixed")
	check(g.player.hp==hp and g.player.root_remaining==0,"moving dodges ambush")
	check(shadow.targetable and shadow.state=="recovery","shadow exposed")
	g.clear_run();g.start_run();g.director.phase="complete"
	var interrupted=g.spawn_enemy("necromancer",Vector2(700,700));g.specials.summon(interrupted);interrupted.take_damage(9999);g.specials.tick(1.1)
	check(g.specials.marks.is_empty() and g.enemies.is_empty(),"caster death cancels uncompleted conjuration")
	g.state="running"
	var plague=g.spawn_enemy("plague",g.player.position+Vector2(180,0))
	plague.attack_time=0;plague.tick(0);plague.tick(.7)
	check(g.specials.areas.size()==1,"plague launches flask into telegraphed point")
	g.specials.tick(.9);check(g.player.poison_remaining==0,"warning is harmless")
	g.specials.tick(.11);check(g.player.poison_remaining==10,"impact applies poison")
	g.player.position+=Vector2(100,0);g.specials.tick(.1)
	check(g.player.poison_remaining==10,"leaving pool retains poison")
	g.specials.tick(5.91);check(g.specials.areas.is_empty(),"pool expires six seconds after impact")
	g.player.clear_status();g.player.hp=100;g.player.armor=0;g.player.invulnerable=0
	g.specials.magic(g.player.position-Vector2(20,0),Vector2.RIGHT,12)
	g.specials.tick(.2)
	check(g.player.hp==88 and g.specials.bolts.is_empty(),"magic travels fixed direction and is removed on hit")
	g.player.invulnerable=0;g.player.hp=100
	var attacker=g.spawn_enemy("shadow",g.player.position+Vector2(100,0));attacker.attack_time=0;attacker.tick(0)
	check(not attacker.targetable and not attacker.sprite.visible,"ambush hides and disables contact")
	attacker.tick(1.51);check(g.player.hp==83 and g.player.root_remaining==.75,"ambush hit damages and roots")
	g.player.apply_poison(10,2);g.finish_run(false)
	check(g.player.poison_remaining==0 and g.player.root_remaining==0,"end clears player effects")
	g.start_run();g.director.phase="complete";g.player.hp=1;g.player.invulnerable=0
	g.specials.magic(g.player.position-Vector2(20,0),Vector2.RIGHT,12);g.specials.tick(.2)
	check(g.state=="result" and g.specials.bolts.is_empty(),"lethal magic ends safely while cleaning projectile array")
	g.clear_run();check(g.specials.areas.is_empty() and g.specials.marks.is_empty(),"cleanup")
	g.queue_free();await process_frame;await create_timer(.2).timeout
	print("SPECIAL_ENEMIES_PASS checks=",n);quit()
