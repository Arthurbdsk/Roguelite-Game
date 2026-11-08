extends SceneTree
func _initialize():call_deferred("run")
func run():
 assert(not ResourceLoader.exists("res://scripts/dev/boss_lab.gd"))
 assert(FileAccess.file_exists("res://data/original_characters22.json"))
 for path in ["res://assets/hound.png","res://assets/v08/beast.png","res://assets/v13/slime_king.png","res://assets/v22/sources/bat.png"]:assert(not ResourceLoader.exists(path) and not FileAccess.file_exists(path))
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.start_run()
 assert(g.dev_tools==null and TinyCharacters.available("soldier"))
 var defs:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/original_characters22.json"))
 for kind in defs:assert(TinyCharacters.available(kind) and TinyCharacters.texture(kind).get_width()==int(defs[kind].cell[0])*24)
 for id in ["hound","necromancer","skeleton_sword","skeleton_archer","skeleton_armored","orc_armored","orc_elite","beast","slime_large","slime_small","slime_king","event_blue","event_small"]:
  var e=g.spawn_enemy(id,g.free_enemy_position(Vector2(1050,630),34));assert(e!=null and e.tiny_kind.begins_with("original_") and e.sprite.hframes==24)
 assert(GameIcons.path("weapon:holy_water")=="res://assets/v22/water_vial.png")
 print("ISOLATED_PUBLIC_PACK22_PASS ",ProjectSettings.get_setting("application/config/version"));g.queue_free();await process_frame;await create_timer(.3).timeout;quit()
