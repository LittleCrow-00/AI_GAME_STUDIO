class_name Sanctuary
extends CanvasLayer
## Santuário: escolha de 1 entre 3 oferendas.
##
## É a única tela "grande" do jogo — e por isso ela é deliberadamente silenciosa:
## sem números soltos, sem comparação de dano, só o que a oferenda muda na sua
## relação com a luz. O `Main` pausa a árvore e espera o sinal `boon_chosen`.

signal boon_chosen(boon: BoonData)

const CARD_SIZE := Vector2(300.0, 264.0)
const CARD_Y := 250.0
const CARD_GAP := 30.0

const COL_TEXT := Color(0.88, 0.91, 0.92)
const COL_DIM := Color(0.52, 0.62, 0.65)
const COL_ACCENT := Color(1.0, 0.72, 0.28)

var _boons: Array[BoonData] = []
var _cards: Array[Panel] = []
var _names: Array[Label] = []
var _descriptions: Array[Label] = []
var _rarity_labels: Array[Label] = []
var _open: bool = false


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false


func open(boons: Array[BoonData]) -> void:
	_boons = boons
	for i in range(_cards.size()):
		if i < boons.size():
			_fill_card(i, boons[i])
			_cards[i].visible = true
		else:
			_cards[i].visible = false
	_open = true
	visible = true


func close() -> void:
	_open = false
	visible = false


func is_open() -> bool:
	return _open


func _build() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.015, 0.03, 0.04, 0.88)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(backdrop)

	var title := _make_label("SANTUÁRIO", 40, COL_ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(0.0, 130.0)
	title.size = Vector2(1280.0, 54.0)
	root.add_child(title)

	var subtitle := _make_label(
		"o mar devolve o que você merece · escolha uma oferenda",
		17,
		COL_DIM,
		HORIZONTAL_ALIGNMENT_CENTER,
	)
	subtitle.position = Vector2(0.0, 186.0)
	subtitle.size = Vector2(1280.0, 30.0)
	root.add_child(subtitle)

	var total_width := CARD_SIZE.x * 3.0 + CARD_GAP * 2.0
	var start_x := (1280.0 - total_width) * 0.5

	for i in range(3):
		var card := Panel.new()
		card.position = Vector2(start_x + float(i) * (CARD_SIZE.x + CARD_GAP), CARD_Y)
		card.size = CARD_SIZE
		card.add_theme_stylebox_override("panel", _card_style())
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card.gui_input.connect(_on_card_input.bind(i))
		card.mouse_entered.connect(_on_card_hover.bind(i, true))
		card.mouse_exited.connect(_on_card_hover.bind(i, false))
		root.add_child(card)
		_cards.append(card)

		var name_label := _make_label("", 22, COL_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
		name_label.position = Vector2(18.0, 18.0)
		name_label.size = Vector2(CARD_SIZE.x - 36.0, 32.0)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(name_label)
		_names.append(name_label)

		var rarity_label := _make_label("", 13, COL_DIM, HORIZONTAL_ALIGNMENT_LEFT)
		rarity_label.position = Vector2(18.0, 52.0)
		rarity_label.size = Vector2(CARD_SIZE.x - 36.0, 22.0)
		card.add_child(rarity_label)
		_rarity_labels.append(rarity_label)

		var description_label := _make_label("", 16, COL_DIM, HORIZONTAL_ALIGNMENT_LEFT)
		description_label.position = Vector2(18.0, 96.0)
		description_label.size = Vector2(CARD_SIZE.x - 36.0, 120.0)
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(description_label)
		_descriptions.append(description_label)

		var key_label := _make_label("%d" % (i + 1), 30, COL_ACCENT, HORIZONTAL_ALIGNMENT_RIGHT)
		key_label.position = Vector2(CARD_SIZE.x - 64.0, CARD_SIZE.y - 60.0)
		key_label.size = Vector2(46.0, 40.0)
		card.add_child(key_label)


func _fill_card(index: int, boon: BoonData) -> void:
	_names[index].text = boon.display_name
	_descriptions[index].text = boon.description
	_rarity_labels[index].text = _rarity_name(boon.rarity)
	_rarity_labels[index].add_theme_color_override("font_color", _rarity_color(boon.rarity))


func _on_card_input(event: InputEvent, index: int) -> void:
	if not _open or index >= _boons.size():
		return
	var mouse := event as InputEventMouseButton
	if mouse == null or not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	_choose(index)


func _on_card_hover(index: int, entered: bool) -> void:
	if index >= _cards.size():
		return
	_cards[index].modulate = Color(1.25, 1.2, 1.1) if entered else Color.WHITE


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_1:
			_choose(0)
		KEY_2:
			_choose(1)
		KEY_3:
			_choose(2)
		KEY_ESCAPE:
			_choose(0)


func _choose(index: int) -> void:
	if not _open or index >= _boons.size():
		return
	var boon := _boons[index]
	close()
	boon_chosen.emit(boon)


func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.095, 0.115, 0.97)
	style.border_color = Color(0.35, 0.45, 0.48, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 4.0
	style.content_margin_right = 4.0
	return style


func _rarity_name(rarity: BoonData.Rarity) -> String:
	match rarity:
		BoonData.Rarity.UNCOMMON:
			return "incomum"
		BoonData.Rarity.RARE:
			return "raro"
		_:
			return "comum"


func _rarity_color(rarity: BoonData.Rarity) -> Color:
	match rarity:
		BoonData.Rarity.UNCOMMON:
			return Color(0.45, 0.85, 0.95)
		BoonData.Rarity.RARE:
			return Color(1.0, 0.72, 0.28)
		_:
			return COL_DIM


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
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label