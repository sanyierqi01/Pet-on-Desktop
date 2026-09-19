#version 120

varying vec4 vertColor;
varying vec3 viewNormal;

void main() {
    gl_Position = ftransform();
    vertColor = gl_Color;
    viewNormal = normalize(gl_NormalMatrix * gl_Normal);
}

