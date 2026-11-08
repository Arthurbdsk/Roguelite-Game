extends SceneTree
func _initialize():call_deferred("run")
func run():
 assert(ProjectSettings.get_setting("application/config/version")=="0.24.0")
 assert(not ResourceLoader.exists("res://scripts/dev/boss_lab.gd"))
 for id in ["plague","devourer","guard"]:
  assert(ResourceLoader.exists("res://assets/v24/"+id+".png"))
  assert(not ResourceLoader.exists("res://assets/v24/sources/"+id+".png"))
 assert(FileAccess.file_exists("res://assets/v24/CREDITS.txt"))
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.start_run();g.mastery.begin(false)
 assert(g.dev_tools==null and g.balance.continuous_per_minute==90 and is_equal_approx(g.balance.gold_drop_chance,.2))
 var w=g.weapon_system
 for id in ["plague","devourer","guard"]:
  var e=g.spawn_enemy(id,Vector2(950,730));assert(e.tiny_kind=="original_"+id and e.sprite.hframes==24);g.clear_run();g.state="running"
 w.levels={"axe":1,"magic_wand":8,"fire_wand":8};assert(w._stat("axe","pierce")==3 and is_equal_approx(w._interval("magic_wand"),1.85) and is_equal_approx(w._stat("fire_wand","damage"),141.6))
 var boss=g.spawn_enemy("demon",Vector2(1100,730));assert(is_equal_approx(boss.max_hp,(g.boss_balance.demon_health()+30)*g.balance.enemy_health_multiplier))
 w.projectiles.append({"id":1,"age":0.0,"life":2.0,"position":g.player.position,"velocity":Vector2.ZERO,"distance":0.0,"reach":400.0,"damage":1.0,"pierce":1,"bounce":0,"hits":[]});w._update_projectiles(.01);assert(w.projectiles.is_empty())
 g.clear_run();g.queue_free();await process_frame;await create_timer(.2).timeout;print("PACK24_PASS embedded PC resources, no sources/DEV, authorized balance, actual ghost cleanup and boss health");quit()
