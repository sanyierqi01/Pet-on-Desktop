#ifndef AURORACRAFT_COMMON
#define AURORACRAFT_COMMON

const float SHADOW_STRENGTH = 0.88;      // [0.0 0.25 0.5 0.72 0.88 1.0]
const float SHADOW_SOFTNESS = 1.15;      // [0.25 0.55 0.85 1.15 1.75 2.5]
const float WATER_WAVE_STRENGTH = 0.14;  // [0.0 0.03 0.075 0.12 0.14 0.18]
const float WATER_CLARITY = 0.82;        // [0.35 0.5 0.72 0.82 1.0]
const float CLOUD_DRAMA = 1.45;          // [0.5 0.75 1.1 1.35 1.45 1.7]
const float WEATHER_GLOW = 0.82;         // [0.0 0.25 0.55 0.82 1.1]

float saturate(float x) {
    return clamp(x, 0.0, 1.0);
}

vec3 saturate(vec3 x) {
    return clamp(x, vec3(0.0), vec3(1.0));
}

float luma(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float noise2(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float a = hash12(i);
    float b = hash12(i + vec2(1.0, 0.0));
    float c = hash12(i + vec2(0.0, 1.0));
    float d = hash12(i + vec2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

vec3 encodeNormal(vec3 n) {
    return normalize(n) * 0.5 + 0.5;
}

vec3 decodeNormal(vec3 n) {
    return normalize(n * 2.0 - 1.0);
}

vec3 tonemapAurora(vec3 c) {
    c = max(c, vec3(0.0));
    c = c * (1.0 + c * 0.045) / (1.0 + c);
    return pow(saturate(c), vec3(1.0 / 2.2));
}

vec3 auroraPalette(float t) {
    vec3 dawn = vec3(1.00, 0.52, 0.25);
    vec3 noon = vec3(0.52, 0.70, 1.00);
    vec3 dusk = vec3(0.72, 0.34, 0.82);
    return mix(mix(dawn, noon, smoothstep(0.10, 0.55, t)), dusk, smoothstep(0.55, 1.0, t));
}

#endif
