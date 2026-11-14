class_name Ressonancia
extends Node
## Eixo "Balatro" do jogo: cadeia de acertos que multiplica PONTOS e CERA.
##
## Decisao de design deliberada: a cadeia NAO multiplica dano. Dano vem de
## itens; a cadeia premia agressividade e constroi a pontuacao da sala. Assim
## os dois eixos de build (dano vs. pontuacao) permanecem independentes.

const WINDOW: float = 1.2
const STEP: float = 0.1
const MAX_CHAIN: int = 99

var chain: int = 0
var multiplier: float = 1.0
var score: int = 0

var _left: float = 0.0


func _ready() -> void:
	SignalBus.beam_hit_enemy.connect(_on_beam_hit)


func _process(delta: float) -> void:
	if chain <= 0:
		return
	_left -= delta
	if _left <= 0.0:
		_reset_chain()


func register_hit(damage: float) -> void:
	var previous := chain
	chain = mini(MAX_CHAIN, chain + 1)
	_left = WINDOW
	multiplier = 1.0 + STEP * float(chain)
	score += int(round(damage * multiplier))
	SignalBus.ressonancia_changed.emit(chain, multiplier)
	SignalBus.score_changed.emit(score)
	_emit_thresholds(previous, chain)


## Detecta a passagem de limiar e avisa. Quem aplica a recompensa é o Player.
func _emit_thresholds(previous: int, current: int) -> void:
	for threshold in ThresholdDatabase.crossed(previous, current):
		SignalBus.threshold_reached.emit(threshold)


func reset() -> void:
	_reset_chain()
	score = 0
	SignalBus.score_changed.emit(score)


func _reset_chain() -> void:
	chain = 0
	multiplier = 1.0
	_left = 0.0
	SignalBus.ressonancia_changed.emit(chain, multiplier)


func _on_beam_hit(_enemy: Node, damage: float) -> void:
	register_hit(damage)