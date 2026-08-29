// Height of the border in blocks
#define HEIGHT 350
// How many blocks the border fades off from the top
#define FADEOFF 32

const float STRIPE_SIZE = 0.5;
const float STRIPE_MODULO = 1.0; // Note stripe modulo must be a multiple of stripe size

const float FAR_STRIPE_SIZE = 4;
const float FAR_STRIPE_MODULO = FAR_STRIPE_SIZE;
const float FAR_STRIPE_DISTANCE = 50;
const float FAR_STRIPE_FADE_DISTANCE = 10;

//colors
const vec4 STANDSTILL = vec4(vec3(0.082,0.702,0.894), 0.11); // blue
const vec4 STANDSTILL_ACCENT = vec4(vec3(0.055,0.604,0.769), 1);

const vec4 SHRINKING = vec4(vec3(1.0,0.160,0.117), 0.11); // red
const vec4 SHRINKING_ACCENT = vec4(vec3(1.0,0.160,0.117), 1);

const vec4 GROWING = vec4(vec3(0.219,1.0,0.450), 0.11); // green
const vec4 GROWING_ACCENT = vec4(vec3(0.219,1.0,0.450), 1);

const vec4 MOVING = vec4(vec3(0.522,0.357,0.804), 0.1); // purple
const vec4 MOVING_ACCENT = vec4(vec3(0.408,0.259,0.663), 1);

const vec4 MOVING_SHRINKING = vec4(vec3(0.922,0.208,0.588), 0.11); // violet
const vec4 MOVING_SHRINKING_ACCENT = vec4(vec3(0.671,0.337,0.635), 1);

const vec4 MOVING_GROWING = vec4(vec3(0.208,0.922,0.635), 0.11); // teal
const vec4 MOVING_GROWING_ACCENT = vec4(vec3(0.188,0.682,0.482), 1);

const vec4[] BGS     = vec4[](STANDSTILL, SHRINKING, GROWING, MOVING, MOVING_SHRINKING, MOVING_GROWING);
const vec4[] ACCENTS = vec4[](STANDSTILL_ACCENT, SHRINKING_ACCENT, GROWING_ACCENT, MOVING_ACCENT, MOVING_SHRINKING_ACCENT, MOVING_GROWING_ACCENT);


const float FALLBACK_BORDER_DISTANCE = 200; // If we don't know the render distance, we use this value
