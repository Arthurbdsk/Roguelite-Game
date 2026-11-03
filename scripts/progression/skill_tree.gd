class_name PermanentSkills
extends RefCounted

var game
var definitions: Array[SkillDefinition] = []
var by_id: Dictionary = {}
var last_error: String = ""

func setup(owner_game) -> void:
	game = owner_game
	var catalog: Resource = load("res://data/skills/catalog.tres")
	for definition in catalog.nodes:
		definitions.append(definition)
		by_id[definition.id] = definition

func rank(id: String) -> int:
	if not by_id.has(id):
		return 0
	return clampi(int(game.profile.data.skill_ranks.get(id, 0)), 0, by_id[id].max_rank())

func value(id: String) -> float:
	var level := rank(id)
	return float(by_id[id].values[level - 1]) if level > 0 else 0.0

func state(id: String) -> Dictionary:
	if not by_id.has(id):
		return {"status": "locked", "can_buy": false, "cost": 0, "reason": "Habilidade desconhecida."}
	var definition: SkillDefinition = by_id[id]
	var level := rank(id)
	if level >= definition.max_rank():
		return {"status": "maxed", "can_buy": false, "cost": 0, "reason": "Nível máximo atingido."}
	var cost: int = definition.costs[level]
	for required in definition.prerequisites:
		if rank(required) < int(definition.prerequisites[required]):
			return {"status": "locked", "can_buy": false, "cost": cost, "reason": "Exige %s nível %d." % [by_id[required].title, definition.prerequisites[required]]}
	if game.profile.data.gold < cost:
		return {"status": "unaffordable", "can_buy": false, "cost": cost, "reason": "Faltam %d moedas." % (cost - game.profile.data.gold)}
	return {"status": "owned" if level > 0 else "available", "can_buy": true, "cost": cost, "reason": "Próximo nível disponível."}

func purchase(id: String, expected_rank: int = -1) -> bool:
	last_error = ""
	if game.state not in ["title", "hub", "tree"]:
		last_error = "Compre fora da expedição."
		return false
	if expected_rank >= 0 and expected_rank != rank(id):
		last_error = "A habilidade já foi atualizada."
		return false
	var info := state(id)
	if not info.can_buy:
		last_error = info.reason
		return false
	var before: Dictionary = game.profile.data.duplicate(true)
	game.profile.data.gold -= info.cost
	game.profile.data.skill_ranks[id] = rank(id) + 1
	if not game.profile.save():
		game.profile.data = before
		last_error = game.profile.last_error
		return false
	return true
