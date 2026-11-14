class_name Beam
extends Node2D
## O Feixe: arma, visão e munição do jogador.
##
## Um cone de luz que aplica dano por tick a todo inimigo dentro do ângulo e do
## alcance, com checagem de linha de visão contra o mundo.
##
## Refração cria feixes extras (mesmo tique, ângulos deslocados) e o modificador
## `pierce` remove a checagem de parede — ambos vindos de itens, nunca de `if`
## espalhado pela lógica.

const MAX_EXTRA_BEAMS: int = 4
const REFRACTION_SPREAD_DEG: float = 12.0

@export var range_length: float = 260.0
@export var half_angle_deg: float = 22.0
@export var damage_per_tick: float = 8.0
@export var tick_interval: float = 0.1
@export var world_mask: int = 1
@export var cone_color: Color = Color(1.0, 0.72, 0.28, 0.18)

var active: bool = false

var refraction: int = 0
var pierce_walls: bool = false

var _cone: Polygon2D
var _core: Line2D
var _extra_lines: Array[Line2D] = []
var _glow: PointLight2D
var _tick_accum: float = 0.0
var _half_angle: float = 0.0
var _impact_left: float = 0.0
var _impact_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	_half_angle = deg_to_rad(half_angle_deg)

	_cone = Polygon2D.new()
	_cone.name = "Cone"
	_cone.color = Color.WHITE
	add_child(_cone)

	_core = Line2D.new()
	_core.name = "Core"
	_core.width = 3.0
	_core.default_color = Color(1.0, 0.86, 0.58, 0.75)
	_core.joint_mode = Line2D.LINE_JOINT_ROUND
	add_child(_core)

	for i in range(MAX_EXTRA_BEAMS):
		var line := Line2D.new()
		line.name = "ExtraBeam%d" % i
		line.width = 2.0
		line.default_color = Color(1.0, 0.78, 0.4, 0.5)
		line.visible = false
		add_child(line)
		_extra_lines.append(line)

	_glow = PointLight2D.new()
	_glow.name = "Glow"
	_glow.texture = LightFactory.radial_texture(Color(1.0, 0.78, 0.42, 0.9), Color(1.0, 0.6, 0.2, 0.0))
	_glow.energy = 0.0
	_glow.scale = Vector2(1.8, 1.0)
	add_child(_glow)

	_rebuild()


func configure(p_range: float, p_half_angle_deg: float, p_damage: float) -> void:
	range_length = p_range
	half_angle_deg = p_half_angle_deg
	damage_per_tick = p_damage
	_half_angle = deg_to_rad(half_angle_deg)
	_rebuild()


func set_refraction(count: int) -> void:
	refraction = clampi(count, 0, MAX_EXTRA_BEAMS)
	_rebuild()


func set_pierce_walls(enabled: bool) -> void:
	pierce_walls = enabled


func _process(delta: float) -> void:
	var visible_now := active
	_cone.visible = visible_now
	_core.visible = visible_now
	for line in _extra_lines:
		line.visible = visible_now and line.get_meta("enabled", false)
	_glow.energy = 0.7 if visible_now else 0.0

	_impact_left = maxf(0.0, _impact_left - delta)
	queue_redraw()

	if not visible_now:
		_tick_accum = 0.0
		return

	_tick_accum += delta
	var safety := 0
	while _tick_accum >= tick_interval and safety < 8:
		_tick_accum -= tick_interval
		_apply_damage()
		safety += 1


func _beam_angles() -> Array[float]:
	var angles: Array[float] = [0.0]
	var spread := deg_to_rad(REFRACTION_SPREAD_DEG)
	for i in range(refraction):
		if angles.size() - 1 >= MAX_EXTRA_BEAMS:
			break
		angles.append(spread * float(i + 1))
		angles.append(-spread * float(i + 1))
	return angles


func _rebuild() -> void:
	var points := PackedVector2Array()
	points.append(Vector2.ZERO)
	var segments := 14
	for i in range(segments + 1):
		var angle := -_half_angle + (2.0 * _half_angle) * (float(i) / float(segments))
		points.append(Vector2.RIGHT.rotated(angle) * range_length)
	_cone.polygon = points

	var colors := PackedColorArray()
	colors.append(cone_color)
	for i in range(segments + 1):
		colors.append(Color(cone_color.r, cone_color.g, cone_color.b, 0.0))
	_cone.vertex_colors = colors

	_core.points = PackedVector2Array([Vector2.ZERO, Vector2.RIGHT * range_length])
	_glow.position = Vector2.RIGHT * range_length * 0.42

	var angles := _beam_angles()
	for i in range(_extra_lines.size()):
		var line := _extra_lines[i]
		var beam_index := i + 1
		if beam_index < angles.size():
			var direction := Vector2.RIGHT.rotated(angles[beam_index])
			line.points = PackedVector2Array([Vector2.ZERO, direction * range_length])
			line.set_meta("enabled", true)
			line.visible = active
		else:
			line.set_meta("enabled", false)
			line.visible = false


func _apply_damage() -> void:
	var origin := global_position
	var base_direction := Vector2.RIGHT.rotated(global_rotation)
	var space := get_world_2d().direct_space_state
	var blocker_rid: RID = RID()
	if get_parent() is CollisionObject2D:
		blocker_rid = (get_parent() as CollisionObject2D).get_rid()

	var hit_already := {}
	for offset in _beam_angles():
		_damage_cone(origin, base_direction.rotated(offset), space, blocker_rid, hit_already)


func _damage_cone(
	origin: Vector2,
	direction: Vector2,
	space: PhysicsDirectSpaceState2D,
	blocker_rid: RID,
	hit_already: Dictionary,
) -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or not is_instance_valid(enemy):
			continue
		if hit_already.has(enemy.get_instance_id()):
			continue

		var to_target: Vector2 = enemy.global_position - origin
		var distance := to_target.length()
		if distance > range_length or distance < 0.001:
			continue
		if absf(direction.angle_to(to_target)) > _half_angle:
			continue

		if not pierce_walls and _is_blocked(origin, enemy.global_position, space, blocker_rid):
			continue

		hit_already[enemy.get_instance_id()] = true
		enemy.take_damage(damage_per_tick, origin)
		SignalBus.beam_hit_enemy.emit(enemy, damage_per_tick)
		_impact_position = enemy.global_position
		_impact_left = 0.12


## Faísca no ponto de impacto. Some em 0,12 s.
func _draw() -> void:
	if _impact_left <= 0.0:
		return
	var t := clampf(_impact_left / 0.12, 0.0, 1.0)
	var local := to_local(_impact_position)
	draw_circle(local, 10.0 * t + 3.0, Color(1.0, 0.90, 0.62, 0.30 * t))
	for i in range(4):
		var angle := TAU * float(i) / 4.0 + 0.6
		draw_line(
			local,
			local + Vector2.from_angle(angle) * (9.0 * t),
			Color(1.0, 0.95, 0.75, 0.8 * t),
			1.6,
		)


func _is_blocked(from: Vector2, to: Vector2, space: PhysicsDirectSpaceState2D, blocker_rid: RID) -> bool:
	var query := PhysicsRayQueryParameters2D.create(from, to, world_mask)
	if blocker_rid.is_valid():
		query.exclude = [blocker_rid]
	var hit := space.intersect_ray(query)
	return not hit.is_empty()