class_name Hud
extends Control
## HUD reativo. Nao conhece regras de jogo: apenas escuta o SignalBus e desenha.
## Tudo em codigo (sem .tres de tema) para permitir iteracao rapida na Fase 1.

const BAR_ORIGIN := Vector2(32.0, 30.0)
const BAR_WIDTH := 264.0
const BAR_HEIGHT := 14.0
const BAR_GAP := 10.0

const COL_HEALTH := Color(0.78, 0.20, 0.24)
const COL_OIL := Color(1.0, 0.72, 0.28)
const COL_DASH := Color(0.34, 0.88, 0.85)
const COL_SCORE := Color(0.95, 0.84, 0.45)
const COL_TEXT := Color(0.80, 0.86, 0.88)
const COL_DIM := Color(0.45, 0.55, 0.58)

var _health: float = 100.0
var _health_max: float = 100.0
var _oil: float = 100.0
var _oil_max: float = 100.0
var _dash: int = 1
var _dash_max: int = 1
var _chain: int = 0
var _multiplier: float = 1.0
var _next_threshold: int = 0
var _next_threshold_name: String = ""
var _score: int = 0
var _cera: int = 0
var _room: int = 1
var _room_total: int = 3
var _wave: int = 0
var _wave_total: int = 0
var _enemies: int = 0
var _dry_flash: float = 0.0

var _banner_text: String = ""
var _banner_left: float = 0.0

var _hint: Label
var _hint_left: float = 0.0
var _hint_elapsed: float = 0.0
var _pulse: float = 0.0

var _boss_active: bool = false
var _boss_health: float = 0.0
var _boss_max: float = 1.0

var _readout: Label
var _banner: Label
var _subtitle: Label


func _ready() -> void:
	add_to_group("hud")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_hint = _make_label(15, Color(0.80, 0.86, 0.88), HORIZONTAL_ALIGNMENT_LEFT)
	_hint.size = Vector2(520.0, 24.0)
	_hint.modulate.a = 0.0

	_readout = _make_label(22, COL_TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	_readout.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_readout.position = Vector2(-360.0, 24.0)
	_readout.size = Vector2(328.0, 220.0)

	_banner = _make_label(46, Color(1.0, 0.86, 0.55), HORIZONTAL_ALIGNMENT_CENTER)
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_banner.position = Vector2(-400.0, -150.0)
	_banner.size = Vector2(800.0, 70.0)

	_subtitle = _make_label(20, COL_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	_subtitle.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_subtitle.position = Vector2(-400.0, -78.0)
	_subtitle.size = Vector2(800.0, 40.0)

	_connect()


func _connect() -> void:
	SignalBus.health_changed.connect(_on_health_changed)
	SignalBus.oil_changed.connect(_on_oil_changed)
	SignalBus.dash_charges_changed.connect(_on_dash_changed)
	SignalBus.ressonancia_changed.connect(_on_ressonancia_changed)
	SignalBus.score_changed.connect(_on_score_changed)
	SignalBus.cera_changed.connect(_on_cera_changed)
	SignalBus.wave_started.connect(_on_wave_started)
	SignalBus.enemies_remaining_changed.connect(_on_enemies_changed)
	SignalBus.message_requested.connect(show_banner)
	SignalBus.beam_dried.connect(_on_beam_dried)
	SignalBus.boss_spawned.connect(_on_boss_spawned)
	SignalBus.boss_health_changed.connect(_on_boss_health_changed)
	SignalBus.boss_defeated.connect(_on_boss_defeated)


func _on_boss_spawned(_boss: Node) -> void:
	_boss_active = true


func _on_boss_health_changed(current: float, maximum: float) -> void:
	_boss_health = current
	_boss_max = maxf(1.0, maximum)
	_boss_active = true


func _on_boss_defeated() -> void:
	_boss_active = false


func _process(delta: float) -> void:
	_banner_left = maxf(0.0, _banner_left - delta)
	_dry_flash = maxf(0.0, _dry_flash - delta)
	_pulse += delta
	_banner.modulate.a = clampf(_banner_left, 0.0, 1.0)
	_subtitle.modulate.a = clampf(_banner_left, 0.0, 1.0)
	_update_hint(delta)
	queue_redraw()


func show_hint(text: String, duration: float = 1.6, at: Vector2 = Vector2(300.0, 74.0)) -> void:
	_hint.text = text
	_hint.position = at
	_hint_left = duration
	_hint_elapsed = 0.0
	_hint.modulate.a = 0.0


func _update_hint(delta: float) -> void:
	if _hint_left <= 0.0:
		_hint.modulate.a = 0.0
		return
	_hint_left -= delta
	_hint_elapsed += delta
	var fade_in := clampf(_hint_elapsed / 0.25, 0.0, 1.0)
	var fade_out := clampf(_hint_left / 0.5, 0.0, 1.0)
	_hint.modulate.a = minf(fade_in, fade_out) * 0.34


func set_room(index: int, total: int) -> void:
	_room = index
	_room_total = total


func show_banner(text: String, duration: float = 1.6) -> void:
	_banner_text = text
	_banner_left = duration
	_banner.text = text
	_banner.modulate.a = 1.0


func _make_label(font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = ""
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.04))
	label.add_theme_constant_override("outline_size", 5)
	label.horizontal_alignment = alignment
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _on_health_changed(current: float, maximum: float) -> void:
	_health = current
	_health_max = maxf(1.0, maximum)


func _on_oil_changed(current: float, maximum: float) -> void:
	_oil = current
	_oil_max = maxf(1.0, maximum)


func _on_dash_changed(current: int, maximum: int) -> void:
	_dash = current
	_dash_max = maxi(1, maximum)


func _on_ressonancia_changed(chain: int, multiplier: float) -> void:
	_chain = chain
	_multiplier = multiplier
	var next := ThresholdDatabase.next_after(chain)
	if next == null:
		_next_threshold = 0
		_next_threshold_name = ""
	else:
		_next_threshold = next.at_chain
		_next_threshold_name = next.display_name


func _on_score_changed(score: int) -> void:
	_score = score


func _on_cera_changed(amount: int) -> void:
	_cera = amount


func _on_wave_started(index: int, total: int) -> void:
	_wave = index + 1
	_wave_total = total
	show_banner("ONDA %d / %d" % [_wave, _wave_total], 1.2)


func _on_enemies_changed(count: int) -> void:
	_enemies = count


func _on_beam_dried() -> void:
	_dry_flash = 1.0
	show_banner("SEM OLEO", 1.2)


func _draw() -> void:
	_draw_bar(BAR_ORIGIN, _health / _health_max, COL_HEALTH, "VIDA", "health")
	var oil_ratio := clampf(_oil / _oil_max, 0.0, 1.0)
	var oil_origin := BAR_ORIGIN + Vector2(0, BAR_HEIGHT + BAR_GAP)
	_draw_bar(oil_origin, oil_ratio, COL_OIL, "OLEO", "oil")
	if oil_ratio < 0.25:
		var urgency := 1.0 - (oil_ratio / 0.25)
		var alpha := (0.18 + 0.22 * (0.5 + 0.5 * sin(_pulse * 6.0))) * urgency
		draw_rect(Rect2(oil_origin - Vector2(2, 2), Vector2(BAR_WIDTH + 4, BAR_HEIGHT + 4)), Color(1.0, 0.6, 0.25, alpha), false, 2.0)
	_draw_dash(BAR_ORIGIN + Vector2(0, (BAR_HEIGHT + BAR_GAP) * 2.0 + 6.0))
	_draw_chain(BAR_ORIGIN + Vector2(0, (BAR_HEIGHT + BAR_GAP) * 3.0 + 6.0))
	_draw_cera(BAR_ORIGIN + Vector2(0, (BAR_HEIGHT + BAR_GAP) * 4.0 + 14.0))

	_readout.text = "SALA %d / %d\nONDA %d / %d\nINIMIGOS  %d\n\nCADEIA  %d\nx%.1f\n\nPONTOS  %d" % [
		_room, _room_total, _wave, _wave_total, _enemies, _chain, _multiplier, _score,
	]
	_readout.add_theme_color_override("font_color", COL_HEALTH if _dry_flash > 0.0 else COL_TEXT)

	if _boss_active:
		_draw_boss_bar()


## Glifos pequenos a esquerda das barras. Desenho procedural, sem fonte de icones.
func _draw_icon(origin: Vector2, color: Color, kind: String) -> void:
	match kind:
		"health":
			draw_rect(Rect2(origin + Vector2(-2.0, -8.0), Vector2(4.0, 13.0)), color)
			draw_rect(Rect2(origin + Vector2(-6.5, -3.5), Vector2(13.0, 4.0)), color)
		"oil":
			draw_colored_polygon(
				PackedVector2Array([
					origin + Vector2(0.0, -8.0),
					origin + Vector2(4.5, -1.0),
					origin + Vector2(0.0, 5.0),
					origin + Vector2(-4.5, -1.0),
				]),
				color,
			)
			draw_circle(origin + Vector2(0.0, 0.5), 1.8, Color(1.0, 0.95, 0.8, 0.85))
		"dash":
			draw_polyline(
				PackedVector2Array([
					origin + Vector2(-5.0, 4.0),
					origin + Vector2(0.0, -3.0),
					origin + Vector2(5.0, 4.0),
				]),
				color,
				2.2,
			)
		_:
			draw_circle(origin, 3.0, color)


func _draw_boss_bar() -> void:
	var width := 520.0
	var x := (1280.0 - width) * 0.5
	var y := 40.0
	var ratio := clampf(_boss_health / _boss_max, 0.0, 1.0)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(x, y - 8), "COBRA GRANDE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COL_DIM)
	draw_rect(Rect2(x, y, width, 12), Color(0.03, 0.05, 0.06))
	draw_rect(Rect2(x, y, width * ratio, 12), Color(0.72, 0.34, 0.3))
	draw_rect(Rect2(x, y, width, 12), Color(0.25, 0.32, 0.34), false, 1.0)


func _draw_bar(origin: Vector2, ratio: float, color: Color, caption: String, icon: String) -> void:
	var clamped := clampf(ratio, 0.0, 1.0)
	var background := Rect2(origin, Vector2(BAR_WIDTH, BAR_HEIGHT))
	draw_rect(background, Color(0.03, 0.05, 0.06))
	draw_rect(Rect2(origin, Vector2(BAR_WIDTH * clamped, BAR_HEIGHT)), color)
	draw_rect(background, Color(0.16, 0.24, 0.27), false, 1.0)

	var font := ThemeDB.fallback_font
	draw_string(font, origin + Vector2(0, -6), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COL_DIM)
	_draw_icon(origin + Vector2(-18.0, 1.0), color, icon)


func _draw_dash(origin: Vector2) -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, origin + Vector2(0, -6), "DASH", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COL_DIM)
	_draw_icon(origin + Vector2(-18.0, 2.0), COL_DASH, "dash")
	for i in range(_dash_max):
		var center := origin + Vector2(48.0 + float(i) * 24.0, 7.0)
		var color := COL_DASH if i < _dash else Color(0.12, 0.18, 0.2)
		draw_circle(center, 7.0, color)


## Moeda de cera: círculo com brilho, ao lado do saldo.
func _draw_cera(origin: Vector2) -> void:
	var font := ThemeDB.fallback_font
	draw_circle(origin + Vector2(0.0, 6.0), 7.5, Color(0.55, 0.40, 0.14))
	draw_circle(origin + Vector2(0.0, 6.0), 6.0, Color(0.92, 0.74, 0.32))
	draw_circle(origin + Vector2(-1.6, 4.4), 2.2, Color(1.0, 0.92, 0.66, 0.9))
	draw_string(
		font,
		origin + Vector2(14.0, 11.0),
		"%d" % _cera,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		15,
		COL_SCORE,
	)


## Barra fina do próximo limiar. Sem limiar restante, a barra fica cheia e apagada.
func _draw_chain(origin: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var label := "CADEIA"
	if _next_threshold > 0:
		label = "CADEIA  →  %d · %s" % [_next_threshold, _next_threshold_name]
	draw_string(font, origin + Vector2(0, -6), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COL_DIM)

	var ratio := 1.0
	if _next_threshold > 0:
		ratio = clampf(float(_chain) / float(_next_threshold), 0.0, 1.0)
	var background := Rect2(origin, Vector2(BAR_WIDTH, 6.0))
	draw_rect(background, Color(0.03, 0.05, 0.06))
	draw_rect(Rect2(origin, Vector2(BAR_WIDTH * ratio, 6.0)), COL_SCORE)
	draw_rect(background, Color(0.16, 0.24, 0.27), false, 1.0)