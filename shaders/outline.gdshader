shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(1.0);
uniform float line_thickness : hint_range(0.0, 10.0) = 4.0;
uniform bool outline_enabled = false;

void fragment() {
    vec2 size = TEXTURE_PIXEL_SIZE * line_thickness;
    
    float outline = texture(TEXTURE, UV + vec2(-size.x, 0)).a;
    outline += texture(TEXTURE, UV + vec2(0, size.y)).a;
    outline += texture(TEXTURE, UV + vec2(size.x, 0)).a;
    outline += texture(TEXTURE, UV + vec2(0, -size.y)).a;
    outline += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
    outline += texture(TEXTURE, UV + vec2(size.x, size.y)).a;
    outline += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
    outline += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
    outline = min(outline, 1.0);
    
    vec4 color = texture(TEXTURE, UV);
    
    if (outline_enabled && color.a == 0.0 && outline > 0.0) {
        COLOR = line_color;
    } else {
        COLOR = color;
    }
}
