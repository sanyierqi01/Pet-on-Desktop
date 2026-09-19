#version 120

varying vec2 texcoord;
varying vec4 vertColor;

void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vertColor = gl_Color;
}

