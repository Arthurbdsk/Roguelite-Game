class_name WaveData
extends Resource

@export var title: String = ""
@export var composition: Dictionary = {}
@export var spawn_interval: float = 1.0
@export var max_alive: int = 12
@export var elite_guards: int = 0
@export var boss: bool = false

func count() -> int:
	var total: int = elite_guards + int(boss)
	for value in composition.values():
		total += int(value)
	return total
