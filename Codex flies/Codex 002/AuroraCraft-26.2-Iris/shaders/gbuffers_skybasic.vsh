#version 120

varying vec4 vertColor;
varying vec3 viewDir;

void main() {
    vec4 pos = gl_ModelViewMatrix * gl_Vertex;
    gl_Position = gl_ProjectionMatrix * pos;
    vertColor = gl_Color;
    viewDir = normalize(pos.xyz);
}

