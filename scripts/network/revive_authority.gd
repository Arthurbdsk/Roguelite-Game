class_name ReviveAuthority
extends RefCounted

var rules := CoopRules.new()
var interactions: Dictionary = {}
var completed: Dictionary = {}
var sequence: int = 0

# The caller supplies only host-owned positions, health and current input state.
func update(delta: float, actors: Dictionary, actions: Dictionary) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var claimed: Dictionary = {}
	for rescuer in interactions.keys():
		if not actors.has(rescuer) or not actors[rescuer].get("connected", true):
			interactions.erase(rescuer)
	for rescuer in interactions:
		claimed[interactions[rescuer].target] = rescuer
	for id in actors:
		var actor: Dictionary = actors[id]
		var action: Dictionary = actions.get(id, {})
		var held: bool = action.get("revive", false)
		var moving: bool = Vector2(action.get("movement", Vector2.ZERO)).length_squared() > 0.0001
		if not actor.get("connected", true) or actor.get("down", false) or not held or moving:
			if interactions.has(id):
				claimed.erase(interactions[id].target)
				interactions.erase(id)
			continue
		if not interactions.has(id):
			var nearest: String = ""
			var distance: float = rules.revive_range
			for target in actors:
				if not actors[target].get("connected", true) or not actors[target].get("down", false) or claimed.has(target):
					continue
				var candidate: float = actor.position.distance_to(actors[target].position)
				if candidate < distance or is_equal_approx(candidate, distance) and (nearest.is_empty() or str(target) < nearest):
					nearest = str(target)
					distance = candidate
			if not nearest.is_empty():
				interactions[id] = {"target": nearest, "origin": actor.position, "hp": actor.hp, "revision": actor.get("damage_revision", 0), "progress": 0.0}
				claimed[nearest] = id
		if not interactions.has(id):
			continue
		var interaction: Dictionary = interactions[id]
		var target: String = interaction.target
		if not actors.has(target) or not actors[target].get("connected", true) or not actors[target].get("down", false) or actor.position.distance_squared_to(interaction.origin) > 0.000001 or actor.hp < interaction.hp or actor.get("damage_revision", 0) != interaction.revision or actor.position.distance_to(actors[target].position) > rules.revive_range:
			interactions.erase(id)
			claimed.erase(target)
			continue
		interaction.progress += maxf(0, delta)
		if interaction.progress >= rules.revive_seconds:
			sequence += 1
			var event := {"id": sequence, "target": target, "rescuer": id, "hp": actors[target].max_hp * rules.revive_health, "invulnerability": rules.revive_invulnerability}
			completed[sequence] = true
			events.append(event)
			actors[target].down = false
			actors[target].hp = event.hp
			actors[target].invulnerable = event.invulnerability
			interactions.erase(id)
			claimed.erase(target)
	for id in interactions.keys():
		if not actors.has(id):
			interactions.erase(id)
	return events

func all_down(actors: Dictionary) -> bool:
	var connected: int = 0
	for actor in actors.values():
		if not actor.get("connected", true):
			continue
		connected += 1
		if not actor.get("down", false):
			return false
	return connected > 0
