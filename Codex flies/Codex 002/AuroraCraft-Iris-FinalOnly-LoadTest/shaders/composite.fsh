#version 120

/* DRAWBUFFERS:0 */

uniform sampler2D colortex0;
uniform float frameTimeCounter;

varying vec2 texcoord;

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;
    vec2 p = texcoord * 2.0 - 1.0;
    float sweep = sin(frameTimeCounter * 1.3 + p.x * 2.0) * 0.5 + 0.5;
    color *= mix(vec3(0.42, 0.95, 1.55), vec3(1.55, 0.82, 0.38), sweep);
    gl_FragData[0] = vec4(color, 1.0);
}

