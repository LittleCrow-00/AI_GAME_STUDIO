class_name Farol
extends Node2D
## O Farol da última sala.
##
## Fica apagado até a sala ser limpa. Depois, o jogador precisa ficar dentro do
## círculo por 2 s — a troca final de "luz" por "vitória". Se sair, o progresso
## escorre de volta.

signal lit

@export var radius: float = 72.0
@export var charge_time: float = 2.0

var _progress: float = 0.0
var _active: bool = false
var _pulse: float = 0.0


func _ready() -> void:
	add_to_group("farol")
	_pulse = randf() * TAU


func set_active(value: bool) -> void:
	_active = value
	queue_redraw()


func is_lit() -> bool:
	return _progress >= charge_time


func progress_ratio() -> float:
	return clampf(_progress / charge_time, 0.0, 1.0)


func _process(delta: float) -> void:
	_pulse += delta
	if _active and not is_lit():
		var player := get_tree().get_first_node_in_group("player") as Player
		if player != null and global_position.distance_to(player.global_position) <= radius:
			_progress = minf(charge_time, _progress + delta)
			if is_lit():
				lit.emit()
		else:
			_progress = maxf(0.0, _progress - delta * 0.6)
	queue_redraw()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_pulse * 1.8)

	if _active:
		draw_circle(Vector2.ZERO, radius, Color(1.0, 0.8, 0.45, 0.05 + 0.03 * pulse))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 56, Color(1.0, 0.82, 0.5, 0.35 + 0.2 * pulse), 2.0)

	draw_rect(Rect2(-16.0, -70.0, 32.0, 70.0), Color(0.10, 0.14, 0.16))
	draw_rect(Rect2(-22.0, -78.0, 44.0, 12.0), Color(0.14, 0.19, 0.21))
	draw_rect(Rect2(-10.0, -66.0, 20.0, 22.0), Color(1.0, 0.85, 0.5, 0.35 + 0.5 * pulse))

	var ratio := progress_ratio()
	if ratio > 0.0:
		draw_arc(
			Vector2.ZERO,
			radius * 0.62,
			-PI * 0.5,
			-PI * 0.5 + TAU * ratio,
			40,
			Color(1.0, 0.72, 0.3, 0.9),
			4.0,
		)
	if is_lit():
		draw_circle(Vector2.ZERO, radius * 0.9, Color(1.0, 0.85, 0.55, 0.18))