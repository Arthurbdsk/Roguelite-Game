extends Resource
class_name WeaponData

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: String = ""
@export var affinity: String = ""
@export var evolution_name: String = ""
@export var max_level: int = 5
@export var damage: PackedFloat32Array = PackedFloat32Array()
@export var cooldown: PackedFloat32Array = PackedFloat32Array()
@export var reach: PackedFloat32Array = PackedFloat32Array()
@export var count: PackedInt32Array = PackedInt32Array()
@export var level_descriptions: PackedStringArray = PackedStringArray()
