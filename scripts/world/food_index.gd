class_name FoodIndex
extends RefCounted
var game
var grid:Dictionary={}
var cooldown:float=0
func reset():
	grid.clear();cooldown=0
func tick(delta:float):
	cooldown-=delta
	if cooldown>0:return
	cooldown=game.balance.food_search_interval
	grid.clear()
	for kind in ["gold","xp"]:
		for item in (game.gold_loot.coins if kind=="gold" else game.pickups):
			if item.get("attracted",false) or item.get("protected",false) or item.get("consumed",false):continue
			if kind=="gold" and item.age>=game.balance.coin_lifetime:continue
			var cell:=Vector2i(floori(item.at.x/96),floori(item.at.y/96))
			if not grid.has(cell):grid[cell]=[]
			grid[cell].append({"kind":kind,"item":item})
func nearest(at:Vector2)->Dictionary:
	var cell:=Vector2i(floori(at.x/96),floori(at.y/96))
	var steps:int=ceili(game.balance.food_search_radius/96)
	var distance:float=game.balance.food_search_radius**2
	var best:Dictionary={}
	for x in range(-steps,steps+1):
		for y in range(-steps,steps+1):
			for candidate in grid.get(cell+Vector2i(x,y),[]):
				var item:Dictionary=candidate.item
				if item.get("consumed",false) or item.get("attracted",false) or item.get("protected",false):continue
				var d:float=at.distance_squared_to(item.at)
				if d<distance:distance=d;best=candidate
	return best
func consume(candidate:Dictionary)->bool:
	if candidate.is_empty():return false
	var item:Dictionary=candidate.item
	if item.get("consumed",false) or item.get("attracted",false) or item.get("protected",false):return false
	var source:Array=game.gold_loot.coins if candidate.kind=="gold" else game.pickups
	var index:int=source.find(item)
	if index<0:return false
	if candidate.kind=="gold" and item.age>=game.balance.coin_lifetime:return false
	item.consumed=true
	source.remove_at(index)
	return true
