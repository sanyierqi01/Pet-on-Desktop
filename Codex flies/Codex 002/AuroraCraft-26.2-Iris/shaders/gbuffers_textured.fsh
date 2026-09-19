#version 120

/* DRAWBUFFERS:01 */

#include "/lib/common.glsl"

uniform sampler2D texture;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vertColor;
varying vec3 viewNormal;

void main() {
    vec4 base = texture2D(texture, texcoord) * vertColor;
    if (base.a < 0.1) discard;

    float torch = saturate(lmcoord.x);
    vec3 albedo = base.rgb * (0.92 + 0.18 * lmcoord.y);
    albedo += torch * torch * vec3(0.22, 0.12, 0.035);

    gl_FragData[0] = vec4(albedo, base.a);
    gl_FragData[1] = vec4(encodeNormal(normalize(viewNormal)), 0.0);
}
