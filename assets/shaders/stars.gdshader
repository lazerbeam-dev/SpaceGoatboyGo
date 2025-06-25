shader_type canvas_item;

uniform float star_density = 0.002;
uniform float brightness = 1.2;
uniform float twinkle_speed = 0.5;
uniform float time_offset = 0.0;
uniform float star_sharpness = 0.05;
uniform float jitter_amount = 3.0; // can now be big

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

vec2 random_offset(vec2 cell) {
    float h1 = hash(cell + 0.1);
    float h2 = hash(cell + 0.9);
    return vec2(h1, h2) - 0.5;
}

void fragment() {
    vec2 uv = UV * 1000.0;
    vec2 grid_uv = uv * star_density;
    vec2 base_cell = floor(grid_uv);

    vec3 accum = vec3(0.0);

    // Check 3×3 surrounding cells
    for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
            vec2 cell = base_cell + vec2(float(dx), float(dy));
            float rnd = hash(cell);
            if (rnd < 0.98) continue;

            vec2 offset = random_offset(cell) * jitter_amount;
            vec2 star_pos = cell + offset;
            vec2 local_uv = grid_uv - star_pos;

            float d = length(local_uv);
            float glow = smoothstep(star_sharpness, 0.0, d);
            float twinkle = 0.5 + 0.5 * sin(TIME * twinkle_speed + rnd * 1000.0 + time_offset);
            accum += vec3(1.0) * glow * brightness * twinkle;
        }
    }

    COLOR = vec4(accum, 1.0);
}
