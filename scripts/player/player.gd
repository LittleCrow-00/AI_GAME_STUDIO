class_name Player
extends CharacterBody2D
## O Faroleiro.
##
## Responsabilidades: movimento, dash (com i-frames), óleo, focos de luz,
## integração com o Feixe e o `StatSheet` que os itens alimentam.
## Nenhum conhecimento sobre HUD ou spawn: emite sinais.

signal died

const ACCELERATION := 2200.0
const FRICTION := 2600.0

const DASH_SPEED := 520.0
const DASH_DURATION := 0.15
const DASH_IFRAMES := 0.18
const DASH_COOLDOWN := 0.45

## Dentro de um foco de luz o Faroleiro recarrega, mas quase não anda.
const LIGHT_SLOW_FACTOR := 0.4

# --- Valores base (ponto de partida do StatSheet) ---
@export var base_max_health: float = 100.0
@export var base_max_oil: float = 100.0
@export var base_oil_drain: float = 6.0
@export var base_beam_damage: float = 8.0
@export var base_beam_range: float = 260.0
@export var base_beam_half_angle: float = 22.0
@export var base_move_speed: float = 220.0
@export var base_dash_charges: int = 1
@export var base_light_oil: float = 26.0
@export var dry_lockout: float = 1.5

@onready var beam: Beam = $Beam
@onready var vision_light: PointLight2D = $VisionLight

var stats: StatSheet
var inventory: Inventory

var max_health: float = 100.0
var max_oil: float = 100.0
var health: float = 100.0
var oil: float = 100.0
var is_firing: bool = false

var _oil_drain: float = 6.0
var _move_speed: float = 220.0
var _dash_charges_max: int = 1
var _light_mult: float = 1.0

## Comportamentos agregados pelo inventário. Zero/desligado = sem efeito.
var _refraction: int = 0
var _pierce_walls: bool = false
var _oil_on_hit: float = 0.0
var _oil_on_kill_bonus: float = 0.0
var _nova_damage: float = 0.0
var _nova_radius: float = 0.0

var _dead: bool = false
var _iframes: float = 0.0
var _dash_time_left: float = 0.0
var _dash_cooldown_left: float = 0.0
var _dash_charges: int = 1
var _dash_direction: Vector2 = Vector2.RIGHT
var _dry_left: float = 0.0
var _in_light: bool = false
var _light_rate: float = 0.0
var _in_nova: bool = false
var _known_synergies: Array[StringName] = []


func _ready() -> void:
	add_to_group("player")
	stats = StatSheet.new()
	stats.set_base(&"max_health", base_max_health)
	stats.set_base(&"max_oil", base_max_oil)
	stats.set_base(&"oil_drain_per_second", base_oil_drain)
	stats.set_base(&"beam_damage", base_beam_damage)
	stats.set_base(&"beam_range", base_beam_range)
	stats.set_base(&"beam_half_angle", base_beam_half_angle)
	stats.set_base(&"move_speed", base_move_speed)
	stats.set_base(&"dash_charges_max", float(base_dash_charges))
	stats.set_base(&"light_oil_per_second", base_light_oil)
	inventory = Inventory.new()
	_refresh_stats(false)

	health = max_health
	oil = max_oil
	SignalBus.enemy_died.connect(_on_enemy_died)
	SignalBus.enemy_hit.connect(_on_enemy_hit)
	_emit_all()


func _refresh_stats(heal_delta: bool = true) -> void:
	var previous_max_health := max_health
	var previous_max_oil := max_oil
	var previous_dash_max := _dash_charges_max

	max_health = stats.get_stat(&"max_health")
	max_oil = stats.get_stat(&"max_oil")
	_oil_drain = stats.get_stat(&"oil_drain_per_second")
	_move_speed = stats.get_stat(&"move_speed")
	_dash_charges_max = int(stats.get_stat(&"dash_charges_max"))
	_light_mult = stats.get_stat(&"light_oil_per_second") / maxf(1.0, base_light_oil)

	beam.configure(
		stats.get_stat(&"beam_range"),
		stats.get_stat(&"beam_half_angle"),
		stats.get_stat(&"beam_damage"),
	)
	beam.set_refraction(_refraction)
	beam.set_pierce_walls(_pierce_walls)

	if heal_delta:
		health = minf(max_health, health + maxf(0.0, max_health - previous_max_health))
		oil = minf(max_oil, oil + maxf(0.0, max_oil - previous_max_oil))
	else:
		health = max_health
		oil = max_oil

	if _dash_charges_max > previous_dash_max:
		_dash_charges = _dash_charges_max
	_dash_charges = mini(_dash_charges, _dash_charges_max)


## Adiciona um item ao inventário e recalcula tudo. Devolve `false` se o item já
## está no máximo de stacks (o Santuário usa isso para não oferecer repetidos).
func apply_item(item: ItemData) -> bool:
	if item == null or inventory == null:
		return false
	if not inventory.add(item):
		return false
	_recompute_inventory()

	if item.heal_on_pick > 0.0:
		heal(item.heal_on_pick)
	if item.oil_on_pick > 0.0:
		add_oil(item.oil_on_pick)

	SignalBus.item_acquired.emit(item, inventory.stacks_of(item.id))
	return true


## Refaz o `StatSheet` a partir do inventário. É a única ponte entre itens e
## atributos: nada aqui decide "item X faz Y".
func _recompute_inventory() -> void:
	stats.remove_source(Inventory.SOURCE)
	stats.remove_source(Inventory.SYNERGY_SOURCE)

	var result := inventory.rebuild()
	for modifier in result["modifiers"]:
		stats.add(modifier as StatModifier)

	_refraction = int(result["refraction"])
	_oil_on_hit = float(result["oil_on_hit"])
	_oil_on_kill_bonus = float(result["oil_on_kill_bonus"])
	_nova_damage = float(result["nova_damage"])
	_nova_radius = float(result["nova_radius"])
	_pierce_walls = bool(result["pierce"])

	_refresh_stats(true)

	var current: Array[StringName] = []
	for synergy in result["synergies"]:
		current.append(synergy)
	for synergy in current:
		if not _known_synergies.has(synergy):
			SignalBus.synergy_activated.emit(synergy)
	_known_synergies = current

	SignalBus.health_changed.emit(health, max_health)
	SignalBus.oil_changed.emit(oil, max_oil)
	_emit_dash()


func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	if _dead:
		return
	_handle_light_wells(delta)
	_handle_dash(delta)
	_handle_movement(delta)
	_handle_beam(delta)
	_update_vision()


func _tick_timers(delta: float) -> void:
	_iframes = maxf(0.0, _iframes - delta)
	_dash_cooldown_left = maxf(0.0, _dash_cooldown_left - delta)
	_dry_left = maxf(0.0, _dry_left - delta)


func _handle_light_wells(delta: float) -> void:
	_in_light = false
	_light_rate = 0.0
	for node in get_tree().get_nodes_in_group("light_wells"):
		var well := node as LightWell
		if well == null:
			continue
		if not well.contains_point(global_position):
			continue
		_in_light = true
		_light_rate = maxf(_light_rate, well.oil_per_second * _light_mult)

	if not _in_light:
		return
	oil = minf(max_oil, oil + _light_rate * delta)
	SignalBus.oil_changed.emit(oil, max_oil)


func _handle_movement(delta: float) -> void:
	if _dash_time_left > 0.0:
		velocity = _dash_direction * DASH_SPEED
		move_and_slide()
		return

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var speed_cap := _move_speed * (LIGHT_SLOW_FACTOR if _in_light else 1.0)
	if input.length_squared() > 0.01:
		velocity = velocity.move_toward(input.normalized() * speed_cap, ACCELERATION * delta)
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
		oil = maxf(0.0, oil - _oil_drain * delta)
		if oil <= 0.0:
			_dry_left = dry_lockout
			SignalBus.beam_dried.emit()
	SignalBus.oil_changed.emit(oil, max_oil)


func _update_vision() -> void:
	# Estouro: a lanterna morre. É o único momento em que a tela fica quase preta.
	if _dry_left > 0.0:
		vision_light.energy = 0.06
		vision_light.scale = Vector2.ONE * 0.7
		return

	var ratio := clampf(oil / maxf(1.0, max_oil), 0.0, 1.0)
	vision_light.energy = lerpf(0.26, 1.0, ratio)
	vision_light.scale = Vector2.ONE * lerpf(0.8, 1.1, ratio)


func take_damage(amount: float, source_position: Vector2) -> void:
	if _dead or _iframes > 0.0:
		return
	health = maxf(0.0, health - amount)
	SignalBus.player_damaged.emit(amount, global_position)
	SignalBus.health_changed.emit(health, max_health)
	TimeService.hitstop(70)
	SignalBus.shake_requested.emit(0.5)

	_iframes = 0.35
	var push := global_position - source_position
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


func remove_oil(amount: float) -> void:
	if _dead:
		return
	oil = maxf(0.0, oil - amount)
	SignalBus.oil_removed.emit(amount)
	SignalBus.oil_changed.emit(oil, max_oil)


func is_dead() -> bool:
	return _dead


func is_in_light() -> bool:
	return _in_light


func has_dash_charge() -> bool:
	return _dash_charges > 0 and _dash_cooldown_left <= 0.0 and _dash_time_left <= 0.0


func _on_enemy_hit(_enemy: Node, _damage: float, _position: Vector2) -> void:
	if _oil_on_hit > 0.0:
		add_oil(_oil_on_hit)


func _on_enemy_died(_enemy: Node, position: Vector2) -> void:
	if _dash_charges < _dash_charges_max:
		_dash_charges += 1
		_emit_dash()

	if _oil_on_kill_bonus > 0.0:
		add_oil(_oil_on_kill_bonus)

	if _nova_damage > 0.0 and _nova_radius > 0.0 and not _in_nova:
		_detonate_nova(position)


## Explosão de luz ao matar. `_in_nova` impede que a explosão se auto-alimente.
func _detonate_nova(position: Vector2) -> void:
	_in_nova = true
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_to(position) > _nova_radius:
			continue
		enemy.take_damage(_nova_damage, position)
	_in_nova = false
	SignalBus.shake_requested.emit(0.18)


func _emit_all() -> void:
	SignalBus.health_changed.emit(health, max_health)
	SignalBus.oil_changed.emit(oil, max_oil)
	_emit_dash()


func _emit_dash() -> void:
	SignalBus.dash_charges_changed.emit(_dash_charges, _dash_charges_max)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 13.0, Color(0.05, 0.08, 0.09))
	draw_circle(Vector2.ZERO, 11.0, Color(0.85, 0.72, 0.45))
	draw_circle(Vector2(0, -2), 4.0, Color(1.0, 0.88, 0.55))
	if _iframes > 0.0:
		draw_arc(Vector2.ZERO, 17.0, 0.0, TAU, 28, Color(1, 1, 1, 0.45), 2.0)
	if _dead:
		draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 28, Color(0.78, 0.2, 0.24, 0.8), 3.0)