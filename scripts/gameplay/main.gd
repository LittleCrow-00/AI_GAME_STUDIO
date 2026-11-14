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
const BOSS_ROOM: int = 2
const FINAL_ROOM: int = 3

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
var _started_ms: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	RngService.new_run()
	TimeService.clear()
	_started_ms = Time.get_ticks_msec()

	_ressonancia = Ressonancia.new()
	_ressonancia.name = "Ressonancia"
	add_child(_ressonancia)

	var tutorial := TutorialDirector.new()
	tutorial.name = "TutorialDirector"
	add_child(tutorial)

	SignalBus.player_died.connect(_on_player_died)
	SignalBus.enemy_died.connect(_on_enemy_died)
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
	_arena.is_boss_room = index == BOSS_ROOM
	_arena.is_final_room = index == FINAL_ROOM
	add_child(_arena)
	move_child(_arena, 0)
	_arena.room_cleared.connect(_on_room_cleared)

	player.global_position = Vector2.ZERO
	player.velocity = Vector2.ZERO
	player.heal(25.0)

	hud.set_room(index + 1, ROOM_TOTAL)
	_state = State.COMBAT
	SignalBus.run_state_changed.emit(_state)
	SignalBus.message_requested.emit("DESCEU %d" % (index + 1), 1.4)


func _on_room_cleared() -> void:
	if _transitioning:
		return
	_transitioning = true
	_rooms_cleared += 1

	if _room_index + 1 >= ROOM_TOTAL:
		_win()
		return

	_state = State.SANCTUARY
	SignalBus.run_state_changed.emit(_state)

	var boons := BoonDatabase.draw(3)
	get_tree().paused = true
	sanctuary.open(boons)
	var chosen: BoonData = await sanctuary.boon_chosen
	sanctuary.close()
	get_tree().paused = false

	if chosen != null:
		player.apply_boon(chosen)

	_transitioning = false
	_start_room(_room_index + 1)


func _on_enemy_died(_enemy: Node, _position: Vector2) -> void:
	_kills += 1


func _on_player_died() -> void:
	if _state == State.DEAD or _state == State.VICTORY:
		return
	_state = State.DEAD
	SignalBus.run_state_changed.emit(_state)
	if _arena != null:
		_arena.stop()
	summary.show_summary("A LUZ SE APAGOU", _summary_lines(), Color(0.85, 0.30, 0.30))


func _win() -> void:
	_state = State.VICTORY
	SignalBus.run_state_changed.emit(_state)
	if _arena != null:
		_arena.stop()
	summary.show_summary("O FAROL ACENDEU", _summary_lines(), Color(1.0, 0.86, 0.55))


func _summary_lines() -> Array:
	var seconds := int((Time.get_ticks_msec() - _started_ms) / 1000)
	var minutes := seconds / 60
	var rest := seconds % 60
	return [
		"salas limpas      %d / %d" % [_rooms_cleared, ROOM_TOTAL],
		"abates            %d" % _kills,
		"pontos            %d" % _ressonancia.score,
		"tempo             %02d:%02d" % [minutes, rest],
		"semente           %d" % RngService.run_seed,
	]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().paused = false
		get_tree().reload_current_scene()