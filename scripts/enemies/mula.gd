class_name Mula
extends Enemy
## Mula-sem-cabeça: galopa em linha reta deixando fogo no chão.
##
## A telegrafia é longa (0,7 s) e o galope é rápido — desviar é fácil, mas o
## rastro fecha o caminho. Depois do galope ela para, ofegante: é a janela de
## dano (e o único momento em que ela apanha de verdade).

const FIRE_PATCH_SCENE: PackedScene = preload("res://scenes/gameplay/fire_patch.tscn")

@export var charge_speed: float = 430.0
@export var charge_time: float = 0.85
@export var telegraph_time: float = 0.7
@export var rest_time: float = 1.3
@export var fire_interval: float = 0.11
@export var rest_damage_mult: float = 1.4
@export var charge_trigger_range: float = 520.0

var _charge_left: float = 0.0
var _rest_left: float = 0.0
var _charge_heading: Vector2 = Vector2.RIGHT
var _fire_timer: float = 0.0
var _attack_timer: float = 2.2


func _ready() -> void:
	sprite_texture = preload("res://assets/sprites/mula.svg")
	super._ready()
	body_radius = 15.0
	move_speed = 78.0
	contact_damage = 12.0
	contact_interval = 0.9


func _process(delta: float) -> void:
	super._process(delta)
	queue_redraw()


func _think(delta: float) -> void:
	_attack_timer = maxf(0.0, _attack_timer - delta)

	if _rest_left > 0.0:
		_rest_left = maxf(0.0, _rest_left - delta)
		velocity = velocity.move_toward(Vector2.ZERO, ACCEL * 2.0 * delta)
		return

	if _charge_left > 0.0:
		_charge(delta)
		return

	if _target == null:
		_chase(delta)
		return

	_chase(delta)

	var distance := global_position.distance_to(_target.global_position)
	if _attack_timer > 0.0 or distance > charge_trigger_range:
		return
	_attack_timer = 3.0
	_start_telegraph(telegraph_time)


func _charge(delta: float) -> void:
	_charge_left = maxf(0.0, _charge_left - delta)
	velocity = _charge_heading * charge_speed

	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = fire_interval
		_drop_fire()

	if _charge_left <= 0.0:
		_rest_left = rest_time
		_attack_timer = maxf(_attack_timer, rest_time + 1.0)
		SignalBus.shake_requested.emit(0.1)


func _drop_fire() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var patch := FIRE_PATCH_SCENE.instantiate() as FirePatch
	patch.position = global_position
	parent.add_child(patch)


func _on_telegraph_end() -> void:
	if _target == null:
		return
	_charge_heading = (_target.global_position - global_position).normalized()
	_charge_left = charge_time
	_fire_timer = 0.0
	SignalBus.shake_requested.emit(0.08)


func is_resting() -> bool:
	return _rest_left > 0.0


func take_damage(amount: float, source_position: Vector2) -> void:
	if is_resting():
		super.take_damage(amount * rest_damage_mult, source_position)
		return
	super.take_damage(amount, source_position)


func _draw() -> void:
	super._draw()
	if is_resting():
		draw_arc(Vector2.ZERO, body_radius + 7.0, 0.0, TAU, 24, Color(1.0, 0.86, 0.6, 0.75), 2.0)