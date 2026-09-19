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

    vec3 n = normalize(viewNormal);
    float torch = saturate(lmcoord.x);
    float bevel = pow(1.0 - saturate(abs(n.z)), 2.0);
    vec3 color = base.rgb * (0.82 + lmcoord.y * 0.38);
    color += bevel * vec3(0.06, 0.09, 0.13);
    color += torch * torch * vec3(0.35, 0.20, 0.06);

    gl_FragData[0] = vec4(color, base.a);
    gl_FragData[1] = vec4(encodeNormal(n), 0.0);
}

