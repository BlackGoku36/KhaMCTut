#version 450

in vec4 pos;
in vec2 nor;

out vec3 normal;
out vec3 fragPos;

uniform mat4 MVP;
uniform mat4 M;

void main() {
    gl_Position = MVP * vec4(pos.xyz, 1.0);
    fragPos = vec3(M * vec4(pos.xyz, 1.0));
    normal = vec3(nor.xy, pos.w);
}
