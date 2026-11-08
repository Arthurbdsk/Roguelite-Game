class_name MobileKeyboard
extends CanvasLayer
var game
var field:LineEdit
var preview:Label
var keys:VBoxContainer
var lower:bool=false
var accents:bool=false
var code_mode:bool=false
func setup(owner,target:LineEdit,title:String):
 game=owner;field=target;code_mode=target.max_length==6;layer=60
 if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):DisplayServer.virtual_keyboard_hide()
 field.release_focus()
 var panel:=PanelContainer.new();panel.position=game.mobile.safe.position;panel.size=game.mobile.safe.size;panel.mouse_filter=Control.MOUSE_FILTER_STOP;panel.theme=game.ui.ui_theme;panel.add_theme_stylebox_override("panel",game.ui._style(Color("142238"),game.ui.LINE));add_child(panel)
 var column:=VBoxContainer.new();column.add_theme_constant_override("separation",6);panel.add_child(column)
 var head:=HBoxContainer.new();column.add_child(head)
 var label:=Label.new();label.text=title;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.add_theme_font_size_override("font_size",19);head.add_child(label)
 key(head,"Apagar",erase).custom_minimum_size.x=100
 preview=Label.new();preview.custom_minimum_size.y=36;preview.add_theme_font_size_override("font_size",18);column.add_child(preview)
 var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(scroll)
 keys=VBoxContainer.new();keys.size_flags_horizontal=Control.SIZE_EXPAND_FILL;keys.add_theme_constant_override("separation",4);scroll.add_child(keys)
 var footer:=HBoxContainer.new();footer.add_theme_constant_override("separation",6);column.add_child(footer)
 if not code_mode:
  key(footer,"abc / ABC",func():lower=not lower;make_keys())
  key(footer,"Acentos",func():accents=not accents;make_keys())
  key(footer,"Espaço",func():append(" "))
 key(footer,"Concluir",close)
 update_preview();make_keys()
func key(parent,title:String,action:Callable)->Button:
 var b:=Button.new();b.text=title;b.custom_minimum_size=Vector2(44,44);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.add_theme_font_size_override("font_size",15);b.pressed.connect(action);parent.add_child(b);return b
func make_keys():
 for old in keys.get_children():keys.remove_child(old);old.queue_free()
 var rows:Array=["1234567890","QWERTYUIOP","ASDFGHJKL","ZXCVBNM"] if not accents else ["ÁÀÂÃÉÊÍÓÔÕ","ÚÜÇ","QWERTYUIOP","ASDFGHJKL"]
 for value in rows:
  var row:=HBoxContainer.new();row.add_theme_constant_override("separation",4);keys.add_child(row)
  for letter in value:
   var character:String=letter.to_lower() if lower and not code_mode else letter
   key(row,character,func():append(character))
 MobileScrolling.prepare(keys.get_parent())
func append(character:String):
 if not is_instance_valid(field):close();return
 field.text=(field.text+character).left(field.max_length);field.caret_column=field.text.length();field.text_changed.emit(field.text);update_preview()
func erase():
 if not is_instance_valid(field):close();return
 field.text=field.text.left(maxi(0,field.text.length()-1));field.caret_column=field.text.length();field.text_changed.emit(field.text);update_preview()
func update_preview():preview.text=(field.text if not field.text.is_empty() else "Digite usando as teclas abaixo")+"   %d/%d"%[field.text.length(),field.max_length]
func _process(_delta):
 if not is_instance_valid(field):close()
func close():
 if is_instance_valid(field):field.release_focus()
 if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):DisplayServer.virtual_keyboard_hide()
 queue_free()
