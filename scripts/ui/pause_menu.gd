class_name PauseMenu
extends CanvasLayer
## Menu de pausa e acessibilidade.
##
## Só existe durante o combate: com o Santuário aberto a árvore já está pausada e
## o ESC pertence a ele. `ESC` fecha; ↑/↓ escolhem; Enter ativa; mouse também.

signal closed

const COL_TEXT := Color(0.88, 0.91, 0.92)
const COL_DIM := Color(0.52, 0.62, 0.65)
const COL_ACCENT := Color(1.0, 0.72, 0.28)

const PANEL_SIZE := Vector2(440.0, 372.0)

var _open: bool = false
var _selected: int = 0
var _labels: Array[Label] = []
var _root: Control


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false


func is_open() -> bool:
	return _open


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.010, 0.020, 0.028, 0.78)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(backdrop)

	var panel := Panel.new()
	panel.size = PANEL_SIZE
	panel.position = (Vector2(1280.0, 720.0) - PANEL_SIZE) * 0.5
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.075, 0.090, 0.98)
	style.border_color = Color(0.35, 0.45, 0.48, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	_root.add_child(panel)

	var title := _make_label("PAUSA", 34, COL_ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(0.0, 22.0)
	title.size = Vector2(PANEL_SIZE.x, 44.0)
	panel.add_child(title)

	var subtitle := _make_label("ESC para voltar", 14, COL_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	subtitle.position = Vector2(0.0, 62.0)
	subtitle.size = Vector2(PANEL_SIZE.x, 22.0)
	panel.add_child(subtitle)

	var entries := [
		"Continuar",
		"Tremor de tela",
		"Flashes",
		"Som",
		"Reiniciar run",
		"Sair do jogo",
	]
	for i in range(entries.size()):
		var label := _make_label(entries[i], 20, COL_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
		label.position = Vector2(48.0, 108.0 + float(i) * 40.0)
		label.size = Vector2(PANEL_SIZE.x - 96.0, 32.0)
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		label.gui_input.connect(_on_entry_input.bind(i))
		label.mouse_entered.connect(_on_entry_hover.bind(i, true))
		label.mouse_exited.connect(_on_entry_hover.bind(i, false))
		panel.add_child(label)
		_labels.append(label)


func _open_menu() -> void:
	_open = true
	_selected = 0
	visible = true
	get_tree().paused = true
	_refresh()


func _close_menu() -> void:
	if not _open:
		return
	_open = false
	visible = false
	get_tree().paused = false
	closed.emit()


func _refresh() -> void:
	var shake_state := "reduzido" if Settings.reduce_shake else "normal"
	var flash_state := "reduzido" if Settings.reduce_flashes else "normal"
	var sound_state := "mudo" if Settings.muted else "ligado"
	var texts := [
		"Continuar",
		"Tremor de tela: %s" % shake_state,
		"Flashes: %s" % flash_state,
		"Som: %s" % sound_state,
		"Reiniciar run",
		"Sair do jogo",
	]
	for i in range(_labels.size()):
		_labels[i].text = texts[i]
		var color := COL_ACCENT if i == _selected else COL_TEXT
		_labels[i].add_theme_color_override("font_color", color)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return

	if key.physical_keycode == KEY_ESCAPE:
		if _open:
			_close_menu()
		elif _can_open():
			_open_menu()
		get_viewport().set_input_as_handled()
		return

	if not _open:
		return

	match key.physical_keycode:
		KEY_UP, KEY_W:
			_selected = (_selected + _labels.size() - 1) % _labels.size()
			_refresh()
		KEY_DOWN, KEY_S:
			_selected = (_selected + 1) % _labels.size()
			_refresh()
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_activate(_selected)
		_:
			return
	get_viewport().set_input_as_handled()


## Não abre sobre o Santuário (árvore já pausada) nem depois da run acabar.
func _can_open() -> bool:
	if get_tree().paused:
		return false
	var main := get_tree().get_first_node_in_group("run")
	if main != null and int(main.get("_state")) >= 2:
		return false
	return true


func _activate(index: int) -> void:
	match index:
		0:
			_close_menu()
		1:
			Settings.set_reduce_shake(not Settings.reduce_shake)
			_refresh()
		2:
			Settings.set_reduce_flashes(not Settings.reduce_flashes)
			_refresh()
		3:
			Settings.set_muted(not Settings.muted)
			AudioService.set_muted(Settings.muted)
			_refresh()
		4:
			get_tree().paused = false
			get_tree().reload_current_scene()
		5:
			get_tree().paused = false
			get_tree().quit()


func _on_entry_input(event: InputEvent, index: int) -> void:
	var mouse := event as InputEventMouseButton
	if mouse == null or not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	_selected = index
	_activate(index)
	get_viewport().set_input_as_handled()


func _on_entry_hover(index: int, entered: bool) -> void:
	if not entered:
		return
	_selected = index
	_refresh()


func _make_label(
	text: String,
	font_size: int,
	color: Color,
	alignment: HorizontalAlignment,
) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.04))
	label.horizontal_alignment = alignment
	return label