extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.sound.volume=0
 var rows:Array=[]
 for n in 3:
  seed(12120+n);g.profile.data=g.profile.defaults();g.selected_map="fields";g.start_run();g.director.rng.seed=12120+n;g.gold_loot.death_rng.seed=12120+n;g.weapon_system.rng.seed=12120+n
  var frames:int=0;var direction:=Vector2.RIGHT
  while g.state not in ["result","revive_offer"] and g.elapsed<600:
   if g.state=="upgrading":
    var option:String=g.offers[0].id
    for offer in g.offers:
     if offer.id in ["lightning","holy_water","sword","orbit","bombs","heart","ward","crown"]:option=offer.id;break
    g.choose_upgrade(option)
   if frames%12==0:
    var target:Vector2=Vector2(900,630)+Vector2.from_angle(g.elapsed*.08+n)*220
    var closest:float=180*180
    for food in g.pickups:
     var distance:float=g.player.position.distance_squared_to(food.at)
     if distance<closest:closest=distance;target=food.at
    var best:float=-INF
    for i in 16:
     var move:Vector2=Vector2.from_angle(i*TAU/16);var stop:Vector2=g.player.position+move*55
     if not g.arena.safe_position(stop,12) or not g.navigation.clear_segment(g.player.position,stop,10):continue
     var score:float=-stop.distance_to(target)*.05
     for enemy in g.enemies:
      var dist:float=stop.distance_to(enemy.position)
      if dist<90:score-=pow((90-dist)/18,2)
     if score>best:best=score;direction=move
   g.simulate(1.0/60,direction);frames+=1;await physics_frame
  var row:Dictionary={"seed":12120+n,"seconds":snappedf(g.elapsed,.1),"wave":g.director.wave_number(),"level":g.level,"kills":g.kills,"gold":g.gold,"outcome":g.state};rows.append(row);print("BOT_INCOME12 ",JSON.stringify(row));g.clear_run();await process_frame
 var f=FileAccess.open("res://test_output/12-bot-income.json",FileAccess.WRITE);f.store_string(JSON.stringify(rows," "));f.close()
 g.queue_free();await process_frame;print("BOT_INCOME12_PASS three fresh-profile automated gameplay runs; bots do not measure human survival or win income");quit()
