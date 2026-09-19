#version 120

uniform sampler2D colortex0;
uniform float frameTimeCounter;
uniform float rainStrength;

varying vec2 texcoord;

vec3 tonemap(vec3 c) {
    c = max(c, vec3(0.0));
    c = c / (1.0 + c);
    return pow(clamp(c, vec3(0.0), vec3(1.0)), vec3(0.454545));
}

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;
    vec2 p = texcoord * 2.0 - 1.0;
    float vignette = smoothstep(1.45, 0.15, dot(p, p));
    float pulse = sin(frameTimeCounter * 1.7) * 0.5 + 0.5;

    vec3 cold = vec3(0.38, 0.88, 1.65);
    vec3 warm = vec3(1.70, 0.82, 0.28);
    color *= mix(cold, warm, smoothstep(-0.25, 0.55, p.x + pulse * 0.25));
    color = tonemap(color * 2.2);
    color = mix(color, vec3(0.02, 0.22, 0.75), 0.18);
    color *= mix(0.35, 1.12, vignette);

    gl_FragColor = vec4(color, 1.0);
}

