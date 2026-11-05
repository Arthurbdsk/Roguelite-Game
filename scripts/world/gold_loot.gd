class_name GoldLoot
extends Node2D

var death_rng:=RandomNumberGenerator.new()
var death_rolls:int=0
var death_drops:int=0
var game
var coins: Array[Dictionary] = []
var feedback: Array[Dictionary] = []
var serial: int = 0
var texture: Texture2D
var expired_count: int = 0
var collected_count: int = 0

func setup(owner_game) -> void:
	death_rng.randomize()
	game = owner_game
	texture = load("res://assets/effects/coin.png")
	z_index = 3

func reset() -> void:
	coins.clear()
	death_rolls=0;death_drops=0
	feedback.clear()
	expired_count = 0
	collected_count = 0
	queue_redraw()

func roll_death(at:Vector2)->bool:
	if game.coop.active and not game.coop.hosting:return false
	death_rolls+=1
	if death_rng.randf()>=clampf(game.balance.gold_drop_chance,0,1):return false
	death_drops+=1;drop(at,game.balance.gold_drop_value);return true

func drop(at: Vector2, value: int = 1) -> int:
	at=game.arena.loot_point(at)
	serial += 1
	coins.append({"id": serial, "at": at, "age": 0.0, "value": maxi(1, value) * maxi(1, game.balance.coin_value), "attracted": false})
	queue_redraw()
	return serial

func tick(delta: float) -> void:
	if game.state != "running":
		return
	var bounds:Rect2=game.collection_bounds(true)
	var attraction: float = game.player.gold_collection_radius()
	var collected_value: int = 0
	var collected_at: Vector2 = game.player.position
	for i in range(coins.size() - 1, -1, -1):
		var coin: Dictionary = coins[i]
		coin.age += delta
		# Expiration precedes attraction and arrival. Expired value is never banked.
		if coin.age >= game.balance.coin_lifetime:
			coins.remove_at(i)
			expired_count += 1
			continue
		if not coin.get("attracted",false) and not bounds.has_point(coin.at):continue
		var collector = game.collection_player(coin.at)
		if collector == null: continue
		attraction = collector.gold_collection_radius()
		if coin.at.distance_squared_to(collector.position) <= attraction * attraction:
			coin.attracted = true
		if coin.attracted:
			coin.at = coin.at.move_toward(collector.position, game.balance.coin_collect_speed * collector.game.mastery.coin_speed_multiplier() * delta)
		if coin.at.distance_squared_to(collector.position) <= pow(game.balance.coin_arrival_radius, 2):
			var amount: int = coin.value
			coins.remove_at(i)
			game.gold += amount
			if game.coop != null and game.coop.active:
				game.coop.on_gold(amount,coin.get("bonus_eligible",true))
				collected_value += amount
				collected_at = collector.position
			else:
				var before_bonus:int=game.mastery.gold_bonus
				if coin.get("bonus_eligible",true):game.mastery.on_gold(amount)
				game.gold+=game.mastery.gold_bonus-before_bonus
			collected_count += 1
			if feedback.size() < 12:
				feedback.append({"at": collector.position - Vector2(0, 26), "life": 0.55, "amount": amount})
			game.sound.play_cue("gold")
	if collected_value > 0:
		game.coop.publish({"type": "gold_pickup", "at": collected_at, "amount": collected_value})
	for effect in feedback:
		effect.life -= delta
		effect.at.y -= delta * 13
	feedback = feedback.filter(func(effect): return effect.life > 0)
	queue_redraw()

func _draw() -> void:
	if game == null or game.state in ["title", "hub"]:
		return
	var visible:Rect2=game.render_rect().grow(20)
	for coin in coins:
		if not visible.has_point(coin.at):continue
		if coin.age > game.balance.coin_lifetime - 5 and int(coin.age * 6) % 2 == 0:
			continue
		var frame: int = int(coin.age * 10) % 8
		draw_texture_rect_region(texture, Rect2(coin.at.round() - Vector2(8, 9), Vector2(16, 16)), Rect2(frame * 16, 0, 16, 16))
	for effect in feedback:
		draw_string(GameFonts.interface_font(), effect.at, "+%d" % effect.amount, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("dfb969"))

func refund(at:Vector2,amount:int):
	at=game.arena.loot_point(at)
	serial+=1
	coins.append({"id":serial,"at":at,"age":0.0,"value":amount,"attracted":false,"protected":true,"bonus_eligible":false})
