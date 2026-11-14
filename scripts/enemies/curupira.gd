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
	sprite_texture = preload("res://assets/sprites/curupira.svg")
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
	var target_position := _target.global_position
	for attempt in range(8):
		var angle := randf() * TAU
		var candidate := target_position + Vector2.RIGHT.rotated(angle) * blink_distance
		if _is_free(candidate):
			global_position = candidate
			_attack_timer = minf(_attack_timer, 0.8)
			SignalBus.shake_requested.emit(0.06)
			return
	# Sem lugar livre por perto: desiste em vez de atravessar a parede.
	_attack_timer = 0.4


## Ponto livre de colisão? (mascara 1 = mundo)
func _is_free(point: Vector2) -> bool:
	var space := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = point
	query.collision_mask = 1
	query.exclude = [get_rid()]
	return space.intersect_point(query, 1).is_empty()