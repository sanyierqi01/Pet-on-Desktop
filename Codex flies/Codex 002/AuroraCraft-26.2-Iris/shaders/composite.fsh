#version 120

/* DRAWBUFFERS:0 */

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform vec3 sunPosition;

varying vec2 texcoord;

float acLuma(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

vec3 acTonemap(vec3 c) {
    c = max(c, vec3(0.0));
    c = c * (1.0 + c * 0.06) / (1.0 + c);
    return pow(clamp(c, vec3(0.0), vec3(1.0)), vec3(0.454545));
}

void main() {
    vec4 src = texture2D(colortex0, texcoord);
    float depthValue = texture2D(depthtex0, texcoord).r;
    vec2 screenPos = texcoord * 2.0 - 1.0;

    float dayAmount = clamp(sunPosition.y * 0.6 + 0.55, 0.0, 1.0);
    float horizon = clamp(1.0 - abs(screenPos.y) * 0.85, 0.0, 1.0);
    vec3 skyTop = mix(vec3(0.03, 0.04, 0.10), vec3(0.22, 0.48, 1.05), dayAmount);
    vec3 skyLow = mix(vec3(0.28, 0.08, 0.35), vec3(1.10, 0.58, 0.24), dayAmount);
    vec3 stylizedSky = mix(skyTop, skyLow, horizon);
    stylizedSky = mix(stylizedSky, vec3(0.20, 0.25, 0.34), rainStrength * 0.75);

    if (depthValue > 0.9999) {
        float sunDisc = pow(clamp(dot(normalize(screenPos + vec2(0.0, 0.2)), normalize(sunPosition.xy + vec2(0.0001))), 0.0, 1.0), 96.0);
        vec3 skyColor = stylizedSky + sunDisc * vec3(1.8, 1.1, 0.35) * (1.0 - rainStrength);
        gl_FragData[0] = vec4(skyColor, 1.0);
        return;
    }

    float pulse = sin(frameTimeCounter * 0.8) * 0.5 + 0.5;
    vec3 warmGrade = vec3(1.35, 1.06, 0.78);
    vec3 coolGrade = vec3(0.66, 1.02, 1.45);
    vec3 grade = mix(warmGrade, coolGrade, rainStrength);

    vec3 color = src.rgb * grade * 1.35;
    color += stylizedSky * 0.10;
    color = mix(color, color + vec3(0.02, 0.12, 0.22), pulse * 0.08);
    color = acTonemap(color);
    color = mix(vec3(acLuma(color)), color, 1.18);

    gl_FragData[0] = vec4(color, src.a);
}
