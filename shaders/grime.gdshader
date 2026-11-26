// Bề mặt bẩn kiểu texture độ phân giải thấp: vân loang, gỉ, có "texel" vuông như game đời cũ.
// Dùng toạ độ cục bộ của vật nên texture không trôi khi vật di chuyển.
shader_type spatial;
#include "common.gdshaderinc"
uniform vec3 base : source_color = vec3(0.3, 0.3, 0.3);
uniform float texel = 18.0;
uniform float rust = 0.3;
uniform float dirt = 0.6;
uniform float metal = 0.0;
uniform float rough = 0.85;
uniform float seed = 0.0;
uniform vec3 emit : source_color = vec3(1.0, 0.1, 0.05);
uniform float emit_e = 0.0;
varying vec3 lpos;
varying vec3 ln;
void vertex() { lpos = VERTEX; ln = NORMAL; }
void fragment() {
	vec3 an = abs(ln);
	vec2 uv = an.y > an.x && an.y > an.z ? lpos.xz : (an.x > an.z ? lpos.zy : lpos.xy);
	uv = floor(uv * texel) / texel + seed;
	float g = fbm(uv * 1.4);
	float fine = fbm(uv * 8.0 + 5.0);
	vec3 c = base * mix(1.0 - dirt * 0.65, 1.12, g) * mix(0.78, 1.0, fine);
	float streak = smoothstep(0.5, 0.8, fbm(vec2(uv.x * 5.0, uv.y * 0.5) + 17.0));
	c *= mix(1.0, 0.7, streak * dirt);
	float r = smoothstep(0.52, 0.74, fbm(uv * 2.4 + 13.0));
	c = mix(c, vec3(0.27, 0.12, 0.05) * mix(0.55, 1.2, fine), r * rust);
	ALBEDO = c;
	ROUGHNESS = rough;
	METALLIC = metal * (1.0 - r * rust);
	EMISSION = emit * emit_e;
}
