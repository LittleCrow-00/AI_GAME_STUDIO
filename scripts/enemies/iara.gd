class_name Iara
extends Enemy
## Engodo. Mantém distância e dispara uma rajada de projéteis que drenam óleo.
##
## O contraponto do Afogado: se você a ignora, perde óleo; se persegue, sai da
## posição. A telegrafia de 0,55 s é o convite para usar o dash.

@export var preferred_range: float = 230.0
@export var volley_count: int = 3
@export var projectile_speed: float = 210.0
@export var attack_cooldown: float = 2.2

var _attack_timer: float = 1.4


func _ready() -> void:
	sprite_texture = preload("res://assets/sprites/iara.svg")
	super._ready()
	keep_distance = preferred_range
	contact_damage = 4.0


func _think(delta: float) -> void:
	_attack_timer = maxf(0.0, _attack_timer - delta)
	_chase(delta)

	if _target == null:
		return
	var distance := global_position.distance_to(_target.global_position)
	if _attack_timer > 0.0 or distance > preferred_range * 1.7:
		return

	_attack_timer = attack_cooldown
	_start_telegraph(0.55)


func _on_telegraph_end() -> void:
	if _target == null:
		return
	var base := (_target.global_position - global_position).normalized()
	for i in range(volley_count):
		var ratio := 0.0 if volley_count <= 1 else float(i) / float(volley_count - 1)
		var spread := deg_to_rad(-15.0 + 30.0 * ratio)
		_spawn_projectile(base.rotated(spread), projectile_speed, 7.0, 9.0)
	SignalBus.shake_requested.emit(0.08)