class_name MobilePerformance
extends Node
const CAPACITY:int=6000
var game
var samples:=PackedFloat32Array()
var index:int=0
var count:int=0
var clock:float=0
var measured_seconds:float=0
var previous_usec:int=0
func setup(owner):game=owner;samples.resize(CAPACITY)
func reset():index=0;count=0;clock=0;measured_seconds=0;previous_usec=0
func _process(delta:float):
 if game==null or game.state!="running" or game.mobile_backgrounded:previous_usec=0;return
 var now:int=Time.get_ticks_usec()
 if previous_usec==0:previous_usec=now;return
 var elapsed:float=(now-previous_usec)/1000000.0;previous_usec=now
 samples[index]=elapsed*1000;index=(index+1)%CAPACITY;count=mini(count+1,CAPACITY);clock+=elapsed;measured_seconds+=elapsed
 if clock>=15:
  clock=0;print("MOBILE_METRICS "+JSON.stringify(report()))
func report()->Dictionary:
 var sorted:=samples.slice(0,count);sorted.sort();var total:float=0
 for t in sorted:total+=t
 return {"samples":count,"seconds":measured_seconds,"fps":1000.0*count/total if total>0 else 0,"median_ms":sorted[int(count*.5)] if count>0 else 0,"p95_ms":sorted[mini(count-1,int(count*.95))] if count>0 else 0,"p99_ms":sorted[mini(count-1,int(count*.99))] if count>0 else 0,"memory_bytes":OS.get_static_memory_usage(),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"enemies":game.enemies.size(),"players":game.coop.actors.size() if game.coop.active else 1}
