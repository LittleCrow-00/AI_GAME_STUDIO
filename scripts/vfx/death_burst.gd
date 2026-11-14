class_name DeathBurst
extends Node2D
## Explosao curta de fragmentos quando um inimigo morre.
##
## Puramente visual: nao consulta regras, so le a cor do corpo e se autodestrói.

var tint: Color = Color(0.5, 0.9, 0.9)
@export var max_radius: float = 26.0
@export var duration: float = 0.45
var _age: float = 0.0


func _ready() -> void:
	z_index = 6


func _process(delta: float) -> void:
	_age += delta
	queue_redraw()
	if _age >= duration:
		queue_free()


func _draw() -> void:
	var t := clampf(_age / maxf(0.01, duration), 0.0, 1.0)
	var fade := 1.0 - t

	draw_arc(
		Vector2.ZERO,
		5.0 + max_radius * t,
		0.0,
		TAU,
		22,
		Color(tint.r, tint.g, tint.b, 0.7 * fade),
		2.0,
	)
	for i in range(6):
		var angle := TAU * float(i) / 6.0 + 0.4
		var distance := (3.0 + max_radius * 0.8) * t
		draw_circle(
			Vector2.from_angle(angle) * distance,
			2.6 * fade + 0.4,
			Color(tint.r, tint.g, tint.b, 0.65 * fade),
		)