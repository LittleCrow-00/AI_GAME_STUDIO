class_name OilDrop
extends Node2D
## Gota de oleo largada por inimigos. Um dos dois unicos meios de recarregar
## (o outro e ficar parado num Foco). Da um curto delay antes de comecar a
## perseguir o jogador para que a coleta seja uma decisao, nao automatica.

@export var amount: float = 6.0
@export var delay: float = 0.35
@export var homing_speed: float = 320.0
@export var pickup_radius: float = 18.0

var _age: float = 0.0
var _velocity: Vector2 = Vector2.ZERO
var _collected: bool = false


func _ready() -> void:
	_velocity = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(40.0, 90.0)
	z_index = 5


func _process(delta: float) -> void:
	if _collected:
		return
	_age += delta
	_velocity = _velocity.move_toward(Vector2.ZERO, 420.0 * delta)
	position += _velocity * delta

	if _age < delay:
		queue_redraw()
		return

	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or player.is_dead():
		return

	var to_player: Vector2 = player.global_position - global_position
	if to_player.length() <= pickup_radius:
		player.add_oil(amount)
		_collected = true
		SignalBus.oil_pickup_collected.emit(amount)
		queue_free()
		return

	position += to_player.normalized() * homing_speed * delta
	queue_redraw()


func _draw() -> void:
	var pulse := 1.0 + sin(_age * 10.0) * 0.12
	var spin := _age * 2.4
	draw_circle(Vector2.ZERO, 10.0 * pulse, Color(1.0, 0.72, 0.26, 0.10))
	draw_arc(Vector2.ZERO, 8.0 * pulse, spin, spin + TAU * 0.75, 14, Color(1.0, 0.80, 0.35, 0.35), 1.4)
	draw_circle(Vector2.ZERO, 5.4 * pulse, Color(1.0, 0.78, 0.32, 0.30))
	draw_circle(Vector2.ZERO, 3.2 * pulse, Color(1.0, 0.88, 0.50))
	draw_circle(Vector2(-1.0, -1.0), 1.2, Color(1.0, 0.97, 0.85, 0.9))