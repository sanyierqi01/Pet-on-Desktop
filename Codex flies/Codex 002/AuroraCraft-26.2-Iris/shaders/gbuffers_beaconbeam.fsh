#version 120

/* DRAWBUFFERS:01 */

#include "/lib/common.glsl"

uniform sampler2D texture;

varying vec2 texcoord;
varying vec4 vertColor;

void main() {
    vec4 base = texture2D(texture, texcoord) * vertColor;
    if (base.a < 0.02) discard;

    vec3 color = base.rgb * vec3(1.45, 1.35, 1.75) + base.a * vec3(0.25, 0.20, 0.45);
    gl_FragData[0] = vec4(color, base.a);
    gl_FragData[1] = vec4(encodeNormal(vec3(0.0, 0.0, 1.0)), 0.0);
}

