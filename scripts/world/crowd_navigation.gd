class_name CrowdNavigation
extends RefCounted
const CELL:float=24
const SIZE:=Vector2i(75,50)
var game
var grids:Dictionary={}
var fields:Dictionary={}
var agents:Dictionary={}
var clock:float=0
var plans_left:int=48
var deferred:int=0
var queries:int=0
var field_builds:int=0
func reset():
 grids.clear();fields.clear();agents.clear();clock=0
func tick(delta:float):
 clock+=delta;plans_left=48
 if agents.size()>600:
  for key in agents.keys():
   if agents[key].until<clock-2:agents.erase(key)
func key(at:Vector2)->Vector2i:return Vector2i(floori(at.x/CELL),floori(at.y/CELL))
func center(cell:Vector2i)->Vector2:return Vector2(cell)*CELL+Vector2.ONE*CELL/2
func bucket(radius:float)->int:
 for size in [8,16,24,32,48]:
  if radius<=size:return size
 return 48
func grid(radius:int)->Dictionary:
 if grids.has(radius):return grids[radius]
 var valid:Dictionary={}
 for x in SIZE.x:
  for y in SIZE.y:
   var cell:=Vector2i(x,y)
   if game.arena.safe_position(center(cell),radius+2):valid[cell]=true
 grids[radius]=valid
 return valid
func near_cell(at:Vector2,valid:Dictionary)->Vector2i:
 var cell:=key(at)
 if valid.has(cell):return cell
 var best:=Vector2i(-1,-1);var d:float=INF
 for x in range(-3,4):
  for y in range(-3,4):
   var c:=cell+Vector2i(x,y)
   if valid.has(c) and at.distance_squared_to(center(c))<d:best=c;d=at.distance_squared_to(center(c))
 return best
func clear_segment(a:Vector2,b:Vector2,radius:float)->bool:
 for obstacle in game.arena.obstacle_candidates(a,b,radius+1):
  var rect:Rect2=obstacle.grow(radius+1)
  var tmin:float=0;var tmax:float=1
  for axis in 2:
   var delta:float=b[axis]-a[axis]
   if absf(delta)<.0001:
    if a[axis]<rect.position[axis] or a[axis]>rect.end[axis]:tmax=-1;break
   else:
    var first:float=(rect.position[axis]-a[axis])/delta
    var last:float=(rect.end[axis]-a[axis])/delta
    tmin=maxf(tmin,minf(first,last));tmax=minf(tmax,maxf(first,last))
  if tmax>=tmin:return false
 return true
func distances(radius:int,goal:Vector2)->Dictionary:
 var valid:=grid(radius)
 var goals:Array[Vector2i]=[]
 if goal==Vector2.INF:
  for player in game.team_players():goals.append(near_cell(player.position,valid))
 else:goals.append(near_cell(goal,valid))
 var signature:String=str(radius)+str(goals)
 if fields.has(signature) and fields[signature].until>clock:return fields[signature].values
 field_builds+=1
 var values:Dictionary={};var queue:Array[Vector2i]=[]
 for c in goals:
  if valid.has(c):values[c]=0;queue.append(c)
 var index:int=0
 while index<queue.size():
  var c:Vector2i=queue[index];index+=1
  for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
   var next:Vector2i=c+offset
   if valid.has(next) and not values.has(next):values[next]=values[c]+1;queue.append(next)
 if fields.size()>24:fields.clear()
 fields[signature]={"until":clock+.4,"values":values}
 return values
func reachable(at:Vector2,radius:float)->bool:
 var r:int=bucket(radius);var valid:=grid(r);var c:=near_cell(at,valid)
 return valid.has(c) and distances(r,Vector2(900,630)).has(c) and clear_segment(at,center(c),radius)
func steer(enemy,desired:Vector2,goal:Vector2=Vector2.INF)->Vector2:
 if not game.perf_enabled:return plan(enemy,desired,goal)
 var t:int=Time.get_ticks_usec();var result:Vector2=plan(enemy,desired,goal)
 game.perf_us["navigation_planning"]=int(game.perf_us.get("navigation_planning",0))+Time.get_ticks_usec()-t
 return result
func plan(enemy,desired:Vector2,goal:Vector2=Vector2.INF)->Vector2:
 if desired.length_squared()<.01:return desired
 var speed:float=desired.length()
 if agents.has(enemy.serial) and agents[enemy.serial].until>clock:
  return Vector2(agents[enemy.serial].direction)*speed
 if plans_left<=0:
  deferred+=1
  return Vector2(agents[enemy.serial].direction)*speed if agents.has(enemy.serial) else desired
 plans_left-=1;queries+=1
 var target:Vector2=game.player.position if goal==Vector2.INF else goal
 var direction:Vector2=desired.normalized()
 if desired.dot(target-enemy.position)<0:
  target=enemy.position+direction*70
  if not clear_segment(enemy.position,target,enemy.radius):
   var left:Vector2=direction.rotated(PI/2)
   direction=left if clear_segment(enemy.position,enemy.position+left*50,enemy.radius) else -left
 elif not clear_segment(enemy.position,target,enemy.radius):
  var r:int=bucket(enemy.radius);var valid:=grid(r);var cell:=near_cell(enemy.position,valid)
  var distance:=distances(r,goal)
  var current:Vector2i=cell
  for step in 5:
   var best:Vector2i=current;var cost:int=int(distance.get(current,999999))
   for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
    var next:Vector2i=current+offset
    if int(distance.get(next,999999))<cost:best=next;cost=distance[next]
   if best==current:break
   if not clear_segment(enemy.position,center(best),enemy.radius):break
   current=best
  direction=(center(current)-enemy.position).normalized()
 agents[enemy.serial]={"direction":direction,"until":clock+.12+float(enemy.serial%5)*.013}
 return direction*speed
