extends SceneTree
var errors:int=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 if not ok:errors+=1;printerr("FAIL "+label)
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.test_mode=true;g.start_run();g.dev_boss_test=true;g.sound.volume=0
 var w=g.weapon_system;var a=w.additions
 for id in NewWeapons16.IDS:
  check(w.weapon_data[id].damage.size()==8,"eight damage ranks "+id)
  w.levels={id:1};w.apply_upgrade(id);check(w.levels[id]==2,"one choice advances one rank "+id)
 var e=g.spawn_enemy("ghoul",g.player.position+Vector2(12,0));e.hp=10000;e.max_hp=10000;g.rebuild_grid()
 w.levels={"garlic":1};var hp:float=e.hp;a.tick(.01,true);check(e.hp<hp,"garlic immediate contact");hp=e.hp;e.position+=Vector2(300,0);a.tick(.01,true);e.position-=Vector2(300,0);a.tick(.01,true);check(e.hp==hp,"aura reentry cannot reset per-target cooldown")
 w.combat_time+=2;a.tick(.01,true);check(e.hp<hp,"aura recurring interval");e.apply_time_control(3,2,.3,1);check(is_equal_approx(e.frozen_remaining,3.45),"garlic boosts freeze within limit")
 a.reset();w.levels={"whip":2};e.position=g.player.position+Vector2(35,-12);g.rebuild_grid();hp=e.hp;a.launch("whip");a.tick(.11,true);check(e.hp<hp,"whip hits horizontal strip");hp=e.hp;a.tick(.01,true);check(e.hp==hp,"same strike cannot hit twice")
 a.reset();w.levels={"fire_wand":1};a.launch("fire_wand");check(a.shots.size()==3,"three fireballs in fixed fan")
 var direction:Vector2=a.shots[0].velocity;e.position+=Vector2(100,50);check(a.shots[0].velocity==direction,"fire direction does not track")
 a.reset();w.levels={"runetracer":1};a.projectile("runetracer",Vector2.RIGHT);var shot=a.shots[0];var bounds:Rect2=shot.bounds;shot.at=Vector2(bounds.end.x-5,g.player.position.y);a.tick(.1,true);check(shot.velocity.x<0 and shot.bounds==bounds,"rune bounces off immutable launch region")
 a.reset();w.levels={"magic_wand":4};a.launch("magic_wand");check(a.bursts.size()==3,"magic fires short sequence");a.tick(.01,true);check(a.shots.size()==1 and a.bursts.size()==2,"magic burst is sequential")
 var audit:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance16_audit.json"))
 for id in NewWeapons16.IDS:
  for level in range(1,9):
   a.reset();w.levels={id:level};a.launch(id);a.tick(.01,true)
   check(w._stat(id,"damage")>0 and w._interval(id)>=.15,"real values for "+id+" rank "+str(level))
 a.reset();w.levels={"fire_wand":1};e.position=g.player.position+Vector2(80,0);g.rebuild_grid()
 var wall:=StaticBody2D.new();wall.collision_layer=4;wall.position=g.player.position+Vector2(40,0)
 var shape:=CollisionShape2D.new();var rect:=RectangleShape2D.new();rect.size=Vector2(8,100);shape.shape=rect;wall.add_child(shape);g.add_child(wall);await physics_frame
 hp=e.hp;a.projectile("fire_wand",Vector2.RIGHT);a.tick(.6,true);check(a.shots.is_empty() and e.hp==hp,"fireball swept wall collision blocks damage")
 w.levels={"runetracer":1};a.projectile("runetracer",Vector2.RIGHT);var bouncing=a.shots[0];a.tick(.4,true);check(bouncing.velocity.x<0,"rune reflects from actual terrain body")
 wall.queue_free();await physics_frame
 a.reset();w.levels={"magic_wand":2};e.position=g.player.position+Vector2(60,0);g.rebuild_grid();a.launch("magic_wand");a.tick(.01,true)
 e.take_damage(999999)
 var replacement=g.spawn_enemy("ghoul",g.player.position-Vector2(90,0));g.rebuild_grid();a.tick(.13,true)
 check(a.shots.size()>0 and a.shots.back().velocity.x<0,"magic reevaluates living closest target between shots")
 for id in audit.global_20_percent:
  if not w.weapon_data.has(id):continue
  for i in 8:check(is_equal_approx(w.weapon_data[id].damage[i],float(audit.global_20_percent[id].before[i])*1.2*(1.1 if id=="garlic" else 2.0 if id=="fire_wand" else 1.0)),"exact global damage once "+id)
 g.queue_free();await process_frame;await create_timer(.3).timeout;print("WEAPONS16_%s"%("PASS" if errors==0 else "FAIL"));quit(int(errors>0))
