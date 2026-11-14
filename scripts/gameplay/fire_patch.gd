class_name FirePatch
extends Node2D
## Fogo no chão deixado pela Mula-sem-cabeça.
##
## Dura pouco e pune quem fica em cima: o rastro fecha o caminho sem virar parede
## (não bloqueia movimento, só cobra dano).

@export var lifetime: float = 3.0
@export var radius: float = 26.0
@export var damage: float = 6.0
@export var tick_interval: float = 0.5

var _age: float = 0.0
var _tick_left: float = 0.0


func _ready() -> void:
	add_to_group("fire_patches")
	z_index = 2


func _process(delta: float) -> void:
	_age += delta
	_tick_left -= delta
	queue_redraw()

	if _tick_left <= 0.0:
		_tick_left = tick_interval
		_damage_player()

	if _age >= lifetime:
		queue_free()


func _damage_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	if player.global_position.distance_to(global_position) > radius:
		return
	player.take_damage(damage, global_position)


func _draw() -> void:
	var fade := 1.0 - clampf(_age / maxf(0.01, lifetime), 0.0, 1.0) * 0.75

	draw_circle(Vector2.ZERO, radius, Color(0.85, 0.30, 0.08, 0.18 * fade))
	draw_circle(Vector2.ZERO, radius * 0.62, Color(1.0, 0.58, 0.18, 0.22 * fade))

	for i in range(5):
		var angle := TAU * float(i) / 5.0 + _age * 2.2
		var offset := Vector2.from_angle(angle) * radius * 0.45
		draw_circle(offset, 3.2 * fade + 0.6, Color(1.0, 0.82, 0.38, 0.7 * fade))