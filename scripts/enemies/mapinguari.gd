class_name Mapinguari
extends Enemy
## Couraça. De longe o feixe se espalha e ela quase não sente; de perto a luz
## entra pela brecha.
##
## É lenta e aguenta muito, mas a investida pune quem fica colado. O combate vira
## um vaivém: chegar perto para ferir, sair antes do bote.

@export var armor_range: float = 165.0
@export var armor_scale: float = 0.35
@export var charge_speed: float = 300.0
@export var charge_time: float = 0.45
@export var charge_cooldown: float = 3.2
@export var charge_trigger_range: float = 260.0

var _charge_left: float = 0.0
var _charge_heading: Vector2 = Vector2.RIGHT
var _attack_timer: float = 2.0
var _clang_left: float = 0.0


func _ready() -> void:
	sprite_texture = preload("res://assets/sprites/mapinguari.svg")
	super._ready()
	body_radius = 17.0
	move_speed = 54.0
	contact_damage = 16.0
	contact_interval = 1.0
	keep_distance = 0.0


func _process(delta: float) -> void:
	super._process(delta)
	_clang_left = maxf(0.0, _clang_left - delta)
	queue_redraw()


func _think(delta: float) -> void:
	_attack_timer = maxf(0.0, _attack_timer - delta)

	if _charge_left > 0.0:
		_charge_left = maxf(0.0, _charge_left - delta)
		velocity = _charge_heading * charge_speed
		return

	if _target == null:
		_chase(delta)
		return

	_chase(delta)

	var distance := global_position.distance_to(_target.global_position)
	if _attack_timer > 0.0 or distance > charge_trigger_range:
		return
	_attack_timer = charge_cooldown
	_start_telegraph(0.6)


func _on_telegraph_end() -> void:
	if _target == null:
		return
	_charge_heading = (_target.global_position - global_position).normalized()
	_charge_left = charge_time
	SignalBus.shake_requested.emit(0.16)


func take_damage(amount: float, source_position: Vector2) -> void:
	if _target != null and global_position.distance_to(_target.global_position) > armor_range:
		_clang_left = 0.12
		super.take_damage(amount * armor_scale, source_position)
		return
	super.take_damage(amount, source_position)


func is_armored() -> bool:
	return _target != null and global_position.distance_to(_target.global_position) > armor_range


func _draw() -> void:
	super._draw()

	var ring_color := Color(0.78, 0.86, 0.82, 0.5)
	var width := 3.0
	if _clang_left > 0.0:
		ring_color = Color(1.0, 0.95, 0.75, 0.9)
		width = 4.0
	draw_arc(Vector2.ZERO, body_radius + 6.0, 0.0, TAU, 30, ring_color, width)