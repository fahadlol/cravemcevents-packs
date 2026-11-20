#version 330
#moj_import <minecraft:globals.glsl>

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:dynamictransforms.glsl>

uniform sampler2D Sampler0;

in float sphericalVertexDistance;
in float cylindricalVertexDistance;
in vec4 vertexColor;
in vec2 texCoord0;

out vec4 fragColor;

flat in int craveHud;
in vec2 craveHudUv;

in vec2 craveEffect;
void main() {
    vec4 color = texture(Sampler0, texCoord0).rrrr * vertexColor * ColorModulator;
    

    if (craveEffect.x >= 0.0) {
        int kind = int(craveEffect.x);
        float seconds = GameTime <= 1.0 ? GameTime * 1200.0 : GameTime / 20.0;
        if (kind == 0) {
            float hue = fract(craveEffect.y * 0.03 + seconds * 0.09);
            vec3 p = abs(fract(vec3(hue) + vec3(1.0, 2.0/3.0, 1.0/3.0)) * 6.0 - 3.0);
            color.rgb = mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), 0.9);
        } else if (kind == 1) color.rgb = vec3(0.333, 0.804, 0.988);
        else if (kind == 2) color.rgb = vec3(1.0, 0.42, 0.42);
        else if (kind == 3) {
            color.rgb = vec3(1.0, 0.85, 0.24);
            color.a *= 0.3 + ((sin(seconds * 1.5 + craveEffect.y * 0.3) + 1.0) * 0.5) * 0.7;
        }
    }

    if (craveHud != 0) {
        // Suppress only the shadow of a tagged HUD glyph, never a text color globally.
        if (craveHud == 2) discard;
        ivec4 tag = ivec4(round(texture(Sampler0, texCoord0) * 255.0));
        if (tag.r == 19 && tag.g == 37 && tag.a == 255 && tag.b >= 71 && tag.b <= 86) discard;
        color = texture(Sampler0, texCoord0) * ColorModulator;
    }

    if (color.a < 0.1) {
        discard;
    }
    fragColor = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
}
