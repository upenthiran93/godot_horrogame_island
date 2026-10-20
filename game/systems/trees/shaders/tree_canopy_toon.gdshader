// Stylized canopy (puffs, conifer tiers, palm fronds, moss tassels): solid geometry, no alpha, toon light.
// Colour runs from leaf_color_2 (inside/under) to leaf_color (outer/top) using the baked canopy AO.
shader_type spatial;
render_mode cull_disabled;

#include "res://game/systems/trees/shaders/tree_common.gdshaderinc"
#include "res://game/systems/trees/shaders/tree_toon.gdshaderinc"

uniform vec4 leaf_color : source_color = vec4(0.45, 0.68, 0.22, 1.0);
uniform vec4 leaf_color_2 : source_color = vec4(0.13, 0.36, 0.16, 1.0);
uniform vec4 moss_color : source_color = vec4(0.35, 0.4, 0.3, 1.0);

varying float v_fade;
varying float v_fade_in;
varying vec3 v_tint;
varying vec3 v_vnormal;
varying float v_up;

void vertex() {
	float fi;
	v_fade = tree_fade(MODEL_MATRIX[3].xyz, fi);
	v_fade_in = fi;
	v_tint = INSTANCE_CUSTOM.rgb;
	vec3 wn = normalize(mat3(MODEL_MATRIX) * NORMAL);
	v_up = wn.y;
	v_vnormal = (VIEW_MATRIX * vec4(wn, 0.0)).xyz;
	VERTEX += tree_wind_offset(VERTEX, NORMAL, UV2, COLOR, MODEL_MATRIX, TIME, INSTANCE_CUSTOM.a);
	if (v_fade <= 0.0) {
		VERTEX = vec3(0.0);
	}
}

void fragment() {
	if (v_fade < 1.0 && tree_dithered_out(FRAGCOORD.xy, v_fade, v_fade_in)) {
		discard;
	}
	vec3 base = mix(leaf_color_2.rgb, leaf_color.rgb, clamp(COLOR.g * 0.85 + v_up * 0.25, 0.0, 1.0));
	base = COLOR.a < 0.5 ? moss_color.rgb * mix(0.6, 1.0, COLOR.g) : base;
	ALBEDO = base * (0.93 + 0.14 * COLOR.b) * (1.0 + v_tint);
	NORMAL = normalize(v_vnormal);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
