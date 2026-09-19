#version 120

uniform sampler2D colortex0;
uniform float rainStrength;

varying vec2 texcoord;

float finalLuma(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

vec3 finalTonemap(vec3 c) {
    c = max(c, vec3(0.0));
    c = c * (1.0 + c * 0.055) / (1.0 + c);
    return pow(clamp(c, vec3(0.0), vec3(1.0)), vec3(0.454545));
}

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;
    vec2 p = texcoord * 2.0 - 1.0;
    float vignette = smoothstep(1.35, 0.22, dot(p, p));
    float letterbox = smoothstep(0.0, 0.08, texcoord.y) * smoothstep(0.0, 0.08, 1.0 - texcoord.y);
    vec3 gradeWarm = vec3(1.42, 1.02, 0.72);
    vec3 gradeCool = vec3(0.62, 1.05, 1.65);

    color = mix(color, color * vec3(0.88, 0.97, 1.10), rainStrength * 0.28);
    color *= mix(gradeWarm, gradeCool, rainStrength);
    color *= 1.55;
    color = finalTonemap(color);
    color = mix(vec3(finalLuma(color)), color, 1.24);
    color *= mix(0.88, 1.04, vignette);
    color *= mix(0.55, 1.08, letterbox);
    color = mix(color, vec3(0.05, 0.42, 0.80), 0.10);
    gl_FragColor = vec4(color, 1.0);
}
