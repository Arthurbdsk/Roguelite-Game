extends RefCounted
func measure(actor,path:String)->Dictionary:
 var sprite:Sprite2D=actor.sprite;var image:Image=sprite.texture.get_image()
 if image.is_compressed():image.decompress()
 image.convert(Image.FORMAT_RGBA8)
 var pixels:PackedByteArray=image.get_data()
 for i in range(0,pixels.size(),4):
  if pixels[i+3]==0:pixels[i]=0;pixels[i+1]=0;pixels[i+2]=0
 var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(pixels)
 var cell:=Vector2i(image.get_width()/sprite.hframes,image.get_height()/sprite.vframes)
 var bounds:Array=[]
 for i in sprite.hframes:
  var rect:Rect2i=image.get_region(Rect2i(Vector2i(i*cell.x,0),cell)).get_used_rect()
  bounds.append([rect.position.x,rect.position.y,rect.size.x,rect.size.y])
 var collision=actor.find_children("*","CollisionShape2D",false,false)[0]
 return {"texture":path,"image":[image.get_width(),image.get_height()],"cell":[cell.x,cell.y],"frames":sprite.hframes,"rgba_sha256":hash.finish().hex_encode(),"bounds":bounds,"scale":[sprite.global_scale.x,sprite.global_scale.y],"offset":[sprite.position.x,sprite.position.y],"collider_radius":collision.shape.radius,"filter":sprite.texture_filter}
func capture(game)->Dictionary:
 game.set_physics_process(false);game.persistence_enabled=false;game.start_run();game.set_physics_process(false)
 game.weapon_system.attacks_enabled=false;game.state="paused";game.ui.menu.hide();game.ui.hud.hide()
 if game.get("mobile")!=null:game.mobile.surface.hide()
 var result:Dictionary={"version":ProjectSettings.get_setting("application/config/version"),"identity":GameCompatibility.identity(),"characters":{}}
 result.characters.hero=measure(game.player,TinyCharacters.data("soldier").texture)
 for id in EnemyCatalog.ids(game):
  game.state="running";var e=game.spawn_enemy(id,Vector2(1100,730))
  result.characters[id]=measure(e,TinyCharacters.data(e.tiny_kind).texture if not e.tiny_kind.is_empty() else e.data.texture)
  game.clear_run()
 game.state="paused"
 return result
func board(game):
 game.state="running"
 var center:=Vector2(1040,700);var names:Array=["hero"]+EnemyCatalog.ids(game)
 for i in names.size():
  var at:Vector2=center+Vector2(-245+(i%6)*94,-105+int(i/6)*76)
  if names[i]=="hero":game.player.position=at
  else:game.spawn_enemy(names[i],at)
  var label:=Label.new();label.text="Herói" if names[i]=="hero" else game.enemy_data[names[i]].title;label.position=at+Vector2(-43,9);label.size=Vector2(86,24);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_override("font",GameFonts.interface_font());label.add_theme_font_size_override("font_size",8);game.add_child(label)
 game.state="paused";game.camera.global_position=center;game.camera.force_update_scroll()
