extends Node2D
const EMPTY_QUERY:Array=[]

var experience_texture=preload("res://assets/v12/experience.png")
var survival_config:Dictionary={}
var selected_map:String="courtyard"
var state: String = "title"
var elapsed: float = 0
var kills: int = 0
var earned: int = 0
var level: int = 1
var xp: float = 0
var xp_needed: int = 6
var effects: float = 0.7
var banner: String = ""
var banner_time: float = 0
var shake_time: float = 0
var support: String = "none"
var enemies: Array = []
var pickups: Array[Dictionary] = []
var hazards: Array[Dictionary] = []
var numbers: Array[Dictionary] = []
var navigation:=CrowdNavigation.new()
var grid: Dictionary = {}
var crowd_grid:Dictionary={}
var crowd_near:Dictionary={}
var crowd_push:Dictionary={}
var crowd_pairs:int=0
var crowded_cell_peak:int=0
var perf_enabled:bool=false
var perf_us:Dictionary={}
func perf_mark(section:String,started:int):
 if perf_enabled:perf_us[section]=Time.get_ticks_usec()-started

var crowd_max_radius:float=1
var enemy_collision_margin:float=10
var offers: Array[Dictionary] = []
var boss = null
var boss_defeated: bool = false
var test_mode: bool = false
var slice_mode: bool = false
var hud_clock: float = 0
var serial: int = 1
var banked_reward: int = 0
var gold: int = 0
var banked_gold: int = 0
var run_id: String = ""
var run_settled: bool = false
var persistence_enabled: bool = true
var event_claimed: bool = false
var event_progress: float = 0
var region: Vector2 = Vector2(1260, 810)
var profile := GameProfile.new()
var player: Sentinel
var arena: RuinedArena
var weapon_system: WeaponSystem
var horde_progress:=HordeProgress.new()
var director := HordeDirector.new()
var sound: GameSound
var ui: GameUI
var entities: Node2D
var camera: Camera2D
var enemy_data: Dictionary = {}
var balance: EncounterBalance = preload("res://data/encounters/default.tres")
var gold_loot: GoldLoot
var enemy_projectiles: EnemyProjectiles
var skills := PermanentSkills.new()
var run_challenge:int=0
var campaign:=LateCampaign.new()
var late_arena:LateArena
var mastery := RunMastery.new()
var tree_return: String = "title"
var dev_boss_test: bool = false
var dev_boss_kind: String = "demon"
var executioner_defeated: bool = false
var reported_deaths: Dictionary = {}
var boss_balance: BossBalance = preload("res://data/bosses/balance.tres")
var boss_arena: BossArena
var special_events
var chests
var specials: SpecialEncounters
var slime_families:SlimeFamilies
var food_index:=FoodIndex.new()
var dev_tools
var coop: CoopSession

func _ready() -> void:
 DisplayServer.window_set_title("Hordas")
 test_mode = "--self-test" in OS.get_cmdline_user_args()
 slice_mode = "--slice" in OS.get_cmdline_user_args()
 persistence_enabled = not test_mode
 get_tree().auto_accept_quit = false
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--profile-slot="):
   var slot: String = argument.trim_prefix("--profile-slot=").validate_filename()
   profile = GameProfile.new("user://profile_%s.json" % slot.left(40))
 register_inputs()
 if not test_mode:
  profile.load_profile()
 survival_config=JSON.parse_string(FileAccess.get_file_as_string("res://data/survival.json"))
 balance.continuous_per_minute=survival_config.generation.per_minute;balance.difficulty_seconds=survival_config.generation.stage_seconds;balance.continuous_stage_rate=survival_config.generation.stage_rate
 skills.setup(self)
 mastery.setup(self)
 for id in ["ice_crystal","channel_totem","ghoul", "hound", "guard", "demon", "executioner", "skeleton_sword", "skeleton_archer", "necromancer", "beast", "plague", "shadow", "devourer", "slime_large", "slime_small", "guardian", "horror"]:
  enemy_data[id] = load("res://data/enemies/" + id + ".tres")
 for pair in [["siege_archer","skeleton_archer"],["slime_king","slime_large"],["event_blue","slime_large"],["event_small","slime_small"]]:
  enemy_data[pair[0]]=enemy_data[pair[1]].duplicate();enemy_data[pair[0]].id=pair[0]
 enemy_data.siege_archer.title="Arqueiro do cerco";enemy_data.siege_archer.speed=0;enemy_data.siege_archer.attack_interval+=survival_config.events.siege_extra_interval;enemy_data.siege_archer.attack_range=survival_config.events.siege_range;enemy_data.siege_archer.arrow_range=survival_config.events.siege_arrow_range;enemy_data.siege_archer.arrow_lifetime=survival_config.events.siege_arrow_lifetime
 enemy_data.slime_king.title="Slime Rei";enemy_data.slime_king.health*=survival_config.events.king_health;enemy_data.slime_king.speed*=survival_config.events.king_speed;enemy_data.slime_king.radius=survival_config.events.king_radius;enemy_data.slime_king.texture="res://assets/v13/slime_king.png";enemy_data.slime_king.frames=8
 enemy_data["boss"] = enemy_data.demon
 arena = RuinedArena.new()
 arena.z_index = -20
 add_child(arena)
 entities = Node2D.new()
 entities.y_sort_enabled = true
 add_child(entities)
 player = preload("res://scenes/entities/player.tscn").instantiate()
 player.game = self
 player.position = Vector2(900, 630)
 entities.add_child(player)
 camera = Camera2D.new()
 camera.limit_left = 0
 camera.limit_top = 0
 camera.limit_right = 1800
 camera.limit_bottom = 1200
 camera.position_smoothing_enabled = false
 player.add_child(camera)
 weapon_system = WeaponSystem.new()
 add_child(weapon_system)
 weapon_system.setup(self)
 navigation.game=self
 food_index.game=self
 horde_progress.game=self
 director.setup(self)
 sound = GameSound.new()
 add_child(sound)
 gold_loot = GoldLoot.new()
 add_child(gold_loot)
 gold_loot.setup(self)
 enemy_projectiles = EnemyProjectiles.new()
 add_child(enemy_projectiles)
 enemy_projectiles.setup(self)
 boss_arena = BossArena.new()
 add_child(boss_arena)
 boss_arena.setup(self)
 campaign.setup(self)
 late_arena=LateArena.new();add_child(late_arena);late_arena.setup(self)
 specials = SpecialEncounters.new()
 add_child(specials)
 specials.setup(self)
 slime_families=SlimeFamilies.new();slime_families.game=self;slime_families.z_index=2;add_child(slime_families)
 special_events=load("res://scripts/world/special_events.gd").new();add_child(special_events);special_events.setup(self)
 chests=load("res://scripts/world/reward_chests.gd").new();add_child(chests);chests.setup(self)
 coop = CoopSession.new()
 add_child(coop)
 coop.setup(self)
 ui = GameUI.new()
 add_child(ui)
 ui.setup(self)
 apply_settings()
 show_title()
 if development_build() and ResourceLoader.exists("res://scripts/dev/boss_lab.gd"):
  dev_tools=load("res://scripts/dev/boss_lab.gd").new();add_child(dev_tools);dev_tools.setup(self)
 if dev_tools!=null and "--dev-room" in OS.get_cmdline_user_args():
  dev_tools.enter();open_online()
 if "--online" in OS.get_cmdline_user_args():
  for argument in OS.get_cmdline_user_args():
   if argument.begins_with("--name="): coop.local_name = argument.trim_prefix("--name=")
  open_online()
 if "--play" in OS.get_cmdline_user_args():
  start_run()
 for argument in OS.get_cmdline_user_args():
  if dev_tools!=null and argument.begins_with("--encounter-test="):dev_tools.launch_argument(argument.get_slice("=",1))
  if dev_tools!=null and argument.begins_with("--boss-test="):
   dev_tools.launch_argument("demon1" if argument.get_slice("=",1)=="demon" else "executioner")

 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--benchmark14="):
   if not OS.get_cmdline_user_args().has("--profile-slot=benchmark14"):get_tree().quit(2);return
   var runner=load("res://scripts/diagnostics/benchmark14.gd").new();add_child(runner);runner.call_deferred("setup",self,arg.trim_prefix("--benchmark14="))

func development_build()->bool:return (OS.has_feature("editor") or OS.has_feature("dev_tools")) and ResourceLoader.exists("res://scripts/dev/boss_lab.gd") and FileAccess.file_exists("res://data/dev/presets.json")

func _input(event:InputEvent):
 if dev_tools!=null and event is InputEventKey and event.pressed and not event.echo:
  if event.physical_keycode==KEY_F8:
   dev_tools.toggle();get_viewport().set_input_as_handled()
  elif event.physical_keycode==KEY_ESCAPE and dev_tools.panel.visible:
   dev_tools.panel.hide();get_viewport().set_input_as_handled()

func register_inputs() -> void:
 if not InputMap.has_action("revive"):
  InputMap.add_action("revive")
  var key := InputEventKey.new()
  key.physical_keycode = KEY_E
  InputMap.action_add_event("revive", key)
  var button := InputEventJoypadButton.new()
  button.button_index = JOY_BUTTON_Y
  InputMap.action_add_event("revive", button)
 var bindings := {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN]}
 for action in bindings:
  if not InputMap.has_action(action):
   InputMap.add_action(action, 0.2)
  for code in bindings[action]:
   var key := InputEventKey.new()
   key.physical_keycode = code
   InputMap.action_add_event(action, key)
 var axes := {"move_left": [JOY_AXIS_LEFT_X, -1], "move_right": [JOY_AXIS_LEFT_X, 1], "move_up": [JOY_AXIS_LEFT_Y, -1], "move_down": [JOY_AXIS_LEFT_Y, 1]}
 for action in axes:
  var axis := InputEventJoypadMotion.new()
  axis.axis = axes[action][0]
  axis.axis_value = axes[action][1]
  InputMap.action_add_event(action, axis)
 var dpad := {"move_left": JOY_BUTTON_DPAD_LEFT, "move_right": JOY_BUTTON_DPAD_RIGHT, "move_up": JOY_BUTTON_DPAD_UP, "move_down": JOY_BUTTON_DPAD_DOWN}
 for action in dpad:
  var button := InputEventJoypadButton.new()
  button.button_index = dpad[action]
  InputMap.action_add_event(action, button)

func _physics_process(delta: float) -> void:
 if not test_mode:
  simulate(delta, Input.get_vector("move_left", "move_right", "move_up", "move_down"))

func simulate(delta: float, movement: Vector2 = Vector2.ZERO) -> void:
 campaign.decision_tick(delta)
 if dev_tools!=null and dev_tools.active and dev_tools.panel.visible:movement=Vector2.ZERO
 if coop != null and coop.active:
  coop.tick(delta, movement)
  return
 if state != "running":
  return
 elapsed += delta
 horde_progress.tick()
 campaign.tick()
 navigation.tick(delta)
 var previous_position: Vector2 = player.position
 player.movement_multiplier = boss_arena.slow_multiplier(player.position)
 player.tick(delta, movement)
 mastery.tick(delta, previous_position.distance_to(player.position) if movement.length_squared() > 0.01 else 0)
 slime_families.tick(delta)
 special_events.tick(delta)
 chests.tick(delta)
 director.tick(delta)
 if state != "running":
  return
 gold_loot.tick(delta)
 food_index.tick(delta)
 rebuild_grid()
 prepare_crowd()
 for enemy in enemies.duplicate():
  if is_instance_valid(enemy) and enemy.alive:
   enemy.tick(delta)
   if state != "running":
    return
 rebuild_grid()
 weapon_system.update_combat(delta)
 update_pickups(delta)
 if state != "running":
  queue_redraw()
  return
 enemy_projectiles.tick(delta)
 update_hazards(delta)
 specials.tick(delta)
 boss_arena.tick(delta)
 late_arena.tick(delta)
 if state != "running":
  queue_redraw()
  return
 update_event(delta)
 for number in numbers:
  number.life -= delta
  number.at.y -= delta * 14
 numbers = numbers.filter(func(n): return n.life > 0)
 if banner_time > 0:
  banner_time -= delta
  if banner_time <= 0:
   banner = ""
 if shake_time > 0:
  shake_time -= delta
  camera.offset = Vector2(randf_range(-2, 2), randf_range(-2, 2)) if profile.data.settings.shake else Vector2.ZERO
 else:
  camera.offset = Vector2.ZERO
 hud_clock -= delta
 if hud_clock <= 0:
  ui.update_hud(snapshot())
  hud_clock = 0.1
 queue_redraw()

func start_run(selected_support: String = "none") -> void:
 if dev_boss_test and not test_mode:
  persistence_enabled = true
 dev_boss_test = false
 if selected_support not in ["none", "arsenal", "library"]:
  selected_support = "none"
 if selected_support != "none" and not profile.data.buildings[selected_support]:
  selected_support = "none"
 support = selected_support
 clear_run()
 arena.apply_map(selected_map)
 run_challenge=clampi(int(profile.data.challenge_active),0,skills.rank("challenge"))
 run_id = "%d_%d_%d" % [Time.get_unix_time_from_system(), Time.get_ticks_usec(), randi()]
 run_settled = false
 player.poison_remaining = 0
 player.poison_clock = 0
 player.root_remaining = 0
 player.hp = 100
 player.max_hp = 100
 player.speed = 96
 player.pickup_radius = 42
 player.armor = 0
 player.invulnerable = 1
 player.down = false
 player.sprite.rotation = 0
 player.position = Vector2(900, 630)
 player.facing = Vector2.DOWN
 camera.reset_smoothing()
 weapon_system.reset(support)
 mastery.begin()
 director.reset()
 state = "running"
 ui.render("running")
 ui.update_hud(snapshot())

func clear_run() -> void:
 if chests!=null:chests.reset()
 if special_events!=null:special_events.reset()
 horde_progress.reset()
 campaign.reset()
 if late_arena!=null:late_arena.reset()
 food_index.reset()
 navigation.reset()
 if is_instance_valid(weapon_system) and weapon_system.ground!=null:weapon_system.ground.reset();weapon_system.arsenal.reset()
 if slime_families!=null:slime_families.reset()
 if is_instance_valid(player): player.clear_status()
 if specials != null: specials.reset()
 for enemy in enemies:
  if is_instance_valid(enemy):
   enemy.queue_free()
 enemies.clear()
 pickups.clear()
 hazards.clear()
 numbers.clear()
 grid.clear();crowd_grid.clear();crowd_max_radius=1
 gold_loot.reset()
 enemy_projectiles.reset()
 boss_arena.reset()
 reported_deaths.clear()
 elapsed = 0
 kills = 0
 earned = 0
 gold = 0
 banked_gold = 0
 banked_reward = 0
 level = 1
 xp = 0
 xp_needed = 6
 boss = null
 boss_defeated = false
 executioner_defeated = false
 event_claimed = false
 event_progress = 0
 shake_time = 0
 camera.offset = Vector2.ZERO
 queue_redraw()

func show_title() -> void:
 state = "title"
 ui.render("title", profile.data)

func open_online() -> void:
 state = "online"
 ui.render("online")

func team_players() -> Array:
 return coop.live_players() if coop != null and coop.active else [player]

func collection_player(at: Vector2):
 return coop.nearest_player(at) if coop != null and coop.active else player

func scaling_participants()->int:
 if dev_tools!=null and dev_tools.active:return dev_tools.applied_participants if dev_tools.running_test else dev_tools.participants
 return coop.initial_size if coop!=null and coop.active and coop.hosting else 1

func enemy_scale() -> Dictionary:
 var scale:Dictionary=coop.rules.scaling(scaling_participants())
 for key in ["health","damage","count"]:scale[key]*=1+.05*run_challenge
 return scale

func wave_composition(original: Dictionary) -> Dictionary:
 return coop.rules.composition(original,scaling_participants(),1+.05*run_challenge)

func hidden_spawn(at: Vector2, margin: float) -> bool:
 for member in team_players():
  var center: Vector2 = member.position.clamp(Vector2(320, 180), Vector2(1480, 1020))
  if Rect2(center - Vector2(320, 180), Vector2(640, 360)).grow(margin).has_point(at): return false
 return true

func players_near(at: Vector2, reach: float) -> bool:
 for member in team_players():
  if member.position.distance_to(at) < reach: return true
 return false

func projectile_victim(start: Vector2, end: Vector2, radius: float):
 var best = null
 var distance: float = INF
 for member in team_players():
  var nearest := Geometry2D.get_closest_point_to_segment(member.position, start, end)
  if nearest.distance_to(member.position) <= member.radius + radius:
   var candidate: float = start.distance_squared_to(nearest)
   if candidate < distance: best = member; distance = candidate
 return best

func damage_team_area(at: Vector2, radius: float, amount: float) -> void:
 for member in team_players():
  if member.position.distance_to(at) <= radius + member.radius: member.take_damage(amount, at)

func damage_team_cone(at: Vector2, direction: Vector2, reach: float, half_angle: float, amount: float) -> void:
 for member in team_players():
  var offset: Vector2 = member.position - at
  if offset.length() <= reach + member.radius and absf(direction.angle_to(offset.normalized())) <= half_angle: member.take_damage(amount, at)

func enter_hub() -> void:
 if coop != null and coop.active: coop.leave()
 state = "hub"
 ui.render("hub", profile.data)

func open_skill_tree() -> void:
 if state not in ["title", "hub", "tree"]:
  return
 if state != "tree":
  tree_return = state
 state = "tree"
 ui.render("tree", profile.data)

func close_skill_tree() -> void:
 if tree_return == "hub":
  enter_hub()
 else:
  show_title()

func buy_skill(id: String, expected_rank: int = -1) -> void:
 if state not in ["title", "hub", "tree"]:
  return
 if skills.purchase(id, expected_rank):
  sound.play_cue("select")
 ui.render("tree", profile.data)

func weapon_hit(enemy, amount: float, force: Vector2) -> void:
 mastery.hit(enemy, amount, force)

func start_boss_test(kind: String) -> void:
 if not development_build():return
 start_run()
 run_challenge=0
 dev_boss_kind = "executioner" if kind == "executioner" else "demon"
 dev_boss_test = true
 persistence_enabled = false
 mastery.begin(false)
 for id in ["boots", "ward", "magnet"]:
  weapon_system.apply_upgrade(id)
  weapon_system.apply_upgrade(id)
 var weapon_level: int = 4 if kind == "executioner" else 5
 weapon_system.levels = {"sword": weapon_level, "bolt": weapon_level, "orbit": weapon_level}
 level = 18 if kind == "executioner" else 21
 director.phase = "complete"
 player.position = Vector2(700, 630)
 if kind == "executioner":
  elapsed = 300
  spawn_enemy("executioner", Vector2(860, 630))
  announce("TESTE: O CARRASCO", 2.5)
 else:
  director.wave_index = 9
  boss_arena.begin_portal()
 ui.update_hud(snapshot())

func retry() -> void:
 if dev_tools!=null and dev_tools.active:dev_tools.start_encounter();return
 if coop.active:
  coop.leave()
  open_online()
  return
 if dev_boss_test:
  if state in ["running", "paused", "upgrading", "revive_offer", "endless_choice"]:
   finish_run(false)
  if dev_boss_kind in ["guardian","horror","true"]:start_late_test(dev_boss_kind)
  else:start_boss_test(dev_boss_kind)
  return
 if state in ["running", "paused", "upgrading", "revive_offer", "endless_choice"]:
  finish_run(false)
 start_run(support)

func abandon() -> void:
 if dev_tools!=null and dev_tools.active:dev_tools.end_test();return
 if coop.active:
  coop.leave()
  return
 # Leaving a live expedition settles it once, just like defeat.
 if state in ["running", "paused", "upgrading", "revive_offer", "endless_choice"]:
  finish_run(false)
 else:
  enter_hub()

func finish_run(won: bool) -> void:
 won=won or campaign.cleared
 if dev_tools!=null and dev_tools.active:
  dev_tools.complete(won);return
 if coop != null and coop.active:
  coop.finish(won)
  return
 if state not in ["running", "paused", "upgrading", "revive_offer", "endless_choice"] or run_settled:
  return
 state = "result"
 chests.reset();special_events.stop()
 player.clear_status()
 weapon_system.ground.reset();weapon_system.arsenal.reset();slime_families.reset()
 run_settled = true
 boss_arena.stop_combat()
 late_arena.reset()
 camera.offset = Vector2.ZERO
 banked_gold = 0 if dev_boss_test else gold
 banked_reward = profile.reward(elapsed, kills, won, earned, gold, run_id, director.wave_number(), mastery.gold_fraction) if persistence_enabled else floori(elapsed / 30.0) + floori(kills / 30.0) + earned + (10 if won else 0)
 if dev_boss_test:
  banked_reward = 0
 sound.play_cue("victory" if won else "defeat")
 ui.render("result", {"won": won, "elapsed": elapsed, "kills": kills, "earned": banked_reward, "level": level, "gold": banked_gold, "total_gold": profile.data.gold, "wave": director.wave_number(), "dev": dev_boss_test})

func request_quit() -> void:
 if coop != null and coop.active:
  coop.finish(false)
  if coop.connection.socket != null: coop.connection.socket.poll()
 if state in ["running", "paused", "upgrading", "revive_offer", "endless_choice"]:
  finish_run(false)
 get_tree().quit()

func _notification(what: int) -> void:
 if what == NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(ui):
  request_quit()

func toggle_pause() -> void:
 if coop.active and not coop.ended:
  if coop.menu_open: coop.close_menu()
  else:
   coop.menu_open = true
   ui.render("online_pause")
  return
 if ui.screen == "settings":
  ui.render(ui.return_screen, profile.data)
  return
 if state == "running":
  state = "paused"
  ui.render("paused")
 elif state == "paused":
  state = "running"
  ui.render("running")
  ui.update_hud(snapshot())

func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("revive") and state=="running" and not coop.active:
  if chests.try_open(player):get_viewport().set_input_as_handled();return
 if coop != null and coop.active:
  if event is InputEventKey and event.pressed and not event.echo:
   if event.physical_keycode == KEY_TAB: coop.open_upgrades(); return
   if ui.screen == "upgrading" and event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_4:
    var choices: Array = coop.actors[coop.connection.peer_id].offers if coop.hosting else coop.received_personal.get("offers", [])
    var index: int = event.physical_keycode - KEY_1
    if index < choices.size(): coop.choose(choices[index].id)
    return
 if event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START):
  if state in ["running", "paused"]:
   toggle_pause()
  elif ui.screen == "settings":
   ui.render(ui.return_screen, profile.data)
  elif state == "hub":
   show_title()
  elif state == "tree":
   close_skill_tree()
  elif state == "lab":
   show_title()
 if state == "upgrading" and event is InputEventKey and event.pressed and not event.echo:
  var index: int = event.physical_keycode - KEY_1
  if index >= 0 and index < offers.size():
   choose_upgrade(offers[index].id)
 if event is InputEventKey and event.pressed and event.physical_keycode == KEY_F11:
  set_option("fullscreen", not profile.data.settings.fullscreen)

func add_xp(amount: float) -> void:
 if coop != null and coop.active:
  if coop.hosting: coop.share_xp(amount)
  return
 if dev_boss_test:
  return
 xp += amount * (1.0+.07*int(weapon_system.passives.get("crown",0))+mastery.value("experience"))
 check_level()

func check_level() -> void:
 if xp < xp_needed or state != "running":
  return
 xp -= xp_needed
 level += 1
 xp_needed = 6 + (level - 1) * 5
 offers = weapon_system.get_offers()
 state = "upgrading"
 sound.play_cue("level")
 ui.update_hud(snapshot())
 ui.render("upgrading", {"offers": offers})

func choose_upgrade(id: String) -> void:
 if coop.active:
  coop.choose(id)
  return
 if state != "upgrading":
  return
 var valid := false
 for offer in offers:
  if offer.id == id:
   valid = true
 if not valid or not weapon_system.apply_upgrade(id):
  return
 sound.play_cue("select")
 state = "running"
 ui.render("running")
 ui.update_hud(snapshot())
 check_level()

func buy_building(id: String) -> void:
 if profile.purchase(id):
  sound.play_cue("select")
 ui.render("hub", profile.data)

func set_option(key: String, value) -> void:
 if not profile.data.settings.has(key):
  return
 profile.data.settings[key] = clampf(float(value), 0, 1) if key in ["volume", "effects"] else bool(value)
 apply_settings()
 if not test_mode:
  profile.save()

func apply_settings() -> void:
 effects = profile.data.settings.effects
 sound.volume = profile.data.settings.volume
 if not test_mode:
  DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if profile.data.settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func spawn_enemy(id: String, point: Vector2, elite: bool = false, chain_meta:Dictionary={}):
 id = "demon" if id == "boss" else id
 if id=="slime_large" and not (coop.active and not coop.hosting) and not slime_families.can_add():return null
 var enemy = load("res://scripts/entities/event_creature.gd").new() if id in ["siege_archer","slime_king","event_blue","event_small"] else HazardTarget.new() if id in ["ice_crystal","channel_totem"] else LateBoss.new() if id in ["guardian","horror"] else SlimeEnemy.new() if id in ["slime_large","slime_small"] else Devourer.new() if id=="devourer" else HordeBoss.new() if id in ["demon", "executioner"] else (SpecialEnemy.new() if id in ["necromancer","beast","plague","shadow"] else preload("res://scenes/entities/enemy.tscn").instantiate())
 enemy.position = point
 enemy.chain_root=int(chain_meta.get("root",0));enemy.chain_generation=int(chain_meta.get("generation",-1))
 enemy.serial = serial
 serial += 1
 var stats: EnemyData = enemy_data[id].duplicate()
 if id in ["slime_small","event_small"]:
  stats.health=enemy_data.ghoul.health*balance.slime_small_health_ratio
  stats.speed=enemy_data.ghoul.speed*balance.slime_small_speed_ratio
  stats.damage=enemy_data.ghoul.damage*balance.slime_small_damage_ratio
 var scale: Dictionary = enemy_scale()
 if enemy is HazardTarget:stats.health=float(late_arena.patterns.config.crystal_health if id=="ice_crystal" else late_arena.patterns.config.totem_health)
 stats.health *= 1.0 if enemy is HazardTarget else balance.enemy_health_multiplier
 stats.health *= 1.0 if enemy is HazardTarget else scale.health
 stats.damage *= scale.damage
 if id in ["ghoul","skeleton_sword","skeleton_archer"]:stats.speed*=balance.common_speed_multiplier
 stats.speed *= balance.enemy_speed_multiplier
 stats.speed *= scale.speed
 var health_factor:float=float(survival_config.events.siege_health) if id=="siege_archer" else float(survival_config.events.blue_health) if id=="event_blue" else float(survival_config.events.small_health) if id=="event_small" else 1
 stats.health*=health_factor
 if id=="event_small":stats.speed*=survival_config.events.small_speed
 enemy.setup(self, stats, elite)
 enemy.difficulty_health_factor=health_factor
 if id=="siege_archer":enemy.event_kind="siege"
 if enemy is HazardTarget:enemy.owner_boss=int(chain_meta.get("pattern_owner",0))
 if enemy is HordeBoss:
  enemy.max_hp *= scale.health
  enemy.hp = enemy.max_hp
 horde_progress.apply(enemy)
 if not (coop.active and not coop.hosting):
  var free:Vector2=free_enemy_position(point,enemy.radius)
  if free==Vector2.INF:enemy.free();return null
  enemy.position=free
 entities.add_child(enemy)
 if coop.active and not coop.hosting:enemy.collision_mask=0
 enemies.append(enemy)
 enemy_collision_margin=maxf(enemy_collision_margin,enemy.radius+5)
 var cell:=Vector2i(floori(enemy.position.x/40),floori(enemy.position.y/40))
 if not grid.has(cell):grid[cell]=[]
 grid[cell].append(enemy)
 var body_cell:=Vector2i(floori(enemy.position.x/16),floori(enemy.position.y/16))
 if not crowd_grid.has(body_cell):crowd_grid[body_cell]=[]
 crowd_grid[body_cell].append(enemy);crowd_max_radius=maxf(crowd_max_radius,enemy.radius)
 late_arena.chain.register(enemy)
 if id=="necromancer" and enemy.chain_root>0:enemy.summon_cooldown=0;enemy.attack_time=2
 if id=="slime_large" and not (coop.active and not coop.hosting):slime_families.reserved[enemy.serial]=true
 if id in ["demon", "executioner", "guardian", "horror"]:
  boss = enemy
 return enemy

func enemy_killed(enemy) -> void:
 if reported_deaths.has(enemy.get_instance_id()):
  return
 reported_deaths[enemy.get_instance_id()] = true
 late_arena.chain.remove(enemy)
 if enemy.data.id=="slime_large":slime_families.schedule(enemy)
 kills += 1
 if enemy is Devourer:
  if enemy.swallowed_gold>0:gold_loot.refund(enemy.position,enemy.swallowed_gold)
  if enemy.swallowed_xp>0:drop_xp(enemy.position,enemy.swallowed_xp,true)
 if not special_events.on_death(enemy):
  gold_loot.roll_death(enemy.position)
  drop_xp(enemy.position,float(enemy.data.experience)*balance.death_experience_multiplier)
 if enemy.elite:
  earned += 3
  announce("CARRASCO ABATIDO  |  +3 MEDALHAS", 3)
 if enemy is LateBoss:
  if enemy.data.id=="horror":campaign.remember_clear()
  gold+=int(campaign.config.guardian_reward if enemy.data.id=="guardian" else campaign.config.horror_reward)
  earned+=3 if enemy.data.id=="guardian" else 8
  late_arena.on_death(enemy)
 elif enemy is HordeBoss:
  if enemy.is_executioner:
   executioner_defeated = true
   gold += boss_balance.executioner_reward
   earned += 3
  else:
   boss_defeated = true
   gold += boss_balance.demon_reward
   earned += 5
  boss_arena.on_boss_death(enemy)
 elif enemy.data.behavior == "boss":
  boss_defeated = true
  boss = null
  earned += 5
  hazards.clear()
  announce("CHEFE DERROTADO. ELIMINE OS RESTANTES.", 4)
 enemies.erase(enemy)
 boss_arena.notify_enemy_removed(enemy)

func despawn_enemy(enemy) -> void:
 if not is_instance_valid(enemy):
  return
 slime_families.reserved.erase(enemy.serial)
 late_arena.chain.remove(enemy)
 enemy.alive = false
 enemy.targetable = false
 enemies.erase(enemy)
 boss_arena.notify_enemy_removed(enemy)
 enemy.queue_free()

func nearest_enemy(origin: Vector2, max_range: float):
 var best = null
 var distance := max_range * max_range
 for enemy in enemies:
  if not is_instance_valid(enemy) or not enemy.alive or not enemy.targetable:
   continue
  var current: float = enemy.position.distance_squared_to(origin)
  if current < distance or (is_equal_approx(current, distance) and best != null and enemy.serial < best.serial):
   best = enemy
   distance = current
 return best

func rebuild_grid() -> void:
 grid.clear();crowd_grid.clear();crowd_max_radius=1
 enemy_collision_margin=10
 for enemy in enemies:
  if not is_instance_valid(enemy) or not enemy.alive:
   continue
  enemy_collision_margin=maxf(enemy_collision_margin,enemy.radius+5)
  var cell := Vector2i(floori(enemy.position.x / 40), floori(enemy.position.y / 40))
  if not grid.has(cell):
   grid[cell] = []
  grid[cell].append(enemy)
  var body_cell:=Vector2i(floori(enemy.position.x/16),floori(enemy.position.y/16))
  if not crowd_grid.has(body_cell):crowd_grid[body_cell]=[]
  crowd_grid[body_cell].append(enemy);crowd_max_radius=maxf(crowd_max_radius,enemy.radius)

func enemy_space_free(at:Vector2,radius:float,except=null)->bool:
 if not arena.safe_position(at,radius):return false
 var cell:=Vector2i(floori(at.x/16),floori(at.y/16))
 var span:int=ceili((radius+crowd_max_radius+2)/16)
 for x in range(-span,span+1):
  for y in range(-span,span+1):
   for other in crowd_grid.get(cell+Vector2i(x,y),EMPTY_QUERY):
    if not is_instance_valid(other) or not other.alive or other.collision_layer==0 or other==except:continue
    if at.distance_squared_to(other.position)<pow(radius+other.radius+1,2):return false
 return true

func free_enemy_position(at:Vector2,radius:float,except=null,max_distance:float=240,avoid_players:bool=true)->Vector2:
 if enemy_space_free(at,radius,except) and (not avoid_players or not players_near(at,radius+14)):return at
 var step:float=maxf(8,radius*.7)
 for ring in range(1,ceili(max_distance/step)+1):
  var distance:float=ring*step
  var count:int=maxi(12,ceili(TAU*distance/maxf(8,radius*1.5)))
  for i in count:
   var point:Vector2=at+Vector2.from_angle(i*TAU/count+ring*.37)*distance
   if enemy_space_free(point,radius,except) and (not avoid_players or not players_near(point,radius+14)) and navigation.reachable(point,radius):return point
 return Vector2.INF

func prepare_crowd():
 crowd_near.clear();crowd_push.clear();crowd_pairs=0;crowded_cell_peak=0
 for bucket in crowd_grid.values():crowded_cell_peak=maxi(crowded_cell_peak,bucket.size())
 for enemy in enemies:
  if not is_instance_valid(enemy) or not enemy.alive or enemy.collision_layer==0:continue
  if not crowd_near.has(enemy.serial):crowd_near[enemy.serial]=PackedVector3Array();crowd_push[enemy.serial]=Vector2.ZERO
  var reach:float=enemy.radius+crowd_max_radius+5
  var low:=Vector2i(floori((enemy.position.x-reach)/16),floori((enemy.position.y-reach)/16))
  var high:=Vector2i(floori((enemy.position.x+reach)/16),floori((enemy.position.y+reach)/16))
  for x in range(low.x,high.x+1):
   for y in range(low.y,high.y+1):
    for other in crowd_grid.get(Vector2i(x,y),EMPTY_QUERY):
     if other.serial<=enemy.serial or not other.alive or other.collision_layer==0:continue
     var offset:Vector2=enemy.position-other.position;var minimum:float=enemy.radius+other.radius+4
     if offset.length_squared()>pow(minimum+1,2):continue
     var distance:float=offset.length()
     if distance<.01:offset=Vector2.from_angle((enemy.serial+other.serial)*2.4)*(1 if enemy.serial>other.serial else -1);distance=1
     var normal:Vector2=offset/distance
     if not crowd_near.has(other.serial):crowd_near[other.serial]=PackedVector3Array();crowd_push[other.serial]=Vector2.ZERO
     crowd_near[enemy.serial].append(Vector3(normal.x,normal.y,distance-enemy.radius-other.radius-.4))
     crowd_near[other.serial].append(Vector3(-normal.x,-normal.y,distance-enemy.radius-other.radius-.4))
     var push:Vector2=normal*clampf((minimum-distance)/maxf(4,minimum*.3),0,1)
     crowd_push[enemy.serial]+=push;crowd_push[other.serial]-=push;crowd_pairs+=1
func separation(enemy)->Vector2:
 return Vector2(crowd_push.get(enemy.serial,Vector2.ZERO)).limit_length(2)
func crowd_velocity(enemy,desired:Vector2)->Vector2:
 for pair in crowd_near.get(enemy.serial,EMPTY_QUERY):
  var normal:=Vector2(pair.x,pair.y);var gap:float=pair.z
  var allowed:float=maxf(0,gap)*30;var inward:float=desired.dot(normal)
  if inward< -allowed:desired-=normal*(inward+allowed)
  if gap<0:desired+=normal*minf(45,-gap*35)
 return desired

func query_enemies(at:Vector2,radius:float)->Array:
 var result:Array=[]
 var reach:float=radius+crowd_max_radius
 var low:=Vector2i(floori((at.x-reach)/40),floori((at.y-reach)/40));var high:=Vector2i(floori((at.x+reach)/40),floori((at.y+reach)/40))
 for x in range(low.x,high.x+1):
  for y in range(low.y,high.y+1):
   for enemy in grid.get(Vector2i(x,y),EMPTY_QUERY):
    if is_instance_valid(enemy) and enemy.alive and at.distance_squared_to(enemy.position)<=pow(radius+enemy.radius,2):result.append(enemy)
 return result

func update_pickups(delta: float) -> void:
 var bounds:Rect2=collection_bounds()
 for i in range(pickups.size() - 1, -1, -1):
  var item: Dictionary = pickups[i]
  if not item.get("attracted",false) and not bounds.has_point(item.at):continue
  var collector = collection_player(item.at)
  if collector == null: continue
  var offset: Vector2 = collector.position - item.at
  if offset.length() < collector.pickup_radius:
   item.attracted = true
  if item.attracted:
   item.at = item.at.move_toward(collector.position, delta * 220)
  if item.at.distance_to(collector.position) < 10:
   pickups.remove_at(i)
   sound.play_cue("pickup")
   add_xp(item.xp)
   if state != "running":
    return

func add_hazard(point: Vector2, radius: float, warning: float, damage: float) -> void:
 if hazards.size() >= 32:
  return
 hazards.append({"at": point, "radius": radius, "life": warning + 0.25, "warning": warning, "damage": damage, "age": 0.0, "hit": false})

func update_hazards(delta: float) -> void:
 for hazard in hazards:
  hazard.age += delta
  hazard.life -= delta
  if hazard.age >= hazard.warning and not hazard.hit:
   hazard.hit = true
   damage_team_area(hazard.at, hazard.radius, hazard.damage)
 hazards = hazards.filter(func(h): return h.life > 0)

func update_event(delta: float) -> void:
 if elapsed < 120 or event_claimed:
  return
 if players_near(region, 42):
  event_progress += delta
  if event_progress >= 6:
   event_claimed = true
   earned += 2
   for member in team_players(): member.hp = minf(member.max_hp, member.hp + 25)
   add_xp(10)
   announce("ÁREA CONCLUÍDA  |  VIDA +25  |  +2 MEDALHAS", 4)
 else:
  event_progress = maxf(0, event_progress - delta * 0.5)

func add_damage_number(point: Vector2, amount: float) -> void:
 if numbers.size() < int(20 * effects):
  numbers.append({"at": point, "value": str(roundi(amount)) if is_equal_approx(amount,roundf(amount)) else ("%.2f"%amount).trim_suffix("0"), "life": 0.55})

func announce(text: String, duration: float) -> void:
 banner = text
 banner_time = duration

func camera_rect() -> Rect2:
 var center := player.position.clamp(Vector2(320, 180), Vector2(1480, 1020))
 return Rect2(center - Vector2(320, 180), Vector2(640, 360))

func render_rect()->Rect2:
 var view_size:Vector2=get_viewport_rect().size/camera.zoom
 return Rect2(camera.get_screen_center_position()-view_size*.5,view_size)

func snapshot() -> Dictionary:
 return {"hp": player.hp, "max_hp": player.max_hp, "xp": xp, "xp_needed": xp_needed, "elapsed": elapsed, "level": level, "kills": kills, "gold": gold+coop.local_gold_bonus(), "earned": earned + floori(elapsed / 30.0) + floori(kills / 30.0), "wave": director.wave_number(), "weapons": weapon_system.get_loadout(), "passives": weapon_system.get_passives(), "dev":dev_boss_test,"chain_debug":late_arena.chain.snapshot(),"true_form":is_instance_valid(boss) and boss.data.id=="horror" and boss.form==2,"boss_hp": boss.hp if is_instance_valid(boss) else 0, "boss_max": boss.max_hp if is_instance_valid(boss) else 0, "boss_name": "TRUE FORM" if is_instance_valid(boss) and boss.data.id=="horror" and boss.form==2 else (boss.data.title+" | Fase %d"%boss.form) if is_instance_valid(boss) and boss is HordeBoss and not boss.is_executioner else (boss.data.title if is_instance_valid(boss) else ""), "banner": banner, "pressure": "TESTE DEV" if dev_tools!=null and dev_tools.active else director.pressure()}

func _draw() -> void:
 if state in ["title", "hub"]:
  return
 var visible:Rect2=render_rect().grow(20)
 for item in pickups:
  if not visible.has_point(item.at):continue
  var at: Vector2 = item.at.round()
  draw_texture_rect_region(experience_texture,Rect2(at-Vector2(8,12),Vector2(16,16)),Rect2(int(elapsed*5)%4*16,0,16,16))
 for hazard in hazards:
  var active: bool = hazard.age >= hazard.warning
  var color := Color("e6a66c") if active else Color("b65f42")
  draw_circle(hazard.at, hazard.radius, Color(color, 0.22 if active else 0.09))
  draw_arc(hazard.at, hazard.radius, 0, TAU, 40, color, 2, false)
  draw_arc(hazard.at, hazard.radius * minf(1, hazard.age / hazard.warning), 0, TAU, 40, Color(color, 0.5), 1, false)
 if elapsed >= 120 and not event_claimed:
  draw_arc(region, 42, 0, TAU, 32, Color("c5a361"), 1, false)
  draw_arc(region, 45, -PI / 2, -PI / 2 + TAU * event_progress / 6, 32, Color("d7c9a1"), 2, false)
  draw_rect(Rect2(region - Vector2(7, 11), Vector2(14, 19)), Color("7c7153"))
  draw_string(GameFonts.interface_font(), region + Vector2(-48, -52), "ÁREA  |  FIQUE 6s", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("d7c9a1"))
 for number in numbers:
  draw_string(GameFonts.interface_font(), number.at, number.value, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("e3c9a0"))

func drop_xp(at:Vector2,amount:float,protected:bool=false):
 if amount<=0:return
 at=arena.loot_point(at)
 for item in pickups:
  if pickups.size()>=240 and item.get("protected",false)==protected and not item.get("attracted",false):
   item.xp+=amount;return
 serial+=1
 pickups.append({"id":serial,"at":at,"xp":amount,"attracted":false,"protected":protected})

func collection_bounds(gold_items:bool=false)->Rect2:
 var bounds:=Rect2()
 var first:bool=true
 for collector in team_players():
  var reach:float=collector.gold_collection_radius() if gold_items else collector.pickup_radius
  reach=maxf(reach,balance.coin_arrival_radius if gold_items else 10)+1
  var area:=Rect2(collector.position-Vector2.ONE*reach,Vector2.ONE*reach*2)
  bounds=area if first else bounds.merge(area);first=false
 return bounds

func open_map_select():
 state="maps";ui.render("maps")

func show_revive_offer():
 state="revive_offer";ui.render("revive_offer")
func use_solo_revive():
 if state=="revive_offer" and mastery.use_revive():state="running";ui.render("running")

func start_late_test(kind:String):
 if not development_build():return
 if kind not in ["guardian","horror","true"]:return
 start_run();dev_boss_kind=kind;dev_boss_test=true;persistence_enabled=false;run_challenge=0;mastery.begin(false)
 director.phase="complete";elapsed=900 if kind=="guardian" else 1200
 weapon_system.levels={"sword":8,"bolt":8,"orbit":8,"lightning":8,"clock":8,"holy_water":8}
 for id in ["boots","heart","ward","crown"]:
  for i in 8:weapon_system.apply_upgrade(id)
 level=80 if kind=="guardian" else 96;player.position=Vector2(820,630)
 late_arena.begin_encounter("guardian" if kind=="guardian" else "horror")
 if kind=="true":
  late_arena.tick(1.3);boss.take_damage(boss.max_hp/maxf(.01,1-horde_progress.resistance())+.01);boss.tick(1.7)
 announce("TESTE: "+kind.to_upper()+" | SEM SALVAMENTO",3)
 ui.update_hud(snapshot())
