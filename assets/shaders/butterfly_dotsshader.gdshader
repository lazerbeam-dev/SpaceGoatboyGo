shader_type canvas_item;

// === Visual controls ===
uniform int dot_count = 120; // Total dots (try 100–300)
uniform float time_scale = 1.0;
uniform float swirl_amplitude = 0.2;
uniform float swirl_speed = 1.0;
uniform float color_cycle_speed = 1.0;
uniform float pulse_speed = 3.0;
uniform float interference_strength = 1.2;

// === Dot geometry variation ===
uniform float base_radius = 0.12;
uniform float radius_variation = 1.0;
uniform float edge_softness = 0.4;

// === Optional masking ===
uniform bool use_source_mask = false;

// === Optional border fade ===
uniform bool use_border_fade = false;

//
// === Helpers ===
//

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 hue_shift(float t) {
	return hsv2rgb(vec3(mod(t, 1.0), 1.0, 1.0));
}

void fragment() {
	vec2 uv = UV;
	float global_time = TIME * time_scale;
	vec3 final_col = vec3(0.0);
	float total_weight = 0.0;

	for (int i = 0; i < dot_count; i++) {
		// Random position
		vec2 seed = vec2(float(i) * 4.0, float(i) * 7.0);
		vec2 pos = vec2(rand(seed), rand(seed + 5.7));

		// Swirl animation
		pos += vec2(
			sin(global_time * swirl_speed + float(i)) * swirl_amplitude,
			cos(global_time * swirl_speed + float(i)) * swirl_amplitude
		);

		// Distance from this dot
		vec2 diff = uv - pos;
		float dist = length(diff);

		// Radius
		float r_rand = rand(seed + 10.0);
		float radius = base_radius * mix(0.2, 1.0, pow(r_rand, radius_variation));

		// Pulsing
		float pulse = sin(global_time * pulse_speed + float(i)) * 0.5 + 0.5;
		float effective_radius = radius * (0.8 + 0.4 * pulse);

		// Edge softness
		float mask = smoothstep(effective_radius, effective_radius * (1.0 - edge_softness), dist);

		// Interference and color
		float interference = sin((dist - pulse) * 40.0 + float(i)) * interference_strength;
		float t = global_time * color_cycle_speed + interference + float(i) * 0.1;
		vec3 col = hue_shift(t);

		final_col += col * mask;
		total_weight += mask;
	}

	final_col = (total_weight > 0.0) ? final_col / total_weight : final_col;

	// Optional border fade
	if (use_border_fade) {
		float border = smoothstep(0.5, 0.9, length(uv - 0.5));
		final_col *= border;
	}

	// Optional alpha mask
	float alpha = 1.0;
	if (use_source_mask) {
		alpha = texture(TEXTURE, uv).a;
	}
	COLOR = vec4(final_col, alpha);
}
