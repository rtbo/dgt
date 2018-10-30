/// Common definitions for the rendering backend
module dgt.render.defs;


// common uniforms

/// MVP transform
struct MVP
{
    import gfx.math.mat : FMat4;

    FMat4 model;
    FMat4 viewProj;
}


// vertex types

/// Vertex type with only 2D position
struct P2Vertex
{
    import gfx.math.vec : FVec2;

    FVec2 position;
}

/// Vertex type with 2D position and 2D tex coords
struct P2T2Vertex
{
    import gfx.math.vec : FVec2;

    FVec2 position;
    FVec2 texCoord;
}

/// Vertex type with 2D position and 4 components color
struct P2C4Vertex
{
    import gfx.math.vec : FVec2, FVec4;

    FVec2 position;
    FVec4 color;
}
