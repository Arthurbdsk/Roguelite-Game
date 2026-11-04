extends SceneTree
var g
func _initialize():call_deferred("run")
func capture(name:String):
 g.weapon_system.queue_redraw();g.enemy_projectiles.queue_redraw()
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://test_output/"+name+".png")
func run():
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.sound.volume=0;g.start_run();g.director.phase="complete";g.banner=""
 g.weapon_system.lightning_fx.append({"at":g.player.position+Vector2(80,20),"life":.16})
 await capture("06-raio-arena")
 g.weapon_system.lightning_fx.clear();g.weapon_system.beams.append({"origin":g.player.position,"end":g.player.position+Vector2(180,-60),"width":12,"life":.2})
 await capture("06-feixe-arena")
 g.weapon_system.beams.clear()
 for i in 5:g.enemy_projectiles.fire_ball(g.player.position+Vector2(40+i*30,20+i*12),Vector2.DOWN.rotated(-.4),0,1)
 await capture("06-fogo-arena")
 g.enemy_projectiles.reset()
 g.weapon_system.levels={"sludge":3,"holy_water":4,"clock":2}
 g.weapon_system.passives={"crown":1,"boots":2,"magnet":2}
 var offers:Array=[]
 for id in ["sludge","holy_water","clock"]:
  var n:int=g.weapon_system.levels[id]
  offers.append({"id":id,"name":g.weapon_system.weapon_data[id].display_name,"icon":g.weapon_system.weapon_data[id].icon,"detail":"Nível %d → %d"%[n,n+1],"description":g.weapon_system.upgrade_values(id,n)})
 g.ui.render("upgrading",{"offers":offers});await capture("06-build")
 var panel=g.ui.menu.find_child("BuildPanel",true,false)
 for c in panel.get_children():
  if c is Control:assert(c.get_global_rect().end.y<334)
 g.queue_free();await process_frame;await create_timer(.4).timeout;print("VISUAL06_PASS arena sprites and build bounds");quit()
