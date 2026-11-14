extends Node
## Preferências do jogador, persistidas em `user://settings.cfg`.
##
## Existe para acessibilidade (reduzir tremor/flashes) sem depender de save de
## run. Nada de balanceamento aqui: são opções de apresentação.

const PATH := "user://settings.cfg"

var reduce_shake: bool = false
var reduce_flashes: bool = false
var muted: bool = false


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		return
	reduce_shake = bool(config.get_value("video", "reduce_shake", false))
	reduce_flashes = bool(config.get_value("video", "reduce_flashes", false))
	muted = bool(config.get_value("audio", "muted", false))


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("video", "reduce_shake", reduce_shake)
	config.set_value("video", "reduce_flashes", reduce_flashes)
	config.set_value("audio", "muted", muted)
	config.save(PATH)


func set_reduce_shake(value: bool) -> void:
	reduce_shake = value
	save_settings()


func set_reduce_flashes(value: bool) -> void:
	reduce_flashes = value
	save_settings()


func set_muted(value: bool) -> void:
	muted = value
	save_settings()