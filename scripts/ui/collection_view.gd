class_name CollectionView
extends Control
var game
var ui
var entries:Array=[]
var buttons:Array=[]
var grid:GridContainer
var counter:Label
var detail:RichTextLabel
var detail_icon:TextureRect
var current:int=0
func setup(owner,interface):
 game=owner;ui=interface;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var panel:=Panel.new();panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.add_theme_stylebox_override("panel",ui._style(GameUI.PANEL,GameUI.LINE));add_child(panel)
 var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","top","right","bottom"]:margin.add_theme_constant_override("margin_"+side,12)
 add_child(margin)
 var column:=VBoxContainer.new();column.add_theme_constant_override("separation",8);margin.add_child(column)
 var header:=HBoxContainer.new();column.add_child(header)
 counter=Label.new();counter.name="DiscoveryCount";counter.size_flags_horizontal=Control.SIZE_EXPAND_FILL;counter.add_theme_font_size_override("font_size",17);header.add_child(counter)
 var back:=Button.new();back.text="Voltar";back.pressed.connect(func():ui.render("title"));header.add_child(back)
 var scroll:=ScrollContainer.new();scroll.name="CollectionScroll";scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(scroll)
 grid=GridContainer.new();grid.name="CollectionGrid";grid.columns=8;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_theme_constant_override("h_separation",6);grid.add_theme_constant_override("v_separation",6);scroll.add_child(grid)
 for id in game.weapon_system.weapon_data:
  var d=game.weapon_system.weapon_data[id]
  entries.append({"key":"weapon:"+id,"name":d.display_name,"icon":d.icon,"description":d.description+"\n"+game.weapon_system.upgrade_values(id,0),"compatibility":weapon_compatibility(id)})
 for id in game.weapon_system.passive_data:
  var d=game.weapon_system.passive_data[id]
  entries.append({"key":"passive:"+id,"name":d.display_name,"icon":d.icon,"description":d.level_descriptions[0],"compatibility":"Passiva da partida, até nível 8. Usa um dos quatro espaços."})
 for d in game.consumables.config.items:entries.append({"key":"consumable:"+str(d.id),"name":d.name,"icon":"res://assets/v15/"+d.id+".png","description":d.description,"compatibility":"Coleta imediata. Sem níveis e sem ocupar espaços."})
 var found:int=0
 for i in entries.size():
  var e:Dictionary=entries[i];var known:bool=game.profile.data.get("discoveries",{}).get(e.key,false)==true
  found+=int(known)
  var b:=Button.new();b.custom_minimum_size=Vector2(56,54);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.tooltip_text=e.name if known else "Não descoberto";b.pressed.connect(select.bind(i));b.focus_entered.connect(select.bind(i));grid.add_child(b);buttons.append(b)
  if known:
   var icon:=TextureRect.new();icon.texture=load(e.icon);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);icon.offset_left=12;icon.offset_top=10;icon.offset_right=-12;icon.offset_bottom=-10;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;b.add_child(icon)
  else:b.text="?"
 counter.text="Coleção: %d de %d"%[found,entries.size()]
 var fixed:=PanelContainer.new();fixed.name="CollectionDetails";fixed.custom_minimum_size.y=112;fixed.add_theme_stylebox_override("panel",ui._style(Color("606b7b"),GameUI.LINE));column.add_child(fixed)
 var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);fixed.add_child(row)
 detail_icon=TextureRect.new();detail_icon.custom_minimum_size=Vector2(44,44);detail_icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;detail_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;detail_icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;row.add_child(detail_icon)
 detail=RichTextLabel.new();detail.name="CollectionDescription";detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL;detail.add_theme_font_size_override("normal_font_size",12);detail.scroll_active=true;row.add_child(detail)
 var initial:int=0
 for i in entries.size():
  if game.profile.data.get("discoveries",{}).get(entries[i].key,false):initial=i;break
 resized.connect(responsive);select(initial);call_deferred("responsive")
func responsive():
 grid.columns=8 if size.x>=600 else 6 if size.x>=440 else 4
func select(index:int):
 current=index
 if not is_instance_valid(detail):return
 var e:Dictionary=entries[index];var known:bool=game.profile.data.get("discoveries",{}).get(e.key,false)==true
 detail_icon.texture=load(e.icon) if known else null
 detail.text=e.name+"\n"+e.description+"\n"+e.compatibility if known else "?\nItem não descoberto. Encontre ou equipe este item durante uma partida."
 for i in buttons.size():buttons[i].add_theme_stylebox_override("normal",ui._style(Color("182133"),Color("fff0ac") if i==index else GameUI.LINE,2 if i==index else 1))
func weapon_compatibility(id:String)->String:
 var area:bool=id in ["sword","sludge","holy_water","ice_wave","bombs","blades","clock"]
 var duration:bool=id in ["sludge","holy_water","ice_wave"]
 var amount:bool=id in ["bolt","axe","boomerang","bombs","holy_water"]
 return "Lupa: %s | Ampulheta: %s | Quantidade permanente: %s"%["largura" if id=="clock" else "sim" if area else "não","sim" if duration else "não","sim" if amount else "não"]
