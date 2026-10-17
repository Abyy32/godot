extends Node2D
class_name ArenaStage

export var arena_id = "forest_shrine"
var ground_body: StaticBody2D

func _ready() -> void:
	var data: Dictionary = GameSession.arena_by_id(arena_id)
	ground_body = StaticBody2D.new()
	ground_body.collision_layer = 1
	ground_body.collision_mask = 1
	ground_body.position = Vector2((data.left_bound + data.right_bound) * 0.5, 551)
	var collision = CollisionShape2D.new()
	var floor = RectangleShape2D.new()
	floor.size = Vector2(data.right_bound - data.left_bound, 32)
	collision.shape = floor
	ground_body.add_child(collision)
	add_child(ground_body)

func _draw() -> void:
	var data: Dictionary = GameSession.arena_by_id(arena_id)
	var accent: Color = data.accent
	draw_rect(Rect2(0, 0, 1280, 720), data.color)
	match arena_id:
		"forest_shrine":
			_draw_forest(accent)
		"training_dojo":
			_draw_dojo(accent)
		"ruined_outpost":
			_draw_outpost(accent)
	_draw_ground(accent, data.left_bound, data.right_bound)

func _draw_forest(accent: Color) -> void:
	draw_circle(Vector2(1010, 125), 46, Color("#d7e7ff"))
	draw_circle(Vector2(1024, 117), 42, Color("#101a36"))
	var hills = PoolVector2Array([Vector2(0, 440), Vector2(145, 320), Vector2(290, 415), Vector2(455, 286), Vector2(620, 420), Vector2(815, 310), Vector2(1010, 420), Vector2(1175, 300), Vector2(1280, 390), Vector2(1280, 550), Vector2(0, 550)])
	draw_colored_polygon(hills, Color("#1a2a49"))
	for x in [95.0, 185.0, 1095.0, 1185.0]:
		draw_rect(Rect2(x, 330, 16, 205), Color("#0a1426"))
		draw_colored_polygon(PoolVector2Array([Vector2(x - 62, 350), Vector2(x + 8, 270), Vector2(x + 86, 350)]), Color("#18352f"))
	_draw_torii(Vector2(640, 445), accent)

func _draw_torii(origin: Vector2, color: Color) -> void:
	draw_rect(Rect2(origin.x - 76, origin.y - 150, 18, 155), color.darkened(0.35))
	draw_rect(Rect2(origin.x + 58, origin.y - 150, 18, 155), color.darkened(0.35))
	draw_rect(Rect2(origin.x - 105, origin.y - 164, 210, 17), color)
	draw_rect(Rect2(origin.x - 82, origin.y - 184, 164, 12), color.lightened(0.1))

func _draw_dojo(accent: Color) -> void:
	draw_rect(Rect2(0, 130, 1280, 400), Color("#2b2630"))
	draw_rect(Rect2(0, 150, 1280, 16), accent.darkened(0.3))
	for x in [120.0, 360.0, 600.0, 840.0, 1080.0]:
		draw_rect(Rect2(x, 145, 18, 390), Color("#573c30"))
		draw_rect(Rect2(x + 34, 205, 128, 190), Color("#8b7760"))
		draw_rect(Rect2(x + 43, 214, 110, 172), Color("#323a47"))
		draw_line(Vector2(x + 98, 214), Vector2(x + 98, 386), Color("#aa9275"), 4)
		draw_line(Vector2(x + 43, 300), Vector2(x + 153, 300), Color("#aa9275"), 4)
	draw_rect(Rect2(0, 510, 1280, 25), accent.darkened(0.2))

func _draw_outpost(accent: Color) -> void:
	draw_circle(Vector2(1030, 145), 52, Color("#e5a277"))
	var skyline = PoolVector2Array([Vector2(0, 435), Vector2(95, 435), Vector2(95, 345), Vector2(220, 345), Vector2(220, 400), Vector2(380, 400), Vector2(380, 300), Vector2(510, 300), Vector2(510, 430), Vector2(720, 430), Vector2(720, 350), Vector2(910, 350), Vector2(910, 425), Vector2(1080, 425), Vector2(1080, 325), Vector2(1240, 325), Vector2(1240, 450), Vector2(1280, 450), Vector2(1280, 550), Vector2(0, 550)])
	draw_colored_polygon(skyline, Color("#3b2934"))
	for x in [142.0, 432.0, 762.0, 1135.0]:
		draw_rect(Rect2(x, 373, 10, 24), accent.lightened(0.18))
		draw_colored_polygon(PoolVector2Array([Vector2(x - 34, 505), Vector2(x + 3, 465), Vector2(x + 45, 505)]), Color("#594047"))

func _draw_ground(accent: Color, left_bound: float, right_bound: float) -> void:
	draw_rect(Rect2(0, 535, 1280, 185), Color("#202b3a"))
	draw_rect(Rect2(left_bound, 535, right_bound - left_bound, 5), accent.lightened(0.35))
	for x in [left_bound, right_bound - 12.0]:
		draw_rect(Rect2(x, 510, 12, 60), accent.darkened(0.15))
