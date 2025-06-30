shader_type canvas_item;

uniform float angle_degrees : hint_range(0.0, 180.0) = 45.0;     // Total angle of the cone, pointing right
uniform float edge_softness : hint_range(0.0, 0.5) = 0.05;       // How soft the blend at the angular edges is
uniform vec4 blend_color : source_color = vec4(1.0, 0.0, 0.0, 1.0); // The color at the angular edges
uniform float color_blend_falloff : hint_range(0.1, 5.0) = 1.0; // Controls the "speed" of the color blend from white to blend_color

uniform float min_radius : hint_range(0.0, 1.0) = 0.0;          // Inner cutoff radius (do not render up to this point)
uniform float max_radius : hint_range(0.0, 1.0) = 0.0;          // Max radius at the center of the cone (starts at 0, animated by script)
uniform float radial_softness : hint_range(0.0, 0.2) = 0.02;    // Softness for the radial edges (made slightly smaller default)


void fragment() {
    vec2 delta = UV - vec2(0.5);
    float dist = length(delta); // Distance from the center

    float angle_rad = atan(delta.y, delta.x);

    if (angle_rad < 0.0) {
        angle_rad += 2.0 * PI;
    }

    float cone_half_angle_rad = radians(angle_degrees) * 0.5;
    float cone_center_angle = 0.0; // Right direction

    float angle_diff = abs(mod(angle_rad - cone_center_angle + PI, 2.0 * PI) - PI);

    // --- Angular Cone Mask ---
    float cone_angular_mask = smoothstep(cone_half_angle_rad + edge_softness, cone_half_angle_rad - edge_softness, angle_diff);

    // --- Dynamic Radius for Bulge Effect ---
    // This part creates the "bulge" by making the effective radius vary with angle.
    // It's max_radius at angle_diff = 0, and shrinks towards min_radius at cone edges.
    float radius_factor = 1.0 - smoothstep(0.0, cone_half_angle_rad, angle_diff);
    // Ensure that current_effective_radius never goes below min_radius or above max_radius set by the uniform.
    float current_effective_radius = mix(min_radius, max_radius, radius_factor);

    // --- Radial Mask ---
    // This handles the inner cut-off and the outer fade, creating the actual radial shape.
    float radial_fade = smoothstep(min_radius - radial_softness, min_radius + radial_softness, dist); // Fade in from min_radius
    radial_fade *= (1.0 - smoothstep(current_effective_radius - radial_softness, current_effective_radius + radial_softness, dist)); // Fade out at current_effective_radius

    // --- Combined Mask for Shape ---
    float final_alpha_mask = cone_angular_mask * radial_fade;

    // --- Color Blend ---
    // Controls the blend from white (center) to blend_color (edges).
    float color_blend_amount = smoothstep(0.0, cone_half_angle_rad * color_blend_falloff, angle_diff);
    vec4 final_color_mix = mix(vec4(1.0, 1.0, 1.0, 1.0), blend_color, color_blend_amount);

    // Final color: Apply mixed RGB and control overall alpha with the combined shape mask.
    COLOR = vec4(final_color_mix.rgb, final_color_mix.a * final_alpha_mask);
}