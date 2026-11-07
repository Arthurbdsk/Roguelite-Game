class_name UIAssets18
extends RefCounted
static var button_texture:Texture2D
static var panel_texture:Texture2D
static func button(state:String="normal")->StyleBoxTexture:
 if button_texture==null:button_texture=load("res://assets/v18/button_wood.png")
 var style:=StyleBoxTexture.new();style.texture=button_texture
 for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:style.set_texture_margin(side,4);style.set_content_margin(side,4)
 style.modulate_color=Color(1.15,1.15,1.1) if state=="hover" else Color(.7,.7,.7) if state=="pressed" else Color(.5,.5,.5) if state=="disabled" else Color.WHITE
 return style
static func panel()->StyleBoxTexture:
 if panel_texture==null:panel_texture=load("res://assets/v18/panel_medieval.png")
 var style:=StyleBoxTexture.new();style.texture=panel_texture
 for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:style.set_texture_margin(side,10);style.set_content_margin(side,10)
 return style
