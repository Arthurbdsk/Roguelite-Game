extends RefCounted
static func capture(g)->Dictionary:
 g.set_physics_process(false);g.persistence_enabled=false;g.profile.data=g.profile.defaults();g.start_run();g.mastery.begin(false);g.run_challenge=0;g.sound.volume=0
 var result:Dictionary={"player":{"hp":g.player.max_hp,"speed":g.player.speed,"armor":g.player.armor,"reduction":g.player.damage_reduction},"weapons":[],"enemies":[],"rates":[]}
 var w=g.weapon_system
 var target=g.spawn_enemy("ghoul",Vector2(1100,730));target.hp=1000000;target.max_hp=1000000
 for bonus in [false,true]:
  for id in w.weapon_data:
   for level in range(1,9):
    w.reset();w.levels={id:level};w.passives={"cadence":8,"lens":8,"hourglass":8} if bonus else {}
    var before:float=target.hp;w._hit(target,w._stat(id,"damage"),Vector2.ZERO)
    result.weapons.append({"id":id,"level":level,"bonus":bonus,"damage":w._stat(id,"damage"),"actual_hit":before-target.hp,"cooldown":w._interval(id),"count":w._stat(id,"count"),"reach":w._stat(id,"reach")})
 g.clear_run();g.state="running"
 for count in [1,2,3,4]:
  g.coop.active=count>1;g.coop.hosting=true;g.coop.initial_size=count
  for time in [0,240]:
   g.elapsed=time;result.rates.append({"players":count,"time":time,"rate":g.director.rate(),"scale":g.enemy_scale()})
   for id in EnemyCatalog.ids(g):
    g.elapsed=time
    var e=g.spawn_enemy(id,Vector2(1100,730));assert(e!=null,id)
    var before:float=e.hp;e.take_damage(10)
    result.enemies.append({"id":id,"players":count,"time":time,"hp":e.max_hp,"damage":e.data.damage,"resistance":e.data.damage_resistance,"actual_hit_10":before-e.hp,"speed":e.data.speed,"radius":e.radius,"attack_interval":e.data.attack_interval})
    g.clear_run();g.state="running"
   await g.get_tree().process_frame
 g.coop.active=false;g.elapsed=0;g.clear_run();g.state="running"
 return result
