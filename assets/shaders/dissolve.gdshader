shader_type canvas_item;

uniform sampler2D noise_texture;
uniform float dissolve_amount = 0.0;
uniform float edge_width = 0.1;
uniform vec4 edge_color : source_color = vec4(1.0, 0.6, 0.1, 1.0);

uniform float noise_scale = 1.0;
uniform vec2 noise_offset = vec2(0.0);

uniform vec4 blend_color : source_color = vec4(0.6, 0.6, 0.6, 1.0); // Less bright
uniform float blend_amount = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a < 0.01) {
		discard;
	}

	// Global blend tint
	tex.rgb = mix(tex.rgb, blend_color.rgb, blend_amount);

	// Sample and scale noise
	vec2 shifted_uv = UV * noise_scale + noise_offset;
	float noise = texture(noise_texture, shifted_uv).r;

	float edge_start = dissolve_amount - edge_width;

	// Fully dissolved (includes dissolve_amount >= 1.0 safety)
	if (noise < edge_start || dissolve_amount >= 1.0) {
		discard;
	}
	// Dissolve edge band
	else if (noise < dissolve_amount) {
		COLOR = vec4(edge_color.rgb, tex.a);
	}
	// Fully visible
	else {
		COLOR = tex;
	}
}
