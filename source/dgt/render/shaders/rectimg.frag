#version 450

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable


layout(std140, binding=1) uniform Locals {
    vec4 stroke;
    float width;
} locals;

layout(binding=2) uniform sampler2D imgSampler;

layout(location=0) in vec2 vx_Position;
layout(location=1) in vec2 vx_TexCoord;
layout(location=2) in vec3 vx_Edge;

layout(location=0) out vec4 o_Color;

void main()
{
    const float dist = length(vx_Position.xy - vx_Edge.xy) - vx_Edge.z;

    const float fillOpacity = clamp(0.5 - dist, 0, 1);
    // little endian texel swizzling
    vec4 col = texture(imgSampler, vx_TexCoord).bgra * fillOpacity;

    if (locals.width > 0.0) {
        const float strokeOpacity = clamp(0.5 - (abs(dist)-locals.width/2), 0, 1);
        col = locals.stroke * strokeOpacity + col * (1 - strokeOpacity);
    }

    if (col.a == 0) {
        discard; // important if not blending
    }
    else {
        o_Color = col;
    }
}
