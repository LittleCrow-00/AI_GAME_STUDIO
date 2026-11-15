extends Node2D
## Controlador da run.
##
## Sequência: sala 0 → santuário → sala 1 → santuário → sala 2 (chefe) →
## santuário → sala 3 (Farol) → vitória.
##
## Main nunca valida dano nem decide spawn: ele decide QUANDO as coisas acontecem
## e o que a run mostra no fim.

enum State { COMBAT, SANCTUARY, DEAD, VICTORY }

const ARENA_SCENE: PackedScene = preload("res://scenes/gameplay/arena.tscn")
const ROOM_TOTAL: int = 4
const PROLOGUE_ROOM: int = -1
const BOSS_ROOM: int = 2
const FINAL_ROOM: int = 3
const BOSS_COBRA: EnemyData = preload("res://data/enemies/cobra_grande.tres")
const BOSS_CUCA: EnemyData = preload("res://data/enemies/cuca.tres")
const BIOME_MARE: BiomeData = preload("res://data/biomes/mare_baixa.tres")
const BIOME_FOSSA: BiomeData = preload("res://data/biomes/fossa.tres")
const BIOME_CRIPTA: BiomeData = preload("res://data/biomes/cripta_afundada.tres")
const BIOME_CORACAO: BiomeData = preload("res://data/biomes/coracao_do_farol.tres")
const DIFF_FLOR: DifficultyData = preload("res://data/difficulty/flor_da_agua.tres")
const DIFF_FOSSA: DifficultyData = preload("res://data/difficulty/fossa.tres")
const DIFF_CRIPTA: DifficultyData = preload("res://data/difficulty/cripta_afundada.tres")
const DIFF_CORACAO: DifficultyData = preload("res://data/difficulty/coracao_do_farol.tres")

## Economia da run. Preço sobe por andar para a cera continuar sendo decisão.
@export var room_clear_cera: int = 5
@export var shop_price_base: int = 10
@export var shop_price_step: int = 4

@onready var player: Player = $Player
@onready var hud: Hud = $UI/Hud
@onready var sanctuary: Sanctuary = $UI/Sanctuary
@onready var summary: RunSummary = $UI/Summary

var _arena: Arena
var _ressonancia: Ressonancia
var _state: State = State.COMBAT
var _room_index: int = 0
var _transitioning: bool = false
var _kills: int = 0
var _rooms_cleared: int = 0
var _cera: int = 0
var _started_ms: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("run")
	RngService.new_run()
	TimeService.clear()
	_started_ms = Time.get_ticks_msec()

	_ressonancia = Ressonancia.new()
	_ressonancia.name = "Ressonancia"
	add_child(_ressonancia)

	var tutorial := TutorialDirector.new()
	tutorial.name = "TutorialDirector"
	add_child(tutorial)

	var sparks := SparkPool.new()
	sparks.name = "Sparks"
	add_child(sparks)

	var touch := TouchControls.new()
	touch.name = "TouchControls"
	add_child(touch)

	SignalBus.player_died.connect(_on_player_died)
	SignalBus.enemy_died.connect(_on_enemy_died)
	sanctuary.purchase_requested.connect(_on_purchase_requested)

	for unlock_item in SaveSystem.starting_items():
		player.apply_item(unlock_item)

	_start_room(0)


func _start_room(index: int) -> void:
	_room_index = index
	_transitioning = false

	if _arena != null and is_instance_valid(_arena):
		_arena.stop()
		_arena.queue_free()
		_arena = null

	_arena = ARENA_SCENE.instantiate() as Arena
	_arena.setup(index)
	_arena.is_prologue = index == PROLOGUE_ROOM
	_arena.boss = _boss_for(index)
	_arena.biome = _biome_for(index)
	_arena.difficulty = _difficulty_for(index)
	_arena.is_boss_room = _arena.boss != null
	_arena.is_final_room = index == FINAL_ROOM
	add_child(_arena)
	move_child(_arena, 0)
	_arena.room_cleared.connect(_on_room_cleared)

	player.global_position = Vector2.ZERO
	player.velocity = Vector2.ZERO
	player.heal(25.0)

	if index < 0:
		hud.set_room(0, ROOM_TOTAL)
		SignalBus.message_requested.emit("O FAROL", 1.6)
	else:
		hud.set_room(index + 1, ROOM_TOTAL)
		SignalBus.message_requested.emit("DESCEU %d" % (index + 1), 1.4)

	_state = State.COMBAT
	SignalBus.run_state_changed.emit(_state)


## Bioma por profundidade: a descida esfria e fica mais roxa.
func _biome_for(index: int) -> BiomeData:
	match index:
		1:
			return BIOME_FOSSA
		2:
			return BIOME_CRIPTA
		3:
			return BIOME_CORACAO
		_:
			return BIOME_MARE


## Curva de dificuldade por andar (dados, não conta na lógica).
func _difficulty_for(index: int) -> DifficultyData:
	match index:
		1:
			return DIFF_FOSSA
		2:
			return DIFF_CRIPTA
		3:
			return DIFF_CORACAO
		_:
			return DIFF_FLOR


## Chefe por sala: a Cobra Grande guarda a descida; a Cuca guarda o Farol.
func _boss_for(index: int) -> EnemyData:
	if index < 0:
		return null
	if index == BOSS_ROOM:
		return BOSS_COBRA
	if index == FINAL_ROOM:
		return BOSS_CUCA
	return null


func _on_room_cleared() -> void:
	if _transitioning:
		return
	_transitioning = true
	if _room_index == PROLOGUE_ROOM:
		_transitioning = false
		_start_room(0)
		return

	_rooms_cleared += 1

	if _room_index + 1 >= ROOM_TOTAL:
		_win()
		return

	_state = State.SANCTUARY
	SignalBus.run_state_changed.emit(_state)

	_add_cera(room_clear_cera)
	var price := shop_price_base + shop_price_step * _room_index
	get_tree().paused = true
	sanctuary.open(ItemDatabase.draw(3, _room_index + 1), _cera, price, true)
	await sanctuary.closed
	sanctuary.close()
	get_tree().paused = false

	_transitioning = false
	_start_room(_room_index + 1)


## O Santuário pede; o Main é a autoridade da carteira.
func _on_purchase_requested(item: ItemData, price: int) -> void:
	if item == null:
		return
	if price > _cera:
		sanctuary.deny_purchase(-1)
		return
	if price > 0:
		_add_cera(-price)
	player.apply_item(item)
	sanctuary.set_cera(_cera)


func _add_cera(amount: int) -> void:
	_cera = maxi(0, _cera + amount)
	SignalBus.cera_changed.emit(_cera)


func _on_enemy_died(enemy: Node, _position: Vector2) -> void:
	_kills += 1
	var fallen := enemy as Enemy
	if fallen != null:
		_add_cera(fallen.cera_drop)


func _on_player_died() -> void:
	if _state == State.DEAD or _state == State.VICTORY:
		return
	_state = State.DEAD
	SignalBus.run_state_changed.emit(_state)
	if _arena != null:
		_arena.stop()
	SaveSystem.record_run(_cera, _ressonancia.score)
	summary.show_summary("A LUZ SE APAGOU", _summary_lines(), Color(0.85, 0.30, 0.30))


func _win() -> void:
	_state = State.VICTORY
	SignalBus.run_state_changed.emit(_state)
	if _arena != null:
		_arena.stop()
	SaveSystem.record_run(_cera, _ressonancia.score)
	summary.show_summary("O FAROL ACENDEU", _summary_lines(), Color(1.0, 0.86, 0.55))


func _summary_lines() -> Array:
	var seconds := int((Time.get_ticks_msec() - _started_ms) / 1000)
	var minutes := seconds / 60
	var rest := seconds % 60
	return [
		"salas limpas      %d / %d" % [_rooms_cleared, ROOM_TOTAL],
		"abates            %d" % _kills,
		"pontos            %d" % _ressonancia.score,
		"cera              %d" % _cera,
		"tempo             %02d:%02d" % [minutes, rest],
		"semente           %d" % RngService.run_seed,
	]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().paused = false
		get_tree().reload_current_scene()