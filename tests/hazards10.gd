extends SceneTree
var failures:int=0
func _initialize():call_deferred("run")
func check(ok:bool,description:String):
 if not ok:failures+=1;printerr("FAIL: ",description)
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.sound.volume=0
 for scenario in [{"map":"courtyard","facing":Vector2.DOWN},{"map":"library","facing":Vector2.DOWN},{"map":"fields","facing":Vector2.DOWN},{"map":"courtyard","facing":Vector2.RIGHT}]:
  var map:String=scenario.map
  g.selected_map=map;g.start_late_test("horror");g.weapon_system.levels.clear();g.player.position=Vector2(900,630);g.player.facing=scenario.facing
  g.late_arena.tick(1.3);var boss=g.boss
  check(g.late_arena.cast("ice",boss),map+" safe ice plan")
  g.late_arena.tick(1.6);await physics_frame
  var rect:Rect2=Rect2(g.late_arena.areas[0].at-g.late_arena.areas[0].size/2,g.late_arena.areas[0].size)
  if scenario.facing==Vector2.RIGHT:check(rect.size.y>rect.size.x,"vertical wall in actual courtyard")
  var side:Vector2=Vector2.DOWN if rect.size.x>rect.size.y else Vector2.RIGHT
  var along:Vector2=Vector2.RIGHT if rect.size.x>rect.size.y else Vector2.DOWN
  var start:Vector2=rect.get_center()+along*(rect.size.dot(along)/2-35)-side*(rect.size.dot(side)/2+35)
  var target:Vector2=start+side*(rect.size.dot(side)+75)
  g.player.position=start
  for i in 55:await physics_frame;g.player.tick(1.0/60,side)
  check(not rect.has_point(g.player.position) and (g.player.position-rect.get_center()).dot(side)<0,map+" player cannot cross solid wall")
  g.player.position=target
  for id in ["ghoul","beast"]:
   var enemy=g.spawn_enemy(id,start);enemy.attack_time=1000
   for i in 400:
    await physics_frame;g.navigation.tick(1.0/60);g.rebuild_grid();enemy.tick(1.0/60)
    if enemy.position.distance_to(target)<35:break
   check(enemy.position.distance_to(target)<35,map+" "+id+" routes around dynamic wall")
   check(g.arena.safe_position(enemy.position,enemy.radius-.5),map+" legal final position")
   g.despawn_enemy(enemy)
  g.late_arena.clear_attacks(boss);await physics_frame
  check(g.arena.dynamic_walls.is_empty() and g.arena.safe_position(rect.get_center(),5),map+" wall collider removed")
  print("HAZARDS10_MAP ",map," failures=",failures)
 g.selected_map="courtyard";g.start_late_test("horror");g.late_arena.tick(1.3);g.weapon_system.levels.clear()
 var boss=g.boss;boss.position=Vector2(1050,630);g.player.position=Vector2(900,630);g.player.hp=100;g.player.invulnerable=0
 boss.begin_attack("dash");var locked:Vector2=boss.locked_target
 g.player.position+=Vector2(0,90);boss.tick(1.3);check(boss.locked_target==locked,"dash target remains fixed after player moves")
 for i in 65:await physics_frame;boss.tick(1.0/60)
 check(g.player.hp==100 and boss.state=="recovery","dash can be dodged and has recovery")
 g.late_arena.clear_attacks(boss);boss.locked_target=Vector2(900,630);boss.charge_direction=Vector2.LEFT
 g.late_arena.cast("columns",boss);var fixed:Vector2=g.late_arena.areas[0].at
 g.player.position=Vector2(1020,500);g.late_arena.tick(.1)
 check(g.late_arena.areas[0].at==fixed,"column positions fixed at launch")
 g.late_arena.tick(2.6)
 check(g.late_arena.areas.is_empty() and g.player.hp==100,"column sequence expires and does not follow moved player")
 g.queue_free();await process_frame;await create_timer(.3).timeout
 print("HAZARDS10_","PASS" if failures==0 else "FAIL"," dynamic collisions/navigation, three maps, dash and fixed columns failures=",failures);quit(0 if failures==0 else 1)
