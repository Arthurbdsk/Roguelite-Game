class_name EncounterBalance
extends Resource

@export_group("Hordas")
@export var waves: Array[Resource] = []
@export var initial_preparation: float = 2.5
@export var preparation_seconds: float = 2.5
@export var minimum_spawn_interval: float = 0.12
@export var max_enemies: int = 240
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

@export_group("Novos inimigos")
@export var enemy_health_multiplier:float=1.6
@export var enemy_speed_multiplier:float=1.3
@export var food_search_radius:float=180
@export var food_search_interval:float=.3
@export var devour_health_gain:float=5
@export var devour_damage_gain:float=.5
@export var devour_growth_step:float=.025
@export var devour_max_scale:float=2.2
@export var slime_children:int=15
@export var slime_split_warning:float=.65
@export var slime_grace:float=.5
@export var slime_small_speed_ratio:float=1.8
@export var slime_small_health_ratio:float=.15
@export var slime_small_damage_ratio:float=.2
@export var split_entity_budget:int=420

@export var slime_family_gold:int=4
@export var slime_family_xp:int=8

@export var common_speed_multiplier:float=1.15
