class_name GameUI
extends CanvasLayer

const INK := Color("142238")
const PANEL := Color("484f68")
const LINE := Color("bca15d")
const IVORY := Color("f2ecda")
const MUTED := Color("b5c4d1")
const COPPER := Color("b65f42")
const ICE := Color("83c4bd")

var game
var screen: String = "title"
var return_screen: String = "title"
var selected_support: String = "none"
var root: Control
var menu: Control
var hud: Control
var life_bar: ProgressBar
var experience_bar: ProgressBar
var true_health:TrueHealthBar
var boss_bar: ProgressBar
var life_text: Label
var time_text: Label
var level_text: Label
var counts_text: Label
var pressure_text: Label
var banner_text: Label
var boss_text: Label
var dev_chain_label:Label
var build_stats_label:Label
var status_text:Label
var status_icon:TextureRect
var status_labels:Dictionary={}
var status_row:HBoxContainer
var pause_hint: Label
var loadout: BuildStrip
var passive_text: Label
var ui_theme: Theme
var previous_data: Dictionary = {}
var selected_skill: String = "edge"
var bestiary_return:String="title"

func setup(game_ref) -> void:
 game = game_ref
 layer = 20
 _build_theme()
 root = Control.new()
 root.name = "GameInterface"
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.mouse_filter = Control.MOUSE_FILTER_IGNORE
 root.theme = ui_theme
 add_child(root)
 _build_hud()
 menu = Control.new()
 menu.name = "Menus"
 menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.add_child(menu)

func _build_theme() -> void:
 ui_theme = Theme.new()
 ui_theme.default_font_size = 12
 ui_theme.default_font = GameFonts.interface_font()
 ui_theme.set_color("font_color", "Label", IVORY)
 ui_theme.set_color("font_color", "Button", IVORY)
 ui_theme.set_color("font_hover_color", "Button", Color("f0e6c8"))
 ui_theme.set_color("font_focus_color", "Button", Color("f0e6c8"))
 ui_theme.set_color("font_disabled_color", "Button", Color("aeb8c2"))
 ui_theme.set_stylebox("normal", "Button", _style(PANEL, LINE))
 ui_theme.set_stylebox("hover", "Button", _style(Color("59627b"), LINE))
 ui_theme.set_stylebox("pressed", "Button", _style(Color("646c80"), IVORY))
 ui_theme.set_stylebox("focus", "Button", _style(Color(0, 0, 0, 0), IVORY, 2))
 ui_theme.set_stylebox("disabled", "Button", _style(Color("151e22"), Color("303c3c")))
 for state_name in ["normal","hover","pressed","disabled"]:ui_theme.set_stylebox(state_name,"Button",UIAssets18.button(state_name))
 ui_theme.set_stylebox("background", "ProgressBar", _bar_style(Color("0c1216"), Color("45514d"), 1))
 ui_theme.set_stylebox("fill", "ProgressBar", _bar_style(ICE, ICE))
 ui_theme.set_stylebox("panel", "Panel", _style(PANEL, LINE))
 ui_theme.set_stylebox("normal", "LineEdit", _style(PANEL, LINE))
 ui_theme.set_stylebox("focus", "LineEdit", _style(PANEL, ICE))
 ui_theme.set_color("font_color", "LineEdit", IVORY)
 ui_theme.set_color("font_color", "LinkButton", MUTED)
 ui_theme.set_color("font_hover_color", "LinkButton", IVORY)
 ui_theme.set_color("font_focus_color", "LinkButton", IVORY)
 ui_theme.set_stylebox("focus", "LinkButton", _style(Color(0, 0, 0, 0), ICE))

func _style(fill: Color, border: Color, thickness: int = 1) -> StyleBoxFlat:
 var box := StyleBoxFlat.new()
 box.bg_color = fill
 box.border_color = border
 box.set_border_width_all(thickness)
 box.content_margin_left = 9
 box.content_margin_right = 9
 box.content_margin_top = 5
 box.content_margin_bottom = 5
 return box

func _bar_style(fill: Color, border: Color, thickness: int = 0) -> StyleBoxFlat:
 var box := StyleBoxFlat.new()
 box.bg_color = fill
 box.border_color = border
 box.set_border_width_all(thickness)
 box.content_margin_left = 0.0
 box.content_margin_right = 0.0
 box.content_margin_top = 0.0
 box.content_margin_bottom = 0.0
 return box

func _box(parent: Node, rect: Rect2, color: Color = PANEL) -> Panel:
 var p := Panel.new()
 p.position = rect.position
 p.size = rect.size
 p.mouse_filter = Control.MOUSE_FILTER_IGNORE
 p.add_theme_stylebox_override("panel", _style(color, LINE))
 parent.add_child(p)
 return p

func _label(parent: Node, text: String, rect: Rect2, font_size: int = 12, color: Color = IVORY, centered: bool = false) -> Label:
 var label := Label.new()
 label.text = DisplayNumbers.clean(text)
 label.position = rect.position
 label.add_theme_font_size_override("font_size", font_size)
 label.add_theme_color_override("font_color", color)
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.clip_text = true
 if centered:
  label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 parent.add_child(label)
 # Set the size after enabling wrapping; otherwise the initial single-line
 # minimum expands this control and it never shrinks to the card width.
 label.size = Vector2(rect.size.x,maxf(rect.size.y,label.get_theme_font("font").get_height(font_size)))
 return label

func _grant_focus(control) -> void:
 if is_instance_valid(control) and control.is_inside_tree():
  control.grab_focus()

func _button(parent: Node, text: String, rect: Rect2, action: Callable, primary: bool = false) -> Button:
 var b := Button.new()
 b.text = DisplayNumbers.clean(text)
 b.position = rect.position
 b.size = rect.size
 b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 b.pressed.connect(action)
 b.focus_entered.connect(_focus_sound)
 if primary:
  b.add_theme_stylebox_override("normal", _style(Color("355e49"), LINE))
 parent.add_child(b)
 return b

func _focus_sound() -> void:
 if game != null and game.get("sound") != null:
  game.sound.play_cue("select")

func _link(parent: Node, text: String, pos: Vector2, action: Callable) -> LinkButton:
 var link := LinkButton.new()
 link.text = text
 link.position = pos
 link.add_theme_font_size_override("font_size", 10)
 link.pressed.connect(action)
 parent.add_child(link)
 return link

func _backdrop(alpha: float = 1.0) -> void:
 var shade := ColorRect.new()
 shade.color = Color(INK, alpha)
 shade.size = Vector2(640, 360)
 menu.add_child(shade)
 var top_line := ColorRect.new()
 top_line.color = COPPER
 top_line.position = Vector2(0, 0)
 top_line.size = Vector2(640, 2)
 top_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
 menu.add_child(top_line)

func render(which: String, data: Dictionary = {}) -> void:
 if root == null:
  return
 if which!="running":game.bestiary.flush()
 screen = which
 previous_data = data.duplicate(true)
 for child in menu.get_children():
  menu.remove_child(child)
  child.queue_free()
 menu.visible = which != "running"
 hud.visible = which in ["running", "paused", "upgrading", "result"]
 match which:
  "online", "lobby", "online_pause": CoopMenu.build(self, which)
  "title": _title()
  "maps": _map_selection()
  "hub": _hub(data)
  "updates":
   var view:=UpdateView.new();menu.add_child(view);view.setup(game,self)
  "bestiary":
   var view:=BestiaryView.new();menu.add_child(view);view.setup(game,self)
  "collection":
   var view:=CollectionView.new();menu.add_child(view);view.setup(game,self)
  "upgrading": _upgrades(data)
  "revive_offer":
   _backdrop(.9)
   _label(menu,"Reviver",Rect2(80,70,480,40),28,IVORY,true)
   _label(menu,"Retorne com 40% da vida e 2 segundos de proteção.\nUma utilização por partida. Sua build será preservada.",Rect2(70,122,500,55),13,IVORY,true)
   _button(menu,"Usar retorno",Rect2(175,197,290,32),game.use_solo_revive,true)
   _button(menu,"Encerrar partida",Rect2(175,239,290,30),func():game.finish_run(false))
  "endless_choice":
   _backdrop(.92)
   _label(menu,"CAMPANHA VENCIDA",Rect2(50,65,540,42),24,IVORY,true)
   _label(menu,"Continue com sua build, ouro e tempo atuais.\nOnline: todos precisam concordar em até 30 segundos.",Rect2(70,120,500,60),13,IVORY,true)
   _button(menu,"Continuar no infinito",Rect2(140,200,360,36),func():game.campaign.vote(true),true)
   _button(menu,"Encerrar com vitória",Rect2(140,247,360,34),func():game.campaign.vote(false))
  "paused": _paused()
  "settings": _settings()
  "result": _result(data)
  "tree":
   _backdrop()
   var tree_view := SkillTreeView.new()
   menu.add_child(tree_view)
   tree_view.setup(game, self)

func _title() -> void:
 _backdrop()
 var margin := MarginContainer.new()
 margin.name = "TitleLayout"
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for edge in ["left", "right"]: margin.add_theme_constant_override("margin_"+edge,24)
 margin.add_theme_constant_override("margin_top",14)
 margin.add_theme_constant_override("margin_bottom",48)
 menu.add_child(margin)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation",8)
 margin.add_child(column)
 var title := Label.new()
 title.text = "HORDAS"
 title.add_theme_font_size_override("font_size",36)
 column.add_child(title)
 var subtitle := Label.new()
 subtitle.text = "Sobreviva aos inimigos e derrote os chefes."
 subtitle.add_theme_font_size_override("font_size",12)
 column.add_child(subtitle)
 var row := HBoxContainer.new()
 row.size_flags_vertical = Control.SIZE_EXPAND_FILL
 row.add_theme_constant_override("separation",24)
 column.add_child(row)
 var actions := VBoxContainer.new()
 actions.custom_minimum_size.x = 220
 actions.add_theme_constant_override("separation",6)
 row.add_child(actions)
 var play := _button(actions,"Jogar",Rect2(),func(): game.open_map_select(),true)
 _button(actions,"Cooperativo online",Rect2(),func(): game.open_online())
 _button(actions,"Base e aprimoramentos",Rect2(),func(): game.enter_hub())
 var libraries:=HBoxContainer.new();libraries.add_theme_constant_override("separation",8);actions.add_child(libraries)
 _button(libraries,"Coleção",Rect2(),func(): render("collection"))
 _button(libraries,"Bestiário",Rect2(),func():bestiary_return="title";render("bestiary"))
 _button(libraries,"Atualizações disponíveis" if game.updates!=null and game.updates.available() else "Atualizações",Rect2(),func():render("updates"))
 var settings := HBoxContainer.new()
 settings.add_theme_constant_override("separation",8)
 actions.add_child(settings)
 var options := _button(settings,"Opções",Rect2(),func(): _open_settings("title"))
 options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var leave := _button(settings,"Sair",Rect2(),func(): get_tree().quit())
 leave.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var art := VBoxContainer.new()
 art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 row.add_child(art)
 var castle := TextureRect.new()
 castle.texture = load("res://assets/fortress.png")
 castle.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 castle.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 castle.size_flags_vertical = Control.SIZE_EXPAND_FILL
 castle.custom_minimum_size.y = 100
 art.add_child(castle)
 var help := Label.new()
 help.text = "WASD / setas: mover. Esc: menu.\nA dificuldade sobe a cada 2 minutos."
 help.add_theme_font_size_override("font_size",11)
 art.add_child(help)
 _footer()
 call_deferred("_grant_focus",play)

func _footer() -> void:
 var footer := VBoxContainer.new()
 footer.name = "Footer"
 footer.anchor_top = 1
 footer.anchor_bottom = 1
 footer.anchor_right = 1
 footer.offset_left = 24
 footer.offset_right = -24
 footer.offset_top = -33
 footer.offset_bottom = -6
 footer.add_theme_constant_override("separation",6)
 menu.add_child(footer)
 var rule := HSeparator.new()
 rule.custom_minimum_size.y = 1
 footer.add_child(rule)
 var links := HBoxContainer.new()
 footer.add_child(links)
 _link(links,"Feito por Socialy",Vector2.ZERO,func(): OS.shell_open("https://www.instagram.com/socialy_webdesign/"))
 var spacer := Control.new()
 spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 links.add_child(spacer)
 _link(links,"Privacidade",Vector2.ZERO,func(): _legal("privacy"))
 _link(links,"Termos",Vector2.ZERO,func(): _legal("terms"))

func _hub(data: Dictionary) -> void:
 _backdrop()
 var p: Dictionary = data
 if p.is_empty() and game.profile != null:
  p = game.profile.data
 var buildings: Dictionary = p.get("buildings", {})
 if selected_support != "none" and not bool(buildings.get(selected_support, false)):
  selected_support = "none"
 _label(menu, "BASE", Rect2(24, 14, 420, 38), 28)
 _label(menu, "%d MEDALHAS  |  %d OURO" % [int(p.get("seals", 0)), int(p.get("gold", 0))], Rect2(370, 22, 247, 24), 13, ICE)
 _label(menu, "Construções e medalhas permanecem após a morte.", Rect2(25, 55, 590, 20), 12, MUTED)
 _building_card("arsenal", "ARSENAL", "Arco inicial.\nOrbes giram 15% mais devagar.", bool(buildings.get("arsenal", false)), Vector2(25, 84))
 _building_card("library", "BIBLIOTECA", "Orbes iniciais.\nArco tem intervalo 15% maior.", bool(buildings.get("library", false)), Vector2(331, 84))
 _label(menu, "Apoio da próxima partida", Rect2(25, 207, 590, 20), 14)
 var none := _button(menu, _choice("none", "Sem apoio"), Rect2(25, 235, 188, 30), func(): _select_support("none"))
 var arsenal := _button(menu, _choice("arsenal", "Arsenal"), Rect2(225, 235, 188, 30), func(): _select_support("arsenal"))
 arsenal.disabled = not bool(buildings.get("arsenal", false))
 var library := _button(menu, _choice("library", "Biblioteca"), Rect2(425, 235, 188, 30), func(): _select_support("library"))
 library.disabled = not bool(buildings.get("library", false))
 _label(menu, "Armas, níveis e passivas da partida são temporários.", Rect2(25, 274, 380, 24), 11, MUTED)
 _button(menu, "Voltar", Rect2(25, 292, 90, 24), func(): game.show_title())
 _button(menu, "Aprimoramentos", Rect2(127, 292, 140, 24), game.open_skill_tree)
 _button(menu, "Bestiário", Rect2(279, 292, 120, 24),func():bestiary_return="hub";render("bestiary"))
 _button(menu, "Partir", Rect2(425, 278, 188, 35), func(): game.open_map_select(), true)
 _footer()
 call_deferred("_grant_focus", none)

func _choice(id: String, text: String) -> String:
 return ("[X] " if selected_support == id else "") + text

func _select_support(id: String) -> void:
 selected_support = id
 render("hub", game.profile.data)

func _building_card(id: String, title: String, desc: String, owned: bool, pos: Vector2) -> void:
 _box(menu, Rect2(pos, Vector2(282, 112)))
 _label(menu, title, Rect2(pos + Vector2(12, 8), Vector2(255, 23)), 17, ICE if owned else IVORY)
 _label(menu, desc, Rect2(pos + Vector2(12, 38), Vector2(255, 37)), 11, MUTED)
 if owned:
  _label(menu, "RESTAURADO", Rect2(pos + Vector2(12, 84), Vector2(255, 20)), 11, ICE)
 else:
  var b := _button(menu, "Restaurar: 8 medalhas", Rect2(pos + Vector2(12, 79), Vector2(258, 25)), func():
   game.buy_building(id)
   render("hub", game.profile.data))
  b.disabled = int(game.profile.data.get("seals", 0)) < 8

func _upgrades(data: Dictionary) -> void:
 _backdrop(0.97)
 _label(menu,"Subiu de nível",Rect2(20,10,600,32),24,IVORY,true)
 var margin:=MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for spec in [["left",20],["right",20],["top",52],["bottom",28]]:margin.add_theme_constant_override("margin_"+str(spec[0]),int(spec[1]))
 menu.add_child(margin)
 var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);margin.add_child(row)
 var choice_scroll:=ScrollContainer.new();choice_scroll.name="ChoiceScroll";choice_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;choice_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;row.add_child(choice_scroll)
 var choices:=VBoxContainer.new();choices.name="UpgradeList";choices.size_flags_horizontal=Control.SIZE_EXPAND_FILL;choices.add_theme_constant_override("separation",6);choice_scroll.add_child(choices)
 var offers:Array=data.get("offers",[])
 for i in mini(4,offers.size()):
  var offer:Dictionary=offers[i]
  var button:=_button(choices,"",Rect2(),func():game.choose_upgrade(offer.id))
  for state_name in ["normal","hover","pressed"]:button.add_theme_stylebox_override(state_name,_style(Color("293c54") if state_name=="hover" else Color("203047"),LINE))
  button.custom_minimum_size.y=88
  button.size_flags_vertical=Control.SIZE_EXPAND_FILL
  var inset:=MarginContainer.new();inset.mouse_filter=Control.MOUSE_FILTER_IGNORE;inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  for edge in ["left","right","top","bottom"]:inset.add_theme_constant_override("margin_"+edge,7)
  button.add_child(inset)
  var line:=HBoxContainer.new();line.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_theme_constant_override("separation",8);inset.add_child(line)
  var icon:=TextureRect.new();icon.custom_minimum_size=Vector2(32,32);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
  if ResourceLoader.exists(offer.get("icon","")):icon.texture=load(offer.icon)
  line.add_child(icon)
  var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_theme_constant_override("separation",2);line.add_child(column)
  var name_label:=Label.new();name_label.text="%d. %s"%[i+1,offer.name];name_label.add_theme_font_size_override("font_size",12);column.add_child(name_label)
  var level_label:=Label.new();level_label.text=offer.get("detail","Novo");level_label.add_theme_font_size_override("font_size",9);level_label.modulate=ICE;column.add_child(level_label)
  var desc:=Label.new();desc.text=DisplayNumbers.clean(offer.description);desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;desc.add_theme_font_size_override("font_size",11);column.add_child(desc)
  inset.minimum_size_changed.connect(func():button.custom_minimum_size.y=maxf(88,inset.get_combined_minimum_size().y))
  if i==0:call_deferred("_grant_focus",button)
 var build_scroll:=ScrollContainer.new();build_scroll.custom_minimum_size.x=220;build_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;row.add_child(build_scroll)
 var build:=VBoxContainer.new();build.name="BuildPanel";build.custom_minimum_size.x=204;build.add_theme_constant_override("separation",4);build_scroll.add_child(build)
 var heading:=Label.new();heading.text="Build atual";heading.add_theme_font_size_override("font_size",14);build.add_child(heading)
 if game.get("weapon_system")!=null:
  for group in [game.weapon_system.get_loadout(),game.weapon_system.get_passives()]:
   var is_weapon:bool=group==game.weapon_system.get_loadout()
   var slots:=Label.new();slots.text="%s: %d/%d"%["Armas" if is_weapon else "Passivas",group.size(),6 if is_weapon else game.weapon_system.passive_limit()];slots.add_theme_font_size_override("font_size",10);build.add_child(slots)
   var icons:=HBoxContainer.new();icons.add_theme_constant_override("separation",6);build.add_child(icons)
   for empty_slot in (6 if is_weapon else 4)-group.size():
    var empty:=Label.new();empty.text="[  ]";empty.add_theme_font_size_override("font_size",10);icons.add_child(empty)
   for item in group:
    var stack:=VBoxContainer.new();icons.add_child(stack)
    var icon:=TextureRect.new();icon.texture=load(item.icon) if ResourceLoader.exists(item.icon) else null;icon.custom_minimum_size=Vector2(16,16);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;stack.add_child(icon)
    var level_label:=Label.new();level_label.text=("MÁX" if item.level==8 else "Nv.%d"%item.level);level_label.add_theme_font_size_override("font_size",8);stack.add_child(level_label)
  build_stats_label=Label.new();build_stats_label.text=game.weapon_system.build_stats();build_stats_label.add_theme_font_size_override("font_size",10);build_stats_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;build.add_child(build_stats_label)
 _label(menu,"1 / 2 / 3 / 4: escolher. Esc: fechar no cooperativo.",Rect2(20,338,600,18),9,MUTED,true)

func _paused() -> void:
 _backdrop(0.91)
 _label(menu, "PAUSA", Rect2(20, 49, 600, 42), 28, IVORY, true)
 var resume := _button(menu, "Continuar", Rect2(210, 116, 220, 31), func(): game.toggle_pause(), true)
 _button(menu, "Reiniciar partida", Rect2(210, 155, 220, 30), func(): game.retry())
 _button(menu, "Opções", Rect2(210, 193, 220, 30), func(): _open_settings("paused"))
 _button(menu, "Voltar à base", Rect2(210, 231, 220, 30), func(): game.abandon())
 _label(menu, "Esc ou Start para continuar", Rect2(20, 289, 600, 22), 11, MUTED, true)
 call_deferred("_grant_focus", resume)

func _open_settings(from: String) -> void:
 return_screen = from
 render("settings")

func _settings() -> void:
 _backdrop()
 _label(menu, "OPÇÕES", Rect2(28, 23, 584, 40), 29)
 var settings: Dictionary = game.profile.data.get("settings", {})
 _label(menu, "Efeitos sonoros", Rect2(65, 98, 180, 22), 14)
 var volume := HSlider.new()
 volume.position = Vector2(276, 98)
 volume.size = Vector2(278, 22)
 volume.min_value = 0.0
 volume.max_value = 1.0
 volume.step = 0.05
 volume.value = float(settings.get("volume", 0.6))
 volume.value_changed.connect(func(value: float): game.set_option("volume", value))
 menu.add_child(volume)
 _label(menu, "Intensidade dos efeitos", Rect2(65, 144, 207, 22), 14)
 var effects := HSlider.new()
 effects.position = Vector2(276, 144)
 effects.size = Vector2(278, 22)
 effects.min_value = 0.0
 effects.max_value = 1.0
 effects.step = 0.05
 effects.value = float(settings.get("effects", 0.75))
 effects.value_changed.connect(func(value: float): game.set_option("effects", value))
 menu.add_child(effects)
 _label(menu,"Música",Rect2(65,234,180,22),14)
 var music_volume:=HSlider.new();music_volume.name="MusicVolume";music_volume.position=Vector2(276,234);music_volume.size=Vector2(278,22)
 music_volume.min_value=0;music_volume.max_value=1;music_volume.step=.05;music_volume.value=float(settings.get("music",.35))
 music_volume.value_changed.connect(func(value):game.set_option("music",value));menu.add_child(music_volume)
 var shake := CheckButton.new()
 shake.text = "Tremor de câmera"
 shake.position = Vector2(65, 190)
 shake.size = Vector2(260, 29)
 shake.button_pressed = bool(settings.get("shake", true))
 shake.toggled.connect(func(value: bool): game.set_option("shake", value))
 menu.add_child(shake)
 var fullscreen := CheckButton.new()
 fullscreen.text = "Tela cheia"
 fullscreen.position = Vector2(347, 190)
 fullscreen.size = Vector2(220, 29)
 fullscreen.button_pressed = bool(settings.get("fullscreen", false))
 fullscreen.toggled.connect(func(value: bool): game.set_option("fullscreen", value))
 menu.add_child(fullscreen)
 _button(menu, "Voltar", Rect2(65, 278, 490, 32), func(): render(return_screen, game.profile.data))
 call_deferred("_grant_focus", volume)

func _result(data: Dictionary) -> void:
 _backdrop(0.94)
 var won: bool = bool(data.get("won", false))
 _label(menu, "VITÓRIA" if won else "FIM DA PARTIDA", Rect2(24, 35, 592, 43), 28, ICE if won else IVORY, true)
 _label(menu, "Modo teste: saldo permanente não alterado." if data.get("dev", false) else ("Chefe final derrotado." if won else "Seu ouro foi somado ao saldo permanente."), Rect2(24, 87, 592, 24), 12, MUTED, true)
 _box(menu, Rect2(84, 121, 472, 132))
 _label(menu, "ESTÁGIO %d\n%s" % [int(data.get("wave", 1)), _clock(float(data.get("elapsed", 0)))], Rect2(99, 134, 142, 39), 13)
 _label(menu, "ABATES\n%d" % int(data.get("kills", 0)), Rect2(252, 134, 135, 39), 13)
 _label(menu, "NÍVEL\n%d" % int(data.get("level", 1)), Rect2(405, 134, 136, 39), 13)
 _label(menu, "OURO RECEBIDO\n+%d" % int(data.get("gold", 0)), Rect2(99, 193, 142, 42), 12, Color("dfb969"))
 _label(menu, "OURO TOTAL\n%d" % int(data.get("total_gold", 0)), Rect2(252, 193, 135, 42), 12, Color("dfb969"))
 _label(menu, "MEDALHAS\n+%d" % int(data.get("earned", 0)), Rect2(405, 193, 136, 42), 12, ICE)
 var again := _button(menu, "Tentar novamente", Rect2(130, 268, 182, 34), func(): game.retry(), true)
 _button(menu, "Base", Rect2(326, 268, 184, 34), func(): game.enter_hub())
 _label(menu, "Armas e melhorias temporárias foram encerradas.", Rect2(24, 323, 592, 20), 11, MUTED, true)
 call_deferred("_grant_focus", again)

func _legal(kind: String) -> void:
 var back_screen: String = screen
 var back_data: Dictionary = previous_data.duplicate(true)
 for child in menu.get_children():
  menu.remove_child(child)
  child.queue_free()
 _backdrop()
 var privacy: bool = kind == "privacy"
 _label(menu, "POLÍTICA DE PRIVACIDADE" if privacy else "TERMOS DE SERVIÇO", Rect2(30, 26, 580, 40), 24)
 var content: String
 if privacy:
  content = "O solo funciona offline, sem conta, anúncios ou análise de uso. Progresso e opções ficam no seu computador.\n\nAo criar ou entrar numa sala, o serviço recebe nome escolhido, código, habilidades e mensagens da partida. O endereço de rede é necessário à conexão. Os dados da sala ficam em memória até seu encerramento; a hospedagem pode manter registros técnicos.\n\nO link Socialy abre o Instagram, sujeito às regras desse serviço."
 else:
  content = "Protótipo para teste e avaliação. Sistemas, arte e balanceamento podem mudar. O progresso é local; preserve uma cópia antes de atualizar.\n\nO cooperativo depende do serviço de salas e da conexão dos participantes. A saída do anfitrião encerra a sessão. Não há reconexão, migração de anfitrião ou garantia de disponibilidade.\n\nSem compras, cadastro ou assinatura. Autoria e licenças estão documentadas no projeto."
 _label(menu, content, Rect2(32, 91, 576, 190), 13, MUTED)
 var back := _button(menu, "Voltar", Rect2(32, 297, 576, 32), func(): render(back_screen, back_data))
 call_deferred("_grant_focus", back)

func _build_hud() -> void:
 hud = Control.new()
 hud.name = "HUD"
 hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
 root.add_child(hud)
 _box(hud, Rect2(10, 10, 165, 39), Color("11191ce8"))
 _box(hud,Rect2(440,10,190,39),Color("142238ed"))
 dev_chain_label=_label(hud,"",Rect2(10,105,360,30),8,MUTED)
 true_health=TrueHealthBar.new();hud.add_child(true_health);true_health.visible=false
 status_row=HBoxContainer.new();status_row.position=Vector2(12,267);status_row.add_theme_constant_override("separation",5);hud.add_child(status_row)
 for id in ["poison","root","slow","frozen"]:
  var panel:=PanelContainer.new();panel.add_theme_stylebox_override("panel",_style(Color("142238"),Color("647085")));status_row.add_child(panel)
  var row:=HBoxContainer.new();row.add_theme_constant_override("separation",4);panel.add_child(row)
  var icon:=TextureRect.new();icon.texture=GameIcons.texture("status:"+id);icon.custom_minimum_size=Vector2(16,16);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;row.add_child(icon)
  var text:=Label.new();text.add_theme_font_size_override("font_size",10);row.add_child(text);panel.hide();status_labels[id]={"panel":panel,"label":text}
  if id=="poison":status_icon=icon;status_text=text
 life_text = _label(hud, "VIDA", Rect2(17, 14, 151, 15), 10)
 life_bar = _bar(hud, Rect2(17, 33, 151, 7), COPPER)
 time_text = _label(hud, "00:00", Rect2(263, 11, 114, 31), 24, IVORY, true)
 time_text.add_theme_font_override("font",GameFonts.timer_font())
 pressure_text = _label(hud, "ARENA", Rect2(452, 12, 176, 18), 11, MUTED)
 pressure_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 counts_text = _label(hud, "", Rect2(452, 31, 176, 18), 11, IVORY)
 counts_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 _hud_icon("GoldIcon","attribute:gold",Vector2(444,31))
 counts_text.position.x=464;counts_text.size.x=164
 loadout = BuildStrip.new()
 loadout.position = Vector2(11, 55)
 loadout.size = Vector2(230, 28)
 loadout.mouse_filter = Control.MOUSE_FILTER_IGNORE
 loadout.visible=true
 hud.add_child(loadout)
 passive_text = _label(hud, "", Rect2(12, 57, 220, 20), 10, MUTED)
 passive_text.hide()
 banner_text = _label(hud, "", Rect2(170, 85, 300, 38), 17, IVORY, true)
 boss_text = _label(hud, "", Rect2(162, 300, 316, 18), 11, IVORY, true)
 boss_bar = _bar(hud, Rect2(162, 321, 316, 6), COPPER)
 _hud_icon("ExperienceIcon","attribute:experience",Vector2(12,320))
 level_text = _label(hud, "Nível 1", Rect2(32, 322, 110, 16), 10, ICE)
 pause_hint = _label(hud, "ESC: PAUSA", Rect2(520, 322, 108, 16), 10, MUTED)
 pause_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 experience_bar = _bar(hud, Rect2(12, 343, 616, 5), ICE)

func _hud_icon(node_name:String,key:String,at:Vector2):
 var icon:=TextureRect.new()
 icon.name=node_name
 icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 icon.texture=GameIcons.texture(key)
 icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
 hud.add_child(icon)
 icon.position=at;icon.size=Vector2(16,16)

func _bar(parent: Node, rect: Rect2, color: Color) -> ProgressBar:
 var bar := ProgressBar.new()
 bar.show_percentage = false
 bar.custom_minimum_size = Vector2.ZERO
 bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
 bar.add_theme_stylebox_override("background", _bar_style(Color("0c1216"), Color("45514d"), 1))
 bar.add_theme_stylebox_override("fill", _bar_style(color, color))
 parent.add_child(bar)
 # Set the requested dimensions only after removing the default text and theme minima.
 bar.position = rect.position
 bar.size = rect.size
 return bar

func update_hud(data: Dictionary) -> void:
 if hud == null:
  return
 _update_build_icons(data)
 if screen=="upgrading" and is_instance_valid(build_stats_label):build_stats_label.text=game.weapon_system.build_stats()
 pause_hint.text = "ESC: MENU" if game.get("coop") != null and game.coop.active else "ESC: PAUSA"
 if game.get("player")!=null:
  var p=game.player
  var states:Dictionary={"poison":"Veneno: %d s"%ceili(p.poison_remaining) if p.poison_remaining>0 else "","root":"Preso: "+DisplayNumbers.seconds(p.root_remaining) if p.root_remaining>0 else "","slow":"Lentidão: %d%%"%roundi((1-p.movement_multiplier)*100) if p.movement_multiplier<1 else "","frozen":"Tempo parado: %d s"%ceili(game.consumables.freeze_left) if game.consumables.freeze_left>0 else ""}
  for id in status_labels:
   status_labels[id].label.text=states[id];status_labels[id].panel.visible=not states[id].is_empty()
 life_bar.max_value = maxf(1.0, float(data.get("max_hp", 100.0)))
 life_bar.value = float(data.get("hp", 100.0))
 life_text.text = "VIDA   %d / %d" % [ceili(data.get("hp", 100)), ceili(life_bar.max_value)]
 experience_bar.max_value = maxf(1.0, float(data.get("xp_needed", 10.0)))
 experience_bar.value = float(data.get("xp", 0))
 level_text.text = "NÍVEL %d" % int(data.get("level", 1))
 time_text.text = _clock(float(data.get("elapsed", 0.0)))
 dev_chain_label.visible=data.get("dev",false)
 if dev_chain_label.visible:
  var stats:Dictionary=data.get("chain_debug",{})
  dev_chain_label.text="Cadeia: solicitados %d | gerados %d | adiados %d"%[stats.get("requested",0),stats.get("generated",0),stats.get("deferred",0)]
 counts_text.text = "%d abates  |  %d ouro" % [int(data.get("kills", 0)), int(data.get("gold", 0))]
 pressure_text.text = str(data.get("pressure", "ARENA"))
 banner_text.text = str(data.get("banner", ""))
 var max_boss: float = float(data.get("boss_max", 0.0))
 true_health.visible=max_boss>0 and data.get("true_form",false)
 if true_health.visible:true_health.update_health(float(data.get("boss_hp",0)),max_boss)
 boss_bar.visible = max_boss > 0.0 and not true_health.visible
 boss_text.visible = boss_bar.visible
 if boss_bar.visible:
  boss_bar.max_value = max_boss
  boss_bar.value = float(data.get("boss_hp", 0.0))
  boss_text.text = str(data.get("boss_name", "DEMÔNIO")).to_upper()
 var passive_names: Array[String] = []
 for passive in data.get("passives", []):
  var compact_name: String = str(passive.get("name", "")).get_slice(" ", 0)
  passive_names.append("%s %d" % [compact_name, int(passive.get("level", 1))])
 passive_text.text = " / ".join(passive_names)

func _update_build_icons(data:Dictionary):
 loadout.set_build([data.get("weapons",[]),data.get("passives",[])])

func _clock(value: float) -> String:
 var seconds: int = maxi(0, int(value))
 return "%02d:%02d" % [seconds / 60, seconds % 60]

func _map_selection():
 _backdrop()
 _label(menu,"ESCOLHA O MAPA",Rect2(30,32,580,40),25,IVORY,true)
 for i in 3:
  var id:String=["courtyard","library","fields"][i]
  var names=["Pátio","Biblioteca","Campos"]
  var desc=["Pedra e pátio aberto.","Corredores largos entre estantes.","Grama, caminhos de terra e ruínas."]
  _button(menu,names[i]+" | "+desc[i],Rect2(60,100+i*60,520,46),func():game.selected_map=id;game.start_run(selected_support))
 _button(menu,"Voltar",Rect2(60,293,130,30),game.show_title)
