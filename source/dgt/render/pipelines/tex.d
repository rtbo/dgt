module dgt.render.pipelines.tex;

import dgt.render.pipelines.defs;
import dgt.math;

import gfx.pipeline;
import gfx.device;
import gfx.foundation.rc;
import gfx.foundation.typecons;

class TexPipeline : Disposable
{
    private StateObject _pso;
    private ConstBuffer!MVP _mvpBlk;
    private Encoder _encoder;

    alias Vertex = P2T2Vertex;
    alias Meta = TexMeta;
    alias StateObject = PipelineState!TexMeta;
    alias Data = StateObject.Data;

    this(CommandBuffer cmdBuf, Option!Blend blend)
    {
        auto prog = makeRc!Program(ShaderSet.vertexPixel(
            texVShader, texFShader
        ));

        _pso = new StateObject(
            prog.obj, Primitive.Triangles,
            Rasterizer.fill.withSamples()
        );
        _pso.retain();
        _pso.outColor.info.blend = blend;

        _mvpBlk = new ConstBuffer!MVP(1);
        _mvpBlk.retain();

        _encoder = Encoder(cmdBuf);
    }

    override void dispose()
    {
        _pso.release();
        _mvpBlk.release();
        _encoder = Encoder.init;
    }

    void updateUniforms(in FMat4 transform)
    {
        _encoder.updateConstBuffer(_mvpBlk, MVP(transform));
    }

    void draw(VertexBuffer!Vertex vbuf,
                VertexBufferSlice slice,
                ShaderResourceView!Rgba8 srv,
                Sampler sampler,
                RenderTargetView!Rgba8 rtv)
    {
        _encoder.draw!TexMeta(slice, _pso, Data(
            rc(vbuf), rc(_mvpBlk), rc(srv), rc(sampler), rc(rtv)
        ));
    }
}


private:

struct MVP {
    FMat4 mvp;
}

struct TexMeta
{
    VertexInput!P2T2Vertex   input;

    @GfxName("MVP")
    ConstantBlock!MVP       mvp;

    @GfxName("t_Sampler")
    ResourceView!Rgba8          texture;

    @GfxName("t_Sampler")
    ResourceSampler             sampler;

    @GfxName("o_Color")
    ColorOutput!Rgba8           outColor;
}

enum texVShader = `
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
version(LittleEndian)
{
    // ImageFormat order is argb, in native order (that is actually bgra)
    // the framebuffer order is rgba, so some swizzling is needed
    enum texFShader = `
        #version 330

        in vec2 v_TexCoord;
        out vec4 o_Color;
        uniform sampler2D t_Sampler;

        void main() {
            vec4 sample = texture(t_Sampler, v_TexCoord);
            o_Color = sample.bgra;
        }
    `;
}
version(BigEndian)
{
    // ImageFormat order is argb, in native order
    // the framebuffer order is rgba, so a left shift is needed
    enum texFShader = `
        #version 330

        in vec2 v_TexCoord;
        out vec4 o_Color;
        uniform sampler2D t_Sampler;

        void main() {
            vec4 sample = texture(t_Sampler, v_TexCoord);
            o_Color = sample.gbar;
        }
    `;
}