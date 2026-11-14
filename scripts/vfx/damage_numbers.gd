class_name DamageNumbers
extends CanvasLayer
## Numeros flutuantes de dano. Puramente reativo: escuta o SignalBus e desenha.
## Um dos primeiros lugares onde se percebe "peso" no combate.

func _ready() -> void:
	layer = 10
	SignalBus.damage_number_requested.connect(_spawn)


func _spawn(amount: float, position: Vector2, is_critical: bool) -> void:
	var label := Label.new()
	label.text = str(int(round(amount)))
	label.add_theme_font_size_override("font_size", 26 if is_critical else 17)
	label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.52) if not is_critical else Color(1.0, 0.55, 0.35))
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.04))
	label.add_theme_constant_override("outline_size", 5)
	label.z_index = 20
	label.position = position + Vector2(-8, -14)
	add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(randf_range(-16.0, 16.0), -46.0), 0.65)
	tween.tween_property(label, "modulate:a", 0.0, 0.45).set_delay(0.25)
	tween.chain().tween_callback(label.queue_free)