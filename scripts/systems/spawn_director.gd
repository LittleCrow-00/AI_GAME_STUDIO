class_name SpawnDirector
extends Node
## Diretor de spawn por orçamento de ameaça.
##
## Em vez de "N inimigos", a sala recebe um orçamento e uma lista de inimigos com
## custo. O diretor gasta o orçamento aos poucos, respeitando um teto de vivos.
## Isso escala de forma previsível e permite ondas grandes sem virar parede de
## inimigos (e sem estourar o orçamento de performance do Web).

signal spawn_enemy(data: EnemyData)

@export var spawn_interval: float = 0.55
@export var max_alive: int = 14

var alive_count: int = 0

var _pool: Array[EnemyData] = []
var _budget: int = 0
var _timer: float = 0.0
var _running: bool = false
var _rng := RandomNumberGenerator.new()


func configure(pool: Array[EnemyData], budget: int, max_alive_count: int) -> void:
	_pool = pool
	_budget = budget
	max_alive = max_alive_count
	_timer = 0.0
	alive_count = 0
	_rng.randomize()


func start() -> void:
	_running = true
	_timer = 0.0


func stop() -> void:
	_running = false


func budget_left() -> int:
	return _budget


func is_running() -> bool:
	return _running


func _process(delta: float) -> void:
	if not _running or _budget <= 0 or alive_count >= max_alive:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = spawn_interval

	var data := _pick()
	if data == null:
		_budget = 0
		return
	_budget = maxi(0, _budget - data.cost)
	spawn_enemy.emit(data)


func _pick() -> EnemyData:
	if _pool.is_empty():
		return null
	return _pool[_rng.randi_range(0, _pool.size() - 1)]