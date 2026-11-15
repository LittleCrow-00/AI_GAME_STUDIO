shader_type canvas_item;
render_mode unshaded;

// Rim light de 1 texel: nao muda a silhueta, so acende a borda de cima e da
// esquerda para o personagem sair do chao escuro. Funciona com pixel art
// porque compara a alpha do texel vizinho.

uniform vec4 rim_color : source_color = vec4(1.0, 0.86, 0.62, 1.0);
uniform float rim_strength : hint_range(0.0, 2.0) = 0.7;
uniform float rim_min_alpha : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float left = texture(TEXTURE, UV - vec2(TEXTURE_PIXEL_SIZE.x, 0.0)).a;
	float up = texture(TEXTURE, UV - vec2(0.0, TEXTURE_PIXEL_SIZE.y)).a;
	float edge = clamp(tex.a - min(left, up), 0.0, 1.0);
	float k = edge * rim_strength * step(rim_min_alpha, tex.a);
	COLOR = vec4(mix(tex.rgb, rim_color.rgb, k), tex.a);
}