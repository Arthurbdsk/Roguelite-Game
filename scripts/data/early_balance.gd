class_name EarlyBalance
extends RefCounted
const HEALTH={"ghoul":36.0,"hound":32.0,"skeleton_sword":36.0,"skeleton_archer":32.0,"guard":44.0,"orc_armored":50.0,"skeleton_armored":50.0,"slime_small":24.0,"slime_large":48.0}
static func applies(id:String)->bool:return HEALTH.has(id)
static func time_health(stage:int)->float:return minf(stage,2)*1.5+maxi(0,stage-2)*8.0
