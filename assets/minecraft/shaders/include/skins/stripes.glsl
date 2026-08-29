
float stripe(float rot, float z, float radius, float stripe_size) {
    return sin(((rot * PI * 2 * 5*radius + z * 5) + GameTime* 400 * PI)/stripe_size);
}

float getWholeStripes(float rot, float z, float radius, float stripe_size, float modulo) {
    float stripe_bot = stripe(rot, z, radius - mod(radius, modulo), stripe_size);
    float stripe_top = stripe(rot, z, radius - mod(radius, modulo)+modulo, stripe_size);
    return mix(clamp(stripe_bot, 0, 1), clamp(stripe_top, 0, 1), mod(radius, modulo)/modulo);
}

vec4 color_from_pos(RayData ray) {
    float depth = ray.depth; 
    int border_color = int(border_data_x_float + 0.01);
    
    vec3 pos = floor(ray.pos * 16.0) / 16.0;

    float rot = atan(pos.x, pos.y) + PI;
    rot /= PI * 2;

    vec4 bg = BGS[border_color];
    vec4 accent = ACCENTS[border_color];

    float stripe = getWholeStripes(rot, pos.z, ray.border_radius, STRIPE_SIZE, STRIPE_MODULO);

    vec4 color = mix(bg, accent, clamp(stripe, 0, 1));
    if (depth >= FAR_STRIPE_DISTANCE) {
        float far_stripe = getWholeStripes(rot, pos.z, ray.border_radius, FAR_STRIPE_SIZE, FAR_STRIPE_MODULO);
        vec4 far_color = mix(bg, accent, clamp(far_stripe, 0, 1));
        color = mix(color, far_color, clamp((depth - FAR_STRIPE_DISTANCE) / FAR_STRIPE_FADE_DISTANCE, 0, 1));
    }

    if (ray.inside) {
        color = fade_out_with_defaults(color, ray.depth);
    }
    float fade_t = (ray.pos.z + HEIGHT - FADEOFF) / FADEOFF + 1;
    color.a *= clamp(fade_t, 0, 1);
    return color;
}
