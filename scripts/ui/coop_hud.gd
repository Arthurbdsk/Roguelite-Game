class_name CoopHUD
extends Control

var session: CoopSession

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(640, 360)

func _draw() -> void:
	if session == null or not session.active or session.ended: return
	var font: Font = ThemeDB.fallback_font
	var row: int = 0
	for id in session.actors:
		var actor: CoopActor = session.actors[id]
		var at := Vector2(12, 118 + row * 23)
		draw_rect(Rect2(at - Vector2(3, 12), Vector2(126, 21)), Color(0.04, 0.07, 0.08, 0.88))
		draw_string(font, at, actor.display_name + ("  CAÍDO" if actor.down else "  %d" % ceili(actor.player.hp)), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, actor.player.marker_color)
		draw_rect(Rect2(at + Vector2(0, 4), Vector2(118, 2)), Color("374543"))
		draw_rect(Rect2(at + Vector2(0, 4), Vector2(118 * clampf(actor.player.hp / actor.player.max_hp, 0, 1), 2)), actor.player.marker_color)
		row += 1
		if actor.down:
			var screen_at: Vector2 = actor.player.get_global_transform_with_canvas().origin
			if not Rect2(15, 25, 610, 300).has_point(screen_at):
				var center := Vector2(320, 180)
				var direction: Vector2 = (screen_at - center).normalized()
				var edge: Vector2 = center + direction * minf(294 / maxf(absf(direction.x), 0.001), 145 / maxf(absf(direction.y), 0.001))
				draw_colored_polygon(PackedVector2Array([edge + direction * 6, edge - direction * 5 + direction.orthogonal() * 4, edge - direction * 5 - direction.orthogonal() * 4]), actor.player.marker_color)
	var local: CoopActor = session.actors[session.connection.peer_id]
	var hint: String = "Caído. Aguarde um aliado." if local.down else "E: segurar para reviver    Tab: melhorias"
	var offers: Array = local.offers if session.hosting else session.received_personal.get("offers", [])
	if not offers.is_empty(): hint = "Tab: melhoria disponível" + (" após reviver" if local.down else "")
	if local.down and (local.mastery.can_revive() if session.hosting else session.received_personal.get("revive_available",false)):hint="R: usar retorno (40% de vida) ou aguarde um aliado"
	var body_id: String = session.nearby_body(local.id)
	if not body_id.is_empty() and session.actors.has(body_id): hint = "Segure E para reanimar %s (parado, %ds)" % [session.actors[body_id].display_name, ceili(session.rules.revive_seconds)]
	draw_string(font, Vector2(173, 317), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("d7c9a1"))
	for rescuer in session.revives.interactions:
		var interaction: Dictionary = session.revives.interactions[rescuer]
		if not session.actors.has(interaction.target): continue
		var body: Sentinel = session.actors[interaction.target].player
		var at: Vector2 = body.get_global_transform_with_canvas().origin + Vector2(-19, 12)
		draw_rect(Rect2(at, Vector2(38, 4)), Color("11191c"))
		draw_rect(Rect2(at, Vector2(38 * interaction.progress / session.rules.revive_seconds, 4)), Color("83c4bd"))
		draw_string(font, at + Vector2(-16, 16), "%s  %.1fs" % [session.actors[interaction.target].display_name, maxf(0, session.rules.revive_seconds - interaction.progress)], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("d7c9a1"))
