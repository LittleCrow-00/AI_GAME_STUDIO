class_name LightWell
extends Node2D
## Foco de luz: o segundo meio de recarregar óleo.
##
## Recarrega rápido, mas o Faroleiro fica lento dentro dele — a luz que te enche
## também te prende. É a decisão que a Fase 1 não tinha: ficar e recarregar, ou
## sair e lutar.

@export var radius: float = 78.0
@export var oil_per_second: float = 26.0

var _pulse: float = 0.0
var _inside: bool = false


func _ready() -> void:
	add_to_group("light_wells")
	_pulse = randf() * TAU
	_create_light()
	set_process(true)


func _create_light() -> void:
	var light := PointLight2D.new()
	light.name = "Glow"
	light.texture = LightFactory.radial_texture(
		Color(1.0, 0.84, 0.52, 0.75), Color(1.0, 0.65, 0.25, 0.0),
	)
	light.energy = 0.6
	light.texture_scale = radius / 64.0
	add_child(light)


func contains_point(point: Vector2) -> bool:
	return global_position.distance_to(point) <= radius


func is_player_inside() -> bool:
	return _inside


func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()

	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return

	var inside := contains_point(player.global_position)
	if inside == _inside:
		return
	_inside = inside
	if inside:
		SignalBus.light_well_entered.emit(self)
	else:
		SignalBus.light_well_exited.emit(self)


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_pulse * 1.6)
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.78, 0.42, 0.04 + 0.02 * pulse))
	draw_circle(Vector2.ZERO, radius * 0.55, Color(1.0, 0.82, 0.50, 0.05 + 0.03 * pulse))

	var spin := _pulse * 0.35
	for i in range(8):
		var angle := spin + TAU * float(i) / 8.0
		var mark := Vector2.from_angle(angle) * radius * 0.92
		draw_circle(mark, 2.2, Color(1.0, 0.85, 0.50, 0.30 + 0.22 * pulse))

	for i in range(5):
		var t := fmod(_pulse * 0.45 + float(i) * 0.2, 1.0)
		var angle := float(i) * 1.7 + _pulse * 0.2
		var ember := Vector2.from_angle(angle) * (10.0 + 20.0 * t)
		ember.y -= t * 28.0
		draw_circle(ember, 1.8 * (1.0 - t) + 0.4, Color(1.0, 0.86, 0.55, 0.55 * (1.0 - t)))

	draw_circle(Vector2.ZERO, 4.0, Color(1.0, 0.92, 0.72, 0.35 + 0.25 * pulse))