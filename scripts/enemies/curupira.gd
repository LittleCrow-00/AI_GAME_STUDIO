class_name Curupira
extends Enemy
## Enganador. Some e reaparece atrás de você quando você tenta manter distância.
##
## O objetivo de design é impedir o "kiting" eterno: se você corre, ele aparece
## onde você não está olhando.

@export var blink_distance: float = 46.0
@export var blink_trigger_range: float = 190.0
@export var blink_cooldown: float = 2.4

var _attack_timer: float = 1.2


func _ready() -> void:
	super._ready()
	move_speed = 95.0
	contact_damage = 9.0
	body_radius = 10.0


func _think(delta: float) -> void:
	_attack_timer = maxf(0.0, _attack_timer - delta)
	if _target == null:
		return

	var distance := global_position.distance_to(_target.global_position)
	if _attack_timer <= 0.0 and distance > blink_trigger_range:
		_attack_timer = blink_cooldown
		_start_telegraph(0.35)
		return

	_chase(delta)


func _on_telegraph_end() -> void:
	if _target == null:
		return
	var angle := randf() * TAU
	global_position = _target.global_position + Vector2.RIGHT.rotated(angle) * blink_distance
	_attack_timer = minf(_attack_timer, 0.8)
	SignalBus.shake_requested.emit(0.06)