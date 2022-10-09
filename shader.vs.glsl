#version 330 core

layout(location = 0) in vec2 vPos;
layout(location = 1) in vec3 vColor;

out vec4 outColor;

void main() {
     gl_Position = vec4(vPos, 0.0, 1.0);
     outColor = vec4(vColor, 1.0);
}
