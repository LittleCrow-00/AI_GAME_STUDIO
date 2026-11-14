class_name ScreenShake
extends Camera2D
## Screen shake baseado em trauma (Squirrel Eiserloh).
##
## O deslocamento e o quadrado do trauma: dois eventos pequenos incomodam menos
## que um grande, e a queda e suave. Escuta `SignalBus.shake_requested` — quem
## pede shake nao precisa conhecer a camera.

const DECAY: float = 1.6
const MAX_OFFSET: float = 22.0
const MAX_ROTATION_DEG: float = 1.2

var _trauma: float = 0.0
var _time: float = 0.0
var _noise := FastNoiseLite.new()


func _ready() -> void:
	_noise.frequency = 0.02
	_noise.fractal_octaves = 2
	SignalBus.shake_requested.connect(add_trauma)


func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


func _process(delta: float) -> void:
	_time += delta
	_trauma = maxf(0.0, _trauma - DECAY * delta)
	var shake := _trauma * _trauma
	if shake <= 0.0001:
		offset = Vector2.ZERO
		rotation = 0.0
		return
	offset = Vector2(
		_noise.get_noise_2d(_time * 60.0, 0.0),
		_noise.get_noise_2d(0.0, _time * 60.0),
	) * MAX_OFFSET * shake
	rotation = deg_to_rad(_noise.get_noise_2d(_time * 30.0, 100.0) * MAX_ROTATION_DEG * shake)