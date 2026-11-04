class_name SkillTreeView
extends Control
var game
var ui
var buttons:Dictionary={}
var grid:GridContainer
var details:VBoxContainer
var gold_label:Label
var title_label:Label
var refund_button:Button
var scroll:ScrollContainer
var last_purchase:int=-1000
const BG=Color("494c70")
const CARD=Color("898b88")
const GOLD=Color("d9b454")
func frame(color:Color,border:Color=GOLD,width:int=2)->StyleBoxFlat:
 var s:=StyleBoxFlat.new();s.bg_color=color;s.border_color=border;s.set_border_width_all(width);s.set_content_margin_all(5);return s
func label(parent,text:String,font_size:int=12)->Label:
 var l:=Label.new();l.text=text;l.add_theme_font_size_override("font_size",font_size);l.add_theme_color_override("font_color",Color("f7f3e5"));parent.add_child(l);return l
func icon(parent,path:String,size_px:int=26):
 var n:=TextureRect.new();n.texture=load(path);n.custom_minimum_size=Vector2(size_px,size_px);n.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;n.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;n.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;parent.add_child(n);return n
func setup(owner_game,interface):
 game=owner_game;ui=interface
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var panel:=Panel.new();panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.add_theme_stylebox_override("panel",frame(BG));add_child(panel)
 var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,10)
 add_child(margin)
 var column:=VBoxContainer.new();column.add_theme_constant_override("separation",6);margin.add_child(column)
 var head:=HBoxContainer.new();column.add_child(head)
 title_label=label(head,"Seleção de aprimoramentos",20);title_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title_label.clip_text=true
 gold_label=label(head,"",14);gold_label.name="GoldBalance"
 var bar:=HBoxContainer.new();column.add_child(bar)
 refund_button=Button.new();refund_button.text="Reembolsar aprimoramentos";refund_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;refund_button.add_theme_stylebox_override("normal",frame(Color("405fff")));refund_button.pressed.connect(confirm_refund);bar.add_child(refund_button)
 var back:=Button.new();back.text="Voltar";back.pressed.connect(game.close_skill_tree);bar.add_child(back)
 scroll=ScrollContainer.new();scroll.name="PermanentScroll";scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(scroll)
 grid=GridContainer.new();grid.name="PermanentGrid";grid.columns=4;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_theme_constant_override("h_separation",8);grid.add_theme_constant_override("v_separation",8);scroll.add_child(grid)
 for d in game.skills.definitions:
  var card:=Button.new();card.name=d.id;card.custom_minimum_size=Vector2(0,80);card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_child(card)
  card.pressed.connect(select.bind(d.id));card.focus_entered.connect(select.bind(d.id))
  var stack:=VBoxContainer.new();stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);stack.offset_left=4;stack.offset_right=-4;stack.offset_top=4;stack.offset_bottom=-3;stack.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(stack)
  var name_label:=label(stack,d.title,11);name_label.name="CardTitle";name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;name_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;name_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
  icon(stack,d.icon,27).mouse_filter=Control.MOUSE_FILTER_IGNORE
  var dots:=HBoxContainer.new();dots.name="Levels";dots.alignment=BoxContainer.ALIGNMENT_CENTER;dots.mouse_filter=Control.MOUSE_FILTER_IGNORE;stack.add_child(dots)
  for i in d.max_rank():
   var box:=Panel.new();box.custom_minimum_size=Vector2(9,7);box.mouse_filter=Control.MOUSE_FILTER_IGNORE;dots.add_child(box)
  buttons[d.id]=card
 var fixed:=PanelContainer.new();fixed.name="PermanentDetails";fixed.custom_minimum_size=Vector2(0,98);fixed.add_theme_stylebox_override("panel",frame(CARD));column.add_child(fixed)
 var row:=HBoxContainer.new();fixed.add_child(row)
 details=VBoxContainer.new();details.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(details)
 resized.connect(responsive)
 if not game.skills.by_id.has(ui.selected_skill):ui.selected_skill="damage"
 refresh();call_deferred("responsive")
func responsive():
 if not is_instance_valid(grid):return
 grid.columns=4 if size.x>=590 else (3 if size.x>=440 else 2)
 title_label.text="Seleção de aprimoramentos" if size.x>=590 else "Aprimoramentos"
func select(id:String):
 ui.selected_skill=id;game.skills.last_error="";refresh()
func refresh():
 gold_label.text="%d ouro"%game.profile.data.gold
 refund_button.disabled=game.skills.refund_total()==0
 for id in buttons:
  var card:Button=buttons[id];var n:int=game.skills.rank(id);var d=game.skills.by_id[id]
  card.add_theme_stylebox_override("normal",frame(CARD,Color("fff0a4") if id==ui.selected_skill else GOLD,3 if id==ui.selected_skill else 1))
  card.add_theme_stylebox_override("focus",frame(Color(0,0,0,0),Color("fff0a4"),2))
  card.find_child("CardTitle",true,false).text=d.title+(" | MÁX" if n==d.max_rank() else "")
  card.tooltip_text=d.title+(" | Nível máximo" if n==d.max_rank() else " | %d/%d"%[n,d.max_rank()])
  var dots=card.find_child("Levels",true,false)
  for i in dots.get_child_count():dots.get_child(i).add_theme_stylebox_override("panel",frame(Color("eed270") if i<n else Color("342342"),GOLD,1))
 for child in details.get_children():details.remove_child(child);child.queue_free()
 var d=game.skills.by_id[ui.selected_skill];var n:int=game.skills.rank(d.id);var info:Dictionary=game.skills.state(d.id)
 var title_row:=HBoxContainer.new();details.add_child(title_row);icon(title_row,d.icon,22)
 label(title_row,d.title+(" | MÁXIMO" if n==d.max_rank() else " | %d/%d"%[n,d.max_rank()]),12)
 var desc:=label(details,d.description,9);desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 var effect:=label(details,"Atual: "+game.skills.effect(d.id,n)+( "   Após: "+game.skills.effect(d.id,n+1) if n<d.max_rank() else ""),10)
 var action:=HBoxContainer.new();details.add_child(action)
 var price:=label(action,"Próximo: %d ouro"%info.cost if info.status!="maxed" else "Nível máximo",11);price.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 if not game.skills.last_error.is_empty():price.text=game.skills.last_error;price.add_theme_color_override("font_color",Color("722a20"))
 if d.id=="challenge":
  label(action,"Ativos:",10);var spin:=SpinBox.new();spin.min_value=0;spin.max_value=n;spin.value=game.profile.data.challenge_active;spin.custom_minimum_size=Vector2(62,22);spin.value_changed.connect(func(v):game.skills.set_challenge(int(v)));action.add_child(spin)
 var buy:=Button.new();buy.name="BuyPermanent";buy.text="Comprar";buy.custom_minimum_size=Vector2(84,22);buy.add_theme_stylebox_override("normal",frame(Color("3aaf52")));buy.disabled=not info.can_buy;buy.pressed.connect(purchase.bind(d.id,n));action.add_child(buy)
func purchase(id:String,n:int):
 if Time.get_ticks_msec()-last_purchase<350:return
 last_purchase=Time.get_ticks_msec()
 game.skills.purchase(id,n);refresh()
func confirm_refund():
 var revision:int=game.profile.data.upgrade_revision
 var dialog:=ConfirmationDialog.new();dialog.title="Reembolsar aprimoramentos";dialog.dialog_text="Devolver %d de ouro e remover todos os níveis comprados?"%game.skills.refund_total();dialog.ok_button_text="Reembolsar";dialog.cancel_button_text="Cancelar";add_child(dialog)
 dialog.confirmed.connect(func():game.skills.refund(revision);refresh();dialog.queue_free());dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(350,110))
