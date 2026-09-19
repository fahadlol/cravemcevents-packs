                #version 330

                #moj_import <minecraft:fog.glsl>
                #moj_import <minecraft:dynamictransforms.glsl>
                #moj_import <minecraft:globals.glsl>

                uniform sampler2D Sampler0;

                in float sphericalVertexDistance;
                in float cylindricalVertexDistance;
                in vec4 vertexColor;
                in vec2 texCoord0;
                in vec4 effectData;

                out vec4 fragColor;

flat in int craveMinimap;
in vec2 craveMapUv;

                // HSV to RGB conversion for rainbow effect
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

                vec4 oraxen_sample_text() {
                    vec4 texel = texture(Sampler0, texCoord0);
                #ifdef IS_GRAYSCALE
                    return texel.rrrr;
                #else
                    return texel;
                #endif
                }

                void main() {
                    vec4 color = oraxen_sample_text() * vertexColor * ColorModulator;
                    vec4 texColor = color;

                    // Apply text effects if effectData.x >= 0 (effectType, 0 is rainbow)
                    if (effectData.x >= 0.0 && effectData.y > 0.5) {
                        int effectType = int(effectData.x + 0.5);
                        float speed = effectData.y;
                        float charIndex = effectData.z;
                        float param = effectData.w;
                        float timeSeconds = (GameTime <= 1.0) ? (GameTime * 1200.0) : (GameTime / 20.0);

                            // rainbow (id=0)
                            if (effectType == 0) {
                                float hue = fract(charIndex * 0.03 + timeSeconds * 0.09);
                                texColor.rgb = hsv2rgb(vec3(hue, 0.9, 1.0));
                            }
                            // wave (id=1)
                            else if (effectType == 1) {
                                texColor.rgb = vec3(0.333, 0.804, 0.988);
                            }
                            // shake (id=2)
                            else if (effectType == 2) {
                                texColor.rgb = vec3(1.0, 0.42, 0.42);
                            }
                            // pulse (id=3)
                            else if (effectType == 3) {
                                texColor.rgb = vec3(1.0, 0.85, 0.24);
                                float pulse = (sin(timeSeconds * 1.5 + charIndex * 0.3) + 1.0) * 0.5;
                                texColor.a *= 0.3 + pulse * 0.7;
                            }

                    }

                    color = texColor;

                    
    if (craveMinimap != 0) {
        if (craveMapUv.x < 1.0 || craveMapUv.y < 1.0) {
            discard;
        }
        vec4 mapColor = texture(Sampler0, texCoord0);
        color = vec4(mapColor.rgb, 0.98);
    }

    if (color.a < 0.1) {
                        discard;
                    }
                #if defined(IS_SEE_THROUGH) || defined(IS_GUI)
                    fragColor = color;
                #else
                    fragColor = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
                #endif
                }
