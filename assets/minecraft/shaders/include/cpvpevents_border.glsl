#ifndef CPVPEVENTS_BORDER_GLSL
#define CPVPEVENTS_BORDER_GLSL

#moj_import <cpvpevents_border_colors.glsl>
#moj_import <cpvpevents_border_math.glsl>

bool cpvpevents_is_border_marker(vec4 sampledColor) {
    vec4 marker = vec4(231.0 / 255.0, 17.0 / 255.0, 197.0 / 255.0, 253.0 / 255.0);
    return distance(sampledColor, marker) < 0.015;
}

vec4 cpvpevents_border_preview(vec4 sampledColor, float encodedColor, float encodedZ, vec3 encodedScale, float gameTime) {
    if (!cpvpevents_is_border_marker(sampledColor)) {
        return sampledColor;
    }

    int palette = cpvpevents_border_palette(encodedColor);
    vec3 base = cpvpevents_border_color(palette);
    float shape = float(cpvpevents_border_shape(encodedColor));
    float height = shape < 1.5 ? cpvpevents_border_circle_height(encodedZ) : cpvpevents_border_rect_height(encodedZ);
    float u = encodedScale.x + encodedScale.z * 0.013;
    float pattern = cpvpevents_border_pattern(u, height, gameTime);
    float alpha = clamp(0.32 + pattern, 0.18, 0.72);
    return vec4(base + pattern * 0.22, alpha);
}

#endif
