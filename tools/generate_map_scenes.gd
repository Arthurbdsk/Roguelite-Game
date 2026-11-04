extends SceneTree
func _initialize():call_deferred("run")
func run():
 var atlas=TileSetAtlasSource.new();atlas.texture=load("res://assets/map_tiles7.png");atlas.texture_region_size=Vector2i(32,32)
 for i in 16:atlas.create_tile(Vector2i(i,0))
 var tiles=TileSet.new();tiles.tile_size=Vector2i(32,32);tiles.add_source(atlas,0)
 DirAccess.make_dir_recursive_absolute("res://scenes/maps")
 for index in 3:
  var layer=TileMapLayer.new();layer.tile_set=tiles;layer.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
  var rng=RandomNumberGenerator.new();rng.seed=81391
  for x in 57:
   for y in 38:
    var group:int=3 if index==2 and (abs(y*32-630)<52 or abs(x*32-900)<40) else index
    layer.set_cell(Vector2i(x,y),0,Vector2i(group*4+rng.randi_range(0,3),0))
  var scene=PackedScene.new();scene.pack(layer);ResourceSaver.save(scene,"res://scenes/maps/"+["courtyard","library","fields"][index]+"_floor.tscn");layer.free()
 print("EDITABLE_TILE_SCENES_CREATED");quit()
