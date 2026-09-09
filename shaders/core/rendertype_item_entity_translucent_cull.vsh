#version 150

#moj_import <light.glsl>
#moj_import <fog.glsl>
#moj_import <types.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in vec2 UV1;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler0;
uniform sampler2D Sampler2;

#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:projection.glsl>

out float sphericalVertexDistance;
out float cylindricalVertexDistance;

out float vertexDistance;

out vec4 vertexColor;
out vec2 texCoord0;
out vec2 texCoord1;
out vec2 texCoord2;
out vec4 normal;

out vec4 ray_pos1, ray_pos2, ray_pos3, ray_pos4;
out vec4 abs_pos1, abs_pos2, abs_pos3, abs_pos4;
out vec3 ray_glPos;
out vec3 ray_uv1, ray_uv2;
out vec4 ray_lightMapColor;

out vec2 border_xy;
out vec3 border_topLeft;
out vec3 border_pos;
out vec4 border_position0;
out vec4 border_position2;
out vec4 border_position13;
out vec4 border_color;

flat out int type;
out vec4 test;

float getFOV(mat4 ProjMat) {
    return atan(1.0, ProjMat[1][1]) * 114.591559;
}

ivec4 nearest(vec4 a) {
    return ivec4(a * 255.0 + 0.5);
}

void border(int vertId) {
    border_pos = Position;

    const vec2[4] corners = vec2[4](vec2(0), vec2(0, 1), vec2(1, 1), vec2(1, 0));
    border_xy = corners[vertId];
    if (vertId == 0) {
        border_topLeft = vec3(texCoord0, 1);
        border_position0 = vec4(Position, 1);
    }
    if (vertId == 2) {
        border_position2 = vec4(Position, 1);
    }
    if (vertId == 1 || vertId == 3) {
        border_position13 = vec4(Position, 1);
    }
}

void main() {
    type = TYPE_VANILLA;
    border_xy = vec2(0);
    border_pos = border_topLeft = vec3(0);
    border_position13 = border_position2 = border_position0 = vec4(0);
    border_color = Color;
    abs_pos1 = abs_pos2 = abs_pos3 = abs_pos4 = normal = vertexColor = ray_lightMapColor = ray_pos1 = ray_pos2 = ray_pos3 = ray_pos4 = vec4(0);
    ray_glPos = ray_uv1 = ray_uv2 = vec3(0);
    texCoord0 = texCoord1 = texCoord2 = vec2(0);
    vertexDistance = 0;

    ivec4 t = nearest(texture(Sampler0, UV0));
    // circle border
    bool outer = t == ivec4(117, 195, 186, 241);
    if (outer || t == ivec4(117, 195, 186, 243)) {
        type = outer ? TYPE_BORDER : TYPE_BORDER_INNER;
        const vec2[4] corners = vec2[4](vec2(0), vec2(0, 1), vec2(1, 1), vec2(1, 0));
        vec2 corner = corners[(gl_VertexID+2) % 4].yx;

        vec2 texSize = textureSize(Sampler0, 0);
        vec2 uv = floor(UV0 * texSize);

        vec4 modelPos = ModelViewMat * vec4(Position, 1.0);
        modelPos.xy += ProjMat[3].xy / vec2(ProjMat[0][0], ProjMat[1][1]);

        vec2 cornerT = corner * 2 - 1;
        if (ProjMat[3][0] == -1)
            cornerT = cornerT.yx * 32;

        float fov = getFOV(ProjMat);

        switch (gl_VertexID % 4) {
            case 0:
                cornerT.x *= 3;
                break;
            case 2:
                cornerT.y *= 3;
                break;
            case 3:
                cornerT.xy *= 0;
                break;
        }

        // aspect ratio
        cornerT.x *= ProjMat[1][1] / ProjMat[0][0];
        vec4 glPos = vec4(0,0,0,1) + vec4(cornerT * tan(fov * 0.5 * 0.0174532925) * 1.08, 0, 0);

        modelPos.w = 1;

        switch (gl_VertexID % 4) {
            case 0:
                ray_pos1 = modelPos;
                abs_pos1 = ModelViewMat * vec4(1, 0, 1, 1);
                ray_uv1 = vec3(uv, 1);
                break;
            case 1:
                ray_pos2 = modelPos;
                abs_pos2 = ModelViewMat * vec4(1, 0, 0, 1);
                break;
            case 2:
                ray_pos3 = modelPos;
                abs_pos3 = ModelViewMat * vec4(0, 0, 0, 1);
                ray_uv2 = vec3(uv, 1);
                break;
            case 3:
                ray_pos4 = modelPos;
                abs_pos4 = ModelViewMat * vec4(0, 0, 1, 1);
                break;
        }

        glPos.z = min(glPos.z, -1);
        ray_glPos = glPos.xyz;
        mat4 proj = ProjMat;
        proj[3].xy = vec2(0, 0);
        gl_Position = proj * glPos;

        vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, Normal, vec4(1.0));
        ray_lightMapColor = texelFetch(Sampler2, UV2 / 16, 0);
        return;
    }

    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

    sphericalVertexDistance = fog_spherical_distance(Position);
    cylindricalVertexDistance = fog_cylindrical_distance(Position);
    vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, Normal, Color) * texelFetch(Sampler2, UV2 / 16, 0);
    texCoord0 = UV0;
    texCoord1 = UV1;
    texCoord2 = UV2;
    normal = ProjMat * ModelViewMat * vec4(Normal, 0.0);

    // square border
    ivec4 t1 = nearest(texture(Sampler0, UV0 
        - vec2(0.0001, 0) * int(gl_VertexID % 4 == 3) 
        - vec2(0.0001, 0.0001) * int(gl_VertexID % 4 == 2)
        - vec2(0, 0.0001) * int(gl_VertexID % 4 == 1)
        ));
    if (t1 == ivec4(230, 130, 234, 3)) {
        type = TYPE_SQUARE_BORDER;
        border(gl_VertexID % 4);
    }

    ivec4 t2 = nearest(texture(Sampler0, UV0 
        - vec2(0.0001, 0) * int(gl_VertexID % 4 == 1) 
        - vec2(0.0001, 0.0001) * int(gl_VertexID % 4 == 0)
        - vec2(0, 0.0001) * int(gl_VertexID % 4 == 3)
        ));
    if (t2 == ivec4(246, 130, 234, 3)) {
        type = TYPE_SQUARE_BORDER_INNER;
        border((gl_VertexID + 2) % 4);
    }
}


