class_name Projectile
extends Area2D
## Projétil simples, reciclado por `ProjectilePool`.
##
## Ativo = visível + processando. O pool evita criar/destruir nós no meio do
## combate (o que causaria picos de frame no export Web).

var active: bool = false

var direction: Vector2 = Vector2.RIGHT
var speed: float = 260.0
var damage: float = 7.0
var oil_drain: float = 0.0
var lifetime: float = 0.0
var tint: Color = Color(0.34, 0.88, 0.85)


func _ready() -> void:
	collision_layer = 8
	collision_mask = 1 | 2
	monitoring = true
	body_entered.connect(_on_body_entered)
	active = false
	visible = false
	set_physics_process(false)


func activate(
	at_position: Vector2,
	heading: Vector2,
	travel_speed: float,
	hit_damage: float,
	oil_cost: float,
	color: Color,
) -> void:
	position = at_position
	direction = heading.normalized()
	speed = travel_speed
	damage = hit_damage
	oil_drain = oil_cost
	tint = color
	lifetime = 3.0
	active = true
	visible = true
	set_physics_process(true)
	queue_redraw()


func deactivate() -> void:
	active = false
	visible = false
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	if not active:
		return
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		deactivate()


func _on_body_entered(body: Node) -> void:
	if not active:
		return
	if body is Player:
		var player := body as Player
		player.take_damage(damage, global_position)
		if oil_drain > 0.0:
			player.remove_oil(oil_drain)
		deactivate()
		return
	deactivate()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, Color(tint.r, tint.g, tint.b, 0.22))
	draw_circle(Vector2.ZERO, 3.4, tint)
	draw_circle(-direction * 4.0, 1.8, Color(tint.r, tint.g, tint.b, 0.5))