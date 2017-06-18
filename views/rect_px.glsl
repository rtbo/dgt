#version 330

const int MAX_STOPS = 8;

struct ColorStop
{
    vec4 color;
    vec4 position; // only x relevant
};

uniform FillStroke {
    vec4 u_Stroke;
    float u_Width;
    int u_numStops;
};

uniform ColorStops
{
    ColorStop u_Stops[MAX_STOPS];
};

in vec3 vx_Pos;
in vec3 vx_Edge;

out vec4 o_Color;

void main()
{
    float dist = length(vx_Pos.xy - vx_Edge.xy) - vx_Edge.z;

    vec4 col;
    if (u_numStops == 0) {
        col = vec4(0, 0, 0, 0);
    }
    else {
        float fillOpacity = clamp(0.5 - dist, 0, 1);
        if (u_numStops == 1) {
            col = u_Stops[0].color;
        }
        else {
            // at least 2 stops : linear gradient
            if (vx_Pos.z <= u_Stops[0].position.x) {
                col = u_Stops[0].color;
            }
            else if (vx_Pos.z >= u_Stops[u_numStops-1].position.x) {
                col = u_Stops[u_numStops-1].color;
            }
            else {
                for(int i=1; i<u_numStops; ++i) {
                    if (vx_Pos.z < u_Stops[i].position.x) {
                        float pos = (vx_Pos.z - u_Stops[i-1].position.x) /
                                    (u_Stops[i].position.x - u_Stops[i-1].position.x);
                        col = mix(u_Stops[i-1].color, u_Stops[i].color, pos);
                    }
                }
            }
        }
        col *= fillOpacity;
    }

    if (u_Width > 0.0) {
        float strokeOpacity = clamp(0.5 - (abs(dist)-u_Width/2), 0, 1);
        col = u_Stroke * strokeOpacity + col * (1 - strokeOpacity);
    }

    if (col.a == 0) {
        discard; // important if not blending
    }
    else {
        o_Color = col;
    }
}
