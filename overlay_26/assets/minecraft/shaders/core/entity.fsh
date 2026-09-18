#version 330
#moj_import <minecraft:globals.glsl>

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:dynamictransforms.glsl>

uniform sampler2D Sampler0;

#ifdef DISSOLVE
uniform sampler2D DissolveMaskSampler;
#endif

in float sphericalVertexDistance;
in float cylindricalVertexDistance;
#ifdef PER_FACE_LIGHTING
in vec4 vertexPerFaceColorBack;
in vec4 vertexPerFaceColorFront;
#else
in vec4 vertexColor;
#endif

#ifndef EMISSIVE
in vec4 lightMapColor;
#endif

#ifndef NO_OVERLAY
in vec4 overlayColor;
#endif

in vec2 texCoord0;

out vec4 fragColor;


bool crave_is_storm_texel(vec3 rgb) {
    return distance(rgb, vec3(251.0, 13.0, 249.0) / 255.0) < 0.08;
}

float crave_storm_alpha(vec2 uv, float texture_alpha) {
    float phase = sin((uv.x + uv.y) * 150.0 - GameTime * 1800.0);
    float stripe = smoothstep(0.15, 0.70, phase);
    float pulse = 0.78 + 0.22 * sin(GameTime * 900.0);
    return texture_alpha * stripe * pulse * 0.72;
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

void main() {
    vec4 color = texture(Sampler0, texCoord0);
    bool craveStorm = crave_is_storm_texel(color.rgb);
#ifdef ALPHA_CUTOUT
    if (color.a < ALPHA_CUTOUT) {
        discard;
    }
#endif

#ifdef PER_FACE_LIGHTING
    vec4 faceVertexColor = gl_FrontFacing ? vertexPerFaceColorFront : vertexPerFaceColorBack;
#else
    vec4 faceVertexColor = vertexColor;
#endif

#ifdef DISSOLVE
    if (faceVertexColor.a < texture(DissolveMaskSampler, texCoord0).a) {
        discard;
    }
    // The dissolve effect entirely replaces translucency
    faceVertexColor.a = 1.0;
#endif

    if (craveStorm) {
        color = vec4(crave_storm_color(faceVertexColor.rgb) * ColorModulator.rgb,
                crave_storm_alpha(texCoord0, color.a) * ColorModulator.a);
    } else {
        color *= faceVertexColor * ColorModulator;
    }
    if (craveStorm && color.a < 0.025) {
        discard;
    }
#ifndef NO_OVERLAY
    color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
#endif
#ifndef EMISSIVE
    color *= lightMapColor;
#endif

    fragColor = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
}
