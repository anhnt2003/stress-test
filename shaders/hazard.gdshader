// Sọc cảnh báo vàng-đen, tróc sơn và gỉ nặng.
shader_type spatial;
#include "common.gdshaderinc"
uniform float freq = 1.6;
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float s = step(0.5, fract((wpos.x + wpos.y + wpos.z) * freq));
	vec3 c = mix(vec3(0.03, 0.03, 0.03), vec3(0.62, 0.45, 0.05), s);
	float wear = fbm(wpos.xz * 2.2 + wpos.y * 3.0);
	c *= mix(0.45, 1.0, wear);
	c = mix(c, vec3(0.22, 0.09, 0.04), smoothstep(0.55, 0.75, fbm(wpos.xz * 3.5 + 20.0)));
	ALBEDO = c;
	ROUGHNESS = 0.75;
	METALLIC = 0.3;
}
