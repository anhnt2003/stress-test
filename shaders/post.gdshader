// Hậu kỳ: khử màu (giữ lại sắc đỏ), tông lạnh bẩn, giảm số màu + dither, vignette nặng, nhiễu hạt, sọc quét.
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float levels = 14.0;
uniform float dither_strength = 1.0;
uniform float vignette = 0.8;
uniform float grain = 0.06;
uniform float desat = 0.6;
uniform float flash = 0.0; // loé đỏ khi có đối tượng bị loại
const float BAYER[16] = { 0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0 };
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 uv = SCREEN_UV;
	float ca = 0.0008 + flash * 0.005;
	vec3 c = vec3(texture(screen_tex, uv + vec2(ca, 0.0)).r, texture(screen_tex, uv).g, texture(screen_tex, uv - vec2(ca, 0.0)).b);
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	// giữ đỏ, khử các màu khác
	float redness = clamp((c.r - c.g * 1.45) * 4.0, 0.0, 1.0);
	c = mix(c, vec3(l), desat * (1.0 - redness));
	// tông nâu sepia: vùng tối ngả nâu ô-liu, vùng sáng ngả vàng đèn dây tóc
	c = mix(c * vec3(0.94, 0.95, 0.80), c * vec3(1.05, 1.0, 0.84), smoothstep(0.1, 0.75, l));
	c += vec3(0.30, 0.0, 0.0) * flash;
	float d = distance(uv, vec2(0.5));
	c *= 1.0 - vignette * smoothstep(0.28, 0.82, d);
	c *= 0.94 + 0.06 * sin(FRAGCOORD.y * 3.14159);
	c += (h(FRAGCOORD.xy + fract(TIME) * 100.0) - 0.5) * grain;
	ivec2 ip = ivec2(FRAGCOORD.xy) % 4;
	float b = (BAYER[ip.y * 4 + ip.x] / 16.0 - 0.5) * dither_strength;
	c = floor(c * levels + 0.5 + b) / levels;
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
