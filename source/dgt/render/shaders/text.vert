#version 450

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

layout(location=0) in vec2 i_Position;
layout(location=1) in vec2 i_TexCoord;

layout(std140, binding=0) uniform MVP {
    mat4 model;
    mat4 viewProj;
} mvp;

layout(location=0) out vec2 vx_TexCoord;

void main() {
    vx_TexCoord = i_TexCoord;
    const vec4 worldPos = mvp.model * vec4(i_Position, 0, 1);
    gl_Position = mvp.viewProj * vec4(worldPos.xy, 0, 1);
}
