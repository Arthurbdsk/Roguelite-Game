class_name RuinedArena
extends Node2D

var obstacles: Array[Rect2] = []
var decorations: Array[Dictionary] = []
var tiles: Texture2D
var pillar: Texture2D
var grave: Texture2D
var brazier: Texture2D
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 81391
	tiles = load("res://assets/tiles.png")
	pillar = load("res://assets/pillar.png")
	grave = load("res://assets/grave.png")
	brazier = load("res://assets/brazier.png")
	for point in [Vector2(700, 470), Vector2(1100, 470), Vector2(700, 790), Vector2(1100, 790), Vector2(400, 620), Vector2(1400, 620), Vector2(900, 260), Vector2(900, 1000)]:
		add_obstacle(Rect2(point - Vector2(12, 8), Vector2(24, 16)))
		decorations.append({"at": point, "kind": "pillar"})
	for point in [Vector2(600, 325), Vector2(1200, 325), Vector2(600, 950), Vector2(1200, 950)]:
		decorations.append({"at": point, "kind": "brazier"})
	for i in 45:
		var point := Vector2(rng.randi_range(90, 1710), rng.randi_range(90, 1110))
		if point.distance_to(Vector2(900, 620)) > 140:
			decorations.append({"at": point, "kind": "grave"})
	for rect in [Rect2(0, 0, 1800, 24), Rect2(0, 1176, 1800, 24), Rect2(0, 0, 24, 1200), Rect2(1776, 0, 24, 1200)]:
		add_obstacle(rect)
	queue_redraw()

func add_obstacle(rect: Rect2) -> void:
	obstacles.append(rect)
	var wall := StaticBody2D.new()
	wall.position = rect.get_center()
	wall.collision_layer = 4
	wall.collision_mask = 0
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	wall.add_child(shape)
	add_child(wall)

func safe_position(point: Vector2, radius: float = 12.0) -> bool:
	if not Rect2(40, 45, 1720, 1110).has_point(point):
		return false
	for rect in obstacles:
		if rect.grow(radius).has_point(point):
			return false
	return true

func _draw() -> void:
	rng.seed = 4917
	draw_rect(Rect2(0, 0, 1800, 1200), Color("1b2528"))
	if tiles:
		for x in 57:
			for y in 38:
				var index := rng.randi_range(0, 15)
				draw_texture_rect_region(tiles, Rect2(x * 32, y * 32, 32, 32), Rect2((index % 4) * 32, (index / 4) * 32, 32, 32))
	# Fractured courtyard avenues, kept dimmer than every combat silhouette.
	for x in range(795, 1010, 32):
		for y in range(30, 1170, 32):
			draw_rect(Rect2(x, y, 30, 30), Color(0.28, 0.31, 0.29, 0.14))
	for y in range(548, 710, 32):
		for x in range(32, 1770, 32):
			draw_rect(Rect2(x, y, 30, 30), Color(0.28, 0.31, 0.29, 0.14))
	for r in [96, 100, 112]:
		draw_arc(Vector2(900, 630), r, 0, TAU, 64, Color("465146"), 1, false)
	for i in 8:
		var point := Vector2(900, 630) + Vector2.from_angle(i * TAU / 8) * 105
		draw_rect(Rect2(point - Vector2(2, 2), Vector2(4, 4)), Color("7c7153"))
	decorations.sort_custom(func(a, b): return a.at.y < b.at.y)
	for item in decorations:
		var texture: Texture2D = pillar if item.kind == "pillar" else (brazier if item.kind == "brazier" else grave)
		if texture:
			draw_texture(texture, item.at - Vector2(texture.get_width() * 0.5, texture.get_height() - 5))
	for edge in [Rect2(0, 0, 1800, 25), Rect2(0, 1175, 1800, 25), Rect2(0, 0, 25, 1200), Rect2(1775, 0, 25, 1200)]:
		draw_rect(edge, Color("101719"))
