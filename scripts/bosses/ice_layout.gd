class_name IceLayout
extends RefCounted
static func plan(game, length:float, width:float, corridor:float, opening:float)->Array[Rect2]:
 var result:Array[Rect2]=[]
 var players:Array=game.team_players()
 if players.is_empty():return result
 var target=players[randi()%players.size()]
 var vertical:bool=absf(target.facing.x)>absf(target.facing.y)
 for axis_try in 2:
  var along:Vector2=Vector2.DOWN if vertical else Vector2.RIGHT
  var across:Vector2=along.orthogonal()
  for offset in [0,60,-60,120,-120,180,-180]:
   var anchor:Vector2=target.position+across*offset
   var half:float=length*.5
   anchor.x=clampf(anchor.x,half+48 if not vertical else 80,1752-half if not vertical else 1720)
   anchor.y=clampf(anchor.y,half+48 if vertical else 80,1152-half if vertical else 1120)
   var rectangles:Array[Rect2]=[]
   for side in [-1,1]:
    var center:Vector2=anchor+across*side*(corridor+width)*.5
    var gap:float=clampf((target.position-center).dot(along)+side*110,-half+opening,half-opening)
    for span in [Vector2(-half,gap-opening/2),Vector2(gap+opening/2,half)]:
     var size:Vector2=Vector2(width,span.y-span.x) if vertical else Vector2(span.y-span.x,width)
     rectangles.append(Rect2(center+along*(span.x+span.y)*.5-size*.5,size))
   if valid(game,rectangles):return rectangles
  vertical=not vertical
 return result
static func valid(game,rects:Array[Rect2])->bool:
 for rect in rects:
  for player in game.team_players():
   if rect.grow(player.radius+14).has_point(player.position):return false
  var vertical:bool=rect.size.y>rect.size.x
  var count:int=ceili((rect.size.y if vertical else rect.size.x)/20)
  for i in count+1:
   var at:Vector2=rect.position+(Vector2(rect.size.x/2,rect.size.y*i/count) if vertical else Vector2(rect.size.x*i/count,rect.size.y/2))
   if not game.arena.safe_position(at,(rect.size.x if vertical else rect.size.y)/2+2):return false
 var valid_cells:Dictionary=game.navigation.grid(16)
 var players:Array=game.team_players()
 var start:Vector2i=game.navigation.near_cell(players[0].position,valid_cells)
 var visited:Dictionary={start:true};var todo:Array[Vector2i]=[start];var index:int=0
 while index<todo.size():
  var cell:Vector2i=todo[index];index+=1
  for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
   var next:Vector2i=cell+direction
   if visited.has(next) or not valid_cells.has(next):continue
   var at:Vector2=game.navigation.center(next);var blocked:bool=false
   for rect in rects:
    if rect.grow(16).has_point(at):blocked=true;break
   if not blocked:visited[next]=true;todo.append(next)
 if visited.size()<valid_cells.size()*.65:return false
 for player in players:
  if not visited.has(game.navigation.near_cell(player.position,valid_cells)):return false
 return true
