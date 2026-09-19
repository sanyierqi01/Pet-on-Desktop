#version 120

/* DRAWBUFFERS:01 */

uniform sampler2D texture;
uniform float rainStrength;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vertColor;
varying vec3 viewNormal;

void main() {
    vec4 base = texture2D(texture, texcoord) * vertColor;
    if (base.a < 0.1) discard;

    vec3 n = normalize(viewNormal);
    float sky = clamp(lmcoord.y, 0.0, 1.0);
    float torch = clamp(lmcoord.x, 0.0, 1.0);
    float topLight = clamp(n.y * 0.5 + 0.5, 0.0, 1.0);
    vec3 cinematic = mix(vec3(0.06, 0.34, 0.48), vec3(1.25, 0.82, 0.36), sky * topLight);
    vec3 albedo = base.rgb * cinematic * 1.65;
    albedo += torch * torch * vec3(0.55, 0.20, 0.04);
    albedo = mix(albedo, albedo * vec3(0.58, 0.72, 1.25), rainStrength);

    gl_FragData[0] = vec4(albedo, base.a);
    gl_FragData[1] = vec4(n * 0.5 + 0.5, 1.0);
}
