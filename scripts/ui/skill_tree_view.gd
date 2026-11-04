class_name SkillTreeView
extends Control

var game
var ui
var buttons: Dictionary = {}

func setup(owner_game, interface) -> void:
	game = owner_game
	ui = interface
	size = Vector2(640, 360)
	ui._label(self, "HABILIDADES PERMANENTES", Rect2(18, 14, 405, 38), 26)
	ui._label(self, "Permanente. Aplicado ao iniciar uma nova partida.", Rect2(20, 48, 400, 14), 9, ui.MUTED)
	ui._label(self, "%d OURO" % game.profile.data.gold, Rect2(430, 21, 194, 24), 16, Color("dfb969"), true)
	var branch_names := ["COMBATE", "SOBREVIVÊNCIA", "MOVIMENTO", "ESPECIALIZAÇÕES"]
	for branch in 4:
		ui._label(self, branch_names[branch], Rect2(18 + branch * 100, 64, 94, 20), 10, ui.MUTED, true)
	var lines := Node2D.new()
	add_child(lines)
	for definition in game.skills.definitions:
		var destination := point(definition)
		for prerequisite in definition.prerequisites:
			var start := point(game.skills.by_id[prerequisite])
			var edge := Line2D.new()
			if definition.id == "pact":
				edge.points = PackedVector2Array([start + Vector2(47, 0), Vector2(419, start.y), Vector2(419, destination.y), destination + Vector2(47, 0)])
			elif is_equal_approx(start.y, destination.y):
				edge.points = PackedVector2Array([start - Vector2(0, 20), Vector2(start.x, 86), Vector2(destination.x, 86), destination - Vector2(0, 20)])
			else:
				var middle: float = (start.y + destination.y) * 0.5
				edge.points = PackedVector2Array([start + Vector2(0, 20), Vector2(start.x, middle), Vector2(destination.x, middle), destination - Vector2(0, 20)])
			edge.width = 1
			edge.default_color = ui.ICE if game.skills.rank(prerequisite) > 0 else ui.LINE
			lines.add_child(edge)
	for definition in game.skills.definitions:
		var info: Dictionary = game.skills.state(definition.id)
		var level: int = game.skills.rank(definition.id)
		var position_in_tree := Vector2(18 + definition.branch * 100, 91 + definition.depth * 51)
		var button: Button = ui._button(self, "", Rect2(position_in_tree, Vector2(94, 40)), _select.bind(definition.id))
		var labels := {"locked": "Bloqueado", "unaffordable": "Sem ouro", "available": "Disponível", "owned": "Comprado", "maxed": "Máximo"}
		var color: Color = ui.ICE if level > 0 else (ui.COPPER if info.can_buy else ui.LINE)
		button.add_theme_stylebox_override("normal", ui._style(ui.PANEL, color, 2 if definition.id == ui.selected_skill else 1))
		ui._label(button, definition.title, Rect2(5, 3, 84, 23), 10, ui.IVORY if info.status != "locked" else ui.MUTED, true)
		ui._label(button, "%d/%d  %s" % [level, definition.max_rank(), labels[info.status]], Rect2(2, 27, 90, 12), 8, color, true)
		button.focus_entered.connect(_focus.bind(definition.id))
		button.gui_input.connect(_node_input.bind(definition.id, level, button))
		buttons[definition.id] = button
	for definition in game.skills.definitions:
		var button: Button = buttons[definition.id]
		for candidate in game.skills.definitions:
			if candidate.depth == definition.depth and candidate.branch == definition.branch + 1:
				button.focus_neighbor_right = buttons[candidate.id].get_path()
			if candidate.depth == definition.depth and candidate.branch == definition.branch - 1:
				button.focus_neighbor_left = buttons[candidate.id].get_path()
			if candidate.branch == definition.branch and candidate.depth == definition.depth + 1:
				button.focus_neighbor_bottom = buttons[candidate.id].get_path()
			if candidate.branch == definition.branch and candidate.depth == definition.depth - 1:
				button.focus_neighbor_top = buttons[candidate.id].get_path()
	show_details()
	ui._button(self, "Voltar", Rect2(18, 309, 394, 24), game.close_skill_tree)
	ui._label(self, game.skills.last_error if not game.skills.last_error.is_empty() else "Setas: navegar   Espaço: comprar   Esc: voltar", Rect2(18, 338, 606, 18), 10, ui.COPPER if not game.skills.last_error.is_empty() else ui.MUTED, true)
	ui.call_deferred("_grant_focus", buttons[ui.selected_skill])

func point(definition: SkillDefinition) -> Vector2:
	return Vector2(65 + definition.branch * 100, 111 + definition.depth * 51)

func _focus(id: String) -> void:
	if id != ui.selected_skill:
		call_deferred("_select", id)

func _node_input(event: InputEvent, id: String, level: int, button: Button) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_SPACE:
		button.accept_event()
		game.buy_skill(id, level)

func _select(id: String) -> void:
	if not is_inside_tree() or id == ui.selected_skill:
		return
	ui.selected_skill = id
	game.skills.last_error = ""
	ui.render("tree", game.profile.data)

func show_details() -> void:
	var definition: SkillDefinition = game.skills.by_id[ui.selected_skill]
	var info: Dictionary = game.skills.state(definition.id)
	var level: int = game.skills.rank(definition.id)
	ui._box(self, Rect2(426, 69, 198, 263))
	ui._label(self, definition.title, Rect2(438, 81, 174, 40), 16)
	var names := {"locked": "Pré-requisito pendente", "unaffordable": "Ouro insuficiente", "available": "Disponível para compra", "owned": "Comprado: %d/%d" % [level, definition.max_rank()], "maxed": "Maximizado"}
	ui._label(self, names[info.status], Rect2(438, 126, 174, 22), 11, ui.ICE)
	var effect: String = "Efeito:\n" + definition.benefits[0] if level == 0 else "Atual: " + definition.benefits[level - 1]
	if level > 0 and level < definition.max_rank():
		effect += "\n\nPróximo: " + definition.benefits[level]
	ui._label(self, effect, Rect2(438, 153, 174, 100), 11, ui.MUTED)
	var required: Array[String] = []
	for id in definition.prerequisites:
		required.append("%s %d" % [game.skills.by_id[id].title, definition.prerequisites[id]])
	ui._label(self, "Exige: " + ", ".join(required) if not required.is_empty() else "Sem pré-requisitos.", Rect2(438, 255, 174, 34), 9, ui.MUTED)
	var buy: Button = ui._button(self, "Comprar: %d ouro" % info.cost if level < definition.max_rank() else "Maximizado", Rect2(438, 294, 174, 27), game.buy_skill.bind(definition.id, level), true)
	buy.disabled = not info.can_buy
	buy.tooltip_text = info.reason
