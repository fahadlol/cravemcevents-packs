#version 330
#extension GL_ARB_separate_shader_objects : require
#include <minecraft:globals.glsl>

#include <minecraft:fog.glsl>
#include <minecraft:dynamictransforms.glsl>
#include <minecraft:projection.glsl>
#include <minecraft:sample_lightmap.glsl>

layout(location = 0) in vec3 Position;
layout(location = 1) in vec2 UV0;
layout(location = 2) in vec4 Color;
layout(location = 3) in ivec2 UV2;

uniform sampler2D Sampler0;
uniform sampler2D Sampler2;

layout(location = 0) out float sphericalVertexDistance;
layout(location = 1) out float cylindricalVertexDistance;
layout(location = 2) out vec2 texCoord0;
layout(location = 3) out vec4 vertexColor;


layout(location = 4) flat out int craveHudType;
layout(location = 5) out vec2 craveHudUv;
layout(location = 6) flat out vec3 craveHudData;

vec2 crave_corner_uv() {
    int corner = gl_VertexID & 3;
    if (corner == 0) return vec2(0.0, 1.0);
    if (corner == 1) return vec2(1.0, 1.0);
    if (corner == 2) return vec2(1.0, 0.0);
    return vec2(0.0, 0.0);
}

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

    sphericalVertexDistance = fog_spherical_distance(Position);
    cylindricalVertexDistance = fog_cylindrical_distance(Position);
    texCoord0 = UV0;
    vertexColor = Color * sample_lightmap(Sampler2, UV2);

    craveHudType = 0;
    craveHudUv = vec2(0.0);
    craveHudData = vec3(0.0);

    vec4 atlasCorner = texture(Sampler0, UV0);
    bool terrainMarker = atlasCorner.r > 0.90 && atlasCorner.b > 0.90 && atlasCorner.g < 0.12;
    float typeRatio = Color.b / max(Color.g, 0.0001);
    bool freshControl = Color.a > 0.72 && Color.g < 0.18;
    if (terrainMarker) {
        craveHudType = 1;
    } else if (freshControl && typeRatio > 1.65 && typeRatio < 2.35) {
        craveHudType = 2;
    } else if (freshControl && typeRatio > 2.65 && typeRatio < 3.35) {
        craveHudType = 3;
    } else if (freshControl && typeRatio > 3.65 && typeRatio < 4.35) {
        craveHudType = 4;
    }

    if (craveHudType != 0) {
        vec2 local = crave_corner_uv();
        float hudSize = min(360.0, min(ScreenSize.x, ScreenSize.y) * 0.32);
        vec2 pixel = vec2(ScreenSize.x - 18.0 - hudSize + local.x * hudSize,
                18.0 + local.y * hudSize);
        vec2 ndc = vec2(pixel.x * 2.0 / ScreenSize.x - 1.0,
                1.0 - pixel.y * 2.0 / ScreenSize.y);
        gl_Position = vec4(ndc, -1.0, 1.0);
        sphericalVertexDistance = 0.0;
        cylindricalVertexDistance = 0.0;
        vertexColor = vec4(1.0);
        craveHudUv = local;
        craveHudData = vec3(clamp(vec2(Position.x, Position.z) / 8.0 + 0.5, 0.0, 1.0),
                clamp(Color.r / max(Color.g, 0.0001) * (32.0 / 255.0), 0.0, 1.0));
    }
}
