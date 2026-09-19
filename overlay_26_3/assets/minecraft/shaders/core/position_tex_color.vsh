#version 330
#extension GL_ARB_separate_shader_objects : require
#include <minecraft:globals.glsl>

// Can't moj_import in things used during startup, when resource packs don't exist.
// This is a copy of dynamicimports.glsl and projection.glsl
layout(std140) uniform DynamicTransforms {
    mat4 ModelViewMat;
    mat4 TextureMat;
    vec4 ColorModulator;
    vec3 ModelOffset;
};
layout(std140) uniform Projection {
    mat4 ProjMat;
};

layout(location = 0) in vec3 Position;
layout(location = 1) in vec2 UV0;
layout(location = 2) in vec4 Color;


uniform sampler2D Sampler0;
layout(location = 0) out vec2 texCoord0;
layout(location = 2) flat out int craveMapIcon;

layout(location = 1) out vec4 vertexColor;


vec2 crave_gui_corner() {
    int corner = gl_VertexID & 3;
    if (corner == 0) return vec2(0.0, 0.0);
    if (corner == 1) return vec2(0.0, 1.0);
    if (corner == 2) return vec2(1.0, 1.0);
    return vec2(1.0, 0.0);
}

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

    texCoord0 = UV0;
    vertexColor = Color;

    craveMapIcon = 0;
    vec4 edgeMarker = textureLod(Sampler0, UV0, 0.0);
    bool isMinimap = edgeMarker.r > 0.90 && edgeMarker.b > 0.90 && edgeMarker.g < 0.12;
    if (isMinimap) {
        craveMapIcon = 1;
        vec2 local = crave_gui_corner();
        float mapSize = min(360.0, min(ScreenSize.x, ScreenSize.y) * 0.32);
        vec2 pixel = vec2(ScreenSize.x - 18.0 - mapSize + local.x * mapSize,
                18.0 + local.y * mapSize);
        vec2 ndc = vec2(pixel.x * 2.0 / ScreenSize.x - 1.0,
                1.0 - pixel.y * 2.0 / ScreenSize.y);
        gl_Position = vec4(ndc, -0.99, 1.0);
    }
}
