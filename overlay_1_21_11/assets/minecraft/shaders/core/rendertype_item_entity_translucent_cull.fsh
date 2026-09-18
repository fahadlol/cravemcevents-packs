#version 330
#moj_import <minecraft:globals.glsl>

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:dynamictransforms.glsl>

uniform sampler2D Sampler0;

in float sphericalVertexDistance;
in float cylindricalVertexDistance;
in vec4 vertexColor;
in vec2 texCoord0;
in vec2 texCoord1;

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
    vec4 sampled = texture(Sampler0, texCoord0);
    bool craveStorm = crave_is_storm_texel(sampled.rgb);
    vec4 color = craveStorm
            ? vec4(crave_storm_color(vertexColor.rgb) * ColorModulator.rgb,
                    crave_storm_alpha(texCoord0, sampled.a) * ColorModulator.a)
            : sampled * vertexColor * ColorModulator;
    if (color.a < 0.1) {
        discard;
    }
    fragColor = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
}
