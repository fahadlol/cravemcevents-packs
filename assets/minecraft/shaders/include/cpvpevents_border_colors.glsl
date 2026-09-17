#ifndef CPVPEVENTS_BORDER_COLORS_GLSL
#define CPVPEVENTS_BORDER_COLORS_GLSL

vec3 cpvpevents_border_color(int id) {
    if (id == 1) return vec3(0.10, 0.45, 1.00);
    if (id == 2) return vec3(1.00, 0.12, 0.28);
    if (id == 3) return vec3(0.25, 1.00, 0.55);
    if (id == 4) return vec3(0.62, 0.25, 1.00);
    if (id == 5) return vec3(1.00, 0.48, 0.12);
    if (id == 6) return vec3(1.00, 0.86, 0.22);
    if (id == 7) return vec3(0.92, 0.98, 1.00);
    if (id == 8) return vec3(0.00, 0.92, 1.00);
    return vec3(0.10, 0.45, 1.00);
}

#endif
