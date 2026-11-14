class_name RunSummary
extends CanvasLayer
## Tela de fim de run. Não é um menu: é um recibo.
##
## Mostra o que a run produziu (salas, abates, pontos, tempo, semente) e nada
## mais. A semente fica visível de propósito — é o que permite repetir uma run.

const COL_DIM := Color(0.55, 0.64, 0.67)
const COL_TEXT := Color(0.88, 0.91, 0.92)

var _title: Label
var _body: Label
var _footer: Label


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false


func show_summary(title: String, lines: Array, accent: Color) -> void:
	_title.text = title
	_title.add_theme_color_override("font_color", accent)
	_body.text = "\n".join(lines)
	visible = true


func hide_summary() -> void:
	visible = false


func _build() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.012, 0.025, 0.033, 0.82)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(backdrop)

	_title = _make_label("", 44, COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_title.position = Vector2(0.0, 200.0)
	_title.size = Vector2(1280.0, 60.0)
	root.add_child(_title)

	_body = _make_label("", 20, COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_body.position = Vector2(340.0, 280.0)
	_body.size = Vector2(600.0, 220.0)
	root.add_child(_body)

	_footer = _make_label("R · tentar de novo", 16, COL_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	_footer.position = Vector2(0.0, 520.0)
	_footer.size = Vector2(1280.0, 30.0)
	root.add_child(_footer)


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
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.04))
	label.add_theme_constant_override("outline_size", 5)
	label.horizontal_alignment = alignment
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label