extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.persistence_enabled=false;g.start_run()
 var view:=SubViewport.new();view.size=Vector2i(160,120);view.transparent_bg=true;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
 var sprite:=Sprite2D.new();TinyCharacters.install(sprite,"orc");view.add_child(sprite)
 var remains:=CharacterRemains.new();remains.setup(g);view.add_child(remains);remains.set_process(false);remains.z_index=0
 var d:Dictionary=TinyCharacters.data("orc");var at:=Vector2(900,630);view.canvas_transform=Transform2D(0,Vector2(80,80)-at)
 for flip in [false,true]:
  for age in [.0,.13,.26,.39]:
   sprite.position=at+Vector2(d.offset[0]*(-1 if flip else 1),d.offset[1]);sprite.flip_h=flip;sprite.frame=TinyCharacters.frame("orc","death",age/.5);sprite.show();remains.hide()
   await process_frame;await RenderingServer.frame_post_draw
   var original:=view.get_texture().get_image();sprite.hide();remains.show();remains.effects=[{"kind":"orc","at":at,"flip":flip,"scale":1.0,"age":age}];remains.queue_redraw()
   await process_frame;await RenderingServer.frame_post_draw
   var actual:=view.get_texture().get_image()
   assert(original.get_data()==actual.get_data(),"death render shifted from identical live Sprite2D frame")
 g.clear_run()
 for i in 40:
  var e=g.spawn_enemy("ghoul",Vector2(900+i%8*20,630+int(i/8)*20));e.sprite.flip_h=i%2==0;var spot:Vector2=e.position;e.take_damage(100000)
  assert(g.character_remains.effects.back().at==spot)
 assert(g.character_remains.effects.size()==40)
 print("DEATH21_PASS eight pixel-identical comparisons and 40 consecutive deaths")
 view.queue_free();g.queue_free();await process_frame;await create_timer(.3).timeout;quit()
