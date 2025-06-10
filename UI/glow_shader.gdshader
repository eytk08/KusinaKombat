shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 0.85, 0.0, 1.0); // Gold tint
uniform bool selected = false;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    if (selected) {
        // Apply a gold tint to the texture
        tex_color.rgb = mix(tex_color.rgb, outline_color.rgb, 0.35);
    }
    COLOR = tex_color;
}
