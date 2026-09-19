#version 120

/* DRAWBUFFERS:01 */

#include "/lib/common.glsl"

uniform float frameTimeCounter;
uniform float rainStrength;
uniform vec3 sunPosition;

varying vec2 texcoord;
varying vec4 vertColor;
varying vec3 viewPos;

void main() {
    vec2 p = texcoord * 4.0 + vec2(frameTimeCounter * 0.004, 0.0);
    float billow = noise2(p) * 0.55 + noise2(p * 2.1 + 7.0) * 0.30 + noise2(p * 4.2 + 19.0) * 0.15;
    float shape = smoothstep(0.34, 0.84, billow * CLOUD_DRAMA);
    float rim = pow(saturate(dot(normalize(viewPos), normalize(sunPosition)) * 0.5 + 0.5), 3.0);
    vec3 storm = vec3(0.38, 0.42, 0.48);
    vec3 fair = vec3(1.0, 0.96, 0.88) + rim * vec3(0.35, 0.26, 0.12);
    vec3 color = mix(fair, storm, rainStrength * 0.82) * vertColor.rgb;
    float alpha = vertColor.a * mix(0.55, 0.92, shape);

    gl_FragData[0] = vec4(color, alpha);
    gl_FragData[1] = vec4(encodeNormal(vec3(0.0, 1.0, 0.0)), 0.0);
}
