class_name SparkPool
extends Node2D
## Faíscas de impacto.
##
## Um único `_draw` para todas as faíscas: o feixe tica 10x por segundo e
## criar um nó por acerto custaria mais que o efeito. Pool fixo, sem alocação
## em combate.

const MAX_SPARKS := 96
const LIFE := 0.18
const SPEED := 190.0
const LENGTH := 6.0

var _pos: PackedVector2Array = PackedVector2Array()
var _vel: PackedVector2Array = PackedVector2Array()
var _life: PackedFloat32Array = PackedFloat32Array()
var _next: int = 0
var _was_alive: bool = false


func _ready() -> void:
	z_index = 1
	for i in range(MAX_SPARKS):
		_pos.append(Vector2.ZERO)
		_vel.append(Vector2.ZERO)
		_life.append(0.0)
	SignalBus.enemy_hit.connect(_on_enemy_hit)
	set_process(true)


func _on_enemy_hit(_enemy: Node, _damage: float, position: Vector2) -> void:
	# Direção: do inimigo para longe da lanterna (o feixe empurra).
	var from := position
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		from = player.global_position
	var base := (position - from).angle() if position.distance_squared_to(from) > 1.0 else 0.0
	for i in range(4):
		var angle := base + randf_range(-0.7, 0.7)
		_emit(position, Vector2.from_angle(angle))


func _emit(at: Vector2, direction: Vector2) -> void:
	var index := _next
	_next = (_next + 1) % MAX_SPARKS
	_pos[index] = at
	_vel[index] = direction * SPEED * randf_range(0.6, 1.2)
	_life[index] = LIFE


func _process(delta: float) -> void:
	var alive := false
	for i in range(MAX_SPARKS):
		if _life[i] <= 0.0:
			continue
		_life[i] = maxf(0.0, _life[i] - delta)
		_pos[i] += _vel[i] * delta
		_vel[i] *= 0.88
		alive = alive or _life[i] > 0.0
	if alive or _was_alive:
		queue_redraw()
	_was_alive = alive


func _draw() -> void:
	for i in range(MAX_SPARKS):
		var t := _life[i]
		if t <= 0.0:
			continue
		var fade := t / LIFE
		var tail := _pos[i] - _vel[i].normalized() * LENGTH * fade
		draw_line(_pos[i], tail, Color(1.0, 0.86, 0.5, 0.9 * fade), 2.0)
		draw_circle(_pos[i], 1.6 * fade + 0.4, Color(1.0, 0.97, 0.85, fade))