#version 330
#extension GL_ARB_separate_shader_objects : require
#ifdef GL_ARB_shader_draw_parameters
#extension GL_ARB_shader_draw_parameters : enable
#endif
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
layout(location = 5) out vec2 craveMapUv;

vec2 crave_text_corner() {
    int corner = gl_VertexID & 3;
    if (corner == 0) return vec2(0.0, 0.0);
    if (corner == 1) return vec2(0.0, 1.0);
    if (corner == 2) return vec2(1.0, 1.0);
    return vec2(1.0, 0.0);
}

int crave_rgb(ivec2 pixel) {
    ivec3 rgb = ivec3(round(texelFetch(Sampler0, pixel, 0).rgb * 255.0));
    return (rgb.r << 16) | (rgb.g << 8) | rgb.b;
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
    craveMapUv = vec2(-1.0);
    const vec2 mapCorners[4] = vec2[](vec2(0.0), vec2(0.0, 1.0), vec2(1.0), vec2(1.0, 0.0));
    int mapVertex = gl_VertexID;
    #ifdef GL_ARB_shader_draw_parameters
    mapVertex -= gl_BaseVertexARB;
    #endif
    mapVertex &= 3;
    vec2 mapCorner = mapCorners[(mapVertex + 1) & 3];
    ivec2 atlasSize = textureSize(Sampler0, 0);
    ivec2 atlasUv = ivec2(UV0 * vec2(atlasSize));
    ivec2 mapOrigin = atlasUv - ivec2(mapCorner * 128.0);
    bool craveIsMap = crave_rgb(mapOrigin) == 0xFF0000
            && crave_rgb(mapOrigin + ivec2(1, 0)) == 0x597D27
            && crave_rgb(mapOrigin + ivec2(2, 0)) == 0x3737DC;
    if (craveIsMap) {
        craveMinimap = 1;
        craveMapUv = mapCorner * 128.0;
        float mapSize = min(420.0, min(ScreenSize.x, ScreenSize.y) * 0.36);
        vec2 pixel = vec2(ScreenSize.x - 18.0 - mapSize + mapCorner.x * mapSize,
                18.0 + mapCorner.y * mapSize);
        vec2 ndc = vec2(pixel.x * 2.0 / ScreenSize.x - 1.0,
                1.0 - pixel.y * 2.0 / ScreenSize.y);
        gl_Position = vec4(ndc, -0.99, 1.0);
        vertexColor = vec4(1.0);
        #if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
        sphericalVertexDistance = 0.0;
        cylindricalVertexDistance = 0.0;
        #endif
    }
}
