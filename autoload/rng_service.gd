extends Node
## Servico de aleatoriedade deterministica.
##
## Cada "stream" tem semente propria derivada da semente da run. Isso evita que
## rolagens de spawn alterem as rolagens de itens (e vice-versa), permitindo
## replays, testes reproduziveis e daily runs. Ver docs/architecture.md.

const STREAM_SPAWN := "spawn"
const STREAM_LOOT := "loot"
const STREAM_AI := "ai"
const STREAM_FX := "fx"

var run_seed: int = 0

var _streams: Dictionary = {}


func new_run(seed_value: int = -1) -> void:
	if seed_value < 0:
		seed_value = int(Time.get_unix_time_from_system() * 1000.0) & 0x7FFFFFFF
	run_seed = seed_value
	_streams.clear()
	_add_stream(STREAM_SPAWN, run_seed + 0x9E3779B9)
	_add_stream(STREAM_LOOT, run_seed + 0x85EBCA6B)
	_add_stream(STREAM_AI, run_seed + 0xC2B2AE35)
	_add_stream(STREAM_FX, run_seed + 0x27D4EB2F)


func get_stream(stream_name: String) -> RandomNumberGenerator:
	if not _streams.has(stream_name):
		_add_stream(stream_name, run_seed + hash(stream_name))
	return _streams[stream_name] as RandomNumberGenerator


func randf_range(stream_name: String, from: float, to: float) -> float:
	return get_stream(stream_name).randf_range(from, to)


func randi_range(stream_name: String, from: int, to: int) -> int:
	return get_stream(stream_name).randi_range(from, to)


func pick(stream_name: String, source: Array) -> Variant:
	if source.is_empty():
		return null
	return source[get_stream(stream_name).randi_range(0, source.size() - 1)]


func _add_stream(stream_name: String, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_streams[stream_name] = rng