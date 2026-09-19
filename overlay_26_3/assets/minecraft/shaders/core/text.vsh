#version 330
#extension GL_ARB_separate_shader_objects : require
#include <minecraft:globals.glsl>

#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
#include <minecraft:fog.glsl>
#include <minecraft:sample_lightmap.glsl>
#endif

#include <minecraft:dynamictransforms.glsl>
#include <minecraft:projection.glsl>

layout(location = 0) in vec3 Position;
layout(location = 1) in vec4 Color;
layout(location = 2) in vec2 UV0;
uniform sampler2D Sampler0;
#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
layout(location = 3) in ivec2 UV2;
#endif

#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
uniform sampler2D Sampler2;
layout(location = 0) out float sphericalVertexDistance;
layout(location = 1) out float cylindricalVertexDistance;
#endif

layout(location = 2) out vec4 vertexColor;
layout(location = 3) out vec2 texCoord0;


layout(location = 4) flat out int craveMinimap;

vec2 crave_text_corner() {
    int corner = gl_VertexID & 3;
    if (corner == 0) return vec2(0.0, 0.0);
    if (corner == 1) return vec2(0.0, 1.0);
    if (corner == 2) return vec2(1.0, 1.0);
    return vec2(1.0, 0.0);
}

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
    sphericalVertexDistance = fog_spherical_distance(Position);
    cylindricalVertexDistance = fog_cylindrical_distance(Position);
    vertexColor = Color * sample_lightmap(Sampler2, UV2);
#else
    vertexColor = Color;
#endif
    texCoord0 = UV0;

    craveMinimap = 0;
    ivec3 craveTextColor = ivec3(Color.rgb * 255.0 + 0.5);
    bool craveIsMinimap = craveTextColor == ivec3(252, 4, 252);
    if (craveIsMinimap) {
        craveMinimap = 1;
        vec2 local = crave_text_corner();
        float mapSize = min(360.0, min(ScreenSize.x, ScreenSize.y) * 0.32);
        vec2 pixel = vec2(ScreenSize.x - 18.0 - mapSize + local.x * mapSize,
                18.0 + local.y * mapSize);
        vec2 ndc = vec2(pixel.x * 2.0 / ScreenSize.x - 1.0,
                1.0 - pixel.y * 2.0 / ScreenSize.y);
        gl_Position = vec4(ndc, -0.99, 1.0);
        vertexColor = vec4(1.0);
    }
}
