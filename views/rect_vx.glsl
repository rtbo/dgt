#version 330
in vec2 a_Pos;
in vec3 a_Edge;

out vec2 vx_Pos;
out vec3 vx_Edge;

uniform MVP {
    mat4 u_modelMat;
    mat4 u_viewProjMat;
};

void main() {
    vx_Pos = a_Pos;
    vx_Edge = a_Edge;

    vec4 worldPos = u_modelMat * vec4(a_Pos, 0, 1);

    gl_Position = u_viewProjMat * vec4(round(worldPos.x), round(worldPos.y), 0, 1);
}
