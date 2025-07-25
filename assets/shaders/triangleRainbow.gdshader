shader_type canvas_item;

uniform float radius = 0.45;
uniform float edge_softness = 0.02;
uniform float rainbow_scale = 3.0;
uniform float cone_angle_deg = 30.0;

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
    vec2 uv = UV - vec2(0.5); // center UVs
    float dist = length(uv);
    float angle = atan(uv.y, uv.x); // radians from center

    float cone_half = radians(cone_angle_deg) * 0.5;

    // fade alpha at cone edge
    float angle_mask = smoothstep(cone_half + edge_softness, cone_half - edge_softness, abs(angle));

    // fade alpha at radial edge
    float radial_mask = smoothstep(radius + edge_softness, radius - edge_softness, dist);

    float alpha = angle_mask * radial_mask;

    float hue = fract(abs(angle / cone_half) * rainbow_scale);
    vec3 rgb = hsv2rgb(vec3(hue, 1.0, 1.0));

    vec4 tex = texture(TEXTURE, UV);
	COLOR = vec4(rgb, alpha);
}
