shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float saturation : hint_range(0.0, 3.0) = 1.2;
uniform float contrast   : hint_range(0.0, 3.0) = 1.1;
uniform vec3 color_tint                 = vec3(1.0, 1.0, 1.0);

void fragment() {
    vec4 col = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0);

    float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
    col.rgb = mix(vec3(gray), col.rgb, saturation);

    col.rgb = ((col.rgb - 0.5) * contrast) + 0.5;
    col.rgb *= color_tint;

    COLOR = col;
}
