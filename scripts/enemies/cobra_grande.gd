class_name CobraGrande
extends Enemy
## Chefe 1 — Cobra Grande.
##
## Regra central: ela é quase imune no escuro. Só fica vulnerável depois de
## receber luz contínua por 2,5 s — o que força o jogador a parar de desviar e
## apontar o feixe, exatamente o oposto do instinto de "correr e atirar".
##
## Ciclo de ataques: investida (buraco → bote), rajada radial e invocação.

signal health_changed(current: float, maximum: float)

const AFOGADO_SCENE: PackedScene = preload("res://scenes/enemies/afogado.tscn")
const AFOGADO_DATA: EnemyData = preload("res://data/enemies/afogado.tres")

@export var armor_multiplier: float = 0.15
@export var exposure_time: float = 2.5
@export var exposed_window: float = 4.0
@export var charge_speed: float = 420.0
@export var charge_duration: float = 0.55
@export var exposure_per_tick: float = 0.04

var _exposure: float = 0.0
var _exposed_left: float = 0.0
var _charge_left: float = 0.0
var _charge_heading: Vector2 = Vector2.RIGHT
var _action_timer: float = 2.0
var _attack_step: int = 0
var _summon_cooldown: float = 0.0


func _ready() -> void:
	sprite_texture = preload("res://assets/sprites/cobra_grande.svg")
	super._ready()
	body_radius = 34.0
	_fit_sprite()
	contact_damage = 18.0
	contact_interval = 1.0
	SignalBus.beam_hit_enemy.connect(_on_beam_hit)
	SignalBus.boss_spawned.emit(self)
	_emit_health()


func _think(delta: float) -> void:
	_update_exposure(delta)
	_summon_cooldown = maxf(0.0, _summon_cooldown - delta)

	if _charge_left > 0.0:
		_charge_left = maxf(0.0, _charge_left - delta)
		velocity = _charge_heading * charge_speed
		return

	if _target == null:
		_chase(delta)
		return

	_chase(delta)
	_action_timer -= delta
	if _action_timer > 0.0:
		return

	_action_timer = 2.4 if _exposed_left > 0.0 else 1.9
	_next_attack()


func _next_attack() -> void:
	match _attack_step % 3:
		0:
			_start_telegraph(0.6)
		1:
			_start_telegraph(0.5)
		_:
			_start_telegraph(0.5)
	_attack_step += 1


func _on_telegraph_end() -> void:
	match (_attack_step - 1) % 3:
		0:
			_charge()
		1:
			_radial_volley()
		_:
			_summon()


func _charge() -> void:
	if _target == null:
		return
	_charge_heading = (_target.global_position - global_position).normalized()
	_charge_left = charge_duration
	SignalBus.shake_requested.emit(0.12)


func _radial_volley() -> void:
	var count := 12
	for i in range(count):
		var angle := TAU * float(i) / float(count)
		_spawn_projectile(Vector2.RIGHT.rotated(angle), 190.0, 10.0, 6.0)
	SignalBus.shake_requested.emit(0.2)


func _summon() -> void:
	if _summon_cooldown > 0.0:
		_radial_volley()
		return
	_summon_cooldown = 6.0
	var parent := get_parent()
	if parent == null:
		return
	for i in range(2):
		var enemy := AFOGADO_SCENE.instantiate() as Enemy
		enemy.position = global_position + Vector2.RIGHT.rotated(randf() * TAU) * 70.0
		enemy.apply_data(AFOGADO_DATA)
		parent.add_child(enemy)
	SignalBus.shake_requested.emit(0.15)


func _update_exposure(delta: float) -> void:
	if _exposed_left > 0.0:
		_exposed_left = maxf(0.0, _exposed_left - delta)
		if _exposed_left <= 0.0:
			_exposure = 0.0
		return
	_exposure = maxf(0.0, _exposure - delta * 0.12)


func _on_beam_hit(enemy: Node, _damage: float) -> void:
	if enemy != self:
		return
	if _exposed_left > 0.0:
		return
	_exposure = minf(1.0, _exposure + exposure_per_tick)
	if _exposure < 1.0:
		return
	_exposed_left = exposed_window
	_exposure = 0.0
	SignalBus.shake_requested.emit(0.25)
	SignalBus.message_requested.emit("EXPOSTA", 1.0)


func take_damage(amount: float, source_position: Vector2) -> void:
	if _exposed_left <= 0.0:
		super.take_damage(amount * armor_multiplier, source_position)
		return
	super.take_damage(amount, source_position)


func _die() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		if node == self or not is_instance_valid(node):
			continue
		if node is Enemy:
			(node as Enemy).take_damage(99999.0, global_position)
	SignalBus.boss_defeated.emit()
	super._die()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_emit_health()


func _emit_health() -> void:
	SignalBus.boss_health_changed.emit(health, max_health)


func is_exposed() -> bool:
	return _exposed_left > 0.0


func exposure_ratio() -> float:
	return _exposure


func _draw() -> void:
	if _sprite_node == null:
		var body := body_color.darkened(0.45)
		draw_circle(Vector2.ZERO, body_radius, Color(0.02, 0.05, 0.06))
		draw_circle(Vector2.ZERO, body_radius - 3.0, body)

		var segment_count := 7
		for i in range(segment_count):
			var t := float(i) / float(segment_count - 1)
			var offset := Vector2(-body_radius * 1.35 + t * body_radius * 2.7, 0.0)
			draw_circle(offset, 9.0 - t * 4.0, body_color.darkened(0.25))

	if is_exposed():
		draw_arc(Vector2.ZERO, body_radius + 6.0, 0.0, TAU, 40, Color(1.0, 0.55, 0.35, 0.85), 3.0)
	else:
		var ratio := exposure_ratio()
		draw_arc(
			Vector2.ZERO,
			body_radius + 6.0,
			-PI * 0.5,
			-PI * 0.5 + TAU * ratio,
			40,
			Color(1.0, 0.85, 0.5, 0.5),
			2.0,
		)
	draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.9, 0.6, 0.7))