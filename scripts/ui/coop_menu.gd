class_name CoopMenu
extends RefCounted

static func build(ui, screen: String) -> void:
	var session: CoopSession = ui.game.coop
	ui._backdrop(0.94)
	if screen == "online_pause":
		ui._label(ui.menu, "PARTIDA ONLINE", Rect2(40, 62, 560, 40), 27, ui.IVORY, true)
		ui._label(ui.menu, "A partida continua enquanto este menu está aberto.", Rect2(70, 115, 500, 42), 13, ui.MUTED, true)
		if session.actors.has(session.connection.peer_id) and session.actors[session.connection.peer_id].down and (session.actors[session.connection.peer_id].mastery.can_revive() if session.hosting else session.received_personal.get("revive_available",false)):
			ui._button(ui.menu,"Usar Reviver",Rect2(180,146,280,26),func():session.request_self_revive();session.close_menu())
		ui._button(ui.menu, "Continuar", Rect2(180, 178, 280, 34), session.close_menu, true)
		ui._button(ui.menu, "Sair da partida", Rect2(180, 229, 280, 34), session.leave)
		return
	ui._button(ui.menu,"Atualizações",Rect2(470,20,142,28),func():ui.render("updates"))
	ui._label(ui.menu, "COOPERATIVO ONLINE", Rect2(24, 19, 592, 42), 27)
	if screen == "lobby":
		ui._label(ui.menu, "SALA  " + session.connection.code, Rect2(26, 65, 420, 30), 21, ui.ICE)
		ui._button(ui.menu, "Copiar código", Rect2(463, 66, 149, 28), func(): DisplayServer.clipboard_set(session.connection.code))
		var all_ready: bool = not session.connection.players.is_empty()
		var local_ready: bool = false
		for index in session.connection.players.size():
			var member: Dictionary = session.connection.players[index]
			ui._box(ui.menu, Rect2(26, 106 + index * 30, 586, 26))
			ui._label(ui.menu, member.name + ("  (anfitrião)" if member.id == session.connection.host_id else ""), Rect2(37, 111 + index * 30, 370, 22), 13)
			ui._label(ui.menu, "Pronto" if member.ready else "Aguardando", Rect2(460, 111 + index * 30, 140, 22), 12, ui.ICE if member.ready else ui.MUTED)
			all_ready = all_ready and member.ready
			if member.id == session.connection.peer_id: local_ready = member.ready
		var map_choice:=OptionButton.new();map_choice.position=Vector2(26,228);map_choice.size=Vector2(350,24)
		for title in ["Pátio","Biblioteca","Campos"]:map_choice.add_item(title)
		map_choice.select(["courtyard","library","fields"].find(session.lobby_map));map_choice.disabled=not session.hosting
		map_choice.item_selected.connect(func(index):session.connection.send_message({"type":"map","map":["courtyard","library","fields"][index]}))
		ui.menu.add_child(map_choice)
		var challenge_choice:=OptionButton.new();challenge_choice.position=Vector2(392,228);challenge_choice.size=Vector2(220,24)
		var cap:int=session.game.skills.rank("challenge") if session.hosting else session.lobby_challenge
		for i in cap+1:challenge_choice.add_item("Desafio %d: +%d%% vida/dano/quant."%[i,i*5])
		challenge_choice.select(session.lobby_challenge);challenge_choice.disabled=not session.hosting
		challenge_choice.item_selected.connect(func(i):session.connection.send_message({"type":"challenge","value":i}));ui.menu.add_child(challenge_choice)
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
