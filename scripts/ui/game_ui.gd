class_name GameUI
extends CanvasLayer

const INK := Color("11191c")
const PANEL := Color("1a2428")
const LINE := Color("46504c")
const IVORY := Color("d7c9a1")
const MUTED := Color("8d9b95")
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
var boss_bar: ProgressBar
var life_text: Label
var time_text: Label
var level_text: Label
var counts_text: Label
var pressure_text: Label
var banner_text: Label
var boss_text: Label
var loadout: HBoxContainer
var passive_text: Label
var ui_theme: Theme
var last_loadout: String = ""
var previous_data: Dictionary = {}

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
	if ResourceLoader.exists("res://assets/font.ttf"):
		ui_theme.default_font = load("res://assets/font.ttf")
	ui_theme.set_color("font_color", "Label", IVORY)
	ui_theme.set_color("font_color", "Button", IVORY)
	ui_theme.set_color("font_hover_color", "Button", Color("f0e6c8"))
	ui_theme.set_color("font_focus_color", "Button", Color("f0e6c8"))
	ui_theme.set_color("font_disabled_color", "Button", Color("60706c"))
	ui_theme.set_stylebox("normal", "Button", _style(PANEL, LINE))
	ui_theme.set_stylebox("hover", "Button", _style(Color("2d393b"), ICE))
	ui_theme.set_stylebox("pressed", "Button", _style(Color("374543"), IVORY))
	ui_theme.set_stylebox("focus", "Button", _style(Color(0, 0, 0, 0), IVORY, 2))
	ui_theme.set_stylebox("disabled", "Button", _style(Color("151e22"), Color("303c3c")))
	ui_theme.set_stylebox("background", "ProgressBar", _bar_style(Color("0c1216"), Color("45514d"), 1))
	ui_theme.set_stylebox("fill", "ProgressBar", _bar_style(ICE, ICE))
	ui_theme.set_stylebox("panel", "Panel", _style(PANEL, LINE))
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
	label.text = text
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
	label.size = rect.size
	return label

func _grant_focus(control: Control) -> void:
	if is_instance_valid(control) and control.is_inside_tree():
		control.grab_focus()

func _button(parent: Node, text: String, rect: Rect2, action: Callable, primary: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.position = rect.position
	b.size = rect.size
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(action)
	b.focus_entered.connect(_focus_sound)
	if primary:
		b.add_theme_stylebox_override("normal", _style(Color("623e32"), COPPER))
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
	screen = which
	previous_data = data.duplicate(true)
	for child in menu.get_children():
		menu.remove_child(child)
		child.queue_free()
	menu.visible = which != "running"
	hud.visible = which in ["running", "paused", "upgrading", "result"]
	match which:
		"title": _title()
		"hub": _hub(data)
		"upgrading": _upgrades(data)
		"paused": _paused()
		"settings": _settings()
		"result": _result(data)

func _title() -> void:
	_backdrop()
	if ResourceLoader.exists("res://assets/fortress.png"):
		var castle := TextureRect.new()
		castle.texture = load("res://assets/fortress.png")
		castle.position = Vector2(304, 53)
		castle.size = Vector2(320, 200)
		castle.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		castle.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		castle.modulate = Color("b2c7bc")
		castle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		menu.add_child(castle)
	_label(menu, "BRASAFRIA", Rect2(32, 45, 576, 58), 45)
	_label(menu, "A muralha caiu.\nA vigília continua.", Rect2(34, 111, 265, 48), 15, MUTED)
	var play := _button(menu, "Jogar", Rect2(34, 185, 205, 31), func(): game.start_run(), true)
	_button(menu, "Fortaleza", Rect2(34, 223, 205, 29), func(): game.enter_hub())
	_button(menu, "Opções", Rect2(34, 259, 97, 27), func(): _open_settings("title"))
	_button(menu, "Sair", Rect2(140, 259, 99, 27), func(): get_tree().quit())
	_label(menu, "WASD / setas: mover    Esc: pausa\nAtaques automáticos.\nDerrote o rei e resista por 10 min.", Rect2(320, 259, 287, 51), 11, MUTED)
	_footer()
	call_deferred("_grant_focus", play)

func _footer() -> void:
	var rule := ColorRect.new()
	rule.color = LINE
	rule.position = Vector2(24, 321)
	rule.size = Vector2(592, 1)
	menu.add_child(rule)
	_link(menu, "Feito por Socialy", Vector2(26, 334), func(): OS.shell_open("https://www.instagram.com/socialy_webdesign/"))
	_link(menu, "Privacidade", Vector2(432, 334), func(): _legal("privacy"))
	_link(menu, "Termos", Vector2(541, 334), func(): _legal("terms"))

func _hub(data: Dictionary) -> void:
	_backdrop()
	var p: Dictionary = data
	if p.is_empty() and game.profile != null:
		p = game.profile.data
	var buildings: Dictionary = p.get("buildings", {})
	if selected_support != "none" and not bool(buildings.get(selected_support, false)):
		selected_support = "none"
	_label(menu, "A FORTALEZA", Rect2(24, 14, 420, 38), 28)
	_label(menu, "%d SELOS" % int(p.get("seals", 0)), Rect2(477, 22, 140, 24), 16, ICE)
	_label(menu, "Construções e selos permanecem após a morte.", Rect2(25, 55, 590, 20), 12, MUTED)
	_building_card("arsenal", "ARSENAL", "Virote inicial.\nBrasas atacam 15% mais devagar.", bool(buildings.get("arsenal", false)), Vector2(25, 84))
	_building_card("library", "BIBLIOTECA", "Brasas iniciais.\nVirotes atacam 15% mais devagar.", bool(buildings.get("library", false)), Vector2(331, 84))
	_label(menu, "Apoio da próxima expedição", Rect2(25, 207, 590, 20), 14)
	var none := _button(menu, _choice("none", "Sem apoio"), Rect2(25, 235, 188, 30), func(): _select_support("none"))
	var arsenal := _button(menu, _choice("arsenal", "Arsenal"), Rect2(225, 235, 188, 30), func(): _select_support("arsenal"))
	arsenal.disabled = not bool(buildings.get("arsenal", false))
	var library := _button(menu, _choice("library", "Biblioteca"), Rect2(425, 235, 188, 30), func(): _select_support("library"))
	library.disabled = not bool(buildings.get("library", false))
	_label(menu, "Armas, níveis e passivas da partida são temporários.", Rect2(25, 274, 380, 24), 11, MUTED)
	_button(menu, "Voltar", Rect2(25, 292, 105, 24), func(): game.show_title())
	_button(menu, "Partir", Rect2(425, 278, 188, 35), func(): game.start_run(selected_support), true)
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
		var b := _button(menu, "Restaurar: 8 selos", Rect2(pos + Vector2(12, 79), Vector2(258, 25)), func():
			game.buy_building(id)
			render("hub", game.profile.data))
		b.disabled = int(game.profile.data.get("seals", 0)) < 8

func _upgrades(data: Dictionary) -> void:
	_backdrop(0.94)
	_label(menu, "A CHAMA CRESCE", Rect2(20, 32, 600, 38), 27, IVORY, true)
	_label(menu, "Escolha uma melhoria temporária", Rect2(20, 78, 600, 24), 12, MUTED, true)
	var offers: Array = data.get("offers", [])
	for i in range(mini(3, offers.size())):
		var offer: Dictionary = offers[i]
		var id: String = str(offer.get("id", ""))
		var pos := Vector2(20 + i * 204, 111)
		var button := _button(menu, "", Rect2(pos, Vector2(192, 198)), func(): game.choose_upgrade(id))
		var icon_path: String = str(offer.get("icon", ""))
		if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
			var icon := TextureRect.new()
			icon.texture = load(icon_path)
			icon.position = Vector2(12, 14)
			icon.size = Vector2(24, 24)
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(icon)
		_label(button, str(i + 1), Rect2(158, 10, 23, 20), 14, ICE, true)
		_label(button, str(offer.get("name", "Melhoria")), Rect2(12, 45, 168, 34), 15)
		_label(button, str(offer.get("description", "")), Rect2(12, 83, 168, 50), 11, MUTED)
		var detail: String = str(offer.get("detail", "")).replace(" · Só nesta expedição.", ".")
		_label(button, detail, Rect2(12, 141, 168, 48), 10, ICE)
		if i == 0:
			call_deferred("_grant_focus", button)
	_label(menu, "1 / 2 / 3 ou selecione com o controle e confirme", Rect2(20, 319, 600, 20), 11, MUTED, true)

func _paused() -> void:
	_backdrop(0.91)
	_label(menu, "VIGÍLIA SUSPENSA", Rect2(20, 49, 600, 42), 28, IVORY, true)
	var resume := _button(menu, "Continuar", Rect2(210, 116, 220, 31), func(): game.toggle_pause(), true)
	_button(menu, "Reiniciar expedição", Rect2(210, 155, 220, 30), func(): game.retry())
	_button(menu, "Opções", Rect2(210, 193, 220, 30), func(): _open_settings("paused"))
	_button(menu, "Retornar à fortaleza", Rect2(210, 231, 220, 30), func(): game.abandon())
	_label(menu, "Esc ou Start para continuar", Rect2(20, 289, 600, 22), 11, MUTED, true)
	call_deferred("_grant_focus", resume)

func _open_settings(from: String) -> void:
	return_screen = from
	render("settings")

func _settings() -> void:
	_backdrop()
	_label(menu, "OPÇÕES", Rect2(28, 23, 584, 40), 29)
	var settings: Dictionary = game.profile.data.get("settings", {})
	_label(menu, "Volume", Rect2(65, 98, 180, 22), 14)
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
	_label(menu, "A AURORA RESISTE" if won else "A VIGÍLIA TERMINOU", Rect2(24, 35, 592, 43), 28, ICE if won else IVORY, true)
	_label(menu, "O pátio voltou às suas mãos." if won else "As muralhas lembram de cada tentativa.", Rect2(24, 87, 592, 24), 12, MUTED, true)
	_box(menu, Rect2(130, 128, 380, 112))
	_label(menu, "TEMPO\n" + _clock(float(data.get("elapsed", 0.0))), Rect2(146, 143, 170, 37), 13)
	_label(menu, "ABATES\n%d" % int(data.get("kills", 0)), Rect2(335, 143, 150, 37), 13)
	_label(menu, "NÍVEL\n%d" % int(data.get("level", 1)), Rect2(146, 191, 170, 37), 13)
	_label(menu, "SELOS MANTIDOS\n+%d" % int(data.get("earned", 0)), Rect2(335, 191, 160, 37), 13, ICE)
	var again := _button(menu, "Tentar novamente", Rect2(130, 268, 182, 34), func(): game.retry(), true)
	_button(menu, "Fortaleza", Rect2(326, 268, 184, 34), func(): game.enter_hub())
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
		content = "Brasafria é um protótipo local e não exige conta. O jogo não envia dados, não possui anúncios e não utiliza serviços de análise.\n\nProgresso e preferências ficam apenas no arquivo de salvamento da Godot no seu computador. Os dados incluem selos, construções, estatísticas e opções.\n\nO link Socialy abre o Instagram no navegador. Ao acessá-lo, aplicam-se as regras e a política do Instagram."
	else:
		content = "Este protótipo é fornecido para teste e avaliação pessoal. Sistemas, arte e balanceamento podem mudar durante a produção.\n\nO progresso é salvo localmente. Mantenha uma cópia do arquivo antes de substituí-lo por versões novas.\n\nO jogo não oferece compras, conta online ou serviços pagos. A autoria e as licenças dos componentes estão documentadas no projeto."
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
	life_text = _label(hud, "VIDA", Rect2(17, 14, 151, 15), 10)
	life_bar = _bar(hud, Rect2(17, 33, 151, 7), COPPER)
	time_text = _label(hud, "00:00", Rect2(263, 11, 114, 31), 24, IVORY, true)
	pressure_text = _label(hud, "PÁTIO ESQUECIDO", Rect2(452, 12, 176, 18), 11, MUTED)
	pressure_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	counts_text = _label(hud, "", Rect2(452, 31, 176, 18), 11, IVORY)
	counts_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	loadout = HBoxContainer.new()
	loadout.position = Vector2(11, 57)
	loadout.size = Vector2(180, 26)
	loadout.add_theme_constant_override("separation", 5)
	loadout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(loadout)
	passive_text = _label(hud, "", Rect2(12, 87, 220, 20), 10, MUTED)
	banner_text = _label(hud, "", Rect2(140, 70, 360, 38), 17, IVORY, true)
	boss_text = _label(hud, "", Rect2(162, 300, 316, 18), 11, IVORY, true)
	boss_bar = _bar(hud, Rect2(162, 321, 316, 6), COPPER)
	level_text = _label(hud, "NÍVEL 1", Rect2(12, 322, 130, 16), 10, ICE)
	_label(hud, "ESC: PAUSA", Rect2(520, 322, 108, 16), 10, MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	experience_bar = _bar(hud, Rect2(12, 343, 616, 5), ICE)

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
	life_bar.max_value = maxf(1.0, float(data.get("max_hp", 100.0)))
	life_bar.value = float(data.get("hp", 100.0))
	life_text.text = "VIDA   %d / %d" % [int(data.get("hp", 100)), int(life_bar.max_value)]
	experience_bar.max_value = maxf(1.0, float(data.get("xp_needed", 10.0)))
	experience_bar.value = float(data.get("xp", 0))
	level_text.text = "NÍVEL %d" % int(data.get("level", 1))
	time_text.text = _clock(float(data.get("elapsed", 0.0)))
	counts_text.text = "%d abates  |  %d selos" % [int(data.get("kills", 0)), int(data.get("earned", 0))]
	pressure_text.text = str(data.get("pressure", "PÁTIO ESQUECIDO"))
	banner_text.text = str(data.get("banner", ""))
	var max_boss: float = float(data.get("boss_max", 0.0))
	boss_bar.visible = max_boss > 0.0
	boss_text.visible = boss_bar.visible
	if boss_bar.visible:
		boss_bar.max_value = max_boss
		boss_bar.value = float(data.get("boss_hp", 0.0))
		boss_text.text = "O REI SEM BRASA"
	var weapons: Array = data.get("weapons", [])
	var serialized: String = JSON.stringify(weapons)
	if serialized != last_loadout:
		last_loadout = serialized
		for c in loadout.get_children():
			loadout.remove_child(c)
			c.queue_free()
		for weapon in weapons:
			if int(weapon.get("level", 0)) <= 0:
				continue
			var slot := Panel.new()
			slot.custom_minimum_size = Vector2(45, 27)
			slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			loadout.add_child(slot)
			var icon_path: String = str(weapon.get("icon", ""))
			if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
				var icon := TextureRect.new()
				icon.texture = load(icon_path)
				icon.position = Vector2(4, 5)
				icon.size = Vector2(16, 16)
				icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
				slot.add_child(icon)
			_label(slot, str(weapon.get("level", 1)), Rect2(26, 4, 16, 20), 11, IVORY, true)
	var passive_names: Array[String] = []
	for passive in data.get("passives", []):
		var compact_name: String = str(passive.get("name", "")).get_slice(" ", 0)
		passive_names.append("%s %d" % [compact_name, int(passive.get("level", 1))])
	passive_text.text = " / ".join(passive_names)

func _clock(value: float) -> String:
	var seconds: int = maxi(0, int(value))
	return "%02d:%02d" % [seconds / 60, seconds % 60]
