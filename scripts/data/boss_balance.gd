class_name BossBalance
extends Resource

@export_group("Carrasco")
@export var executioner_arrival: float = 300.0
@export var executioner_previous_health: float = 312.0
@export var executioner_health_multiplier: float = 3.0
@export var executioner_speed: float = 64.0
@export var executioner_interval: float = 1.8
@export var executioner_enraged_interval: float = 1.3
@export var executioner_swing_warning: float = 1.1
@export var executioner_tracking: float = 0.62
@export var executioner_swing_range: float = 88.0
@export var executioner_swing_damage: float = 28.0
@export var executioner_charge_speed: float = 210.0
@export var executioner_charge_damage: float = 25.0
@export var executioner_reward: int = 30
@export_group("Demônio")
@export var demon_health_multiplier: float = 2.0
@export var demon_speed: float = 70.0
@export var demon_interval: float = 2.0
@export var demon_phase2_interval: float = 1.65
@export var demon_phase3_interval: float = 1.3
@export var demon_charge_speed: float = 235.0
@export var demon_charge_damage: float = 30.0
@export var demon_reward: int = 120
@export_group("Portal e morte")
@export var portal_trace: float = 1.2
@export var portal_open: float = 0.9
@export var portal_emerge: float = 1.0
@export var portal_close: float = 0.6
@export var death_duration: float = 1.5
@export_group("Tempos compartilhados")
@export var charge_warning: float = 1.0
@export var charge_tracking: float = 0.45
@export var charge_duration: float = 0.72
@export var charge_recovery: float = 1.1
@export var spell_warning: float = 0.85
@export var spell_recovery: float = 0.65
@export var activation_grace: float = 1.0
@export_group("Poderes e limites")
@export var summon_limit: int = 14
@export var summon_batch: int = 4
@export var summon_warning: float = 1.0
@export var fire_speed: float = 135.0
@export var fire_damage: float = 15.0
@export var fire_lifetime: float = 5.0
@export var fire_limit: int = 72
@export var fire_spacing: float = 0.34
@export var second_fire_delay: float = 0.4
@export var final_projectile_limit: int = 120
@export var lightning_warning: float = 1.1
@export var lightning_radius: float = 24.0
@export var lightning_damage: float = 23.0
@export var ice_warning: float = 0.85
@export var ice_duration: float = 4.0
@export var ice_radius: float = 36.0
@export var ice_slow_multiplier: float = 0.68
@export var area_limit: int = 8

func executioner_health() -> float:
	return executioner_previous_health * executioner_health_multiplier

func demon_health() -> float:
	return executioner_health() * demon_health_multiplier

func portal_duration() -> float:
	return portal_trace + portal_open + portal_emerge + portal_close
