module dgt.sg.renderer;

import dgt.context;
import dgt.geometry;
import dgt.math;
import dgt.image;
import dgt.sg.rendernode;
import dgt.sg.renderframe;

import gfx.foundation.rc;
import gfx.foundation.util;
import gfx.pipeline;
import gfx.device;
import gfx.device.gl3;

import std.concurrency;
import std.exception;
import std.experimental.logger;

Tid startRenderLoop(shared(GlContext) context)
{
    trace("starting rendering loop");
    return spawn(&renderLoop, context, thisTid);
}

bool renderFrame(Tid renderLoopTid, immutable(RenderFrame) frame)
{
    import core.time : dur;
    if (!receiveTimeout(dur!"msecs"(15), (ReadyToRender rr){})) {
        return false;
    }
    send(renderLoopTid, frame);
    return true;
}

void finalizeRenderLoop(Tid renderLoopTid)
{
    import core.time : dur;
    trace("terminating render loop");
    prioritySend(renderLoopTid, Finalize());
    if (!receiveTimeout(dur!"msecs"(100), (Finalized f) {})) {
        error("no proper termination of renderer!");
    }
}

private:

struct ReadyToRender {}
struct Finalize {}
struct Finalized {}


void renderLoop(shared(GlContext) context, Tid mainLoopTid)
{
    auto renderer = new Renderer(context);

    bool exit;
    while (!exit)
    {
        send(mainLoopTid, ReadyToRender());
        receive(
            (immutable(RenderFrame) frame) {
                renderer.renderFrame(frame);
            },
            (Finalize f) {
                exit = true;
            }
        );
    }

    renderer.finalize();
    prioritySend(mainLoopTid, Finalized());
}


class Renderer
{
    shared(GlContext) _context;
    Device _device;
    Encoder _encoder;
    BuiltinSurface!Rgba8 _surf;
    RenderTargetView!Rgba8 _rtv;
    Program _prog;
    TexBlitPipeline _pso;
    ISize _size;

    FMat4 _transform;

    this(shared(GlContext) context)
    {
        _context = context;
    }

    void initialize() {
        _device = enforce(createGlDevice());
        _device.retain();

        _surf = new BuiltinSurface!Rgba8(
            _device.builtinSurface,
            cast(ushort)_size.width, cast(ushort)_size.height,
            _context.attribs.samples
        );
        _surf.retain();

        _rtv = _surf.viewAsRenderTarget();
        _rtv.retain();

        _prog = new Program(ShaderSet.vertexPixel(
            texBlitVShader, texBlitFShader
        ));
        _prog.retain();

        _pso = new TexBlitPipeline(_prog, Primitive.Triangles, Rasterizer.fill.withSamples());
        _pso.retain();

        _encoder = Encoder(_device.makeCommandBuffer());
    }

    void finalize()
    {
        _encoder = Encoder.init;
        _pso.release();
        _prog.release();
        _rtv.release();
        _surf.release();
        _device.release();
    }

    void renderFrame(immutable(RenderFrame) frame)
    {
        if (!_context.makeCurrent(frame.windowHandle)) {
            error("could not make rendering context current!");
            return;
        }
        scope(exit) _context.doneCurrent();

        _size = frame.viewport.size;
        if (!_device) {
            initialize();
            log("renderer initialized");
        }

        immutable vp = cast(TRect!ushort)frame.viewport;
        _encoder.setViewport(vp.x, vp.y, vp.width, vp.height);

        if (frame.hasClearColor) {
            auto col = frame.clearColor;
            _encoder.clear!Rgba8(_rtv, [col.r, col.g, col.b, col.a]);
        }

        if (frame.root) {
            renderNode(frame.root);
        }

        _encoder.flush(_device);
        _context.swapBuffers(frame.windowHandle);
    }

    void renderNode(immutable(RenderNode) node)
    {
        final switch(node.type)
        {
        case RenderNode.Type.group:
            immutable grNode = unsafeCast!(immutable(GroupRenderNode))(node);
            foreach (immutable n; grNode.children) {
                renderNode(n);
            }
            break;
        case RenderNode.Type.transform:
            immutable trNode = unsafeCast!(immutable(TransformRenderNode))(node);
            _transform = trNode.transform * _transform;
            break;
        case RenderNode.Type.color:
            renderColorNode(unsafeCast!(immutable(ColorRenderNode))(node));
            break;
        case RenderNode.Type.image:
            renderImageNode(unsafeCast!(immutable(ImageRenderNode))(node));
            break;
        }
    }

    void renderColorNode(immutable(ColorRenderNode) node)
    {

    }

    void renderImageNode(immutable(ImageRenderNode) node)
    {
        immutable img = node.image;
        enforce(img.format == ImageFormat.argb ||
                img.format == ImageFormat.argbPremult);

        auto pixels = retypeSlice!(const(ubyte[4]))(img.data);
        TexUsageFlags usage = TextureUsage.ShaderResource;
        auto tex = makeRc!(Texture2D!Rgba8)(
            usage, ubyte(1), cast(ushort)img.width, cast(ushort)img.height, [pixels]
        );
        auto srv = tex.viewAsShaderResource(0, 0, newSwizzle()).rc();
        auto sampler = makeRc!Sampler(
            srv, SamplerInfo(FilterMethod.Anisotropic, WrapMode.init)
        );

        auto quadVerts = [
            TexBlitVertex([-1f, -1f], [0f, 1f]),
            TexBlitVertex([1f, -1f], [1f, 1f]),
            TexBlitVertex([1f, 1f], [1f, 0f]),
            TexBlitVertex([-1f, 1f], [0f, 0f])
        ];
        ushort[] quadInds = [0, 1, 2, 0, 2, 3];
        auto vbuf = makeRc!(VertexBuffer!TexBlitVertex)(quadVerts);

        auto slice = VertexBufferSlice(new IndexBuffer!ushort(quadInds));

        auto data = TexBlitPipeline.Data(
            vbuf, srv, sampler, rc(_rtv)
        );

        _encoder.draw!TexBlitPipeMeta(slice, _pso, data);
    }
}

struct TexBlitVertex {
    @GfxName("a_Pos")       float[2] pos;
    @GfxName("a_TexCoord")  float[2] texCoord;
}

struct TexBlitPipeMeta {
    VertexInput!TexBlitVertex   input;

    @GfxName("t_Sampler")
    ResourceView!Rgba8          texture;

    @GfxName("t_Sampler")
    ResourceSampler             sampler;

    @GfxName("o_Color")
    ColorOutput!Rgba8           outColor;
}

alias TexBlitPipeline = PipelineState!TexBlitPipeMeta;

enum texBlitVShader = `
    #version 330
    in vec2 a_Pos;
    in vec2 a_TexCoord;

    out vec2 v_TexCoord;

    void main() {
        v_TexCoord = a_TexCoord;
        gl_Position = vec4(a_Pos, 0.0, 1.0);
    }
`;
version(LittleEndian)
{
    // ImageFormat order is argb, in native order (that is actually bgra)
    // the framebuffer order is rgba, so some swizzling is needed
    enum texBlitFShader = `
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
    enum texBlitFShader = `
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