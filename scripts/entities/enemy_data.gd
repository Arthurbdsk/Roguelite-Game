class_name EnemyData
extends Resource

@export var id: String = "ghoul"
@export var title: String = "Zumbi"
@export var health: float = 24
@export var speed: float = 25
@export var damage: float = 8
@export var experience: int = 2
@export var radius: float = 8
@export var texture: String = "res://assets/ghoul.png"
@export var behavior: String = "chase"
@export var frames: int = 4
@export var gold_value: int = 1
@export var contact_damage: bool = true
@export_group("Ataque")
@export var attack_range: float = 34.0
@export var attack_interval: float = 1.7
@export var windup: float = 0.55
@export var recovery: float = 0.35
@export var attack_half_angle: float = 65.0
@export_group("Arco")
@export var preferred_distance: float = 145.0
@export var retreat_distance: float = 105.0
@export var arrow_speed: float = 155.0
@export var arrow_range: float = 300.0
@export var arrow_lifetime: float = 3.0
