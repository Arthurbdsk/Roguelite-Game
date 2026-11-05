extends SceneTree
func _initialize():call_deferred("run")
func run():
 var before=JSON.parse_string('''{
  "axe": [
    28.0,
    35.0,
    35.0,
    43.0,
    43.0,
    52.0,
    60.0,
    68.0
  ],
  "blades": [
    8.0,
    11.0,
    11.0,
    14.0,
    14.0,
    18.0,
    18.0,
    23.0
  ],
  "bolt": [
    14.0,
    17.0,
    18.0,
    23.0,
    27.0,
    30.24,
    30.24,
    33.87
  ],
  "bombs": [
    30.0,
    38.0,
    38.0,
    48.0,
    48.0,
    60.0,
    60.0,
    75.0
  ],
  "boomerang": [
    12.0,
    16.0,
    16.0,
    20.0,
    20.0,
    25.0,
    25.0,
    32.0
  ],
  "clock": [
    1.0,
    1.0,
    2.0,
    2.0,
    3.0,
    3.36,
    3.36,
    3.76
  ],
  "holy_water": [
    8.0,
    12.0,
    12.0,
    16.0,
    20.0,
    22.4,
    22.4,
    25.09
  ],
  "ice_wave": [
    12.0,
    17.0,
    17.0,
    22.0,
    22.0,
    28.0,
    28.0,
    36.0
  ],
  "lightning": [
    42.0,
    52.0,
    64.0,
    78.0,
    95.0,
    106.4,
    106.4,
    119.17
  ],
  "orbit": [
    9.0,
    13.0,
    15.0,
    19.0,
    25.0,
    28.0,
    28.0,
    31.36
  ],
  "sludge": [
    3.0,
    5.0,
    5.0,
    7.0,
    9.0,
    10.08,
    10.08,
    11.29
  ],
  "sword": [
    18.0,
    23.0,
    26.0,
    32.0,
    40.0,
    45.0,
    51.0,
    60.0
  ]
}''')
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.start_run();g.sound.volume=0;g.director.phase="complete"
 for id in before:
  var d=g.weapon_system.weapon_data[id]
  for n in 8:
   g.weapon_system.levels={id:n+1}
   assert(is_equal_approx(d.damage[n],float(before[id][n])*.9))
   assert(is_equal_approx(g.weapon_system._stat(id,"damage"),float(before[id][n])*.9))
   assert(is_equal_approx(g.weapon_system.offer_stat(id,"damage",n),float(before[id][n])*.9))
   var e=g.spawn_enemy("beast",Vector2(1100,630));var hp:float=e.hp
   g.weapon_system._hit(e,g.weapon_system._stat(id,"damage"),Vector2.ZERO)
   assert(is_equal_approx(hp-e.hp,float(before[id][n])*.9))
   g.despawn_enemy(e)
 assert(is_equal_approx(g.weapon_system.weapon_data.clock.damage[0],.9))
 g.clear_run();g.queue_free();await process_frame;await create_timer(.2).timeout
 print("DAMAGE12_PASS 12 weapons x 8 levels, exact 90% data/UI/real damage, fractions; enemy damage unchanged");quit()
