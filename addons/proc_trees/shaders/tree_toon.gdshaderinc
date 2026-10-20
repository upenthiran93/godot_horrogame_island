// Toon lighting shared by the stylized bark and canopy: wrapped two-tone diffuse, cool shade, backlit rim.
// Sun (directional) lights get the toon ramp with toon shadows; local lights (flashlight, lamps) keep their
// falloff so they don't leak light around the tree.

uniform float toon_threshold = 0.5;
uniform float toon_softness = 0.08;
uniform float toon_wrap = 0.35;
uniform float toon_shade = 0.3;
uniform float toon_rim = 0.35;

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float w = (ndl + toon_wrap) / (1.0 + toon_wrap);
	float band = smoothstep(toon_threshold - toon_softness, toon_threshold + toon_softness, w);
	float shadow = smoothstep(0.3, 0.7, ATTENUATION);
	float lit = LIGHT_IS_DIRECTIONAL ? mix(toon_shade, 1.0, band * shadow) : band * ATTENUATION;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0) * (0.3 + 0.7 * max(0.0, -dot(LIGHT, VIEW)));
	lit += toon_rim * rim * (LIGHT_IS_DIRECTIONAL ? shadow : ATTENUATION);
	DIFFUSE_LIGHT += LIGHT_COLOR / PI * lit;
}
