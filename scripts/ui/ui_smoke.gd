extends SceneTree

class StubGame extends Node:
	var profile = preload("res://scripts/core/profile.gd").new("user://ui_smoke_unused.json")
	var sound = null
	var state: String = "title"
	func start_run(_support: String = "none") -> void: pass
	func enter_hub() -> void: pass
	func choose_upgrade(_id: String) -> void: pass
	func toggle_pause() -> void: pass
	func retry() -> void: pass
	func abandon() -> void: pass
	func set_option(_key: String, _value) -> void: pass
	func buy_building(_id: String) -> void: pass
	func show_title() -> void: pass
	func open_skill_tree() -> void: pass
	func start_boss_test(_kind: String) -> void: pass

func _initialize() -> void:
	call_deferred("_validate")

func _validate() -> void:
	var stub := StubGame.new()
	root.add_child(stub)
	var ui := GameUI.new()
	root.add_child(ui)
	ui.setup(stub)
	for which in ["title", "hub", "running", "paused", "settings", "result", "lab"]:
		ui.render(which)
		await process_frame
	ui.render("upgrading", {"offers": [
		{"id": "sword", "name": "Espada", "description": "O arco alcança mais inimigos.", "detail": "Nível 2"},
		{"id": "bolt", "name": "Virote", "description": "Um projétil atravessa a horda.", "detail": "Nova arma"},
		{"id": "orbit", "name": "Brasas", "description": "Proteção em torno da sentinela.", "detail": "Nova arma"}
	]})
	await process_frame
	var concrete_offers: Array[Dictionary] = []
	for weapon_id: String in ["sword", "bolt", "orbit"]:
		var resource = load("res://data/weapons/%s.tres" % weapon_id)
		for level: int in range(5):
			concrete_offers.append({"id": weapon_id, "name": resource.evolution_name if level == 4 else resource.display_name, "description": resource.level_descriptions[level], "detail": "ARMA %d/5 · Só nesta expedição. Nível 5 exige Passo do exílio." % [level + 1]})
	for passive_id: String in ["boots", "magnet", "heart", "ward", "cadence"]:
		var resource = load("res://data/upgrades/%s.tres" % passive_id)
		for level: int in range(2):
			concrete_offers.append({"id": passive_id, "name": resource.display_name, "description": resource.level_descriptions[level], "detail": "PASSIVA %d/2 · Só nesta expedição. 3/3 vagas ocupadas." % [level + 1]})
	for index: int in range(0, concrete_offers.size(), 3):
		ui.render("upgrading", {"offers": concrete_offers.slice(index, mini(index + 3, concrete_offers.size()))})
		await process_frame
		for card in ui.menu.get_children():
			if not card is Button:
				continue
			for text in card.get_children():
				if text is Label:
					assert(text.position.y + text.get_minimum_size().y <= card.size.y - 6.0, "Upgrade card text overflows: " + text.text)
	ui.update_hud({"hp": 58, "max_hp": 100, "elapsed": 359, "weapons": [{"id": "sword", "name": "Espada", "level": 2}], "passives": [{"name": "Botas", "level": 1}], "boss_max": 200, "boss_hp": 100})
	await process_frame
	assert(is_equal_approx(ui.life_bar.size.y, 7.0), "Life bar must stay 7 internal pixels high")
	assert(is_equal_approx(ui.experience_bar.size.y, 5.0), "Experience bar must stay 5 internal pixels high")
	assert(is_equal_approx(ui.boss_bar.size.y, 6.0), "Boss bar must stay 6 internal pixels high")
	ui._legal("privacy")
	await process_frame
	ui._legal("terms")
	await process_frame
	print("UI_SMOKE_OK: all screens, 25 upgrade texts, HUD bars 7/5/6px, privacy and terms")
	quit(0)
