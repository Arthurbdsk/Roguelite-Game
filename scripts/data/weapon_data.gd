extends Resource
class_name WeaponData

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: String = ""
@export var affinity: String = ""
@export var evolution_name: String = ""
@export var max_level: int = 8
@export var damage: PackedFloat32Array = PackedFloat32Array()
@export var cooldown: PackedFloat32Array = PackedFloat32Array()
@export var reach: PackedFloat32Array = PackedFloat32Array()
@export var count: PackedInt32Array = PackedInt32Array()
@export var level_descriptions: PackedStringArray = PackedStringArray()

@export var beam_width:PackedFloat32Array=PackedFloat32Array([8,10,12,14,16,18,20,22])
@export var freeze_duration:float=3.0
@export var freeze_resistance:float=2.0
@export var boss_slow:float=0.3
@export var boss_slow_duration:float=1.0

@export var duration:PackedFloat32Array=PackedFloat32Array([3,3,3.5,3.5,4,4,4.5,4.5])
@export var tick_interval:float=.5
@export var trail_distance:float=18
@export var pool_limit:int=60
@export var flight_time:float=.7

@export var pierce:PackedInt32Array=PackedInt32Array([2,2,3,3,4,4,5,6])
@export var area_radius:PackedFloat32Array=PackedFloat32Array([40,40,44,44,48,48,52,56])
@export var rotation_speed:PackedFloat32Array=PackedFloat32Array([3,3,3.4,3.4,3.8,3.8,4.2,4.6])
