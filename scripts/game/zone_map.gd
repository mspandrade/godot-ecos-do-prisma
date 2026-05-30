extends Node2D
class_name ZoneMap

@export var ground_color := Color("#36553a")
@export var alternate_color := Color("#3d6041")
@export var detail_color := Color("#71945b")
@export var ambient_color := Color("#20322b")
@export var tile_radius := 30
@export var accent_stride := 7

const TILE_HALF := Vector2(48.0, 24.0)

func _ready() -> void:
	z_index = -20
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-4200, -2600, 8400, 5200), ambient_color)
	for x in range(-tile_radius, tile_radius + 1):
		for y in range(-tile_radius, tile_radius + 1):
			var center := Vector2((x - y) * TILE_HALF.x, (x + y) * TILE_HALF.y)
			var color := alternate_color if (x + y) % 2 == 0 else ground_color
			if accent_stride > 0 and abs((x * 11 + y * 17) % accent_stride) == 0:
				color = detail_color
			var diamond := PackedVector2Array([
				center + Vector2(0, -TILE_HALF.y),
				center + Vector2(TILE_HALF.x, 0),
				center + Vector2(0, TILE_HALF.y),
				center + Vector2(-TILE_HALF.x, 0)
			])
			draw_colored_polygon(diamond, color)
			draw_polyline(diamond, color.darkened(0.14), 1.0)
