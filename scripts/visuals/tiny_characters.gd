class_name TinyCharacters
extends RefCounted
static var definitions:Dictionary={}
static var textures:Dictionary={}
static func data(kind:String)->Dictionary:
 if definitions.is_empty():
  definitions=JSON.parse_string(FileAccess.get_file_as_string("res://data/tiny_characters.json"))
  if FileAccess.file_exists("res://data/original_characters22.json"):
   definitions.merge(JSON.parse_string(FileAccess.get_file_as_string("res://data/original_characters22.json")))
 return definitions.get(kind,{})
static func available(kind:String)->bool:
 var d:=data(kind)
 return not d.is_empty() and ResourceLoader.exists(d.texture)
static func texture(kind:String)->Texture2D:
 if not textures.has(kind):textures[kind]=load(data(kind).texture)
 return textures[kind]
static func install(sprite:Sprite2D,kind:String)->bool:
 if not available(kind):return false
 var d:=data(kind)
 sprite.texture=texture(kind);sprite.hframes=int(d.frames);sprite.vframes=1
 sprite.position=Vector2(float(d.offset[0]),float(d.offset[1]));sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 return true
static func frame(kind:String,clip:String,progress:float,loop:bool=false)->int:
 var d:Dictionary=data(kind).clips[clip]
 return int(d.start)+(int(progress*float(d.count))%int(d.count) if loop else clampi(int(progress*float(d.count)),0,int(d.count)-1))
static func contains(kind:String,clip:String,value:int)->bool:
 var d:Dictionary=data(kind).clips[clip]
 return value>=int(d.start) and value<int(d.start)+int(d.count)
