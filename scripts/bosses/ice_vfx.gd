class_name IceVFX
extends RefCounted
static func render(canvas:CanvasItem,ice_texture:Texture2D,area:Dictionary,active:bool):
 var bounds:=Rect2(area.at-area.size/2,area.size)
 canvas.draw_rect(bounds,Color(0.3,0.65,0.8,.14 if active else .06))
 canvas.draw_rect(bounds,Color("9bdcec"),false,1)
 var vertical:bool=area.size.y>area.size.x
 var count:int=int((area.size.y if vertical else area.size.x)/24)
 for i in count:
  var base:Vector2=bounds.position+(Vector2(area.size.x/2,12+i*24) if vertical else Vector2(12+i*24,area.size.y/2))
  if not active:
   canvas.draw_line(base-Vector2(6,0),base+Vector2(6,0),Color("a7e2f2"),1)
   continue
  var age:float=area.age-area.warning
  var remaining:float=area.warning+area.duration-area.age
  var frame:int=mini(2,int(age*12)) if age<.25 else 3+int(age*7+i)%4
  if remaining<.3:frame=mini(9,7+int((.3-remaining)*10))
  canvas.draw_texture_rect_region(ice_texture,Rect2(base.round()-Vector2(16,48),Vector2(32,56)),Rect2(frame*32,0,32,56))
