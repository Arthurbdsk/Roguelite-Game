extends SceneTree
func _initialize():
 var atlas=TileSetAtlasSource.new();atlas.texture=load("res://assets/v12/grass.png");atlas.texture_region_size=Vector2i(32,32)
 for i in 8:atlas.create_tile(Vector2i(i,0))
 var tiles=TileSet.new();tiles.tile_size=Vector2i(32,32);tiles.add_source(atlas,0)
 var layer=TileMapLayer.new();layer.tile_set=tiles;layer.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 var rng=RandomNumberGenerator.new();rng.seed=81391
 for x in 57:
  for y in 38:
   var path:bool=abs(y*32-630)<40 or abs(x*32-900)<36
   layer.set_cell(Vector2i(x,y),0,Vector2i(rng.randi_range(6,7) if path else rng.randi_range(0,5),0))
 var scene=PackedScene.new();scene.pack(layer);ResourceSaver.save(scene,"res://scenes/maps/fields_floor.tscn");layer.free();print("FIELDS12_TILES_CREATED");quit()
