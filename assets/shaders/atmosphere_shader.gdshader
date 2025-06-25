shader_type canvas_item;

uniform vec2 sun_direction = vec2(0.0, -1.0); // from planet center to sun
uniform vec3 day_color : source_color = vec3(0.7, 0.85, 1.0);   // sky blue
uniform vec3 dusk_color : source_color = vec3(1.0, 0.4, 0.2);   // orange/red
uniform float atmosphere_radius = 0.5; // portion of screen covered by gradient

void fragment() {
    vec2 from_center = UV - vec2(0.5);
    float angle_to_sun = dot(normalize(from_center), sun_direction);
    float t = clamp((angle_to_sun + 1.0) * 0.5, 0.0, 1.0); // remap from -1..1 to 0..1

    vec3 sky_color = mix(dusk_color, day_color, pow(t, 1.5)); // nonlinear blend for stronger sunset

    float dist = length(from_center) / atmosphere_radius;
    float falloff = smoothstep(1.0, 0.7, dist);

    COLOR.rgb = sky_color * falloff;
    COLOR.a = falloff;
}
