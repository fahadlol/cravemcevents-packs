                #version 330

                #moj_import <minecraft:fog.glsl>
                #moj_import <minecraft:dynamictransforms.glsl>
                #moj_import <minecraft:projection.glsl>
                #moj_import <minecraft:sample_lightmap.glsl>
                #moj_import <minecraft:globals.glsl>

                in vec3 Position;
                in vec4 Color;
                in vec2 UV0;
                in ivec2 UV2;

                uniform sampler2D Sampler2;
                uniform sampler2D Sampler0;

                out float sphericalVertexDistance;
                out float cylindricalVertexDistance;
                out vec4 vertexColor;
                out vec2 texCoord0;
                out vec4 effectData;
                flat out int craveMinimap;
                out vec2 craveMapUv;
                const bool ORAXEN_ANIMATED_GLYPHS = false;
const bool ORAXEN_TEXT_EFFECTS = true;
const int ORAXEN_ANIM_CONFIG_COUNT = 0;
const ivec2 ORAXEN_ANIM_CONFIGS[1] = ivec2[](
    ivec2(0, 0)
);
const int ORAXEN_EFFECT_COUNT = 4;
const ivec3 ORAXEN_EFFECT_TRIGGERS[4] = ivec3[](
    ivec3(253, 13, 0), // rainbow (id=0)
    ivec3(253, 29, 0), // wave (id=1)
    ivec3(253, 45, 0), // shake (id=2)
    ivec3(253, 61, 0) // pulse (id=3)
);
const int ORAXEN_EFFECT_IDS[4] = int[](
    0,
    1,
    2,
    3
);

                

                vec2 crave_text_corner() {
                    int corner = gl_VertexID & 3;
                    if (corner == 0) return vec2(0.0, 0.0);
                    if (corner == 1) return vec2(0.0, 1.0);
                    if (corner == 2) return vec2(1.0, 1.0);
                    return vec2(1.0, 0.0);
                }

                int crave_rgb(ivec2 pixel) {
                    ivec3 rgb = ivec3(round(texelFetch(Sampler0, pixel, 0).rgb * 255.0));
                    return (rgb.r << 16) | (rgb.g << 8) | rgb.b;
                }

                    void main() {
                        vec3 pos = Position;
                        gl_Position = ProjMat * ModelViewMat * vec4(pos, 1.0);
                        sphericalVertexDistance = fog_spherical_distance(pos);
                        cylindricalVertexDistance = fog_cylindrical_distance(pos);
                        texCoord0 = UV0;
                        vertexColor = Color * sample_lightmap(Sampler2, UV2);
                        effectData = vec4(-1.0, 0.0, 0.0, 0.0); // -1 means no effect

                        int rInt = int(Color.r * 255.0 + 0.5);
                        int gRaw = int(Color.g * 255.0 + 0.5);
                        int bRaw = int(Color.b * 255.0 + 0.5);

                        // Check for animation color on the primary pass only.
                        //
                        // Shadow-pass colors are normal text colors divided by 4, so trying
                        // to detect animated shadow colors by RGB range causes many false
                        // positives (e.g. vanilla white text shadow 63,63,63). That makes
                        // regular text render without shadow. We intentionally only detect
                        // the primary animation marker here to keep vanilla shadows intact.
                        //
                        // A red value of 254 can occur in regular RGB gradients. To avoid
                        // treating those characters as animated glyphs, require the encoded
                        // FPS/loop and frame-count tuple to match an actually generated
                        // animated glyph, and require the frame index to be valid.
                        bool isPrimaryAnim = false;
                        if (ORAXEN_ANIMATED_GLYPHS && ORAXEN_ANIM_CONFIG_COUNT > 0 && rInt == 254) {
                            int candidateFrameIndex = bRaw & 0x0F;
                            int candidateTotalFrames = ((bRaw >> 4) & 0x0F) + 1;
                            if (candidateFrameIndex < candidateTotalFrames) {
                                for (int i = 0; i < ORAXEN_ANIM_CONFIG_COUNT; i++) {
                                    if (gRaw == ORAXEN_ANIM_CONFIGS[i].x && candidateTotalFrames == ORAXEN_ANIM_CONFIGS[i].y) {
                                        isPrimaryAnim = true;
                                        break;
                                    }
                                }
                            }
                        }

                        if (ORAXEN_ANIMATED_GLYPHS && isPrimaryAnim) {
                            int gInt = gRaw;
                            int bInt = bRaw;

                            bool loop = (gInt < 128);
                            float fps = max(1.0, float(gInt & 0x7F));
                            int frameIndex = bInt & 0x0F;
                            int totalFrames = ((bInt >> 4) & 0x0F) + 1;

                            float timeSeconds = (GameTime <= 1.0) ? (GameTime * 1200.0) : (GameTime / 20.0);
                            int rawFrame = int(floor(timeSeconds * fps));
                            int currentFrame = loop ? (rawFrame % totalFrames) : min(rawFrame, totalFrames - 1);

                            float visible = (frameIndex == currentFrame && isPrimaryAnim) ? 1.0 : 0.0;

                            vertexColor = vec4(1.0, 1.0, 1.0, visible) * sample_lightmap(Sampler2, UV2);
                        }

                        // Text effects: exact trigger color matching
                        if (ORAXEN_TEXT_EFFECTS && ORAXEN_EFFECT_COUNT > 0 && (!ORAXEN_ANIMATED_GLYPHS || !isPrimaryAnim)) {
                            // Check for exact trigger color match
                            ivec3 colorInt = ivec3(rInt, gRaw, bRaw);
                            int effectType = -1;
                            for (int i = 0; i < ORAXEN_EFFECT_COUNT; i++) {
                                if (colorInt == ORAXEN_EFFECT_TRIGGERS[i]) {
                                    effectType = ORAXEN_EFFECT_IDS[i];
                                    break;
                                }
                            }

                            if (effectType >= 0) {
                                float speed = 3.0; // Default speed (configured in shader snippets)
                                float param = 3.0; // Default param (configured in shader snippets)
                                float charIndex = float(gl_VertexID >> 2);

                                float timeSeconds = (GameTime <= 1.0) ? (GameTime * 1200.0) : (GameTime / 20.0);

                            // wave (id=1)
                            if (effectType == 1) {
                                float phase = charIndex * 0.6 + timeSeconds * 6.0;
                                pos.y += sin(phase) * 2.0;
                            }
                            // shake (id=2)
                            else if (effectType == 2) {
                                float seed = charIndex + floor(timeSeconds * 32.0);
                                pos.x += (fract(sin(seed * 12.9898) * 43758.5453) - 0.5) * 1.5;
                                pos.y += (fract(sin(seed * 78.233) * 43758.5453) - 0.5) * 1.5;
                            }


                                gl_Position = ProjMat * ModelViewMat * vec4(pos, 1.0);
                            sphericalVertexDistance = fog_spherical_distance(pos);
                            cylindricalVertexDistance = fog_cylindrical_distance(pos);

                                // Pass effect data to fragment shader
                                effectData = vec4(float(effectType), speed, charIndex, param);
                            }
                        }

    craveMinimap = 0;
    craveMapUv = vec2(-1.0);
    int craveHudR = int(Color.r * 255.0 + 0.5);
    int craveHudG = int(Color.g * 255.0 + 0.5);
    int craveHudB = int(Color.b * 255.0 + 0.5);
    int craveHudVertex = gl_VertexID;
#ifdef GL_ARB_shader_draw_parameters
    craveHudVertex -= gl_BaseVertexARB;
#endif
    craveHudVertex &= 3;
    const vec2 craveHudCorners[4] = vec2[](vec2(0.0), vec2(0.0, 1.0), vec2(1.0), vec2(1.0, 0.0));
    vec2 craveHudCorner = craveHudCorners[craveHudVertex];

    bool craveHudRowShadow = craveHudR == 62 && craveHudB == 62 && craveHudG >= 50 && craveHudG <= 59;
    bool craveHudArrowShadow = craveHudR == 61;
    if (craveHudRowShadow || craveHudArrowShadow) {
        vertexColor = vec4(0.0);
    }

    bool craveHudRow = craveHudR == 248 && craveHudB == 248 && craveHudG >= 200 && craveHudG <= 236;
    bool craveHudArrow = craveHudR == 244;
    if (craveHudRow || craveHudArrow) {
        float craveHudMapSize = min(360.0, min(ScreenSize.x, ScreenSize.y) * 0.25);
        vec2 craveHudOrigin = vec2(ScreenSize.x - 12.0 - craveHudMapSize, 12.0);
        vec2 craveHudPixel;
        if (craveHudRow) {
            float craveHudRowIndex = float((craveHudG - 200) / 4);
            craveHudPixel = craveHudOrigin + vec2(
                    craveHudCorner.x * craveHudMapSize,
                    (craveHudRowIndex + craveHudCorner.y) * craveHudMapSize / 10.0
            );
        } else {
            float craveHudArrowSize = clamp(craveHudMapSize * 0.08, 14.0, 28.0);
            vec2 craveHudMarker = vec2(float(craveHudG), float(craveHudB)) * 0.5 / 127.0;
            craveHudMarker = vec2(4.0) + craveHudMarker * (craveHudMapSize - 8.0);
            craveHudPixel = craveHudOrigin + craveHudMarker
                    + (craveHudCorner - vec2(0.5)) * craveHudArrowSize;
        }
        vec2 craveHudNdc = vec2(
                craveHudPixel.x * 2.0 / ScreenSize.x - 1.0,
                1.0 - craveHudPixel.y * 2.0 / ScreenSize.y
        );
        gl_Position = vec4(craveHudNdc, -0.995, 1.0);
        vertexColor = vec4(1.0);
        sphericalVertexDistance = 0.0;
        cylindricalVertexDistance = 0.0;
    }

    const vec2 mapCorners[4] = vec2[](vec2(0.0), vec2(0.0, 1.0), vec2(1.0), vec2(1.0, 0.0));
                        int mapVertex = gl_VertexID & 3;
                        vec2 mapCorner = mapCorners[(mapVertex + 1) & 3];
                        ivec2 atlasSize = textureSize(Sampler0, 0);
                        ivec2 atlasUv = ivec2(UV0 * vec2(atlasSize));
                        ivec2 mapOrigin = atlasUv - ivec2(mapCorner * 128.0);
                        bool craveIsMap = crave_rgb(mapOrigin) == 0xFF0000
                                && crave_rgb(mapOrigin + ivec2(1, 0)) == 0x597D27
                                && crave_rgb(mapOrigin + ivec2(2, 0)) == 0x3737DC;
                        if (craveIsMap) {
                            craveMinimap = 1;
                            craveMapUv = mapCorner * 128.0;
                            float mapSize = min(420.0, min(ScreenSize.x, ScreenSize.y) * 0.36);
                            vec2 pixel = vec2(ScreenSize.x - 18.0 - mapSize + mapCorner.x * mapSize,
                                    18.0 + mapCorner.y * mapSize);
                            vec2 ndc = vec2(pixel.x * 2.0 / ScreenSize.x - 1.0,
                                    1.0 - pixel.y * 2.0 / ScreenSize.y);
                            gl_Position = vec4(ndc, -0.99, 1.0);
                            vertexColor = vec4(1.0);
                            sphericalVertexDistance = 0.0;
                            cylindricalVertexDistance = 0.0;
                        }
                    }
