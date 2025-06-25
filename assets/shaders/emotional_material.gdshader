shader_type canvas_item;

uniform vec4 blend_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float blend_amount = 0.0;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    if (tex.a < 0.01) {
        discard;
    }

    tex.rgb = mix(tex.rgb, blend_color.rgb, blend_amount);
    COLOR = tex;
}
