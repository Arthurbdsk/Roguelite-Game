class_name TrueHealthBar
extends Control
var fill:ProgressBar
var ornament:TextureRect
func _ready():
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 position=Vector2(110,306);size=Vector2(430,36)
 var frame:=Panel.new();frame.name="OrnamentalFrame";frame.position=Vector2(46,5);frame.size=Vector2(376,20)
 var style:=StyleBoxFlat.new();style.bg_color=Color("180b10");style.border_color=Color("5d2938");style.set_border_width_all(3);style.shadow_color=Color("09090d");style.shadow_size=1
 frame.add_theme_stylebox_override("panel",style);add_child(frame)
 fill=ProgressBar.new();fill.name="TrueHealthFill";fill.show_percentage=false;fill.position=Vector2(52,10);fill.size=Vector2(364,10)
 var track:=StyleBoxFlat.new();track.bg_color=Color("15090b");fill.add_theme_stylebox_override("background",track)
 var red:=StyleBoxFlat.new();red.bg_color=Color("d51e3c");red.border_color=Color("ff5362");red.border_width_top=2;fill.add_theme_stylebox_override("fill",red);add_child(fill)
 ornament=TextureRect.new();ornament.name="SkullFinial";ornament.position=Vector2(4,-12);ornament.size=Vector2(48,48);ornament.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;ornament.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;ornament.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 if ResourceLoader.exists("res://assets/v10/bar_ornament.png"):ornament.texture=load("res://assets/v10/bar_ornament.png")
 add_child(ornament)
 var title:=Label.new();title.text="TRUE FORM";title.position=Vector2(56,-15);title.size=Vector2(360,19);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.add_theme_font_override("font",GameFonts.interface_font());title.add_theme_font_size_override("font_size",12);title.add_theme_color_override("font_color",Color("f4d6c0"));add_child(title)
func update_health(hp:float,total:float):fill.max_value=maxf(1,total);fill.value=hp
func _draw():
 for x in [45,420]:
  draw_rect(Rect2(x,1,4,4),Color("2f1922"));draw_rect(Rect2(x-2,23,6,3),Color("2f1922"))
  draw_rect(Rect2(x,4,2,18),Color("b64b57"))
