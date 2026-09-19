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
        float ringDistance = abs(distanceFromCenter - craveHudData.z);
        float outerGlow = 1.0 - smoothstep(0.004, 0.020, ringDistance);
        float core = 1.0 - smoothstep(0.003, 0.008, ringDistance);
        float outside = smoothstep(craveHudData.z + 0.006, craveHudData.z + 0.022, distanceFromCenter);
        vec4 unsafeWash = vec4(0.36, 0.04, 0.52, outside * 0.16);
        vec4 glow = vec4(1.0, 0.10, 0.16, outerGlow * 0.72);
        vec4 ring = vec4(1.0, 0.86, 0.90, core);
        return mix(mix(unsafeWash, glow, outerGlow), ring, core);
    }
    if (craveHudType == 5) {
        vec2 delta = craveHudUv - craveHudData.xy;
        float distanceFromCenter = length(delta);
        float ring = 1.0 - smoothstep(0.004, 0.010,
                abs(distanceFromCenter - craveHudData.z));
        float dash = step(0.46, fract(atan(delta.y, delta.x) * 5.092958 + 8.0));
        return vec4(0.18, 0.92, 1.0, ring * dash * 0.92);
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
