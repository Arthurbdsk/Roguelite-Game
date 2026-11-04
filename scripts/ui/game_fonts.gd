class_name GameFonts
extends RefCounted
const KINGDOM_PATH:String="res://assets/fonts/Kingdom.ttf"
const SUPPORT_PATH:String="res://assets/font.ttf"
static var cached:Font
static func kingdom_available()->bool:return ResourceLoader.exists(KINGDOM_PATH)
static func interface_font()->Font:
 if cached!=null:return cached
 var support:Font=load(SUPPORT_PATH)
 if kingdom_available():
  var primary:FontFile=load(KINGDOM_PATH)
  primary.fallbacks=[support]
  primary.antialiasing=TextServer.FONT_ANTIALIASING_NONE
  cached=primary
 else:cached=support
 return cached
