// Tường bê tông vàng nâu cáu bẩn: texel vuông, vết ván khuôn, vệt nước, gỉ, máu khô gần sàn.
shader_type spatial;
#include "common.gdshaderinc"
uniform float texel = 14.0;
varying vec3 wpos;
varying vec3 wn;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec2 uv = abs(wn.x) > 0.5 ? vec2(wpos.z, wpos.y) : vec2(wpos.x, wpos.y);
	uv = floor(uv * texel) / texel;
	float y = uv.y;
	vec3 c = vec3(0.46, 0.40, 0.30);
	c *= mix(0.5, 1.12, fbm(uv * 0.9));
	c *= mix(0.75, 1.0, fbm(uv * 9.0));
	vec2 g = fract(uv / vec2(2.0, 1.2));
	if (g.x < 0.03 || g.y < 0.05) { c *= 0.55; }
	vec2 hg = (fract(uv / vec2(1.0, 0.6)) - 0.5) * vec2(1.0, 0.6);
	if (length(hg) < 0.05) { c *= 0.4; }
	float st = smoothstep(0.45, 0.78, fbm(vec2(uv.x * 2.5, uv.y * 0.15)));
	c *= mix(1.0, 0.48, st);
	float rs = smoothstep(0.55, 0.82, fbm(vec2(uv.x * 4.0 + 7.0, uv.y * 0.2)));
	c = mix(c, vec3(0.30, 0.14, 0.05), rs * 0.6 * smoothstep(1.0, 4.5, y));
	c *= mix(0.42, 1.0, smoothstep(0.0, 1.5, y + fbm(uv * 1.5) * 0.9));
	float bl = smoothstep(0.60, 0.70, fbm(uv * 1.7 + 31.0)) * smoothstep(2.4, 0.2, y);
	c = mix(c, vec3(0.17, 0.02, 0.012), bl * 0.9);
	ALBEDO = c;
	ROUGHNESS = mix(0.95, 0.5, bl);
}
