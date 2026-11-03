class_name EncounterBalance
extends Resource

@export_group("Hordas")
@export var waves: Array[Resource] = []
@export var initial_preparation: float = 2.5
@export var preparation_seconds: float = 5.0
@export var minimum_spawn_interval: float = 0.12
@export var max_enemies: int = 180
@export var spawn_margin: float = 36.0
@export var spawn_distance_min: float = 390.0
@export var spawn_distance_max: float = 460.0
@export_group("Ouro")
@export var coin_lifetime: float = 60.0
@export var coin_value: int = 1
@export var coin_attraction_radius: float = 44.0
@export var coin_collect_speed: float = 230.0
@export var coin_arrival_radius: float = 8.0
@export_group("Projéteis inimigos")
@export var max_enemy_projectiles: int = 320
@export var arrow_radius: float = 2.0
