extends SceneTree
func _initialize():call_deferred("run")
func run():
 assert(TinyCharacters.available("soldier") and TinyCharacters.available("orc"))
 assert(not ResourceLoader.exists("res://assets/v08/hero.png"))
 assert(not ResourceLoader.exists("res://assets/ghoul.png"))
 assert(FileAccess.file_exists("res://assets/tiny_rpg/NOTICE.txt"))
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.set_physics_process(false);g.start_run()
 assert(g.player.tiny_soldier and g.weapon_system.levels=={"bolt":1})
 var e=g.spawn_enemy("ghoul",Vector2(1000,630))
 assert(e.tiny_kind=="orc" and e.data.id=="ghoul" and e.data.title=="Orc")
 assert(g.character_remains.effects.is_empty())
 e.take_damage(10000,Vector2.ZERO);assert(g.character_remains.effects.size()==1)
 g.clear_run();assert(g.character_remains.effects.is_empty())
 g.queue_free();await process_frame;await create_timer(.3).timeout
 print("TINY_PACK20_PASS official atlases embedded, original visuals excluded, rewards and restart real");quit()
