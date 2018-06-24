#version 450

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

layout(location=0) in vec3 i_Position;
layout(location=1) in vec3 i_Edge;

out gl_PerVertex {
    vec4 gl_Position;
};

layout(location=0) out vec3 vx_Position;
layout(location=1) out vec3 vx_Edge;

layout(std140, binding=0) uniform MVP {
    mat4 model;
    mat4 viewProj;
} mvp;

void main() {
    vx_Position = i_Position;
    vx_Edge = i_Edge;

    const vec4 worldPos = mvp.model * vec4(i_Position.xy, 0, 1);
    gl_Position = mvp.viewProj * vec4(round(worldPos.x), round(worldPos.y), 0, 1);
}
