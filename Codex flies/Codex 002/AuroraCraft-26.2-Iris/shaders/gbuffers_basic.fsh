#version 120

/* DRAWBUFFERS:01 */

#include "/lib/common.glsl"

varying vec4 vertColor;
varying vec3 viewNormal;

void main() {
    vec3 n = normalize(viewNormal);
    vec3 color = vertColor.rgb * vec3(1.08, 1.03, 0.94);
    color += pow(max(n.y, 0.0), 2.0) * vec3(0.08, 0.12, 0.18);

    gl_FragData[0] = vec4(color, vertColor.a);
    gl_FragData[1] = vec4(encodeNormal(n), 0.0);
}

