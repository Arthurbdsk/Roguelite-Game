class_name GoldLoot
extends Node2D

var game
var coins: Array[Dictionary] = []
var feedback: Array[Dictionary] = []
var serial: int = 0
var texture: Texture2D
var expired_count: int = 0
var collected_count: int = 0

func setup(owner_game) -> void:
	game = owner_game
	texture = load("res://assets/gold.png")
	z_index = 3

func reset() -> void:
	coins.clear()
	feedback.clear()
	expired_count = 0
	collected_count = 0
	queue_redraw()

func drop(at: Vector2, value: int = 1) -> int:
	serial += 1
	coins.append({"id": serial, "at": at, "age": 0.0, "value": maxi(1, value) * maxi(1, game.balance.coin_value), "attracted": false})
	queue_redraw()
	return serial

func tick(delta: float) -> void:
	if game.state != "running":
		return
	var attraction: float = game.balance.coin_attraction_radius + maxf(0, game.player.pickup_radius - 42.0)
	for i in range(coins.size() - 1, -1, -1):
		var coin: Dictionary = coins[i]
		coin.age += delta
		# Expiration precedes attraction and arrival. Expired value is never banked.
		if coin.age >= game.balance.coin_lifetime:
			coins.remove_at(i)
			expired_count += 1
			continue
		if coin.at.distance_squared_to(game.player.position) <= attraction * attraction:
			coin.attracted = true
		if coin.attracted:
			coin.at = coin.at.move_toward(game.player.position, game.balance.coin_collect_speed * delta)
		if coin.at.distance_squared_to(game.player.position) <= pow(game.balance.coin_arrival_radius, 2):
			var amount: int = coin.value
			coins.remove_at(i)
			game.gold += amount
			collected_count += 1
			if feedback.size() < 12:
				feedback.append({"at": game.player.position - Vector2(0, 26), "life": 0.55, "amount": amount})
			game.sound.play_cue("gold")
	for effect in feedback:
		effect.life -= delta
		effect.at.y -= delta * 13
	feedback = feedback.filter(func(effect): return effect.life > 0)
	queue_redraw()

func _draw() -> void:
	if game == null or game.state in ["title", "hub"]:
		return
	for coin in coins:
		if coin.age > game.balance.coin_lifetime - 5 and int(coin.age * 6) % 2 == 0:
			continue
		var frame: int = int(coin.age * 6) % 4
		draw_texture_rect_region(texture, Rect2(coin.at.round() - Vector2(4, 6), Vector2(8, 8)), Rect2(frame * 8, 0, 8, 8))
	for effect in feedback:
		draw_string(ThemeDB.fallback_font, effect.at, "+%d" % effect.amount, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("dfb969"))
