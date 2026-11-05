class_name HordeProgress
extends RefCounted
var game
var completed:int=0
var applied_stage:int=0
func reset():completed=0;applied_stage=0
func stage()->int:return maxi(0,floori(game.elapsed/game.balance.difficulty_seconds))
func resistance()->float:return clampf(stage()*game.balance.horde_resistance_step,0,minf(.95,game.balance.horde_resistance_cap))
func apply(enemy):
 if not enemy.alive or enemy.data.behavior=="hazard_target":return
 var bonus:float=stage()*game.balance.horde_health_step*enemy.difficulty_health_factor
 var difference:float=bonus-enemy.horde_health_bonus
 enemy.horde_health_bonus=bonus;enemy.max_hp+=difference;enemy.hp=clampf(enemy.hp+difference,.001,enemy.max_hp)
func tick():
 completed=stage()*2
 if applied_stage==stage():return
 applied_stage=stage()
 for enemy in game.enemies:apply(enemy)
func complete(_wave:int):pass
