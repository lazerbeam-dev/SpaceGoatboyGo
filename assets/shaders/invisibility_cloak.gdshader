shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float invisibility_blend : hint_range(0.0, 1.0) = 1.0; // 0 = fully visible, 1 = full cloak
uniform float refraction_strength : hint_range(0.0, 0.05) = 0.01; // Controls the strength of light refraction
uniform float refraction_speed : hint_range(0.0, 5.0) = 1.0; // Controls the speed of refraction noise
uniform float edge_fade_strength : hint_range(0.0, 10.0) = 2.0; // How strong the edge fade is

void fragment() {
	vec4 sprite_color = texture(TEXTURE, UV);
	
	// Calculate a subtle refraction offset based on time and UV for a "heat haze" or "light bending" effect
	vec2 refraction_offset = vec2(
		sin(UV.x * 20.0 + TIME * refraction_speed),
		cos(UV.y * 20.0 + TIME * refraction_speed)
	) * refraction_strength;

	// Sample the background with the subtle refraction
	vec2 screen_uv = SCREEN_UV + refraction_offset;
	vec4 background_color = texture(SCREEN_TEXTURE, screen_uv);

	// Blend the sprite's original color with the background based on invisibility_blend
	// If invisibility_blend is 1.0, it's fully the background (with refraction).
	// If invisibility_blend is 0.0, it's fully the sprite.
	vec4 final_color = mix(sprite_color, background_color, invisibility_blend);

	// Apply an edge fade to enhance the "cloaked" look
	// This makes the edges of the invisible object slightly more visible or distorted.
	float edge_uv_x = abs(UV.x - 0.5) * 2.0; // 0 at center, 1 at edges
	float edge_uv_y = abs(UV.y - 0.5) * 2.0; // 0 at center, 1 at edges
	float edge_factor = max(edge_uv_x, edge_uv_y); // Max of X or Y to get a general edge
	edge_factor = pow(edge_factor, edge_fade_strength); // Power to control falloff

	// Mix in some of the original sprite color or a slightly different effect at the edges
	// This creates a subtle outline or shimmer, breaking up the perfect invisibility
	final_color.rgb = mix(final_color.rgb, background_color.rgb, edge_factor * invisibility_blend);
	// Maintain the sprite's original alpha for any parts that should genuinely be transparent
	COLOR = final_color;
	COLOR.a = sprite_color.a; // Keep original sprite alpha for areas that are truly transparent in the texture
}