#version 120

/* DRAWBUFFERS:01 */

uniform sampler2D texture;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform vec3 sunPosition;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vertColor;
varying vec3 viewNormal;
varying vec3 viewPos;

void main() {
    vec2 flowA = texcoord * 12.0 + vec2(frameTimeCounter * 0.025, frameTimeCounter * 0.018);
    vec2 flowB = texcoord * 21.0 + vec2(-frameTimeCounter * 0.018, frameTimeCounter * 0.031);
    float wave = sin(flowA.x * 6.2831) * 0.5 + cos(flowB.y * 6.2831) * 0.35;

    vec3 n = normalize(viewNormal + vec3(dFdx(wave), dFdy(wave), 0.0) * 0.65);
    vec3 v = normalize(-viewPos);
    vec3 l = normalize(sunPosition);
    float fresnel = pow(1.0 - clamp(dot(n, v), 0.0, 1.0), 4.0);
    float sparkle = pow(clamp(dot(reflect(-l, n), v), 0.0, 1.0), 48.0) * (1.0 - rainStrength);

    vec3 shallow = vec3(0.08, 0.85, 1.00);
    vec3 deep = vec3(0.00, 0.10, 0.35);
    vec3 water = mix(deep, shallow, 0.74 + 0.12 * wave);
    water *= mix(vec3(0.75, 0.86, 0.96), vec3(0.55, 0.62, 0.68), rainStrength);
    water += fresnel * vec3(0.70, 0.95, 1.30);
    water += sparkle * vec3(1.35, 1.05, 0.62);
    water *= vertColor.rgb;

    float foam = smoothstep(0.68, 0.93, wave + fresnel * 0.8) * (0.35 + rainStrength * 0.45);
    water = mix(water, vec3(0.82, 0.95, 1.0), foam * 0.28);

    float alpha = mix(0.52, 0.82, clamp(0.18 + fresnel * 0.65, 0.0, 1.0));
    gl_FragData[0] = vec4(water, alpha);
    gl_FragData[1] = vec4(n * 0.5 + 0.5, 1.0);
}
