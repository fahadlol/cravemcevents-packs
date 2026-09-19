#version 330

// Can't moj_import in things used during startup, when resource packs don't exist.
// This is a copy of dynamicimports.glsl
layout(std140) uniform DynamicTransforms {
    mat4 ModelViewMat;
    vec4 ColorModulator;
    vec3 ModelOffset;
    mat4 TextureMat;
};

uniform sampler2D Sampler0;

in vec2 texCoord0;
in vec4 vertexColor;

out vec4 fragColor;

flat in int craveMapIcon;

void main() {
    vec4 sampled = texture(Sampler0, texCoord0);
    bool marker = sampled.r > 0.90 && sampled.b > 0.90 && sampled.g < 0.12;
    if (craveMapIcon != 0 && marker) sampled = vec4(0.025, 0.035, 0.05, 0.96);
    vec4 color = sampled * vertexColor;
    if (color.a == 0.0) {
        discard;
    }
    fragColor = color * ColorModulator;
}
