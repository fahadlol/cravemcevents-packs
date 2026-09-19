#version 330

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:dynamictransforms.glsl>

uniform sampler2D Sampler0;

in float sphericalVertexDistance;
in float cylindricalVertexDistance;
in vec2 texCoord0;
in vec4 vertexColor;

out vec4 fragColor;


flat in int craveHudType;
in vec2 craveHudUv;
flat in vec3 craveHudData;

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
        float outline = step(abs(point.x), 0.025 - point.y * 0.45)
                * step(-0.032, point.y) * step(point.y, 0.043);
        float arrow = step(abs(point.x), 0.017 - point.y * 0.36)
                * step(-0.024, point.y) * step(point.y, 0.034);
        return mix(vec4(0.015, 0.02, 0.03, outline), vec4(1.0, 1.0, 1.0, 1.0), arrow);
    }
    float dot = 1.0 - smoothstep(0.014, 0.022, length(delta));
    return vec4(0.12, 0.95, 1.0, dot);
}

void main() {
    if (craveHudType != 0) {
        vec4 hudColor = crave_hud_color();
        if (hudColor.a < 0.02) discard;
        fragColor = hudColor;
        return;
    }

    vec4 color = texture(Sampler0, texCoord0) * vertexColor * ColorModulator;
    if (color.a < 0.1) {
        discard;
    }
    fragColor = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
}
