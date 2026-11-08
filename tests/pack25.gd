extends SceneTree
func _initialize():call_deferred("run")
func run():
 assert(ProjectSettings.get_setting("application/config/version")=="0.26.0")
 assert(GameCompatibility.identity().begins_with("0.26.0+") and GameCompatibility.PROTOCOL==2)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.start_run()
 assert(g.dev_tools==null and EnemyCatalog.ids(g).size()==23 and g.profile.data.bestiary_stats.is_empty())
 for id in ["shadow","executioner"]:
  var e=g.spawn_enemy(id,Vector2(1050,730));assert(e.tiny_kind=="original_"+id);assert(not ResourceLoader.exists("res://assets/v25/sources/"+id+".png"));g.clear_run();g.state="running"
 g.ui.bestiary_return="title";g.ui.render("bestiary");await process_frame;assert(g.ui.menu.get_child(0) is BestiaryView)
 assert(g.coop.rules.scaling(4).health==1 and is_equal_approx(g.coop.rules.scaling(4).count,2.0))
 g.clear_run();g.queue_free();await process_frame;await create_timer(.2).timeout;print("PACK25_PASS embedded PC, canonical bestiary, content identity, new art, easier multiplayer");quit()
