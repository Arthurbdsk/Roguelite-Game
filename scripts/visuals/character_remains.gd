class_name CharacterRemains
extends Node2D
const LIMIT:int=64
var game
var effects:Array=[]
var seen:Dictionary={}
var cosmetic_discards:int=0
func setup(owner):game=owner;z_index=-1
func reset():effects.clear();seen.clear();cosmetic_discards=0;queue_redraw()
func died(enemy):
 if enemy is HordeBoss:return # BossArena owns the complete boss death presentation.
 if enemy.tiny_kind.is_empty():return
 var event:Dictionary={"type":"tiny_death","id":enemy.serial,"kind":enemy.tiny_kind,"at":enemy.position,"flip":enemy.sprite.flip_h,"scale":enemy.sprite.scale.x,"clock":game.elapsed}
 receive(event)
 if game.coop.active and game.coop.hosting:game.coop.publish(event)
func receive(event:Dictionary):
 var id:int=int(event.id)
 if seen.has(id) or not TinyCharacters.available(event.kind):return
 var age:float=maxf(0,game.elapsed-float(event.clock))
 if age>.5 or float(event.clock)>game.elapsed+1:return
 seen[id]=game.elapsed
 if effects.size()>=LIMIT:effects.pop_front();cosmetic_discards+=1
 effects.append({"id":id,"kind":event.kind,"at":event.at if event.at is Vector2 else CoopWire.vector(event.at),"flip":event.flip,"scale":event.scale,"age":age})
 if seen.size()>1024:
  for key in seen.keys():
   if game.elapsed-float(seen[key])>2:seen.erase(key)
 queue_redraw()
func _process(delta:float):
 if game==null:return
 if game.state not in ["running","paused","upgrading"]:
  if not effects.is_empty():effects.clear();queue_redraw()
  return
 if game.state!="running" or effects.is_empty():return
 for fx in effects:fx.age+=delta
 effects=effects.filter(func(fx):return fx.age<.5)
 queue_redraw()
func _draw():
 if game==null:return
 var visible:Rect2=game.render_rect().grow(80)
 for fx in effects:
  if not visible.has_point(fx.at):continue
  var d:Dictionary=TinyCharacters.data(fx.kind)
  var size_px:=Vector2(float(d.cell[0]),float(d.cell[1]))
  var offset:=Vector2(float(d.offset[0]),float(d.offset[1]))
  var dest:=Rect2(offset-size_px*.5,size_px)
  # Flip the local coordinate system around the same physical pivot as Sprite2D.
  # A negative destination width flips UVs, but does not relocate its origin.
  draw_set_transform(fx.at,0,Vector2(-1 if fx.flip else 1,1)*float(fx.scale)*PlatformTuning.enemy_visual_multiplier(fx.kind))
  var frame:int=TinyCharacters.frame(fx.kind,"death",float(fx.age)/.5)
  var alpha:float=minf(1,(.5-float(fx.age))/.08)
  draw_texture_rect_region(TinyCharacters.texture(fx.kind),dest,Rect2(frame*float(d.cell[0]),0,float(d.cell[0]),float(d.cell[1])),Color(1,1,1,alpha))
  draw_set_transform(Vector2.ZERO)
