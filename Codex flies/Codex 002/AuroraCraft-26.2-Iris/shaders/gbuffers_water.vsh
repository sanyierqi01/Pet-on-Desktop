#version 120

uniform float frameTimeCounter;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vertColor;
varying vec3 viewNormal;
varying vec3 viewPos;

void main() {
    vec4 local = gl_Vertex;
    float waveA = sin(local.x * 0.42 + frameTimeCounter * 1.15);
    float waveB = cos(local.z * 0.37 - frameTimeCounter * 0.92);
    local.y += (waveA + waveB) * 0.035;
    vec4 pos = gl_ModelViewMatrix * local;
    gl_Position = gl_ProjectionMatrix * pos;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vertColor = gl_Color;
    viewNormal = normalize(gl_NormalMatrix * gl_Normal);
    viewPos = pos.xyz;
}
