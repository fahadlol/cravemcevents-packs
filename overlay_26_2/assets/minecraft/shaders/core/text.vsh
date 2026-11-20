#version 330
#moj_import <minecraft:globals.glsl>

#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:sample_lightmap.glsl>
#endif

#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:projection.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
in ivec2 UV2;
#endif

#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
uniform sampler2D Sampler2;
out float sphericalVertexDistance;
out float cylindricalVertexDistance;
#endif

out vec4 vertexColor;
out vec2 texCoord0;

uniform sampler2D Sampler0;
flat out int craveHud;
out vec2 craveHudUv;

// Only generated cravemc:font/hud/* textures contain these corner tags.
void crave_minimap_vertex() {
    craveHud = 0;
    craveHudUv = vec2(0.0);
    bool gui = abs(ProjMat[3][3] - 1.0) < 0.0001;
    int red = int(round(Color.r * 255.0));
    if (!gui || (red != 250 && red != 62)) return;
    ivec2 size = textureSize(Sampler0, 0);
    ivec2 pixel = clamp(ivec2(UV0 * vec2(size)), ivec2(0), size - 1);
    ivec4 tag = ivec4(round(texelFetch(Sampler0, pixel, 0) * 255.0));
    if (tag.r != 19 || tag.g != 37 || tag.a != 255 || tag.b < 71 || tag.b > 86) return;
    int code = tag.b - 71;
    int corner = code & 3;
    const vec2 corners[4] = vec2[](vec2(0.0), vec2(0.0, 1.0), vec2(1.0), vec2(1.0, 0.0));
    vec2 local = corners[corner];
    craveHud = red == 250 ? 1 : 2;
    craveHudUv = local;
    // Physical framebuffer pixels: unchanged by GUI Scale, same X/Y scale.
    float margin = 12.0;
    float scale = min(2.0, max(0.01, (min(ScreenSize.x, ScreenSize.y) - 2.0 * margin) / 114.0));
    vec2 origin = vec2(ScreenSize.x - margin - 114.0 * scale, margin);
    vec2 offset = floor(Color.gb * 255.0 + 0.5);
    float glyphSize = code < 4 ? 114.0 : (code < 8 ? 14.0 : (code < 12 ? 8.0 : 9.0));
    vec2 screenPixel = origin + (offset + local * glyphSize) * scale;
    gl_Position = vec4(screenPixel.x * 2.0 / ScreenSize.x - 1.0,
                       1.0 - screenPixel.y * 2.0 / ScreenSize.y, -0.995, 1.0);
    vertexColor = vec4(1.0);
}

out vec2 craveEffect;
void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
    sphericalVertexDistance = fog_spherical_distance(Position);
    cylindricalVertexDistance = fog_cylindrical_distance(Position);
    vertexColor = Color * sample_lightmap(Sampler2, UV2);
#else
    vertexColor = Color;
#endif
    texCoord0 = UV0;


    craveEffect = vec2(-1.0, 0.0);
    ivec3 rgb = ivec3(round(Color.rgb * 255.0));
    if (rgb.r == 253 && rgb.b == 0 && (rgb.g == 13 || rgb.g == 29 || rgb.g == 45 || rgb.g == 61)) {
        int kind = (rgb.g - 13) / 16;
        float index = float(gl_VertexID >> 2);
        float seconds = GameTime <= 1.0 ? GameTime * 1200.0 : GameTime / 20.0;
        vec3 pos = Position;
        if (kind == 1) pos.y += sin(index * 0.6 + seconds * 6.0) * 2.0;
        if (kind == 2) {
            float seed = index + floor(seconds * 32.0);
            pos.xy += vec2(fract(sin(seed * 12.9898) * 43758.5453) - 0.5,
                           fract(sin(seed * 78.233) * 43758.5453) - 0.5) * 1.5;
        }
        gl_Position = ProjMat * ModelViewMat * vec4(pos, 1.0);
        craveEffect = vec2(float(kind), index);
    }

    crave_minimap_vertex();
}
