class_name Cuca
extends Enemy
## Chefe 2 — Cuca.
##
## Regra central: ela **apaga a sua luz**. Enquanto vive, o alcance do feixe encolhe
## 35% — o jogador luta quase cego e o óleo (que também é visão) vira recurso
## disputado. Ela alterna sopro que drena óleo, mergulho e invocação.

signal health_changed(current: float, maximum: float)

const AFOGADO_SCENE: PackedScene = preload("res://scenes/enemies/afogado.tscn")
const AFOGADO_DATA: EnemyData = preload("res://data/enemies/afogado.tres")

@export var beam_range_mult: float = 0.65
@export var volley_count: int = 5
@export var volley_spread_deg: float = 40.0
@export var projectile_speed: float = 230.0
@export var projectile_damage: float = 8.0
@export var projectile_oil_cost: float = 10.0
@export var dive_speed: float = 420.0
@export var dive_time: float = 0.35
@export var dive_distance: float = 130.0
@export var summon_cooldown: float = 6.0

var _aura_applied: bool = false
var _dive_left: float = 0.0
var _dive_heading: Vector2 = Vector2.RIGHT
var _action_timer: float = 2.0
var _attack_step: int = 0
var _summon_timer: float = 4.0


func _ready() -> void:
	sprite_texture = preload("res://assets/sprites/cuca.svg")
	super._ready()
	body_radius = 30.0
	keep_distance = 190.0
	contact_damage = 14.0
	contact_interval = 1.0
	SignalBus.boss_spawned.emit(self)
	_emit_health()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_emit_health()


func _think(delta: float) -> void:
	_apply_aura()
	_summon_timer = maxf(0.0, _summon_timer - delta)

	if _dive_left > 0.0:
		_dive_left = maxf(0.0, _dive_left - delta)
		velocity = _dive_heading * dive_speed
		return

	if _target == null:
		_chase(delta)
		return

	_chase(delta)
	_action_timer -= delta
	if _action_timer > 0.0:
		return

	_action_timer = 2.0
	_next_attack()


func _next_attack() -> void:
	_attack_step += 1
	match _attack_step % 3:
		0:
			_start_telegraph(0.5)
		1:
			_start_telegraph(0.45)
		_:
			if _summon_timer <= 0.0:
				_start_telegraph(0.6)
			else:
				_start_telegraph(0.5)


func _on_telegraph_end() -> void:
	match (_attack_step - 1) % 3:
		0:
			_breath()
		1:
			_dive()
		_:
			if _summon_timer <= 0.0:
				_summon()
			else:
				_breath()


func _breath() -> void:
	if _target == null:
		return
	var base := (_target.global_position - global_position).normalized()
	for i in range(volley_count):
		var ratio := 0.0 if volley_count <= 1 else float(i) / float(volley_count - 1)
		var spread := deg_to_rad(-volley_spread_deg * 0.5 + volley_spread_deg * ratio)
		_spawn_projectile(base.rotated(spread), projectile_speed, projectile_damage, projectile_oil_cost)
	SignalBus.shake_requested.emit(0.12)


func _dive() -> void:
	if _target == null:
		return
	_dive_heading = (_target.global_position - global_position).normalized()
	_dive_left = dive_time
	SignalBus.shake_requested.emit(0.1)

	var landing := _target.global_position - _dive_heading * dive_distance
	if _is_free(landing):
		global_position = landing
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		_spawn_projectile(Vector2.RIGHT.rotated(angle), 170.0, 6.0, 4.0)


func _summon() -> void:
	_summon_timer = summon_cooldown
	var parent := get_parent()
	if parent == null:
		return
	for i in range(2):
		var enemy := AFOGADO_SCENE.instantiate() as Enemy
		enemy.position = global_position + Vector2.RIGHT.rotated(PI * float(i)) * 70.0
		enemy.apply_data(AFOGADO_DATA)
		parent.add_child(enemy)
	SignalBus.shake_requested.emit(0.16)


## Ponto livre de colisão? (mascara 1 = mundo)
func _is_free(point: Vector2) -> bool:
	var space := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = point
	query.collision_mask = 1
	query.exclude = [get_rid()]
	return space.intersect_point(query, 1).is_empty()


func _apply_aura() -> void:
	if _aura_applied or _target == null:
		return
	_aura_applied = true
	var modifier := StatModifier.new(&"beam_range", StatModifier.Mode.MULTIPLY, beam_range_mult)
	_target.apply_aura(&"cuca", [modifier])
	SignalBus.message_requested.emit("A CUCA APAGOU SUA LUZ", 1.6)


func _remove_aura() -> void:
	if not _aura_applied:
		return
	_aura_applied = false
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null:
		player.apply_aura(&"cuca", [])


func _die() -> void:
	_remove_aura()
	SignalBus.boss_defeated.emit()
	super._die()


func _emit_health() -> void:
	SignalBus.boss_health_changed.emit(health, max_health)


func _draw() -> void:
	if _sprite_node != null:
		draw_arc(Vector2.ZERO, body_radius + 7.0, 0.0, TAU, 40, Color(0.62, 0.42, 0.95, 0.55), 2.5)
		return

	var body := body_color.darkened(0.5)
	draw_circle(Vector2.ZERO, body_radius, Color(0.02, 0.05, 0.06))
	draw_circle(Vector2.ZERO, body_radius - 3.0, body)