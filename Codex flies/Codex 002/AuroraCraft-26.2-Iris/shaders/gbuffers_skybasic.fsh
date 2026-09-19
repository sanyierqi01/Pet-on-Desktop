#version 120

/* DRAWBUFFERS:0 */

uniform vec3 sunPosition;
uniform float rainStrength;

varying vec4 vertColor;
varying vec3 viewDir;

void main() {
    float up = clamp(viewDir.y * 0.55 + 0.55, 0.0, 1.0);
    float day = clamp(sunPosition.y * 0.55 + 0.55, 0.0, 1.0);
    vec3 top = mix(vec3(0.015, 0.025, 0.060), vec3(0.20, 0.46, 0.92), day);
    vec3 horizon = mix(vec3(0.40, 0.08, 0.45), vec3(1.00, 0.48, 0.22), day);
    vec3 sky = mix(horizon, top, up);
    sky = mix(sky, vec3(0.20, 0.24, 0.30), rainStrength * 0.78);
    sky *= vertColor.rgb * 1.28;

    gl_FragData[0] = vec4(sky, vertColor.a);
}
