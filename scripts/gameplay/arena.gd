class_name Arena
extends Node2D
## Uma sala de combate.
##
## Responsabilidades: geometria, focos de luz, pool de projéteis e o ciclo de
## ondas (via SpawnDirector). Não conhece run nem meta-progressão: o Main decide
## quando criar/destruir a sala.

signal room_cleared

const OIL_DROP_SCENE: PackedScene = preload("res://scenes/pickups/oil_drop.tscn")
const LIGHT_WELL_SCENE: PackedScene = preload("res://scenes/gameplay/light_well.tscn")

const ENEMY_AFOGADO: EnemyData = preload("res://data/enemies/afogado.tres")
const ENEMY_IARA: EnemyData = preload("res://data/enemies/iara.tres")
const ENEMY_BOTO: EnemyData = preload("res://data/enemies/boto.tres")
const ENEMY_CURUPIRA: EnemyData = preload("res://data/enemies/curupira.tres")
const ENEMY_COBRA: EnemyData = preload("res://data/enemies/cobra_grande.tres")

const FAROL_SCENE: PackedScene = preload("res://scenes/gameplay/farol.tscn")

const WAVES_PER_ROOM: int = 3
const BASE_BUDGET: int = 4
const MAX_ALIVE: int = 14
const WAVE_BREAK: float = 0.7

@export var arena_size: Vector2 = Vector2(1120.0, 640.0)
@export var room_index: int = 0
@export var is_boss_room: bool = false
@export var is_final_room: bool = false

var _director: SpawnDirector
var _wave_index: int = -1
var _alive: int = 0
var _active: bool = false
var _wave_finished: bool = true
var _wave_clear_timer: float = 0.0
var _farol: Farol
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_build_room()

	var pool := ProjectilePool.new()
	pool.name = "ProjectilePool"
	add_child(pool)

	_spawn_light_wells()

	if is_final_room:
		_spawn_farol()

	_director = SpawnDirector.new()
	_director.name = "SpawnDirector"
	add_child(_director)
	_director.spawn_enemy.connect(_on_spawn_enemy)

	SignalBus.enemy_died.connect(_on_enemy_died)
	SignalBus.enemy_killed.connect(_on_enemy_killed)
	start()


func setup(index: int) -> void:
	room_index = index


func start() -> void:
	if _active:
		return
	_active = true
	_start_wave()


func stop() -> void:
	_active = false
	_wave_finished = true
	if _director != null:
		_director.stop()


func _process(delta: float) -> void:
	if not _active:
		return

	if _wave_finished:
		if _wave_clear_timer <= 0.0:
			return
		_wave_clear_timer -= delta
		if _wave_clear_timer <= 0.0:
			_start_wave()
		return

	if _director.budget_left() > 0 or _alive > 0:
		return

	_wave_finished = true
	if _wave_index + 1 >= _waves_total():
		_finish_room()
	else:
		_wave_clear_timer = WAVE_BREAK


func _waves_total() -> int:
	return 1 if is_boss_room else WAVES_PER_ROOM


func _start_wave() -> void:
	_wave_index += 1
	if _wave_index >= _waves_total():
		_finish_room()
		return

	_wave_finished = false
	if is_boss_room:
		_spawn_boss()
		SignalBus.wave_started.emit(0, 1)
		SignalBus.enemies_remaining_changed.emit(_alive)
		return

	var budget := BASE_BUDGET + _wave_index * 2 + room_index * 2
	_director.configure(_enemy_pool(), budget, MAX_ALIVE)
	_director.start()
	SignalBus.wave_started.emit(_wave_index, WAVES_PER_ROOM)
	SignalBus.enemies_remaining_changed.emit(_alive)


func _spawn_boss() -> void:
	var boss := ENEMY_COBRA.scene.instantiate() as Enemy
	boss.position = Vector2(0.0, -160.0)
	boss.apply_data(ENEMY_COBRA)
	boss.max_health = ENEMY_COBRA.health
	boss.health = boss.max_health
	boss.move_speed = ENEMY_COBRA.move_speed
	boss.contact_damage = ENEMY_COBRA.contact_damage
	boss.oil_drop = ENEMY_COBRA.oil_drop
	add_child(boss)
	_alive += 1
	SignalBus.enemies_remaining_changed.emit(_alive)


func _finish_room() -> void:
	if not _active:
		return

	if is_final_room and _farol != null and not _farol.is_lit():
		_farol.set_active(true)
		SignalBus.message_requested.emit("ACENDA O FAROL", 2.0)
		return

	_active = false
	if _director != null:
		_director.stop()
	SignalBus.message_requested.emit("SALA LIMPA", 2.0)
	room_cleared.emit()
	SignalBus.room_cleared.emit()


func _on_farol_lit() -> void:
	if not _active:
		return
	_active = false
	room_cleared.emit()
	SignalBus.room_cleared.emit()


func _enemy_pool() -> Array[EnemyData]:
	var pool: Array[EnemyData] = [ENEMY_AFOGADO, ENEMY_IARA]
	if room_index >= 1:
		pool.append(ENEMY_CURUPIRA)
	if room_index >= 2:
		pool.append(ENEMY_BOTO)
	return pool


func _on_spawn_enemy(data: EnemyData) -> void:
	var enemy := data.scene.instantiate() as Enemy
	enemy.position = _random_spawn_position()
	enemy.apply_data(data)

	var health_scale := 1.0 + 0.18 * float(room_index)
	enemy.max_health = data.health * health_scale
	enemy.health = enemy.max_health
	enemy.move_speed = data.move_speed * (1.0 + 0.03 * float(room_index))
	enemy.contact_damage = data.contact_damage * (1.0 + 0.15 * float(room_index))
	enemy.oil_drop = data.oil_drop

	add_child(enemy)
	_alive += 1
	_director.alive_count = _alive
	SignalBus.enemies_remaining_changed.emit(_alive)


func _on_enemy_died(_enemy: Node, _position: Vector2) -> void:
	if not _active:
		return
	_alive = maxi(0, _alive - 1)
	_director.alive_count = _alive
	SignalBus.enemies_remaining_changed.emit(_alive)
	TimeService.hitstop(45)
	SignalBus.shake_requested.emit(0.22)


func _on_enemy_killed(position: Vector2, oil_drop: float) -> void:
	var drop := OIL_DROP_SCENE.instantiate() as OilDrop
	drop.amount = oil_drop
	drop.position = position
	add_child(drop)


func _spawn_light_wells() -> void:
	var offsets: Array[Vector2] = [Vector2(-350.0, -170.0), Vector2(350.0, 170.0)]
	for offset in offsets:
		var well := LIGHT_WELL_SCENE.instantiate() as LightWell
		well.position = offset
		add_child(well)


func _spawn_farol() -> void:
	_farol = FAROL_SCENE.instantiate() as Farol
	_farol.position = Vector2(0.0, -40.0)
	_farol.lit.connect(_on_farol_lit)
	add_child(_farol)


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