#version 330

uniform sampler2D u_Sampler;

uniform Stroke {
    vec4 u_Stroke;
    float u_Width;
};

in vec2 vx_Pos;
in vec2 vx_Tex;
in vec3 vx_Edge;

out vec4 o_Color;

void main()
{
    float dist = length(vx_Pos.xy - vx_Edge.xy) - vx_Edge.z;

    float fillOpacity = clamp(0.5 - dist, 0, 1);
    vec4 col = texture(u_Sampler, vx_Tex) * fillOpacity;

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
