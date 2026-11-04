class_name ChainBudget
extends RefCounted
var live:Dictionary={}
var requested:int=0
var generated:int=0
var waiting:Dictionary={}
func reset():live.clear();waiting.clear();requested=0;generated=0
func register(enemy):
 if enemy.chain_root<=0:return
 if not live.has(enemy.chain_root):live[enemy.chain_root]={}
 live[enemy.chain_root][enemy.serial]=true
func remove(enemy):
 if live.has(enemy.chain_root):live[enemy.chain_root].erase(enemy.serial)
 waiting.erase(enemy.get_instance_id())
func count(root:int)->int:return live.get(root,{}).size()
func request(owner:int,count_value:int):
 if not waiting.has(owner):waiting[owner]=count_value;requested+=count_value
func deferred()->int:
 var count_value:int=0
 for v in waiting.values():count_value+=int(v)
 return count_value
func snapshot()->Dictionary:return {"requested":requested,"generated":generated,"deferred":deferred()}
