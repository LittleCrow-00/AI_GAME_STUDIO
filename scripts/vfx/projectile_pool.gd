class_name ProjectilePool
extends Node
## Pool fixo de projéteis. Enfileirar em vez de instanciar: menos lixo, menos
## picos de frame. Se o pool encher, o projétil mais antigo é reciclado — e
## melhor um tiro sumir do que o frame-rate cair.

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/vfx/projectile.tscn")
const POOL_SIZE: int = 48

var _pool: Array[Projectile] = []
var _cursor: int = 0


func _ready() -> void:
	add_to_group("projectile_pool")
	for i in range(POOL_SIZE):
		var projectile := PROJECTILE_SCENE.instantiate() as Projectile
		projectile.deactivate()
		add_child(projectile)
		_pool.append(projectile)


func spawn(
	at_position: Vector2,
	heading: Vector2,
	travel_speed: float,
	hit_damage: float,
	oil_cost: float,
	color: Color,
) -> Projectile:
	for i in range(POOL_SIZE):
		var index := (_cursor + i) % POOL_SIZE
		var projectile := _pool[index]
		if projectile.active:
			continue
		_cursor = (index + 1) % POOL_SIZE
		projectile.activate(at_position, heading, travel_speed, hit_damage, oil_cost, color)
		return projectile

	var fallback := _pool[_cursor]
	_cursor = (_cursor + 1) % POOL_SIZE
	fallback.activate(at_position, heading, travel_speed, hit_damage, oil_cost, color)
	return fallback


func active_count() -> int:
	var count := 0
	for projectile in _pool:
		if projectile.active:
			count += 1
	return count