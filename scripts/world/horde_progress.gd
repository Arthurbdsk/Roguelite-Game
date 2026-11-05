class_name HordeProgress
extends RefCounted
var game
var completed:int=0
var cleared:Dictionary={}
func reset():completed=0;cleared.clear()
func stage()->int:return floori(completed/2.0)
func resistance()->float:return clampf(stage()*game.balance.horde_resistance_step,0,minf(.95,game.balance.horde_resistance_cap))
func apply(enemy):
 if not enemy.alive or enemy.data.behavior=="hazard_target":return
 var bonus:float=stage()*game.balance.horde_health_step
 var difference:float=bonus-enemy.horde_health_bonus
 enemy.horde_health_bonus=bonus;enemy.max_hp+=difference;enemy.hp=minf(enemy.max_hp,enemy.hp+difference)
func complete(wave:int):
 if cleared.has(wave):return
 var previous:int=stage();cleared[wave]=true;completed+=1
 if previous!=stage():
  for enemy in game.enemies:apply(enemy)
