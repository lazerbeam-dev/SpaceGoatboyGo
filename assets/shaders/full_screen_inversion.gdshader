shader_type canvas_item;

// === Controls ===
uniform float time_scale = 1.0;          // Global time speed
uniform float dark_speed_ratio = 4.0;    // How much faster dark pixels oscillate
uniform bool invert_dark_faster = true;  // If false, bright pixels oscillate faster

uniform sampler2D screen_texture;        // The screen input (assign from ViewportTexture)

void fragment() {
	vec2 uv = SCREEN_UV; // Use screen coordinates
	vec4 color = texture(screen_texture, uv);

	// Base brightness (luminance)
	float brightness = dot(color.rgb, vec3(0.299, 0.587, 0.114)); // Perceived brightness

	// Oscillation speed based on brightness
	float osc_speed = mix(1.0, dark_speed_ratio, invert_dark_faster ? (1.0 - brightness) : brightness);

	// Time-based oscillation (0 → 1 → 0)
	float t = sin(TIME * time_scale * osc_speed) * 0.5 + 0.5;

	// Opposite color
	vec3 inverted = vec3(1.0) - color.rgb;

	// Blend between original and inverted
	vec3 final_color = mix(color.rgb, inverted, t);

	COLOR = vec4(final_color, color.a);
}
