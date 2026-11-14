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
const ENEMY_BOITATA: EnemyData = preload("res://data/enemies/boitata.tres")
const ENEMY_MAPINGUARI: EnemyData = preload("res://data/enemies/mapinguari.tres")
const ENEMY_MULA: EnemyData = preload("res://data/enemies/mula.tres")
const ENEMY_CAIPORA: EnemyData = preload("res://data/enemies/caipora.tres")

const FAROL_SCENE: PackedScene = preload("res://scenes/gameplay/farol.tscn")

const DEFAULT_BIOME: BiomeData = preload("res://data/biomes/mare_baixa.tres")

const WAVES_PER_ROOM: int = 3
const BASE_BUDGET: int = 4
const MAX_ALIVE: int = 14
const WAVE_BREAK: float = 0.7

@export var arena_size: Vector2 = Vector2(1120.0, 640.0)
@export var room_index: int = 0
@export var is_boss_room: bool = false
@export var is_final_room: bool = false
## Chefe da sala. Vazio = sala de ondas normais.
@export var boss: EnemyData
## Bioma da sala. Vazio = `DEFAULT_BIOME`.
@export var biome: BiomeData
## Prologo: sem ondas, o Farol acende com o feixe.
@export var is_prologue: bool = false
## Chance de um inimigo nascer elite (a partir da 2ª sala).
@export var elite_chance: float = 0.12

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

	if is_prologue:
		_spawn_farol(true)
	elif is_final_room:
		_spawn_farol(false)

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
	if is_prologue:
		SignalBus.message_requested.emit("APONTE O FEIXE PARA O FAROL", 3.0)
		return
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
	return 1 if boss != null else WAVES_PER_ROOM


func _start_wave() -> void:
	_wave_index += 1
	if _wave_index >= _waves_total():
		_finish_room()
		return

	_wave_finished = false
	if boss != null:
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
	var data := boss
	var boss_enemy := data.scene.instantiate() as Enemy
	boss_enemy.position = Vector2(0.0, -160.0)
	boss_enemy.apply_data(data)
	add_child(boss_enemy)
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
		pool.append(ENEMY_BOITATA)
		pool.append(ENEMY_MULA)
		pool.append(ENEMY_CAIPORA)
	if room_index >= 3:
		pool.append(ENEMY_MAPINGUARI)
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
	if room_index >= 1 and _rng.randf() < elite_chance:
		enemy.make_elite()

	add_child(enemy)
	_alive += 1
	_director.alive_count = _alive
	SignalBus.enemies_remaining_changed.emit(_alive)


func _on_enemy_died(enemy: Node, position: Vector2) -> void:
	if not _active:
		return
	_alive = maxi(0, _alive - 1)
	_director.alive_count = _alive
	SignalBus.enemies_remaining_changed.emit(_alive)
	TimeService.hitstop(45)
	SignalBus.shake_requested.emit(0.22)
	_spawn_death_burst(enemy, position)


func _spawn_death_burst(enemy: Node, position: Vector2) -> void:
	var burst := DeathBurst.new()
	burst.position = position
	var body := enemy as Enemy
	if body != null:
		burst.tint = body.body_color
	add_child(burst)


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


func _spawn_farol(charge_by_light: bool = false) -> void:
	_farol = FAROL_SCENE.instantiate() as Farol
	_farol.position = Vector2(0.0, -40.0)
	_farol.charge_by_light = charge_by_light
	_farol.lit.connect(_on_farol_lit)
	if is_prologue:
		_farol.set_active(true)
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
	var palette := _palette()

	draw_rect(floor_rect, palette["base"] as Color)

	var step := 80.0
	var y := -half.y
	while y < half.y - 0.5:
		var x := -half.x
		while x < half.x - 0.5:
			var tile_hash := absi(int(x) * 73856093 ^ int(y) * 19349663)
			var shade := 0.88 + float(tile_hash % 9) * 0.025
			var w := minf(step, half.x - x)
			var h := minf(step, half.y - y)
			var tile := palette["tile"] as Color
			draw_rect(
				Rect2(x + 1.5, y + 1.5, w - 3.0, h - 3.0),
				Color(tile.r * shade, tile.g * shade, tile.b * shade),
			)
			x += step
		y += step

	_draw_puddles(half, palette["puddle"] as Color)
	_draw_walls(half, palette)


## A profundidade muda a paleta: mais fundo, mais frio e mais roxo.
func _palette() -> Dictionary:
	var palette := biome if biome != null else DEFAULT_BIOME
	return {
		"base": palette.base_color,
		"tile": palette.tile_color,
		"puddle": palette.puddle_color,
		"wall": palette.wall_color,
		"edge": palette.edge_color,
		"rim": palette.rim_color,
	}


func _draw_puddles(half: Vector2, tint: Color) -> void:
	var spots: Array[Vector3] = [
		Vector3(-0.28, -0.18, 62.0),
		Vector3(0.31, 0.22, 48.0),
		Vector3(0.05, 0.34, 38.0),
		Vector3(-0.12, 0.05, 30.0),
	]
	for spot in spots:
		var center := Vector2(spot.x * half.x, spot.y * half.y)
		var radius := spot.z
		draw_set_transform(center, 0.0, Vector2(1.0, 0.55))
		draw_circle(Vector2.ZERO, radius, Color(tint.r, tint.g, tint.b, 0.55))
		draw_circle(Vector2.ZERO, radius * 0.72, Color(tint.r * 1.3, tint.g * 1.3, tint.b * 1.3, 0.35))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_arc(center, radius * 0.9, PI * 0.15, PI * 0.85, 18, Color(0.45, 0.62, 0.66, 0.18), 1.6)


func _draw_walls(half: Vector2, palette: Dictionary) -> void:
	var thickness := 60.0
	var wall_color := palette["wall"] as Color
	var edge := palette["edge"] as Color
	var rim := Color(palette["rim"], 0.55)

	var outer := Rect2(
		-half - Vector2(thickness, thickness),
		arena_size + Vector2(thickness, thickness) * 2.0,
	)
	draw_rect(outer, wall_color)

	var inner := Rect2(-half, arena_size)
	draw_rect(inner, edge, false, 3.0)
	draw_rect(Rect2(-half + Vector2(3, 3), arena_size - Vector2(6, 6)), rim, false, 1.0)

	var pillar := 26.0
	for corner in [
		-half + Vector2(-pillar * 0.5, -pillar * 0.5),
		Vector2(half.x - pillar * 0.5, -half.y - pillar * 0.5),
		Vector2(-half.x - pillar * 0.5, half.y - pillar * 0.5),
		half - Vector2(pillar * 0.5, pillar * 0.5),
	]:
		draw_rect(Rect2(corner, Vector2(pillar, pillar)), Color(wall_color.lightened(0.6), 0.9))
		draw_rect(Rect2(corner, Vector2(pillar, pillar)), Color(rim, 0.75), false, 1.5)