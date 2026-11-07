extends SceneTree
var errors:int=0
var checks:int=0
var directory:String
var g
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
 checks+=1
 if not ok:errors+=1;printerr("FAIL "+message)
func capture(name:String):
 g.ui.update_hud(g.snapshot());await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(directory+"/orc-"+name+".png")
func run():
 directory=OS.get_environment("HORDAS_CAPTURE_DIR")
 if directory.is_empty():directory="res://test_output"
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.set_physics_process(false);g.test_mode=true;g.persistence_enabled=false;g.sound.volume=0;g.start_run();g.mastery.begin(false)
 for map_id in ["courtyard","library","fields"]:
  g.clear_run();g.arena.apply_map(map_id);g.state="running";g.player.position=Vector2(900,630);g.camera.position=Vector2.ZERO;g.weapon_system.attacks_enabled=false;g.ui.render("running")
  var e=g.spawn_enemy("ghoul",g.free_enemy_position(Vector2(990,630),8))
  check(e.tiny_kind=="orc" and e.sprite.hframes==34,"34 official Orc frames "+map_id)
  check(e.data.title=="Orc" and e.data.id=="ghoul","display rename preserves ID")
  var base:EnemyData=load("res://data/enemies/ghoul.tres")
  check(base.health==24 and base.speed==25 and base.damage==8 and base.experience==2 and base.radius==8,"base attributes unchanged")
  check(is_equal_approx(e.data.health,24*g.balance.enemy_health_multiplier*g.enemy_scale().health) and is_equal_approx(e.data.speed,25*g.balance.enemy_speed_multiplier*g.balance.common_speed_multiplier*g.enemy_scale().speed),"existing modifiers applied once")
  check(e.sprite.texture==TinyCharacters.texture("orc") and e.sprite.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,"shared nearest atlas")
  e.velocity=Vector2.ZERO;e.clock=.2;e.tick(.016)
  check(TinyCharacters.contains("orc","walk",e.sprite.frame),"walking uses actual displacement")
  check(e.sprite.position==Vector2(2,-9),"left facing physical pivot")
  await capture(map_id+"-walk")
  g.player.dev_invulnerable=false;g.player.invulnerable=0;g.player.armor=0;g.player.damage_reduction=0;g.player.clear_status();g.player.hp=100
  e.position=g.player.position+Vector2(14,0);g.rebuild_grid();e.tick(.01)
  check(g.player.hp==92,"contact retains original damage")
  check(TinyCharacters.contains("orc",e.visual_attack_clip,e.sprite.frame),"real contact plays attack")
  await capture(map_id+"-attack")
  e.tick(.01);check(g.player.hp==92,"animation creates no additional hits")
  g.player.tick_status(.4);e.position=g.player.position+Vector2(14,0);e.tick(.01)
  check(g.player.hp==84,"same original attacker interval")
  e.take_damage(1,e.position+Vector2.RIGHT);e.tick(.01)
  check(TinyCharacters.contains("orc","hurt",e.sprite.frame),"hurt priority")
  await capture(map_id+"-hurt")
  e.position=g.player.position+Vector2(70,0)
  var serial:int=e.serial;var kills:int=g.kills;var xp:int=g.pickups.size()
  e.take_damage(100000,e.position+Vector2.RIGHT)
  check(g.kills==kills+1 and g.pickups.size()==xp+1,"one kill one XP reward")
  check(g.character_remains.effects.size()==1 and g.character_remains.seen.has(serial),"single batched death animation")
  check(g.character_remains.effects[0].at==e.position,"death remains at actual world position")
  var event:Dictionary={"id":serial,"kind":"orc","at":e.position,"flip":true,"scale":1,"clock":g.elapsed}
  g.character_remains.receive(event);check(g.character_remains.effects.size()==1,"duplicate network death ignored")
  await create_timer(.15).timeout;await capture(map_id+"-death")
  await create_timer(.6).timeout;check(g.character_remains.effects.is_empty(),"death effect expires")
  g.clear_run();check(g.character_remains.effects.is_empty() and g.character_remains.seen.is_empty(),"restart cleans effects and identities")
 g.queue_free();await process_frame;await create_timer(.3).timeout
 print("ORC20_"+("PASS" if errors==0 else "FAIL")+" checks="+str(checks));quit(int(errors>0))
