#version 120

/* DRAWBUFFERS:01 */

#include "/lib/common.glsl"

uniform sampler2D texture;

varying vec2 texcoord;
varying vec4 vertColor;

void main() {
    vec4 base = texture2D(texture, texcoord) * vertColor;
    if (base.a < 0.05) discard;

    vec3 color = base.rgb * vec3(1.22, 1.12, 0.92);
    color += base.a * WEATHER_GLOW * vec3(0.10, 0.08, 0.05);

    gl_FragData[0] = vec4(color, base.a);
    gl_FragData[1] = vec4(encodeNormal(vec3(0.0, 0.0, 1.0)), 0.0);
}

