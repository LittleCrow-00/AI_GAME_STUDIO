class_name Sanctuary
extends CanvasLayer
## Santuário: loja de itens.
##
## A primeira escolha da visita é grátis; as seguintes custam **cera**. É a única
## tela "grande" do jogo — e por isso ela é deliberadamente silenciosa: sem
## comparação de dano, só o que o item muda na sua relação com a luz, as tags que
## abrem sinergias, o preço e se a coisa é amaldiçoada.
##
## O Santuário é uma **visão**: ele mostra e pede. Quem tem a carteira é o `Main`
## (`purchase_requested`), que valida, cobra e devolve o saldo com `set_cera`.

signal purchase_requested(item: ItemData, price: int)
signal closed

const CARD_SIZE := Vector2(300.0, 288.0)
const CARD_Y := 232.0
const CARD_GAP := 30.0

const COL_TEXT := Color(0.88, 0.91, 0.92)
const COL_DIM := Color(0.52, 0.62, 0.65)
const COL_ACCENT := Color(1.0, 0.72, 0.28)
const COL_CURSED := Color(0.82, 0.32, 0.38)
const COL_DENIED := Color(0.9, 0.3, 0.3)

var _items: Array[ItemData] = []
var _cards: Array[Panel] = []
var _names: Array[Label] = []
var _descriptions: Array[Label] = []
var _rarity_labels: Array[Label] = []
var _tags_labels: Array[Label] = []
var _price_labels: Array[Label] = []
var _sigils: Array[ItemSigil] = []
var _taken: Array[bool] = []

var _cera: int = 0
var _price: int = 0
var _free_pick: bool = true
var _open: bool = false


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false


## `price` 0 = loja desativada. `free_pick` define se a 1ª escolha é grátis.
func open(items: Array[ItemData], cera: int = 0, price: int = 0, free_pick: bool = true) -> void:
	_items = items
	_cera = cera
	_price = price
	_free_pick = free_pick
	_taken.clear()
	for i in range(_cards.size()):
		_taken.append(false)
		if i < items.size():
			_fill_card(i, items[i])
			_cards[i].visible = true
			_cards[i].modulate = Color.WHITE
		else:
			_cards[i].visible = false
	_open = true
	visible = true


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	closed.emit()


func is_open() -> bool:
	return _open


func set_cera(value: int) -> void:
	_cera = maxi(0, value)
	for i in range(_price_labels.size()):
		_refresh_price(i)


func deny_purchase(index: int) -> void:
	if index < 0 or index >= _cards.size():
		return
	var card := _cards[index]
	card.modulate = Color(1.6, 0.6, 0.6)
	var tween := create_tween()
	tween.tween_property(card, "modulate", Color.WHITE, 0.35)


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
	title.position = Vector2(0.0, 104.0)
	title.size = Vector2(1280.0, 54.0)
	root.add_child(title)

	var subtitle := _make_label(
		"a primeira escolha é sua · as outras custam cera · ESC para descer",
		17,
		COL_DIM,
		HORIZONTAL_ALIGNMENT_CENTER,
	)
	subtitle.position = Vector2(0.0, 160.0)
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
		name_label.position = Vector2(18.0, 16.0)
		name_label.size = Vector2(CARD_SIZE.x - 36.0, 32.0)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(name_label)
		_names.append(name_label)

		var rarity_label := _make_label("", 13, COL_DIM, HORIZONTAL_ALIGNMENT_LEFT)
		rarity_label.position = Vector2(18.0, 50.0)
		rarity_label.size = Vector2(CARD_SIZE.x - 36.0, 22.0)
		card.add_child(rarity_label)
		_rarity_labels.append(rarity_label)

		var description_label := _make_label("", 16, COL_DIM, HORIZONTAL_ALIGNMENT_LEFT)
		description_label.position = Vector2(18.0, 92.0)
		description_label.size = Vector2(CARD_SIZE.x - 36.0, 90.0)
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(description_label)
		_descriptions.append(description_label)

		var tags_label := _make_label("", 13, COL_ACCENT, HORIZONTAL_ALIGNMENT_LEFT)
		tags_label.position = Vector2(18.0, 188.0)
		tags_label.size = Vector2(CARD_SIZE.x - 36.0, 24.0)
		card.add_child(tags_label)
		_tags_labels.append(tags_label)

		var price_label := _make_label("", 17, COL_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
		price_label.position = Vector2(18.0, 228.0)
		price_label.size = Vector2(CARD_SIZE.x - 120.0, 30.0)
		card.add_child(price_label)
		_price_labels.append(price_label)

		var key_label := _make_label("%d" % (i + 1), 30, COL_ACCENT, HORIZONTAL_ALIGNMENT_RIGHT)
		key_label.position = Vector2(CARD_SIZE.x - 64.0, CARD_SIZE.y - 56.0)
		key_label.size = Vector2(46.0, 40.0)
		card.add_child(key_label)

		var sigil := ItemSigil.new()
		sigil.position = Vector2(CARD_SIZE.x - 56.0, 12.0)
		sigil.size = Vector2(40.0, 40.0)
		card.add_child(sigil)
		_sigils.append(sigil)


func _fill_card(index: int, item: ItemData) -> void:
	_names[index].text = item.display_name
	_descriptions[index].text = item.description
	_rarity_labels[index].text = _rarity_name(item.rarity)
	_rarity_labels[index].add_theme_color_override("font_color", _rarity_color(item.rarity))
	_tags_labels[index].text = _tags_text(item)
	_sigils[index].setup(item.tags, _rarity_color(item.rarity))
	_refresh_price(index)


func _refresh_price(index: int) -> void:
	if index >= _price_labels.size():
		return
	var label := _price_labels[index]
	if _taken[index]:
		label.text = "LEVADO"
		label.add_theme_color_override("font_color", COL_DIM)
		_cards[index].modulate = Color(0.55, 0.6, 0.62)
		return

	var price := 0 if _free_pick else _price
	if price <= 0:
		label.text = "GRÁTIS"
		label.add_theme_color_override("font_color", COL_ACCENT)
	elif price <= _cera:
		label.text = "%d CERA" % price
		label.add_theme_color_override("font_color", COL_TEXT)
	else:
		label.text = "%d CERA" % price
		label.add_theme_color_override("font_color", COL_DENIED)


func _tags_text(item: ItemData) -> String:
	if item.tags.is_empty():
		return ""
	var parts: Array[String] = []
	for tag in item.tags:
		parts.append(str(tag))
	return "· ".join(parts)


func _on_card_input(event: InputEvent, index: int) -> void:
	if not _open or index >= _items.size():
		return
	var mouse := event as InputEventMouseButton
	if mouse == null or not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	_choose(index)


func _on_card_hover(index: int, entered: bool) -> void:
	if index >= _cards.size() or _taken[index]:
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
		KEY_ESCAPE, KEY_ENTER:
			close()


func _choose(index: int) -> void:
	if not _open or index >= _items.size() or _taken[index]:
		return

	var price := 0 if _free_pick else _price
	if price > _cera:
		deny_purchase(index)
		return

	if _free_pick:
		_free_pick = false
	_taken[index] = true
	_refresh_price(index)
	purchase_requested.emit(_items[index], price)


func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.095, 0.115, 0.97)
	style.border_color = Color(0.35, 0.45, 0.48, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 4.0
	style.content_margin_right = 4.0
	return style


func _rarity_name(rarity: ItemData.Rarity) -> String:
	match rarity:
		ItemData.Rarity.UNCOMMON:
			return "incomum"
		ItemData.Rarity.RARE:
			return "raro"
		ItemData.Rarity.CURSED:
			return "maldito"
		_:
			return "comum"


func _rarity_color(rarity: ItemData.Rarity) -> Color:
	match rarity:
		ItemData.Rarity.UNCOMMON:
			return Color(0.45, 0.85, 0.95)
		ItemData.Rarity.RARE:
			return Color(1.0, 0.72, 0.28)
		ItemData.Rarity.CURSED:
			return COL_CURSED
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