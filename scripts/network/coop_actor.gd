class_name CoopActor
extends RefCounted

var world
var session
var id: String
var display_name: String
var player: Sentinel
var weapon_system: WeaponSystem
var mastery := RunMastery.new()
var skills := PermanentSkills.new()
var profile: GameProfile
var level: int = 1
var xp: float = 0
var xp_needed: int = 6
var offers: Array[Dictionary] = []
var generation: int = 0
var down: bool = false
var state: String:
	get: return world.state
var earned: int:
	get: return world.earned
	set(value): world.earned = value
var shake_time: float:
	get: return world.shake_time
	set(value):
		if id == session.connection.peer_id:
			world.shake_time = value

func _get(property: StringName):
	return world.get(property)

func setup(owner_world, owner_session, metadata: Dictionary, local: bool) -> void:
	world = owner_world
	session = owner_session
	id = metadata.id
	display_name = metadata.name
	profile = world.profile if local else GameProfile.new("user://unused_remote_actor.json")
	if not local:
		profile.data.upgrade_ranks = metadata.get("skills", {}).duplicate(true)
		profile.data.gold_remainder=clampf(float(metadata.get("gold_remainder",0)),0,.999999)
	skills.setup(self)
	# Do not trust out-of-range or prerequisite-breaking remote ranks.
	var accepted: Dictionary = {}
	for definition in skills.definitions:
		var rank_value: int = clampi(int(profile.data.upgrade_ranks.get(definition.id, 0)), 0, definition.max_rank())
		var valid: bool = true
		for required in definition.prerequisites:
			valid = valid and int(accepted.get(required, 0)) >= int(definition.prerequisites[required])
		if valid and rank_value > 0:
			accepted[definition.id] = rank_value
	if not local:
		profile.data.upgrade_ranks = accepted
	if local:
		player = world.player
		weapon_system = world.weapon_system
		mastery = world.mastery
	else:
		player = preload("res://scenes/entities/player.tscn").instantiate()
		player.game = self
		world.entities.add_child(player)
		weapon_system = WeaponSystem.new()
		world.add_child(weapon_system)
		weapon_system.setup(self)
	player.game = self
	player.display_name = display_name
	weapon_system.game = self
	weapon_system.reset()
	mastery.setup(self)
	mastery.begin()

func finish_run(_won: bool) -> void:
	session.mark_down(id)

func nearest_enemy(origin: Vector2, reach: float):
	return world.nearest_enemy(origin, reach)

func weapon_hit(enemy, amount: float, force: Vector2) -> void:
	mastery.hit(enemy, amount, force)

func add_damage_number(at: Vector2, amount: int) -> void:
	world.add_damage_number(at, amount)

func announce(message: String, duration: float) -> void:
	if id == session.connection.peer_id:
		world.announce(message, duration)

func award_xp(amount: float) -> void:
	xp += amount * (1.0+.07*int(weapon_system.passives.get("crown",0))+mastery.value("experience"))
	prepare_offer()

func prepare_offer() -> void:
	if xp < xp_needed or not offers.is_empty():
		return
	xp -= xp_needed
	level += 1
	xp_needed = 6 + (level - 1) * 5
	generation += 1
	offers = weapon_system.get_offers()

func choose(id_value: String, expected_generation: int) -> bool:
	if down or generation != expected_generation:
		return false
	for offer in offers:
		if offer.id == id_value and weapon_system.apply_upgrade(id_value):
			offers.clear()
			prepare_offer()
			return true
	return false

func personal() -> Dictionary:
	return {"level": level, "xp": xp, "xp_needed": xp_needed, "offers": offers, "generation": generation, "levels": weapon_system.levels, "passives": weapon_system.passives,"gold_bonus":mastery.gold_bonus,"gold_remainder":mastery.gold_fraction,"revive_available":mastery.can_revive(),"stats":{"hp":player.hp,"max_hp":player.max_hp,"speed":player.speed,"armor":player.armor,"pickup_radius":player.pickup_radius,"damage_reduction":player.damage_reduction}}

func release() -> void:
	mastery.game = null
	skills.game = null
	if is_instance_valid(player): player.game = null
	if is_instance_valid(weapon_system): weapon_system.game = null
	world = null
	session = null
