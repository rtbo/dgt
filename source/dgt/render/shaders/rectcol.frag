#version 450

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

const int MAX_STOPS = 8;

struct ColorStop
{
    vec4 color;
    vec4 position; // only x relevant
};

layout(std140, binding=1) uniform Locals {
    vec4 stroke;
    float width;
    int numStops;
    ColorStop stops[MAX_STOPS];
} locals;


layout(location=0) in vec3 vx_Position;
layout(location=1) in vec3 vx_Edge;

layout(location=0) out vec4 o_Color;

void main()
{
    const int numStops = locals.numStops;
    const float dist = length(vx_Position.xy - vx_Edge.xy) - vx_Edge.z;

    vec4 col;
    if (numStops == 0) {
        col = vec4(0, 0, 0, 0);
    }
    else {
        if (numStops == 1) {
            col = locals.stops[0].color;
        }
        else {
            const ColorStop firstStop = locals.stops[0];
            const ColorStop lastStop = locals.stops[numStops-1];

            // at least 2 stops : linear gradient
            if (vx_Position.z <= firstStop.position.x) {
                col = firstStop.color;
            }
            else if (vx_Position.z >= lastStop.position.x) {
                col = lastStop.color;
            }
            else {
                for(int i=1; i<numStops; ++i) {
                    const ColorStop thisStop = locals.stops[i];
                    const ColorStop prevStop = locals.stops[i-1];

                    if (vx_Position.z < thisStop.position.x) {
                        const float pos = (vx_Position.z - prevStop.position.x) /
                                (thisStop.position.x - prevStop.position.x);
                        col = mix(prevStop.color, thisStop.color, pos);
                        break;
                    }
                }
            }
        }
        const float fillOpacity = clamp(0.5 - dist, 0, 1);
        col *= fillOpacity;
    }

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
