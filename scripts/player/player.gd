class_name Player
extends CharacterBody2D
## O Faroleiro.
##
## Responsabilidades: movimento, dash (com i-frames), gerenciamento de oleo e
## integracao com o Feixe. Nenhum conhecimento sobre HUD ou spawn: emite sinais.

signal died

const ACCELERATION := 2200.0
const FRICTION := 2600.0
const MAX_SPEED := 220.0

const DASH_SPEED := 520.0
const DASH_DURATION := 0.15
const DASH_IFRAMES := 0.18
const DASH_COOLDOWN := 0.45
const DASH_CHARGES_MAX := 1

@export var max_health: float = 100.0
@export var max_oil: float = 100.0
@export var oil_drain_per_second: float = 6.0
@export var dry_lockout: float = 1.5

@onready var beam: Beam = $Beam

var health: float = 100.0
var oil: float = 100.0
var is_firing: bool = false

var _dead: bool = false
var _iframes: float = 0.0
var _dash_time_left: float = 0.0
var _dash_cooldown_left: float = 0.0
var _dash_charges: int = DASH_CHARGES_MAX
var _dash_direction: Vector2 = Vector2.RIGHT
var _dry_left: float = 0.0


func _ready() -> void:
	add_to_group("player")
	health = max_health
	oil = max_oil
	_create_vision_light()
	SignalBus.enemy_died.connect(_on_enemy_died)
	_emit_all()


func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	if _dead:
		return
	_handle_dash(delta)
	_handle_movement(delta)
	_handle_beam(delta)


func _tick_timers(delta: float) -> void:
	_iframes = maxf(0.0, _iframes - delta)
	_dash_cooldown_left = maxf(0.0, _dash_cooldown_left - delta)
	_dry_left = maxf(0.0, _dry_left - delta)


func _handle_movement(delta: float) -> void:
	if _dash_time_left > 0.0:
		velocity = _dash_direction * DASH_SPEED
		move_and_slide()
		return

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input.length_squared() > 0.01:
		velocity = velocity.move_toward(input.normalized() * MAX_SPEED, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	move_and_slide()


func _handle_dash(delta: float) -> void:
	if _dash_time_left > 0.0:
		_dash_time_left -= delta
		if _dash_time_left <= 0.0:
			velocity *= 0.35
		return

	if _dash_charges <= 0 or _dash_cooldown_left > 0.0:
		return
	if not Input.is_action_just_pressed("dash"):
		return

	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.length_squared() < 0.01:
		direction = Vector2.RIGHT.rotated(beam.global_rotation)
	_dash_direction = direction.normalized()
	_dash_time_left = DASH_DURATION
	_dash_cooldown_left = DASH_COOLDOWN
	_iframes = maxf(_iframes, DASH_IFRAMES)
	_dash_charges -= 1
	_emit_dash()


func _handle_beam(delta: float) -> void:
	var aim := get_global_mouse_position() - global_position
	if aim.length_squared() > 4.0:
		beam.global_rotation = aim.angle()

	var wants_fire := (
		Input.is_action_pressed("fire")
		and _dry_left <= 0.0
		and oil > 0.0
		and _dash_time_left <= 0.0
	)

	is_firing = wants_fire
	beam.active = wants_fire

	if wants_fire:
		oil = maxf(0.0, oil - oil_drain_per_second * delta)
		if oil <= 0.0:
			_dry_left = dry_lockout
			SignalBus.beam_dried.emit()
	SignalBus.oil_changed.emit(oil, max_oil)


func take_damage(amount: float, source_position: Vector2) -> void:
	if _dead or _iframes > 0.0:
		return
	health = maxf(0.0, health - amount)
	SignalBus.player_damaged.emit(amount, global_position)
	SignalBus.health_changed.emit(health, max_health)

	_iframes = 0.35
	var push := (global_position - source_position)
	if push.length_squared() < 0.01:
		push = Vector2.DOWN
	velocity += push.normalized() * 180.0

	if health <= 0.0:
		_dead = true
		beam.active = false
		died.emit()
		SignalBus.player_died.emit()


func heal(amount: float) -> void:
	if _dead:
		return
	health = minf(max_health, health + amount)
	SignalBus.health_changed.emit(health, max_health)


func add_oil(amount: float) -> void:
	if _dead:
		return
	oil = minf(max_oil, oil + amount)
	SignalBus.oil_changed.emit(oil, max_oil)


func is_dead() -> bool:
	return _dead


func _create_vision_light() -> void:
	var light := PointLight2D.new()
	light.name = "VisionLight"
	light.texture = LightFactory.radial_texture(Color(1.0, 0.86, 0.62, 0.55), Color(0.6, 0.75, 0.9, 0.0))
	light.energy = 0.9
	light.scale = Vector2(1.1, 1.1)
	add_child(light)


func _on_enemy_died(_enemy: Node, _position: Vector2) -> void:
	if _dash_charges < DASH_CHARGES_MAX:
		_dash_charges += 1
		_emit_dash()


func _emit_all() -> void:
	SignalBus.health_changed.emit(health, max_health)
	SignalBus.oil_changed.emit(oil, max_oil)
	_emit_dash()


func _emit_dash() -> void:
	SignalBus.dash_charges_changed.emit(_dash_charges, DASH_CHARGES_MAX)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 13.0, Color(0.05, 0.08, 0.09))
	draw_circle(Vector2.ZERO, 11.0, Color(0.85, 0.72, 0.45))
	draw_circle(Vector2(0, -2), 4.0, Color(1.0, 0.88, 0.55))
	if _iframes > 0.0:
		draw_arc(Vector2.ZERO, 17.0, 0.0, TAU, 28, Color(1, 1, 1, 0.45), 2.0)
	if _dead:
		draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 28, Color(0.78, 0.2, 0.24, 0.8), 3.0)