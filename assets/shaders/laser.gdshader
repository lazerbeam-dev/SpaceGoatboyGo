shader_type canvas_item;

uniform float radius = 0.45;
uniform float edge_softness = 0.02;
uniform float rainbow_scale = 3.0;

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
    float dist = distance(UV, vec2(0.5));
    float circle = smoothstep(radius + edge_softness, radius - edge_softness, dist);

    float hue = fract(dist * rainbow_scale);
    vec3 color = hsv2rgb(vec3(hue, 1.0, 1.0));

    COLOR = vec4(color, circle);
}
