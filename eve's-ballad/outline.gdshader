shader_type canvas_item;

uniform float outline_width = 8.0;        // was 1.5, higher = thicker outline
uniform vec4 outline_color = vec4(1.0, 1.0, 0.8, 1.0);  // slightly warm white glow

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    float alpha = col.a;

    float outline = 0.0;
    outline += texture(TEXTURE, UV + vec2(outline_width * TEXTURE_PIXEL_SIZE.x, 0.0)).a;
    outline += texture(TEXTURE, UV - vec2(outline_width * TEXTURE_PIXEL_SIZE.x, 0.0)).a;
    outline += texture(TEXTURE, UV + vec2(0.0, outline_width * TEXTURE_PIXEL_SIZE.y)).a;
    outline += texture(TEXTURE, UV - vec2(0.0, outline_width * TEXTURE_PIXEL_SIZE.y)).a;
    outline = min(outline, 1.0);

    COLOR = mix(col, outline_color, outline * (1.0 - alpha));
}