class_name Enemy
extends CharacterBody2D
## Inimigo base: vida, dano por contato, morte e telegrafia.
##
## Comportamento fica em `_think(delta)`, que subclasses sobrescrevem. Nada de
## herança para "tipos de ataque": a base só conhece o esqueleto (perseguir,
## esperar, agir, morrer). Variantes trocam o cérebro, não o corpo.

signal died(enemy: Enemy)

const ACCEL: float = 900.0

@export var max_health: float = 30.0
@export var move_speed: float = 70.0
@export var contact_damage: float = 10.0
@export var contact_interval: float = 0.8
@export var oil_drop: float = 6.0
@export var cera_drop: int = 1
@export var body_color: Color = Color(0.34, 0.88, 0.85)
@export var body_radius: float = 11.0
@export var keep_distance: float = 0.0
## Sprite opcional (SVG). Vazio = corpo procedural de reserva.
@export var sprite_texture: Texture2D

var health: float = 30.0

var _contact_cooldown: float = 0.0
var _flash_left: float = 0.0
var _dead: bool = false
var _glow: Polygon2D
var _sprite_node: Sprite2D
var _base_scale: Vector2 = Vector2.ONE
var _anim_time: float = 0.0
var _target: Player

var _telegraph_left: float = 0.0
var _telegraph_total: float = 1.0


func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	_build_glow()
	_build_sprite()


## Cria o sprite a partir de `sprite_texture`, escalado para o corpo.
func _build_sprite() -> void:
	if sprite_texture == null:
		return
	_sprite_node = Sprite2D.new()
	_sprite_node.name = "Sprite"
	_sprite_node.texture = sprite_texture
	add_child(_sprite_node)
	move_child(_sprite_node, 0)
	_fit_sprite()


## Ajusta a escala para que o sprite tenha ~2.8x o diâmetro de colisão.
func _fit_sprite() -> void:
	if _sprite_node == null or _sprite_node.texture == null:
		return
	var height := float(_sprite_node.texture.get_height())
	if height <= 0.0:
		return
	_sprite_node.scale = Vector2.ONE * (body_radius * 2.8 / height)
	_sprite_node.position = Vector2(0.0, -1.0)
	_base_scale = _sprite_node.scale


func _process(delta: float) -> void:
	_anim_time += delta
	_update_sprite_facing()
	_animate_sprite()


## "Respiração" por código: o sprite balança ao andar e achata ao apanhar.
func _animate_sprite() -> void:
	if _sprite_node == null:
		return

	var moving := velocity.length() > 20.0
	var bob := sin(_anim_time * (9.0 if moving else 3.0)) * (1.5 if moving else 0.7)
	_sprite_node.position.y = -1.0 + bob

	var squash := 1.0
	if _flash_left > 0.0:
		squash += 0.10 * (_flash_left / 0.08)
	if _telegraph_left > 0.0:
		var progress := 1.0 - (_telegraph_left / maxf(0.01, _telegraph_total))
		squash += 0.06 * sin(progress * TAU * 3.0)
	_sprite_node.scale = Vector2(_base_scale.x / squash, _base_scale.y * squash)


## Sprites são desenhados "para cima"; giramos para o alvo (ou para a velocidade).
func _update_sprite_facing() -> void:
	if _sprite_node == null:
		return
	var heading := velocity
	if heading.length_squared() < 16.0 and _target != null:
		heading = _target.global_position - global_position
	if heading.length_squared() < 0.01:
		return
	_sprite_node.rotation = heading.angle() + PI * 0.5


func apply_data(data: EnemyData) -> void:
	max_health = data.health
	health = data.health
	move_speed = data.move_speed
	contact_damage = data.contact_damage
	oil_drop = data.oil_drop
	cera_drop = data.cera_drop
	body_color = data.body_color


func _physics_process(delta: float) -> void:
	if _dead:
		return

	_contact_cooldown = maxf(0.0, _contact_cooldown - delta)
	_flash_left = maxf(0.0, _flash_left - delta)
	_target = _find_target()

	if _telegraph_left > 0.0:
		_telegraph_left = maxf(0.0, _telegraph_left - delta)
		velocity = velocity.move_toward(Vector2.ZERO, ACCEL * 2.0 * delta)
		move_and_slide()
		_update_tint()
		if _telegraph_left <= 0.0:
			_on_telegraph_end()
		return

	_think(delta)
	move_and_slide()
	_try_contact()
	_update_tint()


## Comportamento. Subclasses sobrescrevem.
func _think(delta: float) -> void:
	_chase(delta)


## Persegue (ou mantém distância, se `keep_distance` > 0).
func _chase(delta: float) -> void:
	if _target == null:
		velocity = velocity.move_toward(Vector2.ZERO, ACCEL * delta)
		return

	var to_target: Vector2 = _target.global_position - global_position
	var distance := to_target.length()
	var heading := Vector2.ZERO

	if distance > 4.0:
		heading = to_target.normalized()
	if keep_distance > 0.0 and distance < keep_distance:
		heading = -to_target.normalized()

	velocity = velocity.move_toward(heading * move_speed, ACCEL * delta)


## Inicia a telegrafia. O inimigo para e "avisa" antes de agir.
func _start_telegraph(duration: float) -> void:
	_telegraph_total = maxf(0.01, duration)
	_telegraph_left = _telegraph_total
	velocity = Vector2.ZERO


func is_telegraphing() -> bool:
	return _telegraph_left > 0.0


## Chamado quando a telegrafia termina. Subclasses implementam o ataque.
func _on_telegraph_end() -> void:
	pass


func _try_contact() -> void:
	if _target == null or _contact_cooldown > 0.0:
		return
	if global_position.distance_to(_target.global_position) > body_radius + 16.0:
		return
	_target.take_damage(contact_damage, global_position)
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
	died.emit(self)
	SignalBus.enemy_died.emit(self, global_position)
	SignalBus.enemy_killed.emit(global_position, oil_drop)
	queue_free()


func _find_target() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


func _spawn_projectile(
	heading: Vector2,
	travel_speed: float,
	hit_damage: float,
	oil_cost: float,
) -> void:
	var pool := get_tree().get_first_node_in_group("projectile_pool") as ProjectilePool
	if pool == null:
		return
	pool.spawn(global_position, heading, travel_speed, hit_damage, oil_cost, body_color)
	SignalBus.projectile_fired.emit(global_position, heading)


func _update_tint() -> void:
	if _flash_left > 0.0:
		modulate = Color(4, 4, 4)
	elif _telegraph_left > 0.0:
		var progress := 1.0 - (_telegraph_left / _telegraph_total)
		var pulse := 0.5 + 0.5 * sin(progress * TAU * 3.0)
		modulate = Color(1.0 + pulse * 1.4, 1.0 + pulse * 0.5, 1.0 + pulse * 0.5)
	else:
		modulate = Color.WHITE


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
	if _sprite_node != null:
		return
	var body := body_color.darkened(0.35)
	draw_circle(Vector2.ZERO, body_radius, Color(0.03, 0.06, 0.07))
	draw_circle(Vector2.ZERO, body_radius - 2.0, body)
	draw_circle(Vector2.ZERO, body_radius * 0.45, body_color.darkened(0.15))