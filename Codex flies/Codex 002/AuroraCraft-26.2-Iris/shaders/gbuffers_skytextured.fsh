#version 120

/* DRAWBUFFERS:0 */

uniform sampler2D texture;
uniform float rainStrength;

varying vec2 texcoord;
varying vec4 vertColor;

void main() {
    vec4 tex = texture2D(texture, texcoord) * vertColor;
    vec3 glow = vec3(1.35, 1.08, 0.72);
    tex.rgb = mix(tex.rgb * glow, tex.rgb * vec3(0.62, 0.70, 0.88), rainStrength);
    tex.rgb += tex.a * vec3(0.10, 0.08, 0.04) * (1.0 - rainStrength);
    gl_FragData[0] = tex;
}

