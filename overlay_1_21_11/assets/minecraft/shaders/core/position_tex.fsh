#version 330

#moj_import <minecraft:dynamictransforms.glsl>

uniform sampler2D Sampler0;

in vec2 texCoord0;

out vec4 fragColor;

flat in int craveMapIcon;

void main() {
    vec4 color = texture(Sampler0, texCoord0);
    bool marker = color.r > 0.90 && color.b > 0.90 && color.g < 0.12;
    if (craveMapIcon != 0 && marker) color = vec4(0.025, 0.035, 0.05, 0.96);
    if (color.a == 0.0) {
        discard;
    }
    fragColor = color * ColorModulator;
}
