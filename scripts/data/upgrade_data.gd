extends Resource
class_name UpgradeData

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: String = ""
@export var max_level: int = 2
@export var level_descriptions: PackedStringArray = PackedStringArray()
@export var regeneration: PackedFloat32Array = PackedFloat32Array()
