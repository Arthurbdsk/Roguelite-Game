class_name BuildStrip
extends Control

var last_build:Array=[]
var records:Array=[]
var divider:float=-1
var font:Font
func _init():
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 font=GameFonts.interface_font()
func set_build(groups:Array):
 if groups==last_build:return
 last_build=groups;records.clear();divider=-1
 var x:float=0
 for group_index in groups.size():
  if group_index==1 and not groups[group_index].is_empty():divider=x;x+=7
  for item in groups[group_index]:
   records.append({"x":x,"level":int(item.level),"icon":load(item.icon)})
   x+=21
 queue_redraw()
func _draw():
 # Group the backgrounds, atlas sprites and font commands separately.
 # Godot retains these commands until a build change requests a redraw.
 for item in records:
  var rect:=Rect2(item.x-1,-1,18,28)
  draw_rect(rect,GameUI.INK)
  draw_rect(rect,GameUI.LINE if item.level==8 else Color("48576b"),false,1)
 if divider>=0:draw_rect(Rect2(divider+1,2,1,23),GameUI.MUTED)
 for item in records:draw_texture_rect(item.icon,Rect2(item.x,0,16,16),false)
 for item in records:
  var text:=str(item.level)
  var width:float=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,8).x
  draw_string(font,Vector2(item.x+(16-width)*.5,25),text,HORIZONTAL_ALIGNMENT_LEFT,-1,8,GameUI.LINE if item.level==8 else GameUI.IVORY)
