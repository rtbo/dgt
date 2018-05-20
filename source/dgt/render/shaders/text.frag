#version 450

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

layout(location = 0) in vec2 vx_TexCoord;

layout(std140, binding = 1) uniform Locals {
    vec4 color;
} locals;

layout(binding = 2) uniform sampler2D maskSampler;

layout(location = 0) out vec4 o_Color;

void main() {
    const float mask = texture(maskSampler, vx_TexCoord).r;
    const float gamma = 1.8;
    o_Color = pow(mask, gamma) * locals.color;
    // o_Color = mask * locals.color;
}
