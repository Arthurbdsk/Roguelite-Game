class_name SkillDefinition
extends Resource

@export var id: String
@export var title: String
@export var branch: int = 0
@export var depth: int = 0
@export var description: String
@export var costs: PackedInt32Array
@export var benefits: PackedStringArray
@export var values: PackedFloat32Array
@export var prerequisites: Dictionary = {}

func max_rank() -> int:
	return costs.size()

@export var icon:String=""
