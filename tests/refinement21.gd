extends SceneTree
var g
var checks:int=0
func check(ok:bool,label:String):
 checks+=1
 if not ok:push_error(label);quit(1)
func _initialize():call_deferred("run")
func enemy(at:Vector2):
 var e=g.spawn_enemy("ghoul",at);e.hp=1000;e.max_hp=1000;return e
func clear():
 for e in g.enemies:if is_instance_valid(e):e.queue_free()
 g.enemies.clear();g.weapon_system.projectiles.clear();g.rebuild_grid()
func run():
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.set_physics_process(false);g.persistence_enabled=false;g.start_run();g.player.dev_invulnerable=true
 var w=g.weapon_system
 var e=enemy(Vector2(1100,630));g.rebuild_grid();w.levels={"bolt":3}
 check(w._fire_bolts() and w.projectiles.size()==3,"three arrows launched")
 for s in w.projectiles:check(Vector2(s.velocity).normalized().dot((e.position-Vector2(s.position)).normalized())>.99999,"each arrow aims from its own origin")
 w._update_projectiles(.8);check(e.hp<950,"stationary target hit by extra arrows")
 clear();e=enemy(Vector2(1100,670));e.motion_start=Vector2(1100,590);g.rebuild_grid()
 w.projectiles.append({"position":Vector2(900,630),"velocity":Vector2(4000,0),"distance":0.0,"reach":400.0,"damage":10.0,"pierce":1,"bounce":0,"hits":[]})
 w._update_projectiles(.1);check(e.hp==990,"relative sweep hits moving target at high speed")
 clear();var far=enemy(Vector2(1080,630));var near=enemy(Vector2(1020,630));g.rebuild_grid()
 w.projectiles.append({"position":Vector2(900,630),"velocity":Vector2(4000,0),"distance":0.0,"reach":400.0,"damage":10.0,"pierce":1,"bounce":0,"hits":[]})
 w._update_projectiles(.1);check(near.hp==990 and far.hp==1000,"nearest time of impact wins regardless of spawn order")
 clear();e=enemy(Vector2(1100,630));g.arena.add_obstacle(Rect2(1040,610,10,40));g.rebuild_grid();w._fire_bolts();w._update_projectiles(.8)
 check(e.hp==1000 and w.projectiles.is_empty(),"wall blocks arrows before target")
 clear();e=enemy(Vector2(1159,630));g.player.position=Vector2(900,730);e.position=Vector2(1159,730);g.rebuild_grid();w.levels={"bolt":1};w._fire_bolts()
 check(w.projectiles.is_empty(),"no dead or out of selection range target")
 e.position=Vector2(1139,730);g.rebuild_grid();w._fire_bolts();check(w.projectiles[0].reach>w.projectiles[0].selection_range,"flight distance distinct from selection")
 w._update_projectiles(1);check(e.hp<1000,"edge of selection target reached")
 clear();var shadow=g.spawn_enemy("shadow",Vector2(1100,630));shadow.motion_start=shadow.position;shadow.state="ambush";shadow.state_time=2;shadow.ambush_at=Vector2(1120,730);shadow.tick(.016)
 check(shadow.motion_start==shadow.ambush_at,"teleporting Shadow is not swept through its invisible travel")
 print("BOW21_PASS checks=",checks)
 g.queue_free();await process_frame;await create_timer(.3).timeout;quit()
