class_name Boitata
extends Enemy
## Serpente de fogo. Só a luz a fere — e cada instante de luz a enche de calor.
##
## Inverte a decisão do resto do jogo: aqui, segurar o feixe é o erro. O calor
## enche em ~1 s de luz contínua e devolve uma explosão que obriga a recuar.
## Depois da explosão ela fica fria e imune por um instante: é a janela para
## reposicionar, não para continuar atirando.

@export var heat_per_tick: float = 0.085
@export var heat_decay: float = 0.45
@export var flare_radius: float = 155.0
@export var flare_damage: float = 16.0
@export var cool_time: float = 1.8

var _heat: float = 0.0
var _cool_left: float = 0.0


func _ready() -> void:
	sprite_texture = preload("res://assets/sprites/boitata.svg")
	super._ready()
	body_radius = 13.0
	keep_distance = 170.0
	contact_damage = 7.0
	SignalBus.beam_hit_enemy.connect(_on_beam_hit)


func _process(delta: float) -> void:
	super._process(delta)
	queue_redraw()


func _think(delta: float) -> void:
	_cool_left = maxf(0.0, _cool_left - delta)
	_heat = maxf(0.0, _heat - heat_decay * delta)
	_orbit(delta)


## Contorna o jogador em vez de perseguir: o alvo se move, a cobra dança.
func _orbit(delta: float) -> void:
	if _target == null:
		_chase(delta)
		return

	var to_target: Vector2 = _target.global_position - global_position
	var distance := to_target.length()
	var radial := to_target.normalized()
	var heading := radial.orthogonal() * 0.85

	if distance > keep_distance * 1.3:
		heading += radial
	elif distance < keep_distance * 0.75:
		heading -= radial

	velocity = velocity.move_toward(heading.normalized() * move_speed, ACCEL * delta)


func _on_beam_hit(enemy: Node, _damage: float) -> void:
	if enemy != self or _cool_left > 0.0:
		return
	_heat = minf(1.0, _heat + heat_per_tick)
	if _heat < 1.0:
		return
	_flare()


func _flare() -> void:
	_heat = 0.0
	_cool_left = cool_time

	var burst := DeathBurst.new()
	burst.tint = Color(1.0, 0.55, 0.2)
	burst.max_radius = flare_radius
	burst.duration = 0.35
	burst.position = global_position
	get_parent().add_child(burst)

	if _target != null and global_position.distance_to(_target.global_position) <= flare_radius:
		_target.take_damage(flare_damage, global_position)
	SignalBus.shake_requested.emit(0.3)


func take_damage(amount: float, source_position: Vector2) -> void:
	if _cool_left > 0.0:
		return
	super.take_damage(amount, source_position)


func heat_ratio() -> float:
	return _heat


func is_immune() -> bool:
	return _cool_left > 0.0


func _draw() -> void:
	super._draw()

	if is_immune():
		draw_arc(Vector2.ZERO, body_radius + 8.0, 0.0, TAU, 26, Color(0.55, 0.68, 0.78, 0.55), 2.0)
		return
	if _heat <= 0.02:
		return

	draw_arc(
		Vector2.ZERO,
		body_radius + 8.0,
		-PI * 0.5,
		-PI * 0.5 + TAU * _heat,
		26,
		Color(1.0, 0.42 + _heat * 0.35, 0.14, 0.55 + _heat * 0.4),
		2.5,
	)