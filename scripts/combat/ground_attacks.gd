class_name GroundAttacks
extends Node2D
var weapons
var pools:Array[Dictionary]=[]
var hit_times:Dictionary={}
var last_trail:Vector2=Vector2.INF
var trail_clock:float=0
var water_texture=preload("res://assets/v08/holy_water.png")
var vial_texture=preload("res://assets/effects/holy_water_vial.png")
var splash_texture=preload("res://assets/effects/holy_water_splash.png")
var sludge_texture=preload("res://assets/effects/sludge.png")
func setup(system):
	weapons=system;z_index=-6
func reset():
	pools.clear();hit_times.clear();last_trail=Vector2.INF;trail_clock=0;queue_redraw()
func world():
	return weapons.game.world if weapons.game is CoopActor else weapons.game
func add_pool(id:String,at:Vector2,source:Vector2,flight:float=0)->bool:
	if pools.size()>=weapons.weapon_data[id].pool_limit:return false
	pools.append({"kind":id,"at":at,"source":source,"age":0.0,"flight":flight/weapons.projectile_factor(),"duration":weapons._stat(id,"duration"),"radius":weapons._stat(id,"reach"),"damage":weapons._stat(id,"damage"),"interval":weapons.weapon_data[id].tick_interval})
	return true
func tick(delta:float,allow_creation:bool=true):
	trail_clock=maxf(0,trail_clock-delta)
	var position_now:Vector2=weapons.game.player.position
	if last_trail==Vector2.INF:last_trail=position_now
	if allow_creation and int(weapons.levels.get("sludge",0))>0 and trail_clock<=0 and position_now.distance_to(last_trail)>=weapons.weapon_data.sludge.trail_distance:
		var at:Vector2=position_now-weapons.game.player.facing*8
		if world().arena.safe_position(at,weapons._stat("sludge","reach")) and add_pool("sludge",at,at):
			last_trail=position_now;trail_clock=maxf(.15,weapons._interval("sludge"))
	for pool in pools:pool.age+=delta
	pools=pools.filter(func(p):return p.age<p.flight+p.duration)
	var cells:Dictionary={}
	for pool in pools:
		if pool.age<pool.flight:continue
		var low:=Vector2i(floori((pool.at.x-pool.radius)/64),floori((pool.at.y-pool.radius)/64))
		var high:=Vector2i(floori((pool.at.x+pool.radius)/64),floori((pool.at.y+pool.radius)/64))
		for x in range(low.x,high.x+1):
			for y in range(low.y,high.y+1):
				var cell:=Vector2i(x,y)
				if not cells.has(cell):cells[cell]=[]
				cells[cell].append(pool)
	# One decision per owner, weapon and enemy. Overlapping pools cannot stack.
	for enemy in weapons.game.enemies.duplicate():
		if not weapons._valid_target(enemy):continue
		var cell:=Vector2i(floori(enemy.position.x/64),floori(enemy.position.y/64))
		var nearby:Array=cells.get(cell,[])
		if nearby.is_empty():continue
		for id in ["sludge","holy_water"]:
			var key:String=id+":"+str(enemy.serial)
			if weapons.combat_time<float(hit_times.get(key,0)):continue
			var damage:float=0
			var interval:float=.5
			for pool in nearby:
				if pool.kind==id and pool.age>=pool.flight and enemy.position.distance_to(pool.at)<=pool.radius:
					damage=maxf(damage,pool.damage);interval=pool.interval
			if damage>0:
				hit_times[key]=weapons.combat_time+interval
				weapons._hit(enemy,damage,Vector2.ZERO)
	if hit_times.size()>512:
		for key in hit_times.keys():
			if hit_times[key]<weapons.combat_time-1:hit_times.erase(key)
	queue_redraw()
func launch_water()->bool:
	var count:int=int(weapons._stat("holy_water","count"))
	if pools.size()+count>weapons.weapon_data.holy_water.pool_limit:return false
	var center:Vector2=weapons.game.player.position.clamp(Vector2(320,180),Vector2(1480,1020))
	var radius:float=weapons._stat("holy_water","reach")
	var visible:=Rect2(center-Vector2(320,180),Vector2(640,360)).grow(-radius-12)
	var points:Array[Vector2]=[]
	for i in count:
		for attempt in 100:
			var at:=Vector2(weapons.rng.randf_range(visible.position.x,visible.end.x),weapons.rng.randf_range(visible.position.y,visible.end.y))
			if at.distance_to(weapons.game.player.position)>235:continue
			if not world().arena.safe_position(at,radius):continue
			points.append(at);break
	if points.size()!=count:return false
	for at in points:add_pool("holy_water",at,weapons.game.player.position,weapons.weapon_data.holy_water.flight_time)
	return true
func _draw():
	for pool in pools:
		if pool.age<pool.flight:
			var progress:float=clampf(pool.age/pool.flight,0,1)
			var ground:Vector2=pool.source.lerp(pool.at,progress)
			draw_rect(Rect2(ground.round()-Vector2(4,1),Vector2(8,3)),Color(0,0,0,.5))
			var at:Vector2=ground-Vector2(0,12*(1-progress)+sin(progress*PI)*50)
			draw_set_transform(at.round(),progress*TAU)
			draw_texture_rect_region(vial_texture,Rect2(-8,-12,16,24),Rect2(0,0,16,24))
			draw_set_transform(Vector2.ZERO)
			continue
		var remaining:float=pool.flight+pool.duration-pool.age
		var alpha:float=clampf(remaining/.4,0,1)
		var frame:int=int(pool.age*8)%6
		var impact_age:float=pool.age-pool.flight
		if pool.kind=="holy_water":
			frame=4+int(impact_age*8)%8
			if remaining<.4:frame=12+mini(3,int((.4-remaining)*10))
		var texture:Texture2D=water_texture if pool.kind=="holy_water" else sludge_texture
		draw_texture_rect_region(texture,Rect2(pool.at-Vector2.ONE*pool.radius,Vector2.ONE*pool.radius*2),Rect2(frame*64,0,64,64),Color(1,1,1,alpha))
		if pool.kind=="holy_water" and impact_age<.35:
			draw_texture_rect_region(water_texture,Rect2(pool.at-Vector2.ONE*pool.radius,Vector2.ONE*pool.radius*2),Rect2(mini(3,int(impact_age/.35*4))*64,0,64,64),Color(1,1,1,1-impact_age/.35))
