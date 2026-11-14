extends Node
## Hitstop global.
##
## Congela o jogo por alguns milissegundos em impactos importantes. Usa
## `Time.get_ticks_msec()` (tempo real) para nao depender do proprio
## `time_scale` que ele altera — um timer comum nunca terminaria.
##
## Regra de uso: hitstop e para eventos GRANDES (abate, dano no jogador).
## Nunca por tick de feixe: o feixe tica 10x por segundo e o jogo viraria pudim.

const SCALE: float = 0.05
const DEFAULT_DURATION_MS: int = 45

var _until_ms: int = 0
var _active: bool = false


func _ready() -> void:
	Engine.time_scale = 1.0
	set_process(false)


func hitstop(duration_ms: int = DEFAULT_DURATION_MS) -> void:
	if duration_ms <= 0:
		return
	var target := Time.get_ticks_msec() + duration_ms
	if target <= _until_ms:
		return
	_until_ms = target
	if _active:
		return
	_active = true
	Engine.time_scale = SCALE
	set_process(true)


func clear() -> void:
	_until_ms = 0
	_active = false
	Engine.time_scale = 1.0
	set_process(false)


func _process(_delta: float) -> void:
	if Time.get_ticks_msec() < _until_ms:
		return
	clear()


func _exit_tree() -> void:
	clear()