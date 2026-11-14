class_name Arena
extends Node2D
## Uma sala de combate. Constroi as paredes, dispara as ondas e decide quando a
## sala esta limpa. Nao conhece run nem meta-progressao: so responde a `setup`.

signal room_cleared
signal wave_changed(index: int, total: int)

const ENEMY_DATA: EnemyData = preload("res://data/enemies/afogado.tres")
const OIL_DROP_SCENE: PackedScene = preload("res://scenes/pickups/oil_drop.tscn")

@export var arena_size: Vector2 = Vector2(1120.0, 640.0)
@export var waves: Array[int] = [4, 6, 8]
@export var difficulty: float = 1.0

var _wave_index: int = -1
var _alive: int = 0
var _active: bool = false
var _wave_token: int = 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_build_room()
	SignalBus.enemy_died.connect(_on_enemy_died)
	SignalBus.enemy_killed.connect(_on_enemy_killed)
	start()


func setup(room_index: int) -> void:
	difficulty = 1.0 + 0.45 * float(room_index)
	waves.clear()
	var base: Array[int] = [4, 6, 8]
	for count in base:
		waves.append(count + room_index * 2)


func start() -> void:
	if _active:
		return
	_active = true
	_next_wave()


func stop() -> void:
	_active = false
	_wave_token += 1


func _next_wave() -> void:
	if not _active:
		return
	_wave_token += 1
	_wave_index += 1
	if _wave_index >= waves.size():
		_finish_room()
		return

	var count: int = waves[_wave_index]
	_alive = count
	wave_changed.emit(_wave_index, waves.size())
	SignalBus.wave_started.emit(_wave_index, waves.size())
	SignalBus.enemies_remaining_changed.emit(_alive)

	for i in range(count):
		_spawn_enemy()


func _spawn_enemy() -> void:
	var enemy := ENEMY_DATA.scene.instantiate() as Enemy
	enemy.position = _random_spawn_position()
	enemy.apply_data(ENEMY_DATA)
	enemy.max_health = ENEMY_DATA.health * difficulty
	enemy.health = enemy.max_health
	enemy.move_speed = ENEMY_DATA.move_speed * (1.0 + 0.04 * (difficulty - 1.0))
	enemy.contact_damage = ENEMY_DATA.contact_damage * (1.0 + 0.2 * (difficulty - 1.0))
	enemy.oil_drop = ENEMY_DATA.oil_drop
	add_child(enemy)


func _finish_room() -> void:
	_active = false
	SignalBus.message_requested.emit("SALA LIMPA", 2.0)
	room_cleared.emit()
	SignalBus.room_cleared.emit()


func _on_enemy_died(_enemy: Node, _position: Vector2) -> void:
	if not _active:
		return
	_alive = maxi(0, _alive - 1)
	SignalBus.enemies_remaining_changed.emit(_alive)
	if _alive > 0:
		return

	var token := _wave_token
	await get_tree().create_timer(0.7).timeout
	if token != _wave_token or not _active:
		return
	_next_wave()


func _on_enemy_killed(position: Vector2, oil_drop: float) -> void:
	var drop := OIL_DROP_SCENE.instantiate() as OilDrop
	drop.amount = oil_drop
	drop.position = position
	add_child(drop)


func _random_spawn_position() -> Vector2:
	var half := arena_size * 0.5
	var margin := 80.0
	var x := _rng.randf_range(-half.x + margin, half.x - margin)
	var y := _rng.randf_range(-half.y + margin, half.y - margin)
	match _rng.randi_range(0, 3):
		0:
			return Vector2(x, -half.y + margin)
		1:
			return Vector2(x, half.y - margin)
		2:
			return Vector2(-half.x + margin, y)
		_:
			return Vector2(half.x - margin, y)


func _build_room() -> void:
	var half := arena_size * 0.5
	var thickness := 60.0
	var rects: Array[Rect2] = [
		Rect2(-half.x - thickness, -half.y - thickness, arena_size.x + thickness * 2.0, thickness),
		Rect2(-half.x - thickness, half.y, arena_size.x + thickness * 2.0, thickness),
		Rect2(-half.x - thickness, -half.y, thickness, arena_size.y + thickness * 2.0),
		Rect2(half.x, -half.y, thickness, arena_size.y + thickness * 2.0),
	]

	var walls := StaticBody2D.new()
	walls.name = "Walls"
	walls.collision_layer = 1
	walls.collision_mask = 0
	add_child(walls)

	for rect in rects:
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = rect.size
		shape.shape = rectangle
		shape.position = rect.position + rect.size * 0.5
		walls.add_child(shape)


func _draw() -> void:
	var half := arena_size * 0.5
	var floor_rect := Rect2(-half, arena_size)
	draw_rect(floor_rect, Color(0.043, 0.078, 0.094))
	draw_rect(floor_rect, Color(0.11, 0.19, 0.22), false, 3.0)

	var step := 80.0
	var x := -half.x + step
	while x < half.x:
		draw_line(Vector2(x, -half.y), Vector2(x, half.y), Color(0.09, 0.15, 0.18), 1.0)
		x += step
	var y := -half.y + step
	while y < half.y:
		draw_line(Vector2(-half.x, y), Vector2(half.x, y), Color(0.09, 0.15, 0.18), 1.0)
		y += step