extends Control
class_name ArenaPreview

var arena_id = "forest_shrine"

func _ready() -> void:
	update()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		update()

func _draw() -> void:
	var preview_size = rect_size
	if preview_size.x <= 0.0 or preview_size.y <= 0.0:
		preview_size = rect_min_size
	draw_set_transform(Vector2.ZERO, 0.0, preview_size / Vector2(360.0, 220.0))
	match arena_id:
		"forest_shrine":
			_draw_forest()
		"training_dojo":
			_draw_dojo()
		"ruined_outpost":
			_draw_outpost()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_forest() -> void:
	draw_rect(Rect2(0, 0, 360, 220), Color("#111d38"))
	draw_circle(Vector2(281, 48), 29, Color("#e4efff"))
	draw_circle(Vector2(291, 42), 25, Color("#111d38"))
	draw_colored_polygon(PoolVector2Array([Vector2(0, 151), Vector2(55, 98), Vector2(104, 150), Vector2(173, 85), Vector2(244, 151), Vector2(315, 104), Vector2(360, 148), Vector2(360, 220), Vector2(0, 220)]), Color("#203651"))
	for x in [30.0, 78.0, 286.0, 330.0]:
		draw_rect(Rect2(x, 96, 9, 86), Color("#091526"))
		draw_colored_polygon(PoolVector2Array([Vector2(x - 22, 111), Vector2(x + 4, 64), Vector2(x + 31, 111)]), Color("#244339"))
	draw_rect(Rect2(0, 181, 360, 39), Color("#26313c"))
	draw_rect(Rect2(117, 95, 10, 85), Color("#946f50"))
	draw_rect(Rect2(233, 95, 10, 85), Color("#946f50"))
	draw_rect(Rect2(100, 88, 160, 12), Color("#bd9161"))
	draw_rect(Rect2(112, 77, 136, 8), Color("#d0a979"))
	draw_rect(Rect2(0, 180, 360, 3), Color("#77a28c"))

func _draw_dojo() -> void:
	draw_rect(Rect2(0, 0, 360, 220), Color("#252638"))
	draw_rect(Rect2(0, 18, 360, 132), Color("#493c38"))
	draw_rect(Rect2(0, 26, 360, 8), Color("#9d7958"))
	for x in [22.0, 112.0, 202.0, 292.0]:
		draw_rect(Rect2(x, 35, 12, 121), Color("#71513a"))
		draw_rect(Rect2(x + 19, 49, 49, 77), Color("#29313c"))
		draw_rect(Rect2(x + 24, 54, 39, 67), Color("#9e8d76"))
		draw_line(Vector2(x + 43, 54), Vector2(x + 43, 121), Color("#5f5147"), 3)
		draw_line(Vector2(x + 24, 87), Vector2(x + 63, 87), Color("#5f5147"), 3)
	draw_rect(Rect2(0, 150, 360, 70), Color("#483a34"))
	for x in range(0, 360, 45):
		draw_line(Vector2(x, 151), Vector2(x + 19, 220), Color("#80634b"), 2)
	draw_rect(Rect2(0, 148, 360, 5), Color("#c2a377"))

func _draw_outpost() -> void:
	draw_rect(Rect2(0, 0, 360, 220), Color("#382832"))
	draw_circle(Vector2(282, 54), 26, Color("#e99e70"))
	draw_colored_polygon(PoolVector2Array([Vector2(0, 143), Vector2(34, 143), Vector2(34, 91), Vector2(91, 91), Vector2(91, 128), Vector2(140, 128), Vector2(140, 70), Vector2(196, 70), Vector2(196, 145), Vector2(246, 145), Vector2(246, 102), Vector2(305, 102), Vector2(305, 130), Vector2(360, 130), Vector2(360, 186), Vector2(0, 186)]), Color("#593940"))
	for x in [45.0, 160.0, 272.0, 325.0]:
		draw_rect(Rect2(x, 106, 6, 23), Color("#f2b77d"))
		draw_rect(Rect2(x - 5, 129, 16, 4), Color("#352934"))
	draw_rect(Rect2(0, 186, 360, 34), Color("#292d38"))
	draw_colored_polygon(PoolVector2Array([Vector2(8, 187), Vector2(56, 149), Vector2(82, 187)]), Color("#70444a"))
	draw_colored_polygon(PoolVector2Array([Vector2(275, 187), Vector2(312, 155), Vector2(350, 187)]), Color("#70444a"))
	draw_rect(Rect2(0, 183, 360, 4), Color("#cc8062"))
