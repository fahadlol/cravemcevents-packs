#version 330
#extension GL_ARB_separate_shader_objects : require

#include <minecraft:globals.glsl>
#include <minecraft:fog.glsl>
#include <minecraft:dynamictransforms.glsl>
#include <minecraft:oit.glsl>

uniform sampler2D Sampler0;

#ifdef GLINT
uniform sampler2D GlintSampler;
#endif

#ifndef OIT_ALPHA_ONLY
layout(location = 0) in float sphericalVertexDistance;
layout(location = 1) in float cylindricalVertexDistance;
#endif
layout(location = 2) in vec4 vertexColor;
#ifndef OIT_ALPHA_ONLY
layout(location = 3) in vec4 lightMapColor;
layout(location = 4) in vec4 overlayColor;
#endif
layout(location = 5) in vec2 texCoord0;
#ifdef GLINT
layout(location = 6) in vec2 texCoordGlint;
#endif

#ifndef OIT_ALPHA_ONLY
layout(location = 0) out vec4 fragColor;
#endif

#ifndef OIT_ALPHA_ONLY
vec4 calculateFinalColor(vec4 color, bool craveStorm) {
    if (!craveStorm) color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
    if (!craveStorm) color *= lightMapColor;

    #ifdef GLINT
    vec4 glintColor = GlintAlpha * texture(GlintSampler, texCoordGlint);// Glint color modulator?
    // Matches BlendFuntion.GLINT
    color.rgb += glintColor.rgb * glintColor.rgb;
    #endif

    #ifdef OIT_ACCUMULATE
    color = sampleColorForAccumulation(color);
    vec4 fogColor = vec4(FogColor.rgb * color.a, FogColor.a);
    #else
    vec4 fogColor = FogColor;
    #endif

    return apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, fogColor);
}
#endif


bool crave_is_storm_texel(vec3 rgb) {
    return distance(rgb, vec3(251.0, 13.0, 249.0) / 255.0) < 0.08;
}

float crave_storm_alpha(vec2 uv, float texture_alpha) {
    // Stripe shape/animation comes from the shared texture, not atlas UVs.
    float pulse = 0.78 + 0.22 * sin(GameTime * 900.0);
    return texture_alpha * pulse * 0.72;
}

vec3 crave_storm_color(vec3 encoded) {
    vec3 best = vec3(36.0, 200.0, 237.0) / 255.0;
    float bestDistance = distance(encoded, best);
    vec3 candidate = vec3(255.0, 64.0, 64.0) / 255.0;
    float candidateDistance = distance(encoded, candidate);
    if (candidateDistance < bestDistance) { best = candidate; bestDistance = candidateDistance; }
    candidate = vec3(80.0, 232.0, 120.0) / 255.0;
    candidateDistance = distance(encoded, candidate);
    if (candidateDistance < bestDistance) { best = candidate; bestDistance = candidateDistance; }
    candidate = vec3(160.0, 96.0, 255.0) / 255.0;
    candidateDistance = distance(encoded, candidate);
    if (candidateDistance < bestDistance) { best = candidate; bestDistance = candidateDistance; }
    candidate = vec3(235.0, 85.0, 232.0) / 255.0;
    candidateDistance = distance(encoded, candidate);
    if (candidateDistance < bestDistance) { best = candidate; bestDistance = candidateDistance; }
    candidate = vec3(53.0, 230.0, 207.0) / 255.0;
    if (distance(encoded, candidate) < bestDistance) { best = candidate; }
    return best;
}

layout(location = 15) in vec4 craveStormTint;
void main() {
    vec4 color = texture(Sampler0, texCoord0);
    bool craveStorm = crave_is_storm_texel(color.rgb);
    #ifdef ALPHA_CUTOUT
    if (color.a < ALPHA_CUTOUT) {
        discard;
    }
    #endif

    vec4 faceVertexColor = vertexColor;
    if (craveStorm) {
        color = vec4(crave_storm_color(craveStormTint.rgb) * ColorModulator.rgb,
                crave_storm_alpha(texCoord0, color.a) * ColorModulator.a);
    } else {
        color *= faceVertexColor * ColorModulator;
    }
    if (craveStorm && color.a < 0.025) {
        discard;
    }

    #ifdef GLINT
    color.a = max(color.a, GlintAlpha);
    #endif

    #ifdef OIT_ALPHA_ONLY
    executeAlphaOnlyPhase(gl_FragCoord.z, color.a);
    #else
    fragColor = calculateFinalColor(color, craveStorm);
    #endif
}
