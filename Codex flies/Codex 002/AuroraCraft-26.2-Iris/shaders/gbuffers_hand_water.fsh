#version 120

/* DRAWBUFFERS:01 */

#include "/lib/common.glsl"

uniform sampler2D texture;
uniform float frameTimeCounter;

varying vec2 texcoord;
varying vec4 vertColor;
varying vec3 viewNormal;
varying vec3 viewPos;

void main() {
    vec4 base = texture2D(texture, texcoord) * vertColor;
    if (base.a < 0.05) discard;

    float wave = noise2(texcoord * 18.0 + frameTimeCounter * 0.04);
    vec3 n = normalize(viewNormal + vec3(wave - 0.5, 0.0, 0.0) * 0.18);
    vec3 v = normalize(-viewPos);
    float fresnel = pow(1.0 - saturate(dot(n, v)), 3.0);
    vec3 color = mix(vec3(0.03, 0.16, 0.26), vec3(0.12, 0.62, 0.78), WATER_CLARITY);
    color += fresnel * vec3(0.55, 0.75, 1.0);

    gl_FragData[0] = vec4(color * base.rgb, max(base.a, 0.45));
    gl_FragData[1] = vec4(encodeNormal(n), 10007.0 / 65535.0);
}

