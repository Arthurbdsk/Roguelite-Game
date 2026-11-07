class_name GameFonts
extends RefCounted
const PRIMARY_PATH:String="res://assets/fonts/AurusenthialGothic.ttf"
const SUPPORT_PATH:String="res://assets/font.ttf"
static var cached:Font
static var clock_cached:Font
static func primary_available()->bool:return ResourceLoader.exists(PRIMARY_PATH)
static func interface_font()->Font:
 if cached!=null:return cached
 var support:Font=load(SUPPORT_PATH)
 var symbols:=SystemFont.new()
 symbols.font_names=PackedStringArray(["Segoe UI Symbol","DejaVu Sans","Arial"])
 support.fallbacks=[symbols]
 cached=support
 return cached

# The decorative face is deliberately isolated from themes and world text.
static func timer_font()->Font:
 if clock_cached!=null:return clock_cached
 if primary_available():
  var primary:FontFile=load(PRIMARY_PATH)
  primary.fallbacks=[interface_font()]
  primary.antialiasing=TextServer.FONT_ANTIALIASING_NONE
  var readable:=FontVariation.new()
  readable.base_font=primary
  readable.variation_transform=Transform2D.IDENTITY.scaled(Vector2(1.3,1.7))
  readable.spacing_glyph=2
  readable.baseline_offset=.2
  clock_cached=readable
 else:clock_cached=interface_font()
 return clock_cached
