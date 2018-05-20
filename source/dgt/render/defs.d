/// Common definitions for the rendering backend
module dgt.render.defs;

version(none):

import dgt.math.mat : FMat4;
import gfx.pipeline.format : R8, Unorm;
import gfx.pipeline.pso.meta : GfxName;

import std.typecons : Tuple;

// pixel formats

/// 8bits alpha mask gfx format
alias Alpha8 = Tuple!(R8, Unorm);

// common uniforms

/// MVP transform
struct MVP
{
    FMat4 model;
    FMat4 viewProj;
}


// vertex types

/// Vertex type with only 2D position
struct P2Vertex {
    @GfxName("a_Pos")   float[2] pos;
}

/// Vertex type with 2D position and 2D tex coords
struct P2T2Vertex
{
    @GfxName("a_Pos")   float[2] pos;
    @GfxName("a_Tex")   float[2] tex;
}

/// Vertex type with 2D position and 4 components color
struct P2C4Vertex
{
    @GfxName("a_Pos")   float[2] pos;
    @GfxName("a_Col")   float[4] col;
}
