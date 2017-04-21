module dgt.sg.render.pipelines.defs;

import gfx.pipeline.format : R8, Unorm;
import gfx.pipeline.pso.meta : GfxName;

import std.typecons : Tuple;

// pixel formats

/// 8bits alpha mask gfx format
alias Alpha8 = Tuple!(R8, Unorm);


// vertex types

/// Vertex type with only 2D position
struct P2Vertex {
    @GfxName("a_Pos")   float[2] pos;
}

/// Vertex type with 2D position and 2D tex coords
struct P2T2Vertex
{
    @GfxName("a_Pos")       float[2] pos;
    @GfxName("a_TexCoord")  float[2] texCoord;
}
