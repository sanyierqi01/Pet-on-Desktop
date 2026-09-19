#version 120

/* DRAWBUFFERS:01 */

#include "/lib/common.glsl"

uniform sampler2D texture;
uniform float frameTimeCounter;
uniform float rainStrength;

varying vec2 texcoord;
varying vec4 vertColor;

void main() {
    vec4 drop = texture2D(texture, texcoord) * vertColor;
    if (drop.a < 0.05) discard;

    float streak = smoothstep(0.15, 1.0, drop.a);
    vec3 rainTint = mix(vec3(0.50, 0.58, 0.68), vec3(0.66, 0.76, 0.90), WEATHER_GLOW);
    vec3 color = drop.rgb * rainTint + streak * WEATHER_GLOW * vec3(0.06, 0.08, 0.11);
    float alpha = drop.a * mix(0.65, 1.0, rainStrength);

    gl_FragData[0] = vec4(color, alpha);
    gl_FragData[1] = vec4(encodeNormal(vec3(0.0, 0.0, 1.0)), 0.0);
}
