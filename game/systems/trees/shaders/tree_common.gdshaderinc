// Shared by every tree shader: global wind and the per-tree LOD dither crossfade.
// Vertex data written by TreeBuilder:
//   UV2.x   trunk bend weight (0 at the root, grows with height)
//   UV2.y   branch flex (0 on the trunk, grows towards branch tips)
//   COLOR.r leaf flutter weight   COLOR.g ambient occlusion   COLOR.b random phase   COLOR.a 0 = hanging moss
//   INSTANCE_CUSTOM (MultiMesh) rgb = tint offset, a = wind phase offset

global uniform vec4 tree_wind;      // xy = world XZ direction, z = strength, w = gustiness (set by TreeWind)
global uniform vec3 tree_view_pos;  // main camera position, also used in shadow passes (set by TreeForest)

// Per draw call (one MultiMeshInstance3D per LOD per chunk): fade in over x..y, fade out over z..w metres.
instance uniform vec4 lod_fade = vec4(-2.0, -1.0, 1000000.0, 1000001.0);

uniform float wind_bend = 1.0;
uniform float wind_branch = 1.0;
uniform float wind_flutter = 1.0;

float tree_fade(vec3 origin, out float fading_in) {
	float d = distance(origin, tree_view_pos);
	fading_in = d < lod_fade.y ? 1.0 : 0.0;
	return smoothstep(lod_fade.x, lod_fade.y, d) * (1.0 - smoothstep(lod_fade.z, lod_fade.w, d));
}

vec3 tree_wind_offset(vec3 v, vec3 n, vec2 uv2, vec4 col, mat4 model, float t, float phase_ofs) {
	vec3 origin = model[3].xyz;
	float phase = dot(origin, vec3(0.171, 0.0, 0.239)) + phase_ofs * 6.2832;
	vec2 wd = dot(tree_wind.xy, tree_wind.xy) > 1e-6 ? normalize(tree_wind.xy) : vec2(1.0, 0.0);
	vec3 wl = normalize((vec4(wd.x, 0.0, wd.y, 0.0) * model).xyz); // world -> local direction
	float gust = mix(1.0, 0.55 + 0.45 * sin(t * 0.37 + phase * 0.13) * sin(t * 0.91 + phase * 0.31), tree_wind.w);
	float s = tree_wind.z * gust;
	// whole tree leans and sways
	float sway = s * (0.8 + 0.2 * sin(t * 1.2 + phase));
	vec3 off = wl * uv2.x * sway * wind_bend;
	off.y -= uv2.x * uv2.x * sway * sway * wind_bend * 0.1;
	// branches bob on their own phase
	float bp = col.b * 6.2832 + phase;
	float b = sin(t * 1.9 + bp) * 0.65 + sin(t * 3.3 + bp * 1.7) * 0.35;
	off += (wl * 0.6 + vec3(0.0, 0.7, 0.0)) * b * uv2.y * s * wind_branch * 0.08;
	// leaf edges flutter
	off += n * sin(t * 8.0 + col.b * 31.0 + (v.x + v.z) * 1.7) * col.r * s * wind_flutter * 0.04;
	return off;
}

// Interleaved-gradient dither. The fading-in LOD uses the inverted pattern, so the two LODs of one tree
// cover exactly complementary pixels while they crossfade (no holes, no double-draw, no transparency).
bool tree_dithered_out(vec2 frag, float fade, float fading_in) {
	float n = fract(52.9829189 * fract(dot(frag, vec2(0.06711056, 0.00583715))));
	n = mix(n, 1.0 - n, fading_in);
	return n >= fade;
}
