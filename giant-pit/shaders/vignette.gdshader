shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.22;
uniform float softness : hint_range(0.0, 1.0) = 0.45;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv * vec2(1.0, 0.82));
	float edge = 0.28 + softness * 0.35;
	float vig = smoothstep(edge, edge + 0.35, dist);
	COLOR = vec4(0.0, 0.0, 0.0, vig * intensity);
}
