extends Node2D
## Controlador da run. Orquestra salas, transicoes e fim de jogo.
##
## Ordem de responsabilidade (do menos para o mais volátil):
##   Arena  -> sala e ondas
##   Player -> combate e recursos
##   Main   -> sequencia de salas, vitoria e derrota
##
## Main nunca valida dano nem le spawn: ele apenas decide QUANDO as coisas
## acontecem. Isso mantem a run testavel e a expansao barata.

enum State { COMBAT, CLEARED, DEAD, VICTORY }

const ARENA_SCENE: PackedScene = preload("res://scenes/gameplay/arena.tscn")
const ROOM_TOTAL: int = 3
const TRANSITION_DELAY: float = 2.0

@onready var player: Player = $Player
@onready var hud: Hud = $UI/Hud

var _arena: Arena
var _ressonancia: Ressonancia
var _state: State = State.COMBAT
var _room_index: int = 0
var _transitioning: bool = false


func _ready() -> void:
	RngService.new_run()

	_ressonancia = Ressonancia.new()
	_ressonancia.name = "Ressonancia"
	add_child(_ressonancia)

	SignalBus.player_died.connect(_on_player_died)
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
	_state = State.CLEARED
	SignalBus.run_state_changed.emit(_state)

	await get_tree().create_timer(TRANSITION_DELAY).timeout
	if not is_inside_tree():
		return

	if _room_index + 1 >= ROOM_TOTAL:
		_win()
	else:
		_start_room(_room_index + 1)


func _win() -> void:
	_state = State.VICTORY
	SignalBus.run_state_changed.emit(_state)
	hud.show_banner("O FAROL ACENDEU", 9999.0)
	if _arena != null:
		_arena.stop()


func _on_player_died() -> void:
	_state = State.DEAD
	SignalBus.run_state_changed.emit(_state)
	hud.show_banner("A LUZ SE APAGOU", 9999.0)
	if _arena != null:
		_arena.stop()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()