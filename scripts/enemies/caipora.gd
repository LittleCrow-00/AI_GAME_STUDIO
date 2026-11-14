class_name Caipora
extends Enemy
## Caipora: guardiã que **apaga o chão**.
##
## Mantém distância e semeia poças de escuridão onde o jogador está. Dentro delas
## o feixe encolhe — o combate vira um jogo de escolher onde pisar, não só onde
## mirar. Se já existem zonas demais, ela ri e some (teleporte).

const DARK_ZONE_SCENE: PackedScene = preload("res://scenes/gameplay/dark_zone.tscn")

@export var preferred_range: float = 210.0
@export var zone_cooldown: float = 3.4
@export var max_zones: int = 3
@export var blink_distance: float = 170.0
@export var telegraph_time: float = 0.5

var _zone_timer: float = 2.0


func _ready() -> void:
	sprite_texture = preload("res://assets/sprites/caipora.svg")
	super._ready()
	body_radius = 12.0
	move_speed = 88.0
	contact_damage = 8.0
	keep_distance = preferred_range


func _think(delta: float) -> void:
	_zone_timer = maxf(0.0, _zone_timer - delta)
	_chase(delta)

	if _target == null or _zone_timer > 0.0:
		return
	if global_position.distance_to(_target.global_position) > preferred_range * 2.0:
		return

	_zone_timer = zone_cooldown
	_start_telegraph(telegraph_time)


func _on_telegraph_end() -> void:
	if _target == null:
		return

	if _active_zones() >= max_zones:
		_blink()
		SignalBus.message_requested.emit("A CAIPORA RIU", 0.8)
		return

	var zone := DARK_ZONE_SCENE.instantiate() as DarkZone
	zone.position = _target.global_position
	zone.global_position = _target.global_position
	get_parent().add_child(zone)
	SignalBus.shake_requested.emit(0.06)


func _blink() -> void:
	var target_position := _target.global_position
	for attempt in range(8):
		var angle := randf() * TAU
		var candidate := target_position + Vector2.RIGHT.rotated(angle) * blink_distance
		if _is_free(candidate):
			global_position = candidate
			return


func _is_free(point: Vector2) -> bool:
	var space := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = point
	query.collision_mask = 1
	query.exclude = [get_rid()]
	return space.intersect_point(query, 1).is_empty()


func _active_zones() -> int:
	return get_tree().get_nodes_in_group("dark_zones").size()


func _draw() -> void:
	super._draw()
	if _zone_timer < 0.4:
		draw_arc(Vector2.ZERO, body_radius + 6.0, 0.0, TAU, 24, Color(0.55, 0.42, 0.95, 0.7), 2.0)