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
    vec3 color = base.rgb * vec3(1.12, 1.04, 0.92);
    color += pow(saturate(lmcoord.x), 2.0) * vec3(0.28, 0.15, 0.05);
    color += pow(1.0 - saturate(n.z), 2.0) * vec3(0.08, 0.12, 0.18);

    gl_FragData[0] = vec4(color, base.a);
    gl_FragData[1] = vec4(encodeNormal(n), 0.0);
}

