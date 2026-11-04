class_name CoopRules
extends Resource

@export var health_bonus: float = 0.5
@export var damage_bonus: float = 0.5
@export var speed_bonus: float = 0.2
@export var count_bonus: float = 0.8
@export var revive_seconds: float = 5
@export var revive_range: float = 34
@export var revive_health: float = 0.4
@export var revive_invulnerability: float = 2
@export var state_interval: float = 0.1
@export var input_interval: float = 0.05
@export var interpolation_rate: float = 15
@export var input_timeout: float = 0.35

func scaling(participants: int) -> Dictionary:
	var extra: int = clampi(participants, 1, 4) - 1
	return {"health": 1 + health_bonus * extra, "damage": 1 + damage_bonus * extra, "speed": 1 + speed_bonus * extra, "count": 1 + count_bonus * extra}

func wave_count(original: int, participants: int, boss: bool = false) -> int:
	if boss:
		return original
	return floori(original * scaling(participants).count + 0.5)

func composition(original: Dictionary, participants: int, challenge:float=1.0) -> Dictionary:
	var result: Dictionary = {}
	var fractions: Array[Dictionary] = []
	var total: int = 0
	var allocated: int = 0
	var multiplier: float = scaling(participants).count*challenge
	for id in original:
		var amount: int = maxi(0, int(original[id]))
		total += amount
		var raw: float = amount * multiplier
		result[id] = floori(raw)
		allocated += result[id]
		fractions.append({"id": str(id), "fraction": raw - floorf(raw)})
	fractions.sort_custom(func(a, b): return a.fraction > b.fraction if not is_equal_approx(a.fraction, b.fraction) else a.id < b.id)
	var remaining: int = floori(total*multiplier+.5) - allocated
	for i in remaining:
		result[fractions[i % fractions.size()].id] += 1
	return result
