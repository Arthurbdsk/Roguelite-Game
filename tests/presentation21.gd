extends SceneTree
func _initialize():call_deferred("run")
func run():
 assert(DisplayNumbers.seconds(.4)=="Menos de 1 s")
 assert(DisplayNumbers.attack_interval(.2)=="5 ataques por segundo")
 assert(DisplayNumbers.attack_interval(.4)=="Ataques rápidos")
 assert(DisplayNumbers.seconds(1.2)=="Cerca de 1 s")
 assert(DisplayNumbers.regeneration(.1)=="1 de vida a cada 10 s")
 assert(DisplayNumbers.clean("400 ms | 1.25 s | PC 0.21.0")=="Menos de 1 s | Cerca de 1 s | PC 0.21.0")
 assert(DisplayNumbers.change("Intervalo",.94,.88,7," s").contains("-6%"))
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.start_run()
 var regex:=RegEx.new();regex.compile("[0-9]+[.,][0-9]+|\\bms\\b")
 var w=g.weapon_system
 for id in w.weapon_data:
  for n in 8:assert(regex.search(w.upgrade_values(id,n))==null,"no decimals or ms in weapon upgrades: "+id)
 assert(w.passive_data.crown.display_name=="Toque do Midas")
 w.passives={"crown":8};g.mastery.begin(false);g.xp_needed=10000;g.xp=0;g.add_xp(100);assert(is_equal_approx(g.xp,156))
 print("PRESENTATION21_PASS all weapon levels without ms/decimals; Midas retains +56% experience")
 g.queue_free();await process_frame;await create_timer(.3).timeout;quit()
