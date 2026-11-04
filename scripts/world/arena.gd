class_name RuinedArena
extends Node2D

var floor_layer:TileMapLayer
var definition:MapDefinition
var map_id:String="courtyard"
var obstacles: Array[Rect2] = []
var decorations: Array[Dictionary] = []
var tiles: Texture2D
var pillar: Texture2D
var grave: Texture2D
var brazier: Texture2D
var rng := RandomNumberGenerator.new()

func _ready() -> void:
 rng.seed = 81391
 tiles = load("res://assets/tiles.png")
 pillar = load("res://assets/pillar.png")
 grave = load("res://assets/grave.png")
 brazier = load("res://assets/brazier.png")
 for point in [Vector2(700, 470), Vector2(1100, 470), Vector2(700, 790), Vector2(1100, 790), Vector2(400, 620), Vector2(1400, 620), Vector2(900, 260), Vector2(900, 1000)]:
  add_obstacle(Rect2(point - Vector2(12, 8), Vector2(24, 16)))
  decorations.append({"at": point, "kind": "pillar"})
 for point in [Vector2(600, 325), Vector2(1200, 325), Vector2(600, 950), Vector2(1200, 950)]:
  decorations.append({"at": point, "kind": "brazier"})
 for i in 45:
  var point := Vector2(rng.randi_range(90, 1710), rng.randi_range(90, 1110))
  if point.distance_to(Vector2(900, 620)) > 140:
   decorations.append({"at": point, "kind": "grave"})
 for rect in [Rect2(0, 0, 1800, 24), Rect2(0, 1176, 1800, 24), Rect2(0, 0, 24, 1200), Rect2(1776, 0, 24, 1200)]:
  add_obstacle(rect)
 queue_redraw()

func add_obstacle(rect: Rect2) -> void:
 obstacles.append(rect)
 var wall := StaticBody2D.new()
 wall.position = rect.get_center()
 wall.collision_layer = 4
 wall.collision_mask = 0
 var shape := CollisionShape2D.new()
 var box := RectangleShape2D.new()
 box.size = rect.size
 shape.shape = box
 wall.add_child(shape)
 add_child(wall)

func safe_position(point: Vector2, radius: float = 12.0) -> bool:
 if not Rect2(40, 45, 1720, 1110).has_point(point):
  return false
 for rect in obstacles:
  if rect.grow(radius).has_point(point):
   return false
 return true

func _draw() -> void:
 draw_palette_floor()
 if map_id!="courtyard":
  draw_extra_modules();return
 rng.seed = 4917
 # Fractured courtyard avenues, kept dimmer than every combat silhouette.
 for x in range(795, 1010, 32):
  for y in range(30, 1170, 32):
   draw_rect(Rect2(x, y, 30, 30), Color(0.28, 0.31, 0.29, 0.14))
 for y in range(548, 710, 32):
  for x in range(32, 1770, 32):
   draw_rect(Rect2(x, y, 30, 30), Color(0.28, 0.31, 0.29, 0.14))
 for r in [96, 100, 112]:
  draw_arc(Vector2(900, 630), r, 0, TAU, 64, Color("465146"), 1, false)
 for i in 8:
  var point := Vector2(900, 630) + Vector2.from_angle(i * TAU / 8) * 105
  draw_rect(Rect2(point - Vector2(2, 2), Vector2(4, 4)), Color("7c7153"))
 decorations.sort_custom(func(a, b): return a.at.y < b.at.y)
 for item in decorations:
  var texture: Texture2D = pillar if item.kind == "pillar" else (brazier if item.kind == "brazier" else grave)
  if texture:
   draw_texture(texture, item.at - Vector2(texture.get_width() * 0.5, texture.get_height() - 5))
 for edge in [Rect2(0, 0, 1800, 25), Rect2(0, 1175, 1800, 25), Rect2(0, 0, 25, 1200), Rect2(1775, 0, 25, 1200)]:
  draw_rect(edge, Color("101719"))

func apply_map(id:String):
 if id not in ["courtyard","library","fields"]:id="courtyard"
 if definition!=null and map_id==id:return
 if get_parent().get("navigation")!=null:get_parent().navigation.reset()
 map_id=id;definition=load("res://data/maps/"+id+".tres")
 if is_instance_valid(floor_layer):remove_child(floor_layer);floor_layer.queue_free()
 floor_layer=load("res://scenes/maps/"+id+"_floor.tscn").instantiate();floor_layer.z_index=-1;add_child(floor_layer)

 for node in get_children():
  if node is StaticBody2D:remove_child(node);node.queue_free()
 obstacles.clear();decorations.clear()
 for rect in definition.blocks:
  add_obstacle(rect)
  if id=="courtyard":decorations.append({"at":rect.get_center(),"kind":"pillar"})
 for rect in [Rect2(0,0,1800,24),Rect2(0,1176,1800,24),Rect2(0,0,24,1200),Rect2(1776,0,24,1200)]:add_obstacle(rect)
 queue_redraw()
func draw_palette_floor():
 rng.seed=81391
 if map_id=="library":
  for rect in definition.blocks:
   draw_rect(Rect2(rect.position-Vector2(0,16),rect.size+Vector2(0,16)),Color("483a31"))
   for i in int(rect.size.x/7):
    var colors=[Color("a89668"),Color("6a3540"),Color("536c68"),Color("b28b47")]
    draw_rect(Rect2(rect.position+Vector2(i*7+2,-14),Vector2(5,26)),colors[rng.randi_range(0,3)])
   draw_rect(Rect2(rect.position+Vector2(0,12),Vector2(rect.size.x,5)),Color("a0804c"))
 elif map_id=="fields":
  for rect in definition.blocks:
   draw_colored_polygon(PackedVector2Array([rect.position+Vector2(0,8),rect.position+Vector2(12,-5),rect.position+Vector2(30,2),rect.end,rect.position+Vector2(2,24)]),Color("96978a"))

func draw_extra_modules():
 if map_id=="library":
  for x in [220,470,1330,1580]:
   for y in [360,690,940]:
    draw_rect(Rect2(x,y,36,20),Color("4d3b2b"))
    draw_rect(Rect2(x+3,y+3,30,12),Color("aa8860"))
    draw_rect(Rect2(x+8,y+5,10,7),Color("ddd0a6"))
    draw_rect(Rect2(x+27,y-5,2,12),Color("bda050"));draw_rect(Rect2(x+26,y-8,4,4),Color("f6d78c"))
 elif map_id=="fields":
  for x in [100,1660]:
   for y in [180,470,810,1080]:
    draw_rect(Rect2(x+12,y,8,22),Color("6b5137"))
    for i in 3:draw_colored_polygon(PackedVector2Array([Vector2(x-4+i*2,y+4-i*12),Vector2(x+16,y-24-i*12),Vector2(x+36-i*2,y+4-i*12)]),Color("415b3d"))
  for i in 70:
   var at:=Vector2(70+(i*137)%1640,70+(i*239)%1060)
   draw_rect(Rect2(at,Vector2(2,2)),Color("c6b888") if i%3 else Color("9da87c"))
