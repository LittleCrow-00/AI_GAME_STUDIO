class_name LightFactory
extends RefCounted
## Cria texturas procedurais de luz. Evita depender de assets externos para
## a iluminação 2D do jogo (viabiliza o estilo "programmer-art" da Fase 1).

static func radial_texture(inner: Color = Color(1, 1, 1, 1), outer: Color = Color(1, 1, 1, 0)) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, inner)
	gradient.set_color(1, outer)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 256
	texture.height = 256
	return texture


static func unshaded_material() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return material