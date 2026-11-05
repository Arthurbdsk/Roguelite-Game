extends Node2D
var texture:Texture2D
var cover:Rect2
func _draw():
 if texture:draw_texture(texture,Vector2(-texture.get_width()*.5,-texture.get_height()+4))
