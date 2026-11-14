class_name Enemy
extends CharacterBody2D
## Inimigo base. Comportamento padrao: perseguir o jogador e causar dano por
## contato. Variantes futuras compoem este no trocando o brain por um no filho
## (ver docs/architecture.md: composicao sobre heranca).

@export var max_health: float = 30.0
@export var move_speed: float = 70.0
@export var contact_damage: float = 10.0
@export var contact_interval: float = 0.8
@export var oil_drop: float = 6.0
@export var body_color: Color = Color(0.34, 0.88, 0.85)
@export var body_radius: float = 11.0

var health: float = 30.0

var _contact_cooldown: float = 0.0
var _flash_left: float = 0.0
var _dead: bool = false
var _glow: Polygon2D


func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	_build_glow()


func apply_data(data: EnemyData) -> void:
	max_health = data.health
	health = data.health
	move_speed = data.move_speed
	contact_damage = data.contact_damage
	oil_drop = data.oil_drop
	body_color = data.body_color


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_contact_cooldown = maxf(0.0, _contact_cooldown - delta)
	_flash_left = maxf(0.0, _flash_left - delta)
	modulate = Color(4, 4, 4) if _flash_left > 0.0 else Color.WHITE

	var target := _find_target()
	if target == null:
		velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
		move_and_slide()
		return

	var to_target: Vector2 = target.global_position - global_position
	if to_target.length() > 4.0:
		velocity = velocity.move_toward(to_target.normalized() * move_speed, 900.0 * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	move_and_slide()

	if _contact_cooldown <= 0.0 and global_position.distance_to(target.global_position) < body_radius + 16.0:
		target.take_damage(contact_damage, global_position)
		_contact_cooldown = contact_interval


func take_damage(amount: float, source_position: Vector2) -> void:
	if _dead:
		return
	health -= amount
	_flash_left = 0.08
	SignalBus.damage_number_requested.emit(amount, global_position, false)
	SignalBus.enemy_hit.emit(self, amount, global_position)

	var push := global_position - source_position
	if push.length_squared() > 0.01:
		velocity += push.normalized() * 60.0

	if health <= 0.0:
		_die()


func _die() -> void:
	_dead = true
	SignalBus.enemy_died.emit(self, global_position)
	SignalBus.enemy_killed.emit(global_position, oil_drop)
	queue_free()


func _find_target() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


func _build_glow() -> void:
	_glow = Polygon2D.new()
	_glow.name = "Glow"
	_glow.polygon = PackedVector2Array([
		Vector2(0, -4), Vector2(4, 0), Vector2(0, 4), Vector2(-4, 0),
	])
	_glow.color = body_color.lightened(0.45)
	_glow.material = LightFactory.unshaded_material()
	_glow.position = Vector2(0, -body_radius - 4.0)
	add_child(_glow)


func _draw() -> void:
	var body := body_color.darkened(0.35)
	draw_circle(Vector2.ZERO, body_radius, Color(0.03, 0.06, 0.07))
	draw_circle(Vector2.ZERO, body_radius - 2.0, body)
	draw_circle(Vector2.ZERO, body_radius * 0.45, body_color.darkened(0.15))