class_name TutorialDirector
extends Node
## Tutorial quase imperceptível.
##
## Regras que definem este arquivo:
##   - Sem modal, sem parede de texto, sem bloquear input.
##   - Cada dica aparece no máximo UMA vez por run.
##   - Alpha baixo (0.34) e some sozinha — é sussurro, não instrução.
##   - A maior parte do ensino é diegética: a lanterna encolhe quando o óleo
##     cai, o foco de luz pulsa, a gota de óleo voa até você.
##
## O texto só confirma o que o jogador já deveria ter percebido.

const HINT_ALPHA_DURATION: float = 1.8
const OIL_HINT_POSITION := Vector2(300.0, 74.0)
const DASH_HINT_POSITION := Vector2(300.0, 112.0)
const LIGHT_HINT_POSITION := Vector2(300.0, 560.0)

var _oil_warned: bool = false
var _light_hinted: bool = false
var _kill_hinted: bool = false
var _dash_hinted: bool = false


func _ready() -> void:
	SignalBus.oil_changed.connect(_on_oil_changed)
	SignalBus.light_well_entered.connect(_on_light_well_entered)
	SignalBus.enemy_died.connect(_on_enemy_died)
	SignalBus.player_damaged.connect(_on_player_damaged)
	SignalBus.wave_started.connect(_on_wave_started)


func _on_wave_started(index: int, _total: int) -> void:
	if index > 0:
		return
	var hud := _hud()
	if hud != null:
		hud.show_hint("segure o feixe · a luz gasta", HINT_ALPHA_DURATION, Vector2(300.0, 74.0))


func _on_oil_changed(current: float, maximum: float) -> void:
	if _oil_warned or maximum <= 0.0:
		return
	if current / maximum > 0.3:
		return
	_oil_warned = true
	_hint("óleo baixo · você está quase cego", OIL_HINT_POSITION, 2.0)


func _on_light_well_entered(_well: Node) -> void:
	if _light_hinted:
		return
	_light_hinted = true
	_hint("a luz te enche · mas te prende", LIGHT_HINT_POSITION, 2.0)


func _on_enemy_died(_enemy: Node, _position: Vector2) -> void:
	if _kill_hinted:
		return
	_kill_hinted = true
	_hint("o óleo volta", OIL_HINT_POSITION, 1.4)


func _on_player_damaged(_amount: float, _position: Vector2) -> void:
	if _dash_hinted:
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or not player.has_dash_charge():
		return
	_dash_hinted = true
	_hint("shift · o dash atravessa o perigo", DASH_HINT_POSITION, 1.8)


func _hint(text: String, at: Vector2, duration: float) -> void:
	var hud := _hud()
	if hud != null:
		hud.show_hint(text, duration, at)


func _hud() -> Hud:
	return get_tree().get_first_node_in_group("hud") as Hud