shader_type canvas_item;

uniform float radius = 0.45;
uniform float edge_softness = 0.02;
uniform float rainbow_scale = 3.0;
uniform float cone_angle_deg = 30.0;

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
    vec2 delta = UV - vec2(0.5);
    float dist = length(delta);
    float angle = atan(delta.y, delta.x); // angle from center in radians

    float cone_half_rad = radians(cone_angle_deg) * 0.5;

    // Cone mask: fade in at edges of angle
    float angle_mask = smoothstep(cone_half_rad + edge_softness, cone_half_rad - edge_softness, abs(angle));

    // Radial mask: fade at edge of distance
    float radial_mask = smoothstep(radius + edge_softness, radius - edge_softness, dist);

    float final_alpha = angle_mask * radial_mask;

    // --- Rainbow hue based on angle, symmetric about center ---
    float hue_sym = abs(angle / cone_half_rad); // 0 = center, 1 = edge
    float hue = fract(hue_sym * rainbow_scale);

    vec3 color = hsv2rgb(vec3(hue, 1.0, 1.0));

    COLOR = vec4(color, final_alpha);
}
