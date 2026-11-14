class_name DamageNumbers
extends Node2D
## Números flutuantes de dano, com pool fixo.
##
## Fica no mundo (não em CanvasLayer) para acompanhar a câmera. O movimento e a
## vida útil são integrados à mão — sem criar tweens por acerto, que era a
## fonte óbvia de picos de frame em ondas grandes.

const POOL_SIZE: int = 40
const LIFETIME: float = 0.7
const RISE_SPEED: float = 58.0
const DRIFT: float = 26.0

var _labels: Array[Label] = []
var _life: PackedFloat32Array = []
var _velocity: Array[Vector2] = []
var _cursor: int = 0


func _ready() -> void:
	z_index = 50
	for i in range(POOL_SIZE):
		var label := Label.new()
		label.visible = false
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", 17)
		label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.52))
		label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.04))
		label.add_theme_constant_override("outline_size", 5)
		add_child(label)
		_labels.append(label)
		_life.resize(POOL_SIZE)
		_life[i] = 0.0
		_velocity.append(Vector2.ZERO)

	SignalBus.damage_number_requested.connect(_spawn)


func _process(delta: float) -> void:
	for i in range(POOL_SIZE):
		if _life[i] <= 0.0:
			continue
		_life[i] -= delta
		var label := _labels[i]
		if _life[i] <= 0.0:
			label.visible = false
			continue
		_velocity[i] = (_velocity[i] + Vector2(0.0, DRIFT * delta)).limit_length(90.0)
		label.position += _velocity[i] * delta
		label.modulate.a = clampf(_life[i] / (LIFETIME * 0.6), 0.0, 1.0)


func _spawn(amount: float, position: Vector2, is_critical: bool) -> void:
	var index := _acquire()
	var label := _labels[index]
	label.text = str(int(round(amount)))
	label.add_theme_font_size_override("font_size", 26 if is_critical else 17)
	label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.55, 0.35) if is_critical else Color(1.0, 0.86, 0.52),
	)
	label.position = position + Vector2(-8.0, -14.0)
	label.modulate.a = 1.0
	label.visible = true
	_life[index] = LIFETIME
	_velocity[index] = Vector2(randf_range(-20.0, 20.0), -RISE_SPEED)


func _acquire() -> int:
	for i in range(POOL_SIZE):
		var index := (_cursor + i) % POOL_SIZE
		if _life[index] <= 0.0:
			_cursor = (index + 1) % POOL_SIZE
			return index
	var fallback := _cursor
	_cursor = (_cursor + 1) % POOL_SIZE
	return fallback