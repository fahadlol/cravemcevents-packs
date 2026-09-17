#version 330
#extension GL_ARB_separate_shader_objects : require

#include <minecraft:fog.glsl>
#include <minecraft:dynamictransforms.glsl>
#include <minecraft:oit.glsl>

uniform sampler2D Sampler0;

layout(location = 0) in float sphericalVertexDistance;
layout(location = 1) in float cylindricalVertexDistance;
layout(location = 2) in vec2 texCoord0;
layout(location = 3) in vec4 vertexColor;

#ifndef OIT_ALPHA_ONLY
layout(location = 0) out vec4 fragColor;
#endif

vec4 calculateFinalColor(vec4 color) {
    #ifdef OIT_ACCUMULATE
    color = sampleColorForAccumulation(color);
    vec4 fogColor = vec4(FogColor.rgb * color.a, FogColor.a);
    #else
    vec4 fogColor = FogColor;
    #endif
    return apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, fogColor);
}


layout(location = 4) flat in int craveHudType;
layout(location = 5) in vec2 craveHudUv;
layout(location = 6) flat in vec3 craveHudData;

vec4 crave_hud_color() {
    if (craveHudType == 1) {
        vec4 terrain = texture(Sampler0, texCoord0);
        bool marker = terrain.r > 0.90 && terrain.b > 0.90 && terrain.g < 0.12;
        return marker ? vec4(0.025, 0.035, 0.05, 0.94) : vec4(terrain.rgb, 0.94);
    }
    if (craveHudType == 2) {
        float distanceFromCenter = length(craveHudUv - craveHudData.xy);
        float line = 1.0 - smoothstep(0.004, 0.012, abs(distanceFromCenter - craveHudData.z));
        float outside = smoothstep(craveHudData.z, craveHudData.z + 0.012, distanceFromCenter);
        return mix(vec4(0.40, 0.08, 0.52, 0.28), vec4(1.0, 0.08, 0.08, 0.96), line)
                * vec4(1.0, 1.0, 1.0, max(line, outside));
    }
    vec2 delta = craveHudUv - craveHudData.xy;
    if (craveHudType == 3) {
        float angle = craveHudData.z * 6.28318530718;
        mat2 rotation = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
        vec2 point = rotation * delta;
        float arrow = step(abs(point.x), 0.018 - point.y * 0.45)
                * step(-0.025, point.y) * step(point.y, 0.032);
        return vec4(1.0, 1.0, 1.0, arrow);
    }
    float dot = 1.0 - smoothstep(0.014, 0.022, length(delta));
    return vec4(0.12, 0.95, 1.0, dot);
}

void main() {
    if (craveHudType != 0) {
        vec4 hudColor = crave_hud_color();
        if (hudColor.a < 0.02) discard;
        #ifdef OIT_ALPHA_ONLY
        executeAlphaOnlyPhase(-1.0, hudColor.a);
        #else
        #ifdef OIT_ACCUMULATE
        hudColor = sampleColorForAccumulation(hudColor);
        #endif
        fragColor = hudColor;
        #endif
        return;
    }

    vec4 color = texture(Sampler0, texCoord0) * vertexColor * ColorModulator;
    if (color.a < 0.1) {
        discard;
    }
    #ifdef OIT_ALPHA_ONLY
    executeAlphaOnlyPhase(gl_FragCoord.z, color.a);
    #else
    fragColor = calculateFinalColor(color);
    #endif
}
