#version 120

/* DRAWBUFFERS:01 */

uniform sampler2D texture;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vertColor;
varying vec3 viewNormal;

void main() {
    vec4 base = texture2D(texture, texcoord) * vertColor;
    if (base.a < 0.1) discard;

    vec3 albedo = base.rgb;
    albedo = albedo * vec3(1.28, 1.05, 0.82) + pow(clamp(lmcoord.x, 0.0, 1.0), 2.0) * vec3(0.35, 0.16, 0.035);

    gl_FragData[0] = vec4(albedo, base.a);
    gl_FragData[1] = vec4(normalize(viewNormal) * 0.5 + 0.5, 0.0);
}
