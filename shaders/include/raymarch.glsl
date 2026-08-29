#moj_import <config.glsl>


#define V_APPROX 1000000

#define PI 3.14159265359

float border_data_x_float = 0.0;

bool intersectRayCylinder(vec3 ro, vec3 rd, vec3 center, float radius, float height, out vec3 first_hit, out vec3 second_hit, out bool second_miss) {
    second_miss = true;
    first_hit = second_hit = vec3(0.0);
    center.z -= height;

    const vec3 ca = vec3(0.0, 0.0, 1.0);
    
    vec3 oc = ro - center;
    
    vec3 rd_proj = rd - dot(rd, ca) * ca;
    vec3 oc_proj = oc - dot(oc, ca) * ca;
    
    float a = dot(rd_proj, rd_proj);
    float b = 2.0 * dot(rd_proj, oc_proj);
    float c = dot(oc_proj, oc_proj) - radius * radius;
    
    float discriminant = b * b - 4.0 * a * c;
    if (discriminant < 0.0) {
        return true;
    }
    
    float sqrt_discriminant = sqrt(discriminant);
    float t0 = (-b - sqrt_discriminant) / (2.0 * a);
    float t1 = (-b + sqrt_discriminant) / (2.0 * a);
    
    if (t0 > t1) {
        float temp = t0;
        t0 = t1;
        t1 = temp;
    }
    
    if (t0 < 0.0) {
        t0 = t1;  
        if (t0 < 0.0) {
            return true; 
        }
    }

    float z0 = ro.z + t0 * rd.z;
    float z1 = ro.z + t1 * rd.z;
    
    bool validT0 = z0 >= center.z && z0 <= center.z + height;
    bool validT1 = z1 >= center.z && z1 <= center.z + height;
    
    if (!validT0 && !validT1) {
        return true;
    }

    vec3 first_intersection = ro + t0 * rd;
    vec3 second_intersection = ro + t1 * rd;

    if (validT0 && validT1) {
        if (t0 != t1) {
            second_miss = false;
            second_hit = second_intersection;
        }
        first_hit = first_intersection;
    } else if (validT0) {
        first_hit = first_intersection;
    } else {
        first_hit = second_intersection;
    }
    return false;
}

vec4 fade_out(vec4 inColor, float vertexDistance, float fogStart, float fogEnd) {
    if (vertexDistance > fogEnd) {
            discard;
    }
    if (vertexDistance <= fogStart) {
        return inColor;
    }

    float fogValue = smoothstep(fogStart, fogEnd, vertexDistance);
    return vec4(inColor.rgb, mix(inColor.a, 0, fogValue));
}

vec4 fade_out_with_defaults(vec4 inColor, float vertexDistance) {
    float start = FogRenderDistanceStart;
    float end = FogRenderDistanceEnd;

    float vanilla_diff = end - start - 64.0;
    if (end > 1000 && !(-0.1 < vanilla_diff && vanilla_diff < 0.1)) {
        start = FALLBACK_BORDER_DISTANCE-10;
        end = FALLBACK_BORDER_DISTANCE;
    }
    return fade_out(inColor, vertexDistance, start, end);
}

struct RayData {
    vec3 pos;
    vec3 ro;
    float depth;

    float border_radius;
    bool inside;
};


#moj_import <skins/stripes.glsl>

vec4 ray(in vec3 ro, in vec3 rd, inout float depth, float radius, bool behind) {
    bool second_miss;
    vec3 pos;
    vec3 second_pos;
    if (!intersectRayCylinder(ro, rd, vec3(0.0, 0.0, 0.0), radius, HEIGHT, pos, second_pos, second_miss) && (!behind || !second_miss)) {
        depth = length((behind ? second_pos : pos) - ro);
    } else {
        return vec4(0);
    }

    return color_from_pos(RayData(behind ? second_pos : pos, ro, depth, radius, behind || length(ro.xy) < radius));
}

void writeDepth(vec3 Pos) {
        vec4 ProjPos = ProjMat * vec4(Pos, 1);
        gl_FragDepth = ProjPos.z / ProjPos.w * 0.5 + 0.5;
}

void raymarch(bool behind) {
    vec2 texSize = textureSize(Sampler0, 0);
    vec3 RPos1 = round(ray_pos1.xyz * V_APPROX / ray_pos1.w) / V_APPROX;
    vec3 RPos2 = round(ray_pos3.xyz * V_APPROX / ray_pos3.w) / V_APPROX;
    vec3 RPos3 = gl_PrimitiveID % 2 == 0 ? round(ray_pos2.xyz * V_APPROX / ray_pos2.w) / V_APPROX : round(ray_pos4.xyz * V_APPROX / ray_pos4.w) / V_APPROX;

    vec3 Pos1 = round(abs_pos1.xyz * V_APPROX / abs_pos1.w) / V_APPROX;
    vec3 Pos2 = round(abs_pos3.xyz * V_APPROX / abs_pos3.w) / V_APPROX;
    vec3 Pos3 = gl_PrimitiveID % 2 == 0 ? round(abs_pos2.xyz * V_APPROX / abs_pos2.w) / V_APPROX : round(abs_pos4.xyz * V_APPROX / abs_pos4.w) / V_APPROX;

    vec3 tangent = normalize(gl_PrimitiveID % 2 == 0 ? Pos3 - Pos1 : Pos2 - Pos3);
    vec3 bitangent = normalize(gl_PrimitiveID % 2 == 1 ? Pos1 - Pos3 : Pos3 - Pos2);
    vec3 normalT = normalize(cross(tangent, bitangent));

    mat3 TBN = mat3(tangent, bitangent, normalT);

    vec2 UV1 = round(ray_uv1.xy / ray_uv1.z);
    vec2 UV2 = round(ray_uv2.xy / ray_uv2.z);

    vec2 stp = min(UV1, UV2);
    vec2 res = abs(UV1 - UV2);

    vec3 rawCenter = (RPos1 + RPos2) / 2;
    vec3 center = rawCenter * TBN;
    vec3 dir = normalize(ray_glPos);
    vec3 dirTBN = normalize(ray_glPos * TBN);

    if (ProjMat[3][0] == -1) {
        center = vec3(-ray_glPos.xy + rawCenter.xy, rawCenter.z) * TBN;
        dir = vec3(0, 0, -1);
        dirTBN = normalize(dir * TBN);
    }

    float border_radius = length(RPos1 - RPos3); 
    border_data_x_float = length(RPos2 - RPos3) - 1.0;

    float min_depth = MAX_DEPTH;

    fragColor = ray(-center, dirTBN, min_depth, border_radius, behind);

    if (min_depth == MAX_DEPTH) {
        discard;
    }

    writeDepth(dir * min_depth);
}
