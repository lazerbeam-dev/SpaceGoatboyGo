shader_type canvas_item;

uniform float speed = 1.0;
uniform float swirl_intensity = 0.5;
uniform float swirl_frequency = 10.0;
uniform float radial_scale = 1.0;

uniform float symmetry_strength = 1.0;
uniform bool vertical_symmetry = false;

uniform float color_cycle_speed = 1.0;
uniform float color_detail = 10.0;
uniform float color_saturation = 1.0;

uniform float noise_strength = 0.05;
uniform float noise_scale = 10.0;

uniform sampler2D source_texture;// Must assign the texture

// === Simple noise ===
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

vec3 psychedelic_palette(float t) {
	return color_saturation * (0.5 + 0.5 * cos(6.2831 * (t + vec3(0.0, 0.33, 0.67))));
}

void fragment() {
	vec2 uv = UV;

	// === Sample alpha and contours ===
	vec4 src = texture(source_texture, uv);
	float alpha = src.a;

	// Simple edge approximation via sampling neighbors
	float dx = texture(source_texture, uv + vec2(1.0/512.0, 0.0)).a - texture(source_texture, uv - vec2(1.0/512.0, 0.0)).a;
	float dy = texture(source_texture, uv + vec2(0.0, 1.0/512.0)).a - texture(source_texture, uv - vec2(0.0, 1.0/512.0)).a;
	float edge_strength = length(vec2(dx, dy)); // edge detection via alpha gradient

	vec2 p = uv * 2.0 - 1.0;
	p *= radial_scale;

	// Polar swirl
	float angle = atan(p.y, p.x);
	float radius = length(p);

	// Swirl intensity modulated by edge
	float swirl_mod = swirl_intensity * (0.5 + edge_strength); // more swirl near edges
	angle += sin(TIME * speed + radius * swirl_frequency) * swirl_mod;

	vec2 warped = vec2(cos(angle), sin(angle)) * radius / radial_scale;
	uv = warped * 0.5 + 0.5;

	// Symmetry
	if (symmetry_strength > 0.0) {
		uv.x = mix(uv.x, abs(uv.x - 0.5) + 0.5, symmetry_strength);
		if (vertical_symmetry) {
			uv.y = mix(uv.y, abs(uv.y - 0.5) + 0.5, symmetry_strength);
		}
	}

	// Noise warping modulated by alpha
	vec2 noisy_uv = uv + noise_strength * (0.5 + alpha) * vec2(
		noise(uv * noise_scale + vec2(TIME)),
		noise(uv * noise_scale + vec2(42.0, 27.0) + TIME)
	);

	// Color generation
	float t = sin(TIME * color_cycle_speed + noisy_uv.x * color_detail + noisy_uv.y * color_detail);
	vec3 col = psychedelic_palette(t);

	// Final color masked by source alpha
	COLOR = vec4(col, alpha);
}
