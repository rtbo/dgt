
module dgt.render.pipelines.text;

import dgt.render.pipelines.defs;
import dgt.math;

import gfx.pipeline;
import gfx.device;
import gfx.foundation.rc;
import gfx.foundation.typecons;

class TextPipeline : Disposable
{
    private StateObject _pso;
    private ConstBuffer!MVP _mvpBlk;
    private ConstBuffer!Color _colBlk;
    private Encoder _encoder;

    alias Vertex = P2T2Vertex;
    alias Meta = TextMeta;
    alias StateObject = PipelineState!TextMeta;
    alias Data = StateObject.Data;

    this(CommandBuffer cmdBuf)
    {
        auto prog = makeRc!Program(ShaderSet.vertexPixel(
            textVShader, textFShader
        ));

        _pso = new StateObject(
            prog.obj, Primitive.Triangles,
            Rasterizer.fill.withSamples()
        );
        _pso.retain();

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

    void updateMVP(in FMat4 transform)
    {
        _encoder.updateConstBuffer(_mvpBlk, MVP(transform));
    }

    void updateColor(in FVec4 color)
    {
        _encoder.updateConstBuffer(_colBlk, Color(color));
    }

    void draw(VertexBuffer!Vertex vbuf,
                VertexBufferSlice slice,
                ShaderResourceView!Alpha8 srv,
                Sampler sampler,
                RenderTargetView!Rgba8 rtv)
    {
        _encoder.draw!TextMeta(slice, _pso, Data(
            rc(vbuf), rc(_mvpBlk), rc(_colBlk), rc(srv), rc(sampler), rc(rtv)
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

struct TextMeta
{
    VertexInput!P2T2Vertex   input;

    @GfxName("MVP")
    ConstantBlock!MVP       mvp;

    @GfxName("Color")
    ConstantBlock!Color       color;

    @GfxName("t_Sampler")
    ResourceView!Alpha8          texture;

    @GfxName("t_Sampler")
    ResourceSampler             sampler;

    @GfxName("o_Color")
    @GfxBlend(Blend(
        Equation.Add,
        Factor.makeOne(),
        Factor.makeOneMinus(BlendValue.SourceAlpha)
    ))
    BlendOutput!Rgba8           outColor;
}

enum textVShader = `
    #version 330
    in vec2 a_Pos;
    in vec2 a_TexCoord;

    uniform MVP {
        mat4 u_mvpMat;
    };

    out vec2 v_TexCoord;

    void main() {
        v_TexCoord = a_TexCoord;
        gl_Position = u_mvpMat * vec4(a_Pos, 0.0, 1.0);
    }
`;
// ImageFormat order is argb, in native order (that is actually bgra)
// the framebuffer order is rgba, so some swizzling is needed
enum textFShader = `
    #version 330

    in vec2 v_TexCoord;

    uniform sampler2D t_Sampler;
    uniform Color {
        vec4 u_Color;
    };

    out vec4 o_Color;

    void main() {
        vec4 sample = texture(t_Sampler, v_TexCoord);
        o_Color = sample.r * u_Color;
    }
`;
