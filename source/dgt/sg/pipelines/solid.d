module dgt.sg.pipelines.solid;

import dgt.math;
import dgt.sg.defs;

import gfx.device;
import gfx.foundation.rc;
import gfx.foundation.typecons;
import gfx.pipeline;

class SolidPipeline : Disposable
{
    private StateObject _pso;
    private ConstBuffer!MVP _mvpBlk;
    private ConstBuffer!Color _colBlk;
    private Encoder _encoder;


    alias Vertex = P2Vertex;
    alias Meta = SolidMeta;
    alias StateObject = PipelineState!SolidMeta;
    alias Data = StateObject.Data;

    this(CommandBuffer cmdBuf, Option!Blend blend)
    {
        auto prog = makeRc!Program(ShaderSet.vertexPixel(
            solidVShader, solidFShader
        ));

        _pso = new StateObject(
            prog.obj, Primitive.triangles,
            Rasterizer.fill.withSamples()
        );
        _pso.retain();
        _pso.outColor.info.blend = blend;

        _mvpBlk = new ConstBuffer!MVP(1);
        _mvpBlk.retain();
        _colBlk = new ConstBuffer!Color(1);
        _colBlk.retain();

        _encoder = Encoder(cmdBuf);
    }

    override void dispose()
    {
        _pso.release();
        _mvpBlk.release();
        _colBlk.release();
        _encoder = Encoder.init;
    }

    void updateUniforms(in FMat4 transform, in FVec4 color)
    {
        _encoder.updateConstBuffer(_mvpBlk, MVP(transform));
        _encoder.updateConstBuffer(_colBlk, Color(color));
    }

    void draw(VertexBuffer!Vertex vbuf, VertexBufferSlice slice, RenderTargetView!Rgba8 rtv)
    {
        _encoder.draw!SolidMeta(slice, _pso, Data(
            rc(vbuf), rc(_mvpBlk), rc(_colBlk), rc(rtv)
        ));
    }
}



private:

struct MVP {
    FMat4 mvp;
}

struct Color {
    FVec4 color;
}

struct SolidMeta {
    VertexInput!P2Vertex   input;

    @GfxName("MVP")
    ConstantBlock!MVP       mvp;

    @GfxName("Color")
    ConstantBlock!Color       matColor;

    @GfxName("o_Color")
    ColorOutput!Rgba8           outColor;
}

enum solidVShader = `
    #version 330
    in vec2 a_Pos;

    uniform MVP {
        mat4 u_mvpMat;
    };

    void main() {
        gl_Position = u_mvpMat * vec4(a_Pos, 0.0, 1.0);
    }
`;
enum solidFShader = `
    #version 330

    uniform Color {
        vec4 u_matColor;
    };

    out vec4 o_Color;

    void main() {
        o_Color = u_matColor;
    }
`;