class_name Beam
extends Node2D
## O Feixe: arma, visao e municao do jogador.
##
## Um cone de luz que aplica dano por tick a todo inimigo dentro do angulo e do
## alcance, com checagem de linha de visao contra o mundo. O custo e óleo,
## drenado pelo Player — este no so executa; nao conhece economia.
##
## O visual e procedural (Polygon2D com cores por vertice) para permitir
## iteracao rapida de feel sem produzir arte.

@export var range_length: float = 260.0
@export var half_angle_deg: float = 22.0
@export var damage_per_tick: float = 8.0
@export var tick_interval: float = 0.1
@export var world_mask: int = 1
@export var cone_color: Color = Color(1.0, 0.72, 0.28, 0.18)

var active: bool = false

var _cone: Polygon2D
var _core: Line2D
var _glow: PointLight2D
var _tick_accum: float = 0.0
var _half_angle: float = 0.0


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


func _process(delta: float) -> void:
	var visible_now := active
	_cone.visible = visible_now
	_core.visible = visible_now
	_glow.energy = 0.7 if visible_now else 0.0

	if not visible_now:
		_tick_accum = 0.0
		return

	_tick_accum += delta
	var safety := 0
	while _tick_accum >= tick_interval and safety < 8:
		_tick_accum -= tick_interval
		_apply_damage()
		safety += 1


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


func _apply_damage() -> void:
	var origin := global_position
	var direction := Vector2.RIGHT.rotated(global_rotation)
	var space := get_world_2d().direct_space_state
	var blocker_rid: RID = RID()
	if get_parent() is CollisionObject2D:
		blocker_rid = (get_parent() as CollisionObject2D).get_rid()

	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or not is_instance_valid(enemy):
			continue
		var to_target: Vector2 = enemy.global_position - origin
		var distance := to_target.length()
		if distance > range_length or distance < 0.001:
			continue
		if absf(direction.angle_to(to_target)) > _half_angle:
			continue
		if _is_blocked(origin, enemy.global_position, space, blocker_rid):
			continue
		enemy.take_damage(damage_per_tick, origin)
		SignalBus.beam_hit_enemy.emit(enemy, damage_per_tick)


func _is_blocked(from: Vector2, to: Vector2, space: PhysicsDirectSpaceState2D, blocker_rid: RID) -> bool:
	var query := PhysicsRayQueryParameters2D.create(from, to, world_mask)
	if blocker_rid.is_valid():
		query.exclude = [blocker_rid]
	var hit := space.intersect_ray(query)
	return not hit.is_empty()