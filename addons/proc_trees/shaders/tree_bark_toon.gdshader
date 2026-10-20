// Stylized bark: flat two-tone with soft vertical stripes, palm bands, toon light. No textures.
shader_type spatial;
render_mode cull_back;

#include "res://addons/proc_trees/shaders/tree_common.gdshaderinc"
#include "res://addons/proc_trees/shaders/tree_toon.gdshaderinc"

uniform vec4 bark_color : source_color = vec4(0.45, 0.3, 0.2, 1.0);
uniform vec4 bark_color_2 : source_color = vec4(0.3, 0.19, 0.13, 1.0);
uniform float palm_rings = 0.0;

varying float v_fade;
varying float v_fade_in;
varying vec3 v_tint;

void vertex() {
	float fi;
	v_fade = tree_fade(MODEL_MATRIX[3].xyz, fi);
	v_fade_in = fi;
	v_tint = INSTANCE_CUSTOM.rgb;
	VERTEX += tree_wind_offset(VERTEX, NORMAL, UV2, COLOR, MODEL_MATRIX, TIME, INSTANCE_CUSTOM.a);
	if (v_fade <= 0.0) {
		VERTEX = vec3(0.0);
	}
}

void fragment() {
	if (v_fade < 1.0 && tree_dithered_out(FRAGCOORD.xy, v_fade, v_fade_in)) {
		discard;
	}
	float stripe = smoothstep(0.35, 0.65, sin(UV.x * 6.2832 * 3.0 + sin(UV.y * 2.0) * 0.8) * 0.5 + 0.5);
	vec3 col = mix(bark_color.rgb, bark_color_2.rgb, stripe * 0.35);
	col = mix(col, bark_color_2.rgb, palm_rings * step(0.6, fract(UV.y * 2.0)));
	ALBEDO = col * mix(0.6, 1.0, COLOR.g) * (1.0 + v_tint);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
