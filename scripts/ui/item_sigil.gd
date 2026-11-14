class_name ItemSigil
extends Control
## Selo do item no card do Santuário. Desenho procedural por tag.
##
## É apresentação pura: recebe a tag primária e a cor da raridade, e desenha.

var tags: Array[StringName] = []
var tint: Color = Color(1.0, 1.0, 1.0)


func setup(item_tags: Array[StringName], color: Color) -> void:
	tags = item_tags
	tint = color
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, 17.0, Color(0.02, 0.04, 0.05, 0.92))
	draw_arc(center, 17.0, 0.0, TAU, 26, Color(tint.r, tint.g, tint.b, 0.85), 1.6)

	var primary := &""
	if not tags.is_empty():
		primary = tags[0]

	match primary:
		&"lente":
			draw_arc(center, 8.0, 0.0, TAU, 20, tint, 1.8)
			draw_line(center + Vector2(-12, 0), center + Vector2(-4, 0), tint, 1.6)
			draw_line(center + Vector2(4, 0), center + Vector2(12, 0), tint, 1.6)
			draw_line(center + Vector2(0, -12), center + Vector2(0, -4), tint, 1.6)
			draw_line(center + Vector2(0, 4), center + Vector2(0, 12), tint, 1.6)
			draw_circle(center, 2.2, tint)
		&"oleo":
			draw_colored_polygon(
				PackedVector2Array([
					center + Vector2(0, -11),
					center + Vector2(7, 1),
					center + Vector2(0, 10),
					center + Vector2(-7, 1),
				]),
				Color(tint.r, tint.g, tint.b, 0.9),
			)
			draw_circle(center + Vector2(-2, 1), 2.0, Color(1, 1, 1, 0.75))
		&"corpo":
			var shield := PackedVector2Array([
				center + Vector2(0, -11),
				center + Vector2(9, -6),
				center + Vector2(8, 4),
				center + Vector2(0, 11),
				center + Vector2(-8, 4),
				center + Vector2(-9, -6),
			])
			draw_colored_polygon(shield, Color(tint.r, tint.g, tint.b, 0.28))
			draw_polyline(shield + PackedVector2Array([shield[0]]), tint, 1.8)
		&"resonancia":
			var points := PackedVector2Array()
			for i in range(10):
				var radius := 10.0 if i % 2 == 0 else 4.5
				var angle := -PI * 0.5 + TAU * float(i) / 10.0
				points.append(center + Vector2.from_angle(angle) * radius)
			draw_colored_polygon(points, Color(tint.r, tint.g, tint.b, 0.9))
		_:
			draw_circle(center, 4.5, tint)