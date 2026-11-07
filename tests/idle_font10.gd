extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.start_run();g.sound.volume=0;g.weapon_system.levels.clear();g.director.phase="complete"
 var p=g.player;p.position=Vector2(680,470)
 for i in 60:await physics_frame;p.tick(1.0/60,Vector2.RIGHT)
 assert(p.position.x<682 and not p.actually_moving and TinyCharacters.contains("soldier","idle",p.sprite.frame))
 var direction:Vector2=p.facing
 p.tick(.016,Vector2(-.02,0));assert(TinyCharacters.contains("soldier","idle",p.sprite.frame) and p.facing==direction)
 p.position=Vector2(900,630);await physics_frame;p.tick(.016,Vector2.RIGHT);assert(p.actually_moving and TinyCharacters.contains("soldier","walk",p.sprite.frame))
 p.tick(.016,Vector2.ZERO);assert(TinyCharacters.contains("soldier","idle",p.sprite.frame))
 p.begin_swing(Vector2.RIGHT);p.tick(.016,Vector2.ZERO);assert(TinyCharacters.contains("soldier","sword",p.sprite.frame))
 p.hurt_remaining=.2;p.tick(.016,Vector2.ZERO);assert(TinyCharacters.contains("soldier","hurt",p.sprite.frame))
 var font:Font=GameFonts.interface_font()
 for c in "Aprimoramentos: Armadura, Área, Duração, Regeneração, 0123456789% çãáéíóúâêôõ":assert(font.has_char(c.unicode_at(0)))
 print("FONT10 Aurusenthial_available=",GameFonts.primary_available()," Portuguese, digits and symbols verified with fallback only for missing characters")
 g.queue_free();await process_frame;await create_timer(.3).timeout;print("IDLE_FONT10_PASS actual displacement, wall stop, noise, direction, attack/hurt priority");quit()
