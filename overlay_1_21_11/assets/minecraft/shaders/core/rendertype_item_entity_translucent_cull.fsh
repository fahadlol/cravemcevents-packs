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
    float sweep = 0.72 + 0.28 * sin((uv.x + uv.y) * 150.0 - GameTime * 1800.0);
    return clamp(texture_alpha * sweep, 0.10, 0.72);
}

void main() {
    vec4 sampled = texture(Sampler0, texCoord0);
    bool craveStorm = crave_is_storm_texel(sampled.rgb);
    vec4 color = craveStorm
            ? vec4(vertexColor.rgb * ColorModulator.rgb * 1.35,
                    crave_storm_alpha(texCoord0, sampled.a) * ColorModulator.a)
            : sampled * vertexColor * ColorModulator;
    if (color.a < 0.1) {
        discard;
    }
    fragColor = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
}
