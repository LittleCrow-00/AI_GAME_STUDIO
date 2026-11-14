class_name Boto
extends Enemy
## Metamorfo. Orbita a distância, telegrafa e então dispara em linha reta.
##
## É o inimigo que pune a posição parada: o dash atravessa o bote, mas ficar
## recarregando óleo num foco vira aposta.

@export var orbit_range: float = 190.0
@export var dash_speed: float = 430.0
@export var dash_duration: float = 0.26
@export var attack_cooldown: float = 1.8

var _attack_timer: float = 1.0
var _dash_left: float = 0.0
var _dash_heading: Vector2 = Vector2.RIGHT


func _ready() -> void:
	sprite_texture = preload("res://assets/sprites/boto.svg")
	super._ready()
	keep_distance = orbit_range
	contact_damage = 14.0


func _think(delta: float) -> void:
	if _dash_left > 0.0:
		_dash_left = maxf(0.0, _dash_left - delta)
		velocity = _dash_heading * dash_speed
		return

	_attack_timer = maxf(0.0, _attack_timer - delta)
	_chase(delta)

	if _target == null:
		return
	var distance := global_position.distance_to(_target.global_position)
	if _attack_timer > 0.0 or distance > orbit_range * 1.8:
		return

	_attack_timer = attack_cooldown
	_start_telegraph(0.4)


func _on_telegraph_end() -> void:
	if _target == null:
		return
	_dash_heading = (_target.global_position - global_position).normalized()
	_dash_left = dash_duration
	SignalBus.shake_requested.emit(0.1)