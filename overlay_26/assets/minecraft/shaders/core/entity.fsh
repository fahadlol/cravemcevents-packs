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
    float sweep = 0.72 + 0.28 * sin((uv.x + uv.y) * 150.0 - GameTime * 1800.0);
    return clamp(texture_alpha * sweep, 0.10, 0.72);
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
        color = vec4(faceVertexColor.rgb * ColorModulator.rgb * 1.35,
                crave_storm_alpha(texCoord0, color.a) * ColorModulator.a);
    } else {
        color *= faceVertexColor * ColorModulator;
    }
#ifndef NO_OVERLAY
    color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
#endif
#ifndef EMISSIVE
    color *= lightMapColor;
#endif

    fragColor = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
}
