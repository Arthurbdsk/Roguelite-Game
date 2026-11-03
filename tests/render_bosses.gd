extends SceneTree

var g

func _initialize() -> void:
	call_deferred("run")

func capture(name: String) -> void:
	g.ui.update_hud(g.snapshot())
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test_output/" + name + ".png")

func run() -> void:
	g = load("res://scenes/main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	g.sound.volume = 0
	g.profile = GameProfile.new("user://visual_tree_isolated.json")
	g.profile.data.gold = 30
	g.profile.data.skill_ranks = {"edge": 1, "vigor": 2}
	g.ui.selected_skill = "sword_echo"
	g.open_skill_tree()
	await capture("skill_tree")
	g.start_boss_test("executioner")
	g.player.position = Vector2(800, 630)
	g.boss.begin_attack("execute")
	g.boss.state_time = 0.8
	g.boss.tick(0)
	g.banner = ""
	await capture("executioner")
	g.start_boss_test("demon")
	g.boss_arena.tick(0.6)
	g.banner = ""
	await capture("portal_trace")
	g.boss_arena.tick(1.0)
	await capture("portal_open")
	g.boss_arena.tick(1.1)
	await capture("portal_emerge")
	g.boss_arena.tick(1.1)
	g.player.position = Vector2(750, 630)
	g.boss.hp = g.boss.max_hp * 0.6
	g.boss.tick(0)
	g.boss_arena.cast("ice", g.boss, Vector2.LEFT, 2)
	g.boss_arena.tick(0.9)
	g.boss_arena.cast("fire", g.boss, Vector2.LEFT, 2)
	g.enemy_projectiles.tick(0.55)
	g.boss.begin_attack("ice")
	g.boss.tick(0)
	g.banner = ""
	await capture("demon_ice")
	g.boss_arena.areas.clear()
	g.boss_arena.cast("lightning", g.boss, Vector2.LEFT, 3)
	g.boss_arena.tick(0.65)
	g.boss.begin_attack("lightning")
	g.boss.tick(0)
	await capture("demon_lightning")
	g.boss_arena.areas.clear()
	g.boss_arena.cast("summon", g.boss, Vector2.LEFT, 3)
	await capture("demon_summon_warning")
	g.boss_arena.tick(1.01)
	g.boss.hp = g.boss.max_hp * 0.28
	g.boss.tick(0)
	g.boss_arena.cast("fire", g.boss, Vector2.LEFT, 3)
	g.enemy_projectiles.tick(0.4)
	g.banner = ""
	await capture("demon_phase3")
	g.boss.take_damage(99999)
	g.boss_arena.tick(0.5)
	await capture("demon_death")
	g.boss_arena.tick(1.1)
	await capture("boss_test_result")
	g.queue_free()
	await process_frame
	print("BOSS_RENDER_OK")
	quit()
