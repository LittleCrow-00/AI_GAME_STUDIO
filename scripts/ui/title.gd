class_name TitleScreen
extends Control
## Tela de título e meta-progressão.
##
## É o ponto de entrada do jogo: mostra o que a run anterior deixou (cera, runs,
## recorde), onde gastar a cera em desbloqueios permanentes e o botão de descer.
## Apresentação pura: a carteira é do `SaveSystem`.

const COL_TEXT := Color(0.88, 0.91, 0.92)
const COL_DIM := Color(0.52, 0.62, 0.65)
const COL_ACCENT := Color(1.0, 0.72, 0.28)
const COL_OK := Color(0.45, 0.85, 0.60)

const MAIN_SCENE := "res://scenes/main/main.tscn"

var _rows: Array[Label] = []
var _stats: Label
var _selected: int = 0
var _pulse: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	_refresh()


func _process(delta: float) -> void:
	_pulse += delta
	if _rows.size() > 0:
		var alpha := 0.75 + 0.25 * sin(_pulse * 2.4)
		_rows[0].modulate = Color(1.0, 1.0, 1.0, alpha)


func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.012, 0.025, 0.033)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var title := _make_label("FAROLEIRO", 64, COL_ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(0.0, 92.0)
	title.size = Vector2(1280.0, 84.0)
	add_child(title)

	var subtitle := _make_label(
		"a luz é sua arma, sua visão e sua munição",
		20,
		COL_DIM,
		HORIZONTAL_ALIGNMENT_CENTER,
	)
	subtitle.position = Vector2(0.0, 172.0)
	subtitle.size = Vector2(1280.0, 30.0)
	add_child(subtitle)

	_stats = _make_label("", 18, COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_stats.position = Vector2(0.0, 214.0)
	_stats.size = Vector2(1280.0, 28.0)
	add_child(_stats)

	for i in range(UnlockDatabase.count() + 1):
		var label := _make_label("", 20, COL_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
		label.position = Vector2(340.0, 286.0 + float(i) * 42.0)
		label.size = Vector2(600.0, 32.0)
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		label.gui_input.connect(_on_row_input.bind(i))
		label.mouse_entered.connect(_on_row_hover.bind(i, true))
		add_child(label)
		_rows.append(label)

	var footer := _make_label(
		"↑/↓ escolher · Enter confirmar · ESC sair",
		15,
		COL_DIM,
		HORIZONTAL_ALIGNMENT_CENTER,
	)
	footer.position = Vector2(0.0, 620.0)
	footer.size = Vector2(1280.0, 26.0)
	add_child(footer)


func _refresh() -> void:
	_stats.text = "cera  %d      runs  %d      recorde  %d" % [
		SaveSystem.total_cera,
		SaveSystem.runs,
		SaveSystem.best_score,
	]

	if _rows.is_empty():
		return

	_rows[0].text = "DESCER"
	for i in range(1, _rows.size()):
		var unlock := UnlockDatabase.ALL[i - 1]
		var line: String
		if SaveSystem.has_unlock(unlock.id):
			line = "[x] %s — desbloqueado" % unlock.display_name
		elif SaveSystem.total_cera >= unlock.cost:
			line = "[ ] %s — %d cera" % [unlock.display_name, unlock.cost]
		else:
			line = "[ ] %s — %d cera (faltam %d)" % [
				unlock.display_name,
				unlock.cost,
				unlock.cost - SaveSystem.total_cera,
			]
		_rows[i].text = line

	for i in range(_rows.size()):
		var color := COL_ACCENT if i == _selected else COL_TEXT
		if i > 0 and SaveSystem.has_unlock(UnlockDatabase.ALL[i - 1].id):
			color = COL_OK if i != _selected else COL_ACCENT
		_rows[i].add_theme_color_override("font_color", color)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return

	match key.physical_keycode:
		KEY_UP, KEY_W:
			_selected = (_selected + _rows.size() - 1) % _rows.size()
			_refresh()
		KEY_DOWN, KEY_S:
			_selected = (_selected + 1) % _rows.size()
			_refresh()
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_activate(_selected)
		KEY_ESCAPE:
			get_tree().quit()
		_:
			return
	_accept_input()


func _accept_input() -> void:
	# A cena pode já ter sido trocada pelo clique; aí o nó não recebe mais eventos.
	if is_inside_tree():
		get_viewport().set_input_as_handled()


func _activate(index: int) -> void:
	if index <= 0:
		get_tree().change_scene_to_file(MAIN_SCENE)
		return

	var unlock := UnlockDatabase.ALL[index - 1]
	if SaveSystem.has_unlock(unlock.id):
		return
	if SaveSystem.purchase(unlock.id):
		_refresh()


func _on_row_input(event: InputEvent, index: int) -> void:
	var mouse := event as InputEventMouseButton
	if mouse == null or not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	_selected = index
	_activate(index)
	_accept_input()


func _on_row_hover(index: int, entered: bool) -> void:
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
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.04))
	label.horizontal_alignment = alignment
	return label