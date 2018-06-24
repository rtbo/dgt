#version 450

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

layout(location=0) in vec2 i_Position;
layout(location=1) in vec2 i_TexCoord;
layout(location=2) in vec3 i_Edge;

layout(location=0) out vec2 vx_Position;
layout(location=1) out vec2 vx_TexCoord;
layout(location=2) out vec3 vx_Edge;

layout(std140, binding=0) uniform MVP {
    mat4 model;
    mat4 viewProj;
} mvp;

void main() {
    vx_Position = i_Position;
    vx_TexCoord = i_TexCoord;
    vx_Edge = i_Edge;

    const vec4 worldPos = mvp.model * vec4(i_Position, 0, 1);
    gl_Position = mvp.viewProj * vec4(round(worldPos.x), round(worldPos.y), 0, 1);
}
