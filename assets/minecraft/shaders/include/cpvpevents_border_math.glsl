#ifndef CPVPEVENTS_BORDER_MATH_GLSL
#define CPVPEVENTS_BORDER_MATH_GLSL

const float CPVPEVENTS_BORDER_RECT_PACK = 4096.0;
const float CPVPEVENTS_BORDER_SHAPE_BIAS = 10.0;

int cpvpevents_border_shape(float encodedColor) {
    return encodedColor >= CPVPEVENTS_BORDER_SHAPE_BIAS ? 2 : 1;
}

int cpvpevents_border_palette(float encodedColor) {
    float normalized = encodedColor;
    if (normalized >= CPVPEVENTS_BORDER_SHAPE_BIAS) {
        normalized -= CPVPEVENTS_BORDER_SHAPE_BIAS;
    }
    return int(floor(((normalized - 1.0) / 0.1) + 0.5));
}

float cpvpevents_border_circle_height(float encodedZ) {
    return max(1.0, encodedZ);
}

float cpvpevents_border_rect_half_depth(float encodedZ) {
    return max(0.5, floor(encodedZ / CPVPEVENTS_BORDER_RECT_PACK));
}

float cpvpevents_border_rect_height(float encodedZ) {
    return max(1.0, mod(encodedZ, CPVPEVENTS_BORDER_RECT_PACK));
}

float cpvpevents_border_pattern(float wallU, float worldY, float gameTime) {
    float vertical = smoothstep(0.90, 1.0, sin(worldY * 0.55 + gameTime * 1.6) * 0.5 + 0.5);
    float grid = smoothstep(0.88, 1.0, sin(wallU * 0.30) * 0.5 + 0.5);
    float scan = smoothstep(0.965, 1.0, sin((worldY + gameTime * 18.0) * 4.0) * 0.5 + 0.5);
    return max(max(vertical * 0.30, grid * 0.42), scan * 0.22);
}

#endif
