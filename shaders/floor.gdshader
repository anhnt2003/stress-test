// Sàn bê tông nâu bẩn: texel vuông, khe tấm, vết ố, vũng ướt, máu khô.
shader_type spatial;
#include "common.gdshaderinc"
uniform float texel = 14.0;
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = floor(wpos.xz * texel) / texel;
	vec3 c = vec3(0.34, 0.30, 0.23);
	float grime = fbm(p * 0.6);
	c *= mix(0.45, 1.1, grime);
	c *= mix(0.78, 1.0, fbm(p * 8.0));
	vec2 t = fract(p / 2.0);
	if (t.x < 0.035 || t.y < 0.035) { c *= 0.45; }
	float crack = smoothstep(0.03, 0.0, abs(fbm(p * 1.3 + 11.0) - 0.5));
	c *= 1.0 - crack * 0.6;
	float bl = smoothstep(0.63, 0.70, fbm(p * 0.9 + 53.0));
	c = mix(c, vec3(0.16, 0.02, 0.012), bl * 0.85);
	float wet = smoothstep(0.55, 0.7, fbm(p * 0.45 + 90.0));
	ALBEDO = c * mix(1.0, 0.7, wet);
	ROUGHNESS = mix(0.92, 0.2, max(wet, bl * 0.7));
}
