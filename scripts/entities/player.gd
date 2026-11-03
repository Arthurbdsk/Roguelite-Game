class_name Sentinel
extends CharacterBody2D

var game
var hp: float = 100.0
var max_hp: float = 100.0
var speed: float = 96.0
var pickup_radius: float = 42.0
var armor: float = 0.0
var radius: float = 7.0
var facing: Vector2 = Vector2.DOWN
var invulnerable: float = 0.0
var animation: float = 0.0
var sprite: Sprite2D
var movement_multiplier: float = 1.0
var time_since_damage: float = 0.0

func _ready() -> void:
	collision_layer = 1
	collision_mask = 4
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/player.png")
	sprite.hframes = 4
	sprite.position.y = -12
	add_child(sprite)

func tick(delta: float, movement: Vector2) -> void:
	invulnerable = maxf(0.0, invulnerable - delta)
	time_since_damage += delta
	velocity = movement.limit_length() * speed * movement_multiplier
	if movement.length_squared() > 0.01:
		facing = movement.normalized()
		animation += delta * 9
		if absf(movement.x) > 0.05:
			sprite.flip_h = movement.x < 0
	else:
		animation = 0
	sprite.frame = int(animation) % 4
	sprite.modulate = Color(1, 0.55, 0.45) if invulnerable > 0.0 and fmod(invulnerable, 0.16) > 0.08 else Color.WHITE
	move_and_slide()
	position = position.clamp(Vector2(35, 45), Vector2(1765, 1165))
	queue_redraw()

func take_damage(amount: float, source: Vector2) -> bool:
	if invulnerable > 0 or hp <= 0 or game.state != "running":
		return false
	hp = maxf(0, hp - maxf(1, amount - armor))
	time_since_damage = 0
	invulnerable = 0.85
	game.shake_time = 0.16
	game.sound.play_cue("hurt")
	var direction := (position - source).normalized()
	move_and_collide(direction * 5)
	if hp <= 0:
		if not game.mastery.save_from_death():
			game.finish_run(false)
	return true

func _draw() -> void:
	draw_ellipse_shadow()
	# Cold pixels under the sentinel keep them visible in a dense crowd.
	draw_arc(Vector2(0, 1), 10, 0, TAU, 16, Color("83c4bd"), 1, false)

func draw_ellipse_shadow() -> void:
	draw_rect(Rect2(-8, -1, 16, 5), Color(0, 0, 0, 0.35))
