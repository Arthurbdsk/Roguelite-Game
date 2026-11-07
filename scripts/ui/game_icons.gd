class_name GameIcons
extends RefCounted

# One catalog is shared by offers, HUD, collection, chests and DEV builds.
# The original paths remain fallbacks for source checkouts without the pack.
static var catalog:Dictionary={}
static var textures:Dictionary={}
static func entries()->Dictionary:
 if catalog.is_empty():catalog=JSON.parse_string(FileAccess.get_file_as_string("res://data/icon_catalog.json"))
 return catalog
static func path(key:String,fallback:String="")->String:
 var row:Dictionary=entries().get(key,{})
 var selected:String=row.get("asset",fallback)
 return selected if ResourceLoader.exists(selected) else fallback
static func texture(key:String,fallback:String="")->Texture2D:
 var selected:=path(key,fallback)
 if selected.is_empty():return null
 if not textures.has(selected):textures[selected]=load(selected)
 return textures[selected]
