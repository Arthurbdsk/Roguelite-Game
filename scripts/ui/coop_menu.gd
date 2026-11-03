class_name CoopMenu
extends RefCounted

static func build(ui, screen: String) -> void:
	var session: CoopSession = ui.game.coop
	ui._backdrop(0.94)
	if screen == "online_pause":
		ui._label(ui.menu, "PARTIDA ONLINE", Rect2(40, 62, 560, 40), 27, ui.IVORY, true)
		ui._label(ui.menu, "A partida continua enquanto este menu está aberto.", Rect2(70, 115, 500, 42), 13, ui.MUTED, true)
		ui._button(ui.menu, "Continuar", Rect2(180, 178, 280, 34), session.close_menu, true)
		ui._button(ui.menu, "Sair da partida", Rect2(180, 229, 280, 34), session.leave)
		return
	ui._label(ui.menu, "VIGÍLIA COOPERATIVA", Rect2(24, 19, 592, 42), 27)
	if screen == "lobby":
		ui._label(ui.menu, "SALA  " + session.connection.code, Rect2(26, 65, 420, 30), 21, ui.ICE)
		ui._button(ui.menu, "Copiar código", Rect2(463, 66, 149, 28), func(): DisplayServer.clipboard_set(session.connection.code))
		var all_ready: bool = not session.connection.players.is_empty()
		var local_ready: bool = false
		for index in session.connection.players.size():
			var member: Dictionary = session.connection.players[index]
			ui._box(ui.menu, Rect2(26, 106 + index * 34, 586, 30))
			ui._label(ui.menu, member.name + ("  (anfitrião)" if member.id == session.connection.host_id else ""), Rect2(37, 111 + index * 34, 370, 22), 13)
			ui._label(ui.menu, "Pronto" if member.ready else "Aguardando", Rect2(460, 111 + index * 34, 140, 22), 12, ui.ICE if member.ready else ui.MUTED)
			all_ready = all_ready and member.ready
			if member.id == session.connection.peer_id: local_ready = member.ready
		ui._button(ui.menu, "Cancelar prontidão" if local_ready else "Estou pronto", Rect2(26, 260, 215, 32), func(): session.connection.send_message({"type": "ready", "ready": not local_ready}), true)
		if session.hosting:
			var start: Button = ui._button(ui.menu, "Iniciar partida", Rect2(256, 260, 215, 32), func(): session.connection.send_message({"type": "start"}))
			start.disabled = not all_ready
		ui._button(ui.menu, "Sair", Rect2(486, 260, 126, 32), session.leave)
	else:
		ui._label(ui.menu, "Até quatro jogadores. Todos precisam estar prontos.", Rect2(26, 66, 585, 24), 12, ui.MUTED)
		ui._label(ui.menu, "Seu nome", Rect2(26, 110, 260, 23), 13)
		var name_input := LineEdit.new()
		name_input.position = Vector2(26, 140)
		name_input.size = Vector2(270, 33)
		name_input.placeholder_text = "1 a 8 caracteres"
		name_input.text = session.local_name
		name_input.max_length = 24
		ui.menu.add_child(name_input)
		name_input.text_changed.connect(func(value): session.local_name = value)
		ui._label(ui.menu, "Código da sala", Rect2(337, 110, 275, 23), 13)
		var code_input := LineEdit.new()
		code_input.position = Vector2(337, 140)
		code_input.size = Vector2(275, 33)
		code_input.placeholder_text = "ABC123"
		code_input.max_length = 6
		ui.menu.add_child(code_input)
		ui._button(ui.menu, "Criar sala", Rect2(26, 193, 270, 34), func(): session.connect_room(true, name_input.text), true)
		ui._button(ui.menu, "Entrar por código", Rect2(337, 193, 275, 34), func(): session.connect_room(false, name_input.text, code_input.text))
		ui._button(ui.menu, "Voltar", Rect2(26, 275, 130, 28), session.leave)
	ui._label(ui.menu, session.message, Rect2(26, 298, 586, 23), 11, ui.COPPER)
	ui._footer()
