extends SceneTree
var g
var checks:int=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 assert(ok,label)
func capture(name:String):
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/bestiary25/"+name+".png")
func run():
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.start_run();g.player.dev_invulnerable=true
 for map_id in ["courtyard","library","fields"]:
  g.clear_run();g.state="running";g.arena.apply_map(map_id);g.player.position=Vector2(900,630);g.ui.render("running")
  var e=g.spawn_enemy("shadow",Vector2(1000,630));check(e.tiny_kind=="original_shadow" and e.sprite.hframes==32,"Shadow atlas")
  check(e.radius==9 and is_equal_approx(e.data.speed,32*g.balance.enemy_speed_multiplier) and e.data.damage==17,"Shadow combat unchanged")
  e.attack_time=0;e.tick(.01);check(e.state=="ambush" and not e.targetable,"real ambush begins")
  e.tick(.15);check(e.sprite.visible and TinyCharacters.contains(e.tiny_kind,"vanish",e.sprite.frame),"disappear frames")
  await capture(map_id+"-shadow-vanish")
  e.tick(.3);check(not e.sprite.visible and not e.targetable,"middle ambush invisible")
  e.state_time=g.specials.balance.shadow_warning-.15;e.tick(.001);check(e.sprite.visible and TinyCharacters.contains(e.tiny_kind,"appear",e.sprite.frame),"reappearance warns at locked destination")
  await capture(map_id+"-shadow-appear")
  for i in 120:await physics_frame;e.tick(1.0/60)
  check(e.targetable and e.sprite.visible,"ambush cannot leave permanent immunity")
  var at:Vector2=e.position;e.take_damage(100000);check(g.character_remains.effects.back().kind=="original_shadow" and g.character_remains.effects.back().at==at,"death distinct from disappearing")
  g.clear_run();g.state="running"
  var b=g.spawn_enemy("executioner",Vector2(1000,630));check(b.tiny_kind=="original_executioner" and b.sprite.hframes==36,"Carrasco atlas")
  check(b.radius==18 and is_equal_approx(b.max_hp,(g.boss_balance.executioner_health()+30)*g.balance.enemy_health_multiplier),"boss body and HP unchanged")
  for attack in ["execute","charge"]:
   b.begin_attack(attack);b.tick(b.warning_duration()*.45)
   check(TinyCharacters.contains(b.tiny_kind,"execute_prepare" if attack=="execute" else "charge_prepare",b.sprite.frame),"actual attack preparation "+attack)
   await capture(map_id+"-executioner-"+attack)
   b.tick(b.warning_duration()*.6);check(b.state in ["charge","recovery"],"actual attack release "+attack)
   b.state="chase"
  b.hp=b.max_hp*.49;b.tick(.01);check(b.phase==2 and b.visual_phase_seen==2 and b.sprite.modulate!=Color.WHITE,"aggressive phase visual")
  await capture(map_id+"-executioner-phase2")
  b.take_damage(100000);g.boss_arena.tick(.5);check(TinyCharacters.contains(b.tiny_kind,"death",b.sprite.frame) and g.character_remains.effects.is_empty(),"one boss death renderer")
  await capture(map_id+"-executioner-death")
 g.clear_run();g.queue_free();await process_frame;await create_timer(.2).timeout;print("DESIGN25_PASS checks=",checks," three maps, actual ambush/attacks, no gameplay scaling");quit()
