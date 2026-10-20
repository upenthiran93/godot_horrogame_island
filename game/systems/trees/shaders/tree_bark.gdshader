// Realistic bark: tiling noise plates stretched along the branch, normal map, optional moss and palm rings.
shader_type spatial;
render_mode cull_back;

#include "res://game/systems/trees/shaders/tree_common.gdshaderinc"

uniform vec4 bark_color : source_color = vec4(0.36, 0.3, 0.24, 1.0);
uniform vec4 bark_color_2 : source_color = vec4(0.17, 0.14, 0.11, 1.0);
uniform sampler2D bark_noise : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D bark_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_strength = 1.0;
uniform float moss = 0.0;
uniform vec4 moss_color : source_color = vec4(0.25, 0.32, 0.12, 1.0);
uniform float palm_rings = 0.0;

varying float v_fade;
varying float v_fade_in;
varying vec3 v_tint;
varying vec3 v_wnormal;
varying float v_height;

void vertex() {
	float fi;
	v_fade = tree_fade(MODEL_MATRIX[3].xyz, fi);
	v_fade_in = fi;
	v_tint = INSTANCE_CUSTOM.rgb;
	v_height = VERTEX.y;
	v_wnormal = mat3(MODEL_MATRIX) * NORMAL;
	VERTEX += tree_wind_offset(VERTEX, NORMAL, UV2, COLOR, MODEL_MATRIX, TIME, INSTANCE_CUSTOM.a);
	if (v_fade <= 0.0) {
		VERTEX = vec3(0.0); // fully faded: collapse, nothing rasterised
	}
}

void fragment() {
	if (v_fade < 1.0 && tree_dithered_out(FRAGCOORD.xy, v_fade, v_fade_in)) {
		discard;
	}
	vec2 buv = UV * vec2(1.0, 0.35);
	float n = texture(bark_noise, buv).r;
	vec3 col = mix(bark_color_2.rgb, bark_color.rgb, smoothstep(0.2, 0.8, n));
	float ring = palm_rings * smoothstep(0.55, 0.95, fract(UV.y * 2.2 + n * 0.25));
	col = mix(col, bark_color_2.rgb * 0.7, ring);
	float up = normalize(v_wnormal).y;
	float m = moss * clamp(smoothstep(0.05, 0.6, up + (n - 0.5) * 0.8) + (1.0 - smoothstep(0.2, 1.4, v_height)) * 0.9, 0.0, 1.0);
	col = mix(col, moss_color.rgb * (0.7 + 0.6 * n), m);
	ALBEDO = col * (1.0 + v_tint);
	AO = COLOR.g;
	AO_LIGHT_AFFECT = 0.3;
	ROUGHNESS = 0.9;
	SPECULAR = 0.25;
	NORMAL_MAP = texture(bark_normal, buv).rgb;
	NORMAL_MAP_DEPTH = normal_strength * (1.0 - m * 0.6);
}
