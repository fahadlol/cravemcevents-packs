#version 150

#moj_import <fog.glsl>
#moj_import <types.glsl>



uniform sampler2D Sampler0;
uniform float GameTime;

#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:projection.glsl>

in float sphericalVertexDistance;
in float cylindricalVertexDistance;

in vec4 vertexColor;
in vec2 texCoord0;
in vec2 texCoord1;
in vec4 normal;

in vec2 sCoord;
in vec3 worldPos;

in vec4 ray_pos1, ray_pos2, ray_pos3, ray_pos4;
in vec4 abs_pos1, abs_pos2, abs_pos3, abs_pos4;
in vec3 ray_uv1, ray_uv2;
in vec3 ray_glPos;
in vec4 ray_lightMapColor;

in vec2 border_xy;
in vec3 border_pos;
in vec3 border_topLeft;
in vec4 border_position2;
in vec4 border_position0;
in vec4 border_position13;
in vec4 border_color;

#define MAX_DEPTH 1000000

flat in int type;

out vec4 fragColor;

#moj_import <raymarch.glsl>

vec2 mapToRangeMod(vec2 t, vec2 from, vec2 to, vec2 mappedFrom, vec2 mappedTo) {
    vec2 range = to - from;

    vec2 normalized = fract((t - from) / range);

    return mix(mappedFrom, mappedTo, normalized);
}

void main() {
    gl_FragDepth = gl_FragCoord.z;

    if (type == TYPE_SQUARE_BORDER || type == TYPE_SQUARE_BORDER_INNER) {

        int primitive = ((gl_PrimitiveID) + int(type == TYPE_SQUARE_BORDER_INNER)) % 2;
        vec2 topLeft = border_topLeft.xy / border_topLeft.z;
        vec3 pos0 = border_position0.xyz / border_position0.w;
        vec3 pos2 = border_position2.xyz / border_position2.w;
        vec3 pos13 = border_position13.xyz / border_position13.w;

        float height = length((primitive == 0 ? pos0 : pos2)-pos13);
        float width = length((primitive == 1 ? pos0 : pos2)-pos13);

        ivec2 size = textureSize(Sampler0, 0);
        vec2 pixel = 1 / vec2(size);

        topLeft.y += pixel.y;
        vec2 coord = topLeft + fract(mapToRangeMod(border_xy, vec2(0), 1 / vec2(width, height), vec2(0), vec2(1)) + vec2(GameTime*128) * vec2(-1, 1)) * 15.965 / vec2(size);
        fragColor = texture(Sampler0, coord) * border_color;
        if (type == TYPE_SQUARE_BORDER_INNER) fragColor = fade_out(fragColor, length(border_pos), 16.0, 64.0);

        if (fragColor.a < 0.1) {
            discard;
        }
        return;
    } else if (type == TYPE_BORDER) {
        raymarch(false);
        return;
    } else if (type == TYPE_BORDER_INNER) {
        raymarch(true);
        return;
    }

    vec4 color = texture(Sampler0, texCoord0) * vertexColor * ColorModulator;
    if (color.a < 0.1) {
        discard;
    }

    fragColor = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
}

