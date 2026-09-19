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

    float sky = saturate(lmcoord.y);
    float torch = saturate(lmcoord.x);
    vec3 n = normalize(viewNormal);
    vec3 color = base.rgb * (0.78 + sky * 0.42);
    color += torch * torch * vec3(0.32, 0.18, 0.06);
    color += pow(1.0 - max(n.z, 0.0), 2.0) * vec3(0.04, 0.08, 0.12);

    gl_FragData[0] = vec4(color, base.a);
    gl_FragData[1] = vec4(encodeNormal(n), 0.0);
}

