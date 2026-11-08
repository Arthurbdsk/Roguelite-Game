class_name BestiaryView
extends Control
class Preview extends Control:
 var spec:Dictionary={}
 var clock:float=0
 func _ready():mouse_filter=Control.MOUSE_FILTER_IGNORE
 func _process(delta:float):clock+=delta;queue_redraw()
 func _draw():
  if spec.is_empty():return
  var cell:Vector2=spec.cell;var scale_factor:float=maxf(1,minf(floorf(size.x/cell.x),floorf(size.y/cell.y)))
  scale_factor=minf(scale_factor,3)
  var dimensions:Vector2=cell*scale_factor
  var frame:int=int(spec.start)+int(clock*6)%int(spec.count)
  draw_texture_rect_region(spec.texture,Rect2((size-dimensions)/2,dimensions),Rect2(frame*cell.x,0,cell.x,cell.y),Color(1.12,.84,.8) if spec.get("phase",false) else Color.WHITE)
var game
var ui
var selected:String=""
var phase:int=0
var filter:String="Todos"
var narrow_detail:bool=false
var rebuilding:bool=false
var last_size:=Vector2.ZERO
var list_scroll:ScrollContainer
var details:VBoxContainer
var content:Control
var plain_font:Font
func setup(owner,interface):
 game=owner;ui=interface;plain_font=GameFonts.interface_font();set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_theme_font_override("font",plain_font);selected=EnemyCatalog.ids(game)[0]
 resized.connect(resize_page);build()
func resize_page():
 if size!=last_size and not rebuilding:rebuilding=true;call_deferred("build")
func text(parent,value:String,font_size:int=12)->Label:
 var label:=Label.new();label.text=value;label.add_theme_font_override("font",plain_font);label.add_theme_font_size_override("font_size",font_size);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(label);return label
func button(parent,value:String,action:Callable)->Button:
 var node:=Button.new();node.text=value;node.add_theme_font_override("font",plain_font);node.custom_minimum_size.y=44 if mobile() else 30;node.size_flags_horizontal=Control.SIZE_EXPAND_FILL;node.pressed.connect(action);parent.add_child(node);return node
func mobile()->bool:return game.get("mobile")!=null and game.mobile.active
func column(parent)->VBoxContainer:
 var node:=VBoxContainer.new();node.add_theme_constant_override("separation",7);node.size_flags_horizontal=Control.SIZE_EXPAND_FILL;node.size_flags_vertical=Control.SIZE_EXPAND_FILL;parent.add_child(node);return node
func scroll(parent)->ScrollContainer:
 var node:=ScrollContainer.new();node.size_flags_horizontal=Control.SIZE_EXPAND_FILL;node.size_flags_vertical=Control.SIZE_EXPAND_FILL;node.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;node.follow_focus=true;node.scroll_deadzone=12;parent.add_child(node);return node
func build():
 rebuilding=false;last_size=size
 if filter!="Todos" and EnemyCatalog.category(selected)!=filter:
  var candidates:Array=EnemyCatalog.ids(game).filter(func(id):return EnemyCatalog.category(id)==filter)
  if not candidates.is_empty():selected=candidates[0];phase=0
 for child in get_children():remove_child(child);child.queue_free()
 var area:=Rect2(Vector2(12,8),size-Vector2(24,16))
 if mobile():area=game.mobile.safe.grow(-6)
 var panel:=PanelContainer.new();panel.position=area.position;panel.size=area.size;panel.add_theme_stylebox_override("panel",ui._style(Color("142238"),ui.LINE));add_child(panel)
 var page:=column(panel);page.add_theme_constant_override("separation",8)
 var header:=HBoxContainer.new();page.add_child(header);text(header,"Bestiário",20)
 button(header,"Voltar",func():ui.render(ui.bestiary_return,game.profile.data)).custom_minimum_size.x=80
 var filter_row:=HBoxContainer.new();page.add_child(filter_row)
 var picker:=OptionButton.new();picker.name="CategoryFilter";picker.custom_minimum_size.y=44 if mobile() else 28;picker.size_flags_horizontal=Control.SIZE_EXPAND_FILL;filter_row.add_child(picker)
 for item in ["Todos","Comuns","Especiais","Chefes"]:picker.add_item(item)
 picker.select(["Todos","Comuns","Especiais","Chefes"].find(filter));picker.item_selected.connect(func(index):filter=picker.get_item_text(index);build())
 var narrow:bool=area.size.x<560
 if narrow:
  button(filter_row,"Criaturas",func():narrow_detail=false;build())
  button(filter_row,"Ficha",func():narrow_detail=true;build())
 var row:=HBoxContainer.new();row.size_flags_vertical=Control.SIZE_EXPAND_FILL;row.add_theme_constant_override("separation",12);page.add_child(row)
 list_scroll=scroll(row);list_scroll.name="CreatureList";list_scroll.custom_minimum_size.x=172 if not narrow else 0;list_scroll.size_flags_horizontal=0 if not narrow else Control.SIZE_EXPAND_FILL
 var entries:=column(list_scroll);entries.custom_minimum_size.x=160 if not narrow else 0
 for id in EnemyCatalog.ids(game):
  if filter!="Todos" and EnemyCatalog.category(id)!=filter:continue
  var known:bool=game.profile.bestiary_counts(id).seen>0
  var item:=button(entries,game.enemy_data[id].title if known else "Desconhecido",func():selected=id;phase=0;narrow_detail=true;build())
  item.name="Creature_"+id;item.tooltip_text="";item.alignment=HORIZONTAL_ALIGNMENT_LEFT
  item.add_theme_color_override("font_color",ui.ICE if id==selected else ui.IVORY)
 var detail_scroll:=scroll(row);detail_scroll.name="CreatureDetails";details=column(detail_scroll);details.name="CreatureSheet"
 if narrow:list_scroll.visible=not narrow_detail;detail_scroll.visible=narrow_detail
 detail()
func detail():
 var counts:Dictionary=game.profile.bestiary_counts(selected);var known:bool=counts.seen>0
 var entry:Dictionary=EnemyCatalog.entry(game,selected,phase)
 var top:=HBoxContainer.new();top.add_theme_constant_override("separation",10);details.add_child(top)
 var preview:=Preview.new();preview.name="AnimatedCreature";preview.custom_minimum_size=Vector2(128,128);preview.spec=EnemyCatalog.preview(game,selected,phase);preview.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;top.add_child(preview)
 if not known:
  var shader:=Shader.new();shader.code="shader_type canvas_item; void fragment(){vec4 source=texture(TEXTURE,UV); COLOR=vec4(vec3(0.12,0.15,0.19),source.a);}"
  var material:=ShaderMaterial.new();material.shader=shader;preview.material=material
 var heading:=column(top);text(heading,entry.name if known else "Desconhecido",17)
 if not known:text(heading,"Encontre esta criatura durante uma partida para revelar a ficha.");return
 text(heading,entry.description)
 if entry.phases.size()>1:
  var phases:=OptionButton.new();phases.name="PhasePicker";phases.custom_minimum_size.y=44 if mobile() else 30;details.add_child(phases)
  for item in entry.phases:phases.add_item(item)
  phases.select(phase);phases.item_selected.connect(func(index):phase=index;build())
 text(details,"Vida-base: %s   |   Movimento: %s un/s"%[EnemyCatalog.number(entry.hp),EnemyCatalog.number(entry.speed)],13)
 text(details,"Redução de dano: %s%%   |   Defesa fixa: não possui"%EnemyCatalog.number(entry.reduction*100))
 text(details,"Ataques",13)
 for attack in entry.attacks:text(details,attack)
 for ability in entry.abilities:text(details,ability)
 text(details,"Controle: "+entry.control)
 text(details,"Encontrada: %d   |   Eliminada por você: %d"%[counts.seen,counts.kills],13)
 var note:=text(details,"Base: 1 jogador, Desafio 0 e estágio inicial. Valores arredondados. Vida e outros atributos podem variar na partida. Un/s indica a distância percorrida no mundo em um segundo.",11);note.modulate=ui.MUTED
