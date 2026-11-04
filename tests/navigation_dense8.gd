extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.sound.volume=0;g.set_physics_process(false)
 for map in ["courtyard","library","fields"]:
  g.selected_map=map;g.start_run();g.director.phase="complete";g.player.invulnerable=1000;g.weapon_system.levels.clear()
  var barrier:Rect2=Rect2(688,462,24,16) if map=="courtyard" else g.arena.obstacles[0]
  var target:Vector2=barrier.get_center()+Vector2(0,120);var start:Vector2=barrier.get_center()-Vector2(0,90)
  g.player.position=target;var initial:Dictionary={}
  for i in 240:
   var at:Vector2=start+Vector2((i%24-12)*8,-floori(i/24)*7)
   var id:String="beast" if i%8==0 else "ghoul"
   if not g.arena.safe_position(at,g.enemy_data[id].radius+2):continue
   var e=g.spawn_enemy(id,at);e.attack_time=1000;initial[e.serial]=at
  assert(g.enemies.size()>=160)
  var before:int=Time.get_ticks_usec()
  for step in 360:g.simulate(1.0/60);await physics_frame
  var moved:int=0;var illegal:int=0
  for e in g.enemies:
   if e.position.distance_to(initial[e.serial])>80:moved+=1
   if not g.arena.safe_position(e.position,e.radius-.75):illegal+=1
  assert(moved>=g.enemies.size()*.9,map+" blocked crowd "+str(moved))
  assert(illegal==0,map+" collision violations "+str(illegal))
  print("NAV_DENSE8_PASS %s agents=%d moved=%d illegal=%d seconds=%.2f"%[map,g.enemies.size(),moved,illegal,(Time.get_ticks_usec()-before)/1000000.0])
 g.queue_free();await process_frame;await create_timer(.3).timeout;quit()
