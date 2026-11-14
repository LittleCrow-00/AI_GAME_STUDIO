class_name Vignette
extends CanvasLayer
## Escurece as bordas da tela. E apresentacao pura: nao le nem altera estado.
##
## Fica entre o mundo (camada 0) e a UI (camada 10) para o HUD nunca escurecer.

const FRAGMENT := """
shader_type canvas_item;
uniform float strength : hint_range(0.0, 1.0) = 0.6;
uniform vec4 tint : source_color = vec4(0.008, 0.016, 0.022, 1.0);

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float d = length(uv * vec2(1.12, 1.0));
	float v = smoothstep(0.34, 0.88, d);
	COLOR = vec4(tint.rgb, v * strength);
}
"""


func _ready() -> void:
	layer = 5

	var shade := ColorRect.new()
	shade.name = "Shade"
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var shader := Shader.new()
	shader.code = FRAGMENT
	var material := ShaderMaterial.new()
	material.shader = shader
	shade.material = material

	add_child(shade)