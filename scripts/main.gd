extends Node2D

var state: String = "title"
var elapsed: float = 0
var kills: int = 0
var earned: int = 0
var level: int = 1
var xp: int = 0
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
var grid: Dictionary = {}
var offers: Array[Dictionary] = []
var boss = null
var boss_defeated: bool = false
var test_mode: bool = false
var slice_mode: bool = false
var hud_clock: float = 0
var serial: int = 0
var banked_reward: int = 0
var event_claimed: bool = false
var event_progress: float = 0
var region: Vector2 = Vector2(1260, 810)
var profile := GameProfile.new()
var player: Sentinel
var arena: RuinedArena
var weapon_system: WeaponSystem
var director := HordeDirector.new()
var sound: GameSound
var ui: GameUI
var entities: Node2D
var camera: Camera2D
var enemy_data: Dictionary = {}

func _ready() -> void:
	test_mode = "--self-test" in OS.get_cmdline_user_args()
	slice_mode = "--slice" in OS.get_cmdline_user_args()
	register_inputs()
	if not test_mode:
		profile.load_profile()
	for id in ["ghoul", "hound", "guard", "boss"]:
		enemy_data[id] = load("res://data/enemies/" + id + ".tres")
	arena = RuinedArena.new()
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
	director.setup(self)
	sound = GameSound.new()
	add_child(sound)
	ui = GameUI.new()
	add_child(ui)
	ui.setup(self)
	apply_settings()
	show_title()
	if "--play" in OS.get_cmdline_user_args():
		start_run()

func register_inputs() -> void:
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
	if state != "running":
		return
	elapsed = minf(600, elapsed + delta)
	player.tick(delta, movement)
	director.tick(delta)
	rebuild_grid()
	for enemy in enemies.duplicate():
		if is_instance_valid(enemy) and enemy.alive:
			enemy.tick(delta)
			if state != "running":
				return
	weapon_system.update_combat(delta)
	update_pickups(delta)
	update_hazards(delta)
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
	if not slice_mode and elapsed >= 600:
		finish_run(boss_defeated)
	queue_redraw()

func start_run(selected_support: String = "none") -> void:
	if selected_support not in ["none", "arsenal", "library"]:
		selected_support = "none"
	if selected_support != "none" and not profile.data.buildings[selected_support]:
		selected_support = "none"
	support = selected_support
	clear_run()
	player.hp = 100
	player.max_hp = 100
	player.speed = 96
	player.pickup_radius = 42
	player.armor = 0
	player.invulnerable = 1
	player.position = Vector2(900, 630)
	player.facing = Vector2.DOWN
	camera.reset_smoothing()
	weapon_system.reset(support)
	director.reset()
	state = "running"
	ui.render("running")
	ui.update_hud(snapshot())
	announce("PÁTIO DOS ESQUECIDOS", 3)

func clear_run() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()
	pickups.clear()
	hazards.clear()
	numbers.clear()
	grid.clear()
	elapsed = 0
	kills = 0
	earned = 0
	level = 1
	xp = 0
	xp_needed = 6
	boss = null
	boss_defeated = false
	event_claimed = false
	event_progress = 0
	shake_time = 0
	camera.offset = Vector2.ZERO
	queue_redraw()

func show_title() -> void:
	state = "title"
	ui.render("title", profile.data)

func enter_hub() -> void:
	state = "hub"
	ui.render("hub", profile.data)

func retry() -> void:
	start_run(support)

func abandon() -> void:
	# Leaving a live expedition settles it once, just like defeat.
	if state in ["running", "paused", "upgrading"]:
		finish_run(false)
	else:
		enter_hub()

func finish_run(won: bool) -> void:
	if state not in ["running", "paused", "upgrading"]:
		return
	state = "result"
	camera.offset = Vector2.ZERO
	banked_reward = profile.reward(elapsed, kills, won, earned) if not test_mode else floori(elapsed / 30.0) + floori(kills / 30.0) + earned + (10 if won else 0)
	sound.play_cue("victory" if won else "defeat")
	ui.render("result", {"won": won, "elapsed": elapsed, "kills": kills, "earned": banked_reward, "level": level})

func toggle_pause() -> void:
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
	if event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START):
		if state in ["running", "paused"]:
			toggle_pause()
		elif ui.screen == "settings":
			ui.render(ui.return_screen, profile.data)
		elif state == "hub":
			show_title()
	if state == "upgrading" and event is InputEventKey and event.pressed and not event.echo:
		var index: int = event.physical_keycode - KEY_1
		if index >= 0 and index < offers.size():
			choose_upgrade(offers[index].id)
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_F11:
		set_option("fullscreen", not profile.data.settings.fullscreen)

func add_xp(amount: int) -> void:
	xp += amount
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

func spawn_enemy(id: String, point: Vector2, elite: bool = false):
	var enemy = preload("res://scenes/entities/enemy.tscn").instantiate()
	enemy.position = point
	enemy.serial = serial
	serial += 1
	enemy.setup(self, enemy_data[id], elite)
	entities.add_child(enemy)
	enemies.append(enemy)
	if id == "boss":
		boss = enemy
	return enemy

func enemy_killed(enemy) -> void:
	kills += 1
	pickups.append({"at": enemy.position, "xp": enemy.data.experience, "attracted": false})
	if pickups.size() > 240:
		# Merge value rather than discard experience under load.
		pickups[0].xp += pickups[-1].xp
		pickups.pop_back()
	if enemy.elite:
		earned += 3
		announce("CARRASCO ABATIDO  |  +3 SELOS", 3)
	if enemy.data.behavior == "boss":
		boss_defeated = true
		boss = null
		earned += 5
		hazards.clear()
		announce("O REI CAIU. RESISTA ATÉ O AMANHECER.", 4)
	enemies.erase(enemy)

func nearest_enemy(origin: Vector2, max_range: float):
	var best = null
	var distance := max_range * max_range
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.alive:
			continue
		var current: float = enemy.position.distance_squared_to(origin)
		if current < distance or (is_equal_approx(current, distance) and best != null and enemy.serial < best.serial):
			best = enemy
			distance = current
	return best

func rebuild_grid() -> void:
	grid.clear()
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.alive:
			continue
		var cell := Vector2i(floori(enemy.position.x / 40), floori(enemy.position.y / 40))
		if not grid.has(cell):
			grid[cell] = []
		grid[cell].append(enemy)

func separation(enemy) -> Vector2:
	var cell := Vector2i(floori(enemy.position.x / 40), floori(enemy.position.y / 40))
	var push := Vector2.ZERO
	for x in range(-1, 2):
		for y in range(-1, 2):
			for other in grid.get(cell + Vector2i(x, y), []):
				if other == enemy or not is_instance_valid(other) or not other.alive:
					continue
				var offset: Vector2 = enemy.position - other.position
				var length := offset.length()
				var minimum: float = enemy.radius + other.radius
				if length < minimum and length > 0.1:
					push += offset / length * (1.0 - length / minimum)
	return push.limit_length(2)

func update_pickups(delta: float) -> void:
	for i in range(pickups.size() - 1, -1, -1):
		var item: Dictionary = pickups[i]
		var offset: Vector2 = player.position - item.at
		if offset.length() < player.pickup_radius:
			item.attracted = true
		if item.attracted:
			item.at = item.at.move_toward(player.position, delta * 220)
		if item.at.distance_to(player.position) < 10:
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
			if player.position.distance_to(hazard.at) < hazard.radius + player.radius:
				player.take_damage(hazard.damage, hazard.at)
	hazards = hazards.filter(func(h): return h.life > 0)

func update_event(delta: float) -> void:
	if elapsed < 120 or event_claimed:
		return
	if player.position.distance_to(region) < 42:
		event_progress += delta
		if event_progress >= 6:
			event_claimed = true
			earned += 2
			player.hp = minf(player.max_hp, player.hp + 25)
			add_xp(10)
			announce("BRASAS RECUPERADAS  |  VIDA +25  |  +2 SELOS", 4)
	else:
		event_progress = maxf(0, event_progress - delta * 0.5)

func add_damage_number(point: Vector2, amount: int) -> void:
	if numbers.size() < int(20 * effects):
		numbers.append({"at": point, "value": str(amount), "life": 0.55})

func announce(text: String, duration: float) -> void:
	banner = text
	banner_time = duration

func camera_rect() -> Rect2:
	var center := player.position.clamp(Vector2(320, 180), Vector2(1480, 1020))
	return Rect2(center - Vector2(320, 180), Vector2(640, 360))

func snapshot() -> Dictionary:
	return {"hp": player.hp, "max_hp": player.max_hp, "xp": xp, "xp_needed": xp_needed, "elapsed": elapsed, "level": level, "kills": kills, "earned": earned + floori(elapsed / 30.0) + floori(kills / 30.0), "weapons": weapon_system.get_loadout(), "passives": weapon_system.get_passives(), "boss_hp": boss.hp if is_instance_valid(boss) else 0, "boss_max": boss.max_hp if is_instance_valid(boss) else 0, "banner": banner, "pressure": director.pressure()}

func _draw() -> void:
	if state in ["title", "hub"]:
		return
	for item in pickups:
		var at: Vector2 = item.at.round()
		draw_colored_polygon(PackedVector2Array([at + Vector2(0, -4), at + Vector2(3, 0), at + Vector2(0, 4), at + Vector2(-3, 0)]), Color("83c4bd"))
		draw_line(at + Vector2(0, -2), at, Color("e1eee0"), 1)
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
		draw_string(ThemeDB.fallback_font, region + Vector2(-48, -52), "BRASAS  |  RESISTA 6s", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("d7c9a1"))
	for number in numbers:
		draw_string(ThemeDB.fallback_font, number.at, number.value, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("e3c9a0"))
