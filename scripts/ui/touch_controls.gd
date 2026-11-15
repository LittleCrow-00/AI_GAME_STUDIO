class_name TouchControls
extends CanvasLayer
## Controles de toque para Web e Android.
##
## O jogo lê o mesmo `InputMap` do teclado: este nó apenas traduz toque em
## ações (direcional analógico, feixe e dash) e em mira automática, já que no
## celular não existe mouse para apontar.
##
## Sem tocar na lógica de combate: o `Player` continua igual, só ganha um
## `aim_override` opcional.

const MOVE_RADIUS := 78.0
const KNOB_RADIUS := 30.0
const DEAD_ZONE := 0.18
const AIM_RANGE := 560.0
const MOVE_ZONE_RATIO := 0.46

const COL_RING := Color(0.85, 0.93, 0.95, 0.20)
const COL_RING_ACTIVE := Color(1.0, 0.72, 0.28, 0.45)
const COL_KNOB := Color(1.0, 0.78, 0.36, 0.85)
const COL_BEAM := Color(1.0, 0.86, 0.55, 0.9)
const COL_DASH := Color(0.62, 0.88, 0.95, 0.9)
const COL_TEXT := Color(0.06, 0.09, 0.10, 0.85)

## Liga/desliga o nó inteiro. O setter garante que processamento e desenho
## acompanhem a detecção de toque (e os testes consigam forçar o modo).
var enabled := false:
	set(value):
		enabled = value
		set_process(value)
		set_process_input(value)
		visible = value

var _player: Player
var _overlay: Control
var _touch_index := -1
var _origin := Vector2.ZERO
var _touch_pos := Vector2.ZERO
var _vector := Vector2.ZERO
var _beam_held := false
var _beam_index := -1
var _beam_rect := Rect2()
var _dash_center := Vector2.ZERO
var _dash_radius := 52.0
var _last_size := Vector2.ZERO
var _pulse := 0.0


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()
	enabled = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	# O input fica sempre ligado: o navegador nem sempre sabe dizer que é
	# touch antes do primeiro toque, e é ele que revela os controles.
	set_process_input(true)
	if enabled:
		# O jogo é 16:9; no celular, forçar paisagem evita HUD cortado.
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)


func _build_overlay() -> void:
	_overlay = Control.new()
	_overlay.name = "Overlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_on_draw)
	add_child(_overlay)
	_layout()


func _layout() -> void:
	var size := _viewport_size()
	_beam_rect = Rect2(size.x - 190.0, size.y - 200.0, 160.0, 160.0)
	_dash_center = Vector2(size.x - 260.0, size.y - 92.0)
	_dash_radius = 54.0


func _viewport_size() -> Vector2:
	return get_viewport().get_visible_rect().size


func _process(delta: float) -> void:
	_pulse += delta
	var size := _viewport_size()
	if size != _last_size:
		_last_size = size
		_layout()
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Player
	_apply_move()
	_update_aim()
	if _overlay != null:
		_overlay.queue_redraw()


func _input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if not enabled:
		if touch == null:
			return
		enabled = true
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	if touch != null:
		if touch.pressed:
			_press(touch.index, touch.position)
		else:
			_release(touch.index)
		return
	var drag := event as InputEventScreenDrag
	if drag != null and drag.index == _touch_index:
		_touch_pos = drag.position


func _press(index: int, position: Vector2) -> void:
	if _beam_rect.has_point(position):
		_beam_index = index
		_beam_held = true
		Input.action_press(&"fire")
		return
	if position.distance_to(_dash_center) <= _dash_radius + 14.0:
		_dash()
		return
	if position.x > _viewport_size().x * MOVE_ZONE_RATIO:
		return
	_touch_index = index
	_origin = position
	_touch_pos = position
	_vector = Vector2.ZERO


func _release(index: int) -> void:
	if index == _touch_index:
		_touch_index = -1
		_vector = Vector2.ZERO
		_release_move()
		return
	if index != _beam_index:
		return
	_beam_index = -1
	_beam_held = false
	Input.action_release(&"fire")


func _dash() -> void:
	Input.action_press(&"dash")
	# O Player usa `is_action_just_pressed`: soltar no frame seguinte garante
	# que o toque seja visto como um pressionar novo.
	get_tree().create_timer(0.05).timeout.connect(func() -> void: Input.action_release(&"dash"))


func _apply_move() -> void:
	if _touch_index < 0:
		return
	var delta := _touch_pos - _origin
	_vector = (delta / MOVE_RADIUS).limit_length(1.0)
	_set_axis(&"move_right", maxf(0.0, _vector.x))
	_set_axis(&"move_left", maxf(0.0, -_vector.x))
	_set_axis(&"move_down", maxf(0.0, _vector.y))
	_set_axis(&"move_up", maxf(0.0, -_vector.y))


func _release_move() -> void:
	_set_axis(&"move_right", 0.0)
	_set_axis(&"move_left", 0.0)
	_set_axis(&"move_down", 0.0)
	_set_axis(&"move_up", 0.0)


func _set_axis(action: StringName, value: float) -> void:
	if value > DEAD_ZONE:
		Input.action_press(action, value)
	else:
		Input.action_release(action)


func _update_aim() -> void:
	if _player == null:
		return
	if not _beam_held:
		_player.aim_override = Vector2.INF
		return
	var target := _nearest_enemy()
	if target == Vector2.INF:
		var facing := _vector.normalized() if _vector.length_squared() > 0.01 else Vector2.RIGHT
		target = _player.global_position + facing * 200.0
	_player.aim_override = target


func _nearest_enemy() -> Vector2:
	if _player == null:
		return Vector2.INF
	var best := AIM_RANGE * AIM_RANGE
	var found := Vector2.INF
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Node2D
		if enemy == null:
			continue
		var offset := enemy.global_position - _player.global_position
		var dist := offset.length_squared()
		if dist < best:
			best = dist
			found = enemy.global_position
	return found


func _on_draw() -> void:
	if _overlay == null:
		return
	var size := _viewport_size()
	var ring := _origin if _touch_index >= 0 else Vector2(150.0, size.y - 150.0)
	var alpha := 1.0 if _touch_index >= 0 else 0.45
	_overlay.draw_circle(ring, MOVE_RADIUS, Color(COL_RING.r, COL_RING.g, COL_RING.b, COL_RING.a * alpha))
	_overlay.draw_arc(ring, MOVE_RADIUS, 0.0, TAU, 40, COL_RING_ACTIVE * alpha, 2.0)
	var knob := ring + _vector * MOVE_RADIUS if _touch_index >= 0 else ring
	_overlay.draw_circle(knob, KNOB_RADIUS, Color(COL_KNOB.r, COL_KNOB.g, COL_KNOB.b, COL_KNOB.a * alpha))

	var beam_center := _beam_rect.get_center()
	_overlay.draw_circle(beam_center, _beam_rect.size.x * 0.5, Color(COL_BEAM.r, COL_BEAM.g, COL_BEAM.b, 0.10 if not _beam_held else 0.28))
	_overlay.draw_arc(beam_center, _beam_rect.size.x * 0.5, 0.0, TAU, 40, COL_BEAM, 3.0)
	_draw_label(beam_center + Vector2(0.0, 6.0), "FEIXE", COL_BEAM)

	_overlay.draw_circle(_dash_center, _dash_radius, Color(COL_DASH.r, COL_DASH.g, COL_DASH.b, 0.10))
	_overlay.draw_arc(_dash_center, _dash_radius, 0.0, TAU, 40, COL_DASH, 3.0)
	_draw_label(_dash_center + Vector2(0.0, 6.0), "DASH", COL_DASH)


func _draw_label(at: Vector2, text: String, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	_overlay.draw_string(font, at - Vector2(width * 0.5, 0.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, COL_TEXT)
	_overlay.draw_string(font, at - Vector2(width * 0.5, 1.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)