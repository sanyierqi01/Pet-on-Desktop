#version 120

void main() {
    gl_FragData[0] = vec4(vec3(gl_FragCoord.z), 1.0);
}

