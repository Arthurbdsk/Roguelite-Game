class_name CombatSweep
extends RefCounted
static var ray:=PhysicsRayQueryParameters2D.new()

# First contact in the common physics step, including target displacement.
static func circle(start:Vector2,end:Vector2,from:Vector2,to:Vector2,radius:float)->float:
 var relative:Vector2=start-from;var travel:Vector2=(end-start)-(to-from)
 var c:float=relative.length_squared()-radius*radius
 if c<=0:return 0.0
 var a:float=travel.length_squared()
 if a<.000001:return INF
 var b:float=2*relative.dot(travel);var discriminant:float=b*b-4*a*c
 if discriminant<0:return INF
 var t:float=(-b-sqrt(discriminant))/(2*a)
 return t if t>=0 and t<=1 else INF

static func wall(arena,start:Vector2,end:Vector2,radius:float)->Dictionary:
 var best:Dictionary={};var travel:Vector2=end-start
 for raw in arena.obstacle_candidates(start,end,radius):
  var rect:Rect2=raw.grow(radius);var enter:float=0;var leave:float=1;var normal:=Vector2.ZERO;var valid:bool=true
  for axis in 2:
   if absf(travel[axis])<.000001:
    if start[axis]<rect.position[axis] or start[axis]>rect.end[axis]:valid=false;break
   else:
    var near:float=(rect.position[axis]-start[axis])/travel[axis];var far:float=(rect.end[axis]-start[axis])/travel[axis]
    var sign_normal:float=-1
    if near>far:var swap:float=near;near=far;far=swap;sign_normal=1
    if near>=enter:enter=near;normal=Vector2.ZERO;normal[axis]=sign_normal
    leave=minf(leave,far)
    if enter>leave:valid=false;break
  if valid and enter>=0 and enter<=1 and (best.is_empty() or enter<best.fraction):
   if normal==Vector2.ZERO:normal=-travel.normalized()
   best={"fraction":enter,"normal":normal,"position":start.lerp(end,enter)}
 # Also respect physics-only walls created by encounters or tools.
 if arena.is_inside_tree():
  ray.from=start;ray.to=end;ray.collision_mask=4;ray.hit_from_inside=true
  var hit:Dictionary=arena.get_world_2d().direct_space_state.intersect_ray(ray)
  if not hit.is_empty():
   var fraction:float=start.distance_to(hit.position)/maxf(.000001,start.distance_to(end))
   if best.is_empty() or fraction<best.fraction:best={"fraction":fraction,"normal":hit.normal,"position":hit.position}
 return best
