// Realistic foliage: alpha-scissored cards from the leaf atlas (stays in the opaque pipeline), canopy-bent
// normals so the crown shades as one volume, backlight translucency, coverage-preserving alpha at distance.
shader_type spatial;
render_mode cull_disabled;

#include "res://addons/proc_trees/shaders/tree_common.gdshaderinc"

uniform sampler2D leaf_atlas : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec4 leaf_color : source_color = vec4(0.2, 0.33, 0.09, 1.0);
uniform vec4 leaf_color_2 : source_color = vec4(0.33, 0.42, 0.12, 1.0);
uniform vec4 moss_color : source_color = vec4(0.42, 0.45, 0.33, 1.0);
uniform float translucency = 0.6;
uniform float alpha_cut = 0.5;

varying float v_fade;
varying float v_fade_in;
varying vec3 v_tint;
varying vec3 v_vnormal;

void vertex() {
	float fi;
	v_fade = tree_fade(MODEL_MATRIX[3].xyz, fi);
	v_fade_in = fi;
	v_tint = INSTANCE_CUSTOM.rgb;
	v_vnormal = (VIEW_MATRIX * (MODEL_MATRIX * vec4(NORMAL, 0.0))).xyz;
	VERTEX += tree_wind_offset(VERTEX, NORMAL, UV2, COLOR, MODEL_MATRIX, TIME, INSTANCE_CUSTOM.a);
	if (v_fade <= 0.0) {
		VERTEX = vec3(0.0);
	}
}

void fragment() {
	if (v_fade < 1.0 && tree_dithered_out(FRAGCOORD.xy, v_fade, v_fade_in)) {
		discard;
	}
	vec4 tex = texture(leaf_atlas, UV);
	// mip-level estimate: boost alpha as the texture shrinks so distant canopies don't thin out
	vec2 px = UV * vec2(textureSize(leaf_atlas, 0));
	float lod = 0.5 * log2(max(dot(dFdx(px), dFdx(px)), dot(dFdy(px), dFdy(px))));
	ALPHA = tex.a * (1.0 + max(lod, 0.0) * 0.25);
	ALPHA_SCISSOR_THRESHOLD = alpha_cut;
	vec3 base = COLOR.a < 0.5 ? moss_color.rgb : mix(leaf_color.rgb, leaf_color_2.rgb, COLOR.b);
	vec3 col = base * tex.rgb * mix(0.35, 1.0, COLOR.g) * (1.0 + v_tint);
	ALBEDO = col;
	NORMAL = normalize(v_vnormal); // same normal on both faces: the crown reads as one lit volume
	ROUGHNESS = 0.7;
	SPECULAR = 0.35;
	BACKLIGHT = col * translucency;
}
