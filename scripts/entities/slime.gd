class_name SlimeEnemy
extends HordeEnemy
var grace:float=0
func tick(delta:float):
	grace=maxf(0,grace-delta)
	data.contact_damage=grace<=0
	super.tick(delta)
