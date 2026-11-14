extends SceneTree
## Gera os WAVs do FAROLEIRO (PCM 16-bit mono, 44100 Hz).
##
## Rodar uma vez (e depois de mudar um timbre):
##   godot --headless --path . --script res://tools/gen_audio.gd
##
## Nada de sample de terceiro: todo som é sintetizado aqui, com envelope e
## frequências escolhidas para caber na paleta "maré" do jogo.

const RATE: int = 44100
const OUT_DIR: String = "res://assets/audio"

var _seed: int = 20261114


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)

	_write("drone", _drone(8.0))
	_write("hit", _noise_burst(0.06, 0.018, 0.55))
	_write("kill", _kill(0.34))
	_write("pickup", _bell(0.20, 880.0, 1320.0))
	_write("dash", _dash(0.22))
	_write("hurt", _hurt(0.24))
	_write("dry", _noise_burst(0.05, 0.008, 0.9))
	_write("farol", _bell(1.30, 392.0, 523.25))

	print("AUDIO: %d arquivos em %s" % [8, OUT_DIR])
	quit()


func _rng() -> float:
	_seed = int((_seed * 1103515245 + 12345) & 0x7FFFFFFF)
	return float(_seed) / float(0x7FFFFFFF) * 2.0 - 1.0


func _frames(seconds: float) -> int:
	return int(seconds * RATE)


func _drone(seconds: float) -> PackedFloat32Array:
	var total := _frames(seconds)
	var samples := PackedFloat32Array()
	samples.resize(total)
	var lp := 0.0
	for i in range(total):
		var t := float(i) / float(RATE)
		var lfo := 0.78 + 0.22 * sin(TAU * 0.125 * t)
		var tone := 0.34 * sin(TAU * 55.0 * t)
		tone += 0.18 * sin(TAU * 82.5 * t)
		tone += 0.09 * sin(TAU * 110.0 * t + 0.4 * sin(TAU * 0.25 * t))
		lp = lerpf(lp, _rng(), 0.02)
		samples[i] = (tone * lfo + lp * 0.05) * 0.6
	return samples


func _noise_burst(seconds: float, decay: float, cutoff: float) -> PackedFloat32Array:
	var total := _frames(seconds)
	var samples := PackedFloat32Array()
	samples.resize(total)
	var lp := 0.0
	for i in range(total):
		var t := float(i) / float(RATE)
		var env := exp(-t / maxf(0.0005, decay))
		lp = lerpf(lp, _rng(), cutoff)
		samples[i] = lp * env * 0.9
	return samples


func _kill(seconds: float) -> PackedFloat32Array:
	var total := _frames(seconds)
	var samples := PackedFloat32Array()
	samples.resize(total)
	var lp := 0.0
	var phase := 0.0
	for i in range(total):
		var t := float(i) / float(RATE)
		var freq := lerpf(130.0, 44.0, clampf(t / seconds, 0.0, 1.0))
		phase += TAU * freq / float(RATE)
		var env := exp(-t / 0.12)
		lp = lerpf(lp, _rng(), 0.25)
		samples[i] = (sin(phase) * 0.7 + lp * 0.35) * env * 0.9
	return samples


func _bell(seconds: float, base: float, overtone: float) -> PackedFloat32Array:
	var total := _frames(seconds)
	var samples := PackedFloat32Array()
	samples.resize(total)
	for i in range(total):
		var t := float(i) / float(RATE)
		var attack := clampf(t / 0.006, 0.0, 1.0)
		var env := exp(-t / (seconds * 0.35)) * attack
		var tone := sin(TAU * base * t) * 0.6
		tone += sin(TAU * overtone * t) * 0.25 * exp(-t / (seconds * 0.18))
		samples[i] = tone * env * 0.7
	return samples


func _dash(seconds: float) -> PackedFloat32Array:
	var total := _frames(seconds)
	var samples := PackedFloat32Array()
	samples.resize(total)
	var lp := 0.0
	var phase := 0.0
	for i in range(total):
		var t := float(i) / float(RATE)
		var progress := clampf(t / seconds, 0.0, 1.0)
		var env := sin(progress * PI)
		lp = lerpf(lp, _rng(), 0.12 + 0.5 * progress)
		var freq := lerpf(420.0, 150.0, progress)
		phase += TAU * freq / float(RATE)
		samples[i] = (lp * 0.5 + sin(phase) * 0.25) * env * 0.7
	return samples


func _hurt(seconds: float) -> PackedFloat32Array:
	var total := _frames(seconds)
	var samples := PackedFloat32Array()
	samples.resize(total)
	var lp := 0.0
	for i in range(total):
		var t := float(i) / float(RATE)
		var env := exp(-t / 0.09)
		var square := signf(sin(TAU * 110.0 * t))
		lp = lerpf(lp, _rng(), 0.3)
		samples[i] = (square * 0.22 + lp * 0.3) * env * 0.8
	return samples


func _ascii(target: PackedByteArray, offset: int, text: String) -> void:
	for i in range(text.length()):
		target[offset + i] = text.unicode_at(i)


func _write(name: String, samples: PackedFloat32Array) -> void:
	var path := "%s/%s.wav" % [OUT_DIR, name]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("AUDIO: nao abriu %s" % path)
		return

	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in range(samples.size()):
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))

	var header := PackedByteArray()
	header.resize(44)
	_ascii(header, 0, "RIFF")
	header.encode_u32(4, 36 + data.size())
	_ascii(header, 8, "WAVE")
	_ascii(header, 12, "fmt ")
	header.encode_u32(16, 16)
	header.encode_u16(20, 1)
	header.encode_u16(22, 1)
	header.encode_u32(24, RATE)
	header.encode_u32(28, RATE * 2)
	header.encode_u16(32, 2)
	header.encode_u16(34, 16)
	_ascii(header, 36, "data")
	header.encode_u32(40, data.size())

	file.store_buffer(header)
	file.store_buffer(data)
	file.close()