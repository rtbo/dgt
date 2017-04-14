module dgt.sg.renderer;

import dgt.context;
import dgt.geometry;
import dgt.math;
import dgt.image;
import dgt.sg.rendernode;
import dgt.sg.renderframe;

import gfx.foundation.rc;
import gfx.foundation.util;
import gfx.foundation.typecons;
import gfx.pipeline;
import gfx.device;
import gfx.device.gl3;

import std.concurrency;
import std.exception;
import std.experimental.logger;

/// Start a rendering thread that will use the context passed in argument
/// Returns the Tid of the rendering thread.
Tid startRenderLoop(shared(GlContext) context)
{
    trace("starting rendering loop");
    return spawn(&renderLoop, context, thisTid);
}

/// Render a frame with rendering thread identified with renderLoopTid.
bool renderFrame(Tid renderLoopTid, immutable(RenderFrame) frame)
{
    import core.time : dur;
    if (!receiveTimeout(dur!"msecs"(15), (ReadyToRender rr){})) {
        return false;
    }
    send(renderLoopTid, frame);
    return true;
}

/// End the rendering thread identified by renderLoopTid.
/// The native handle is used to make a context current in order to
/// free held graphics resources.
void finalizeRenderLoop(Tid renderLoopTid, size_t nativeHandle)
{
    import core.time : dur;
    trace("terminating render loop");
    prioritySend(renderLoopTid, Finalize(nativeHandle));
    if (!receiveTimeout(dur!"msecs"(100), (Finalized f) {})) {
        error("no proper termination of renderer!");
    }
}

private:

struct ReadyToRender {}
struct Finalize {
    size_t nativeHandle;
}
struct Finalized {}


void renderLoop(shared(GlContext) context, Tid mainLoopTid)
{
    auto renderer = new Renderer(cast(GlContext)context);

    bool exit;
    while (!exit)
    {
        send(mainLoopTid, ReadyToRender());
        receive(
            (immutable(RenderFrame) frame) {
                renderer.renderFrame(frame);
            },
            (Finalize f) {
                renderer.finalize(f.nativeHandle);
                exit = true;
            }
        );
    }

    prioritySend(mainLoopTid, Finalized());
}


class Renderer
{
    GlContext _context;
    Device _device;
    Encoder _encoder;
    BuiltinSurface!Rgba8 _surf;
    RenderTargetView!Rgba8 _rtv;
    Program _prog;
    TexPipeline _texPso;
    ISize _size;

    FMat4 _transform;

    this(GlContext context)
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
            texVShader, texFShader
        ));
        _prog.retain();

        _texPso = new TexPipeline(_prog, Primitive.Triangles, Rasterizer.fill.withSamples());
        _texPso.retain();

        _encoder = Encoder(_device.makeCommandBuffer());
    }

    void finalize(size_t nativeHandle)
    {
        synchronized(_context) {
            _context.makeCurrent(nativeHandle);
            _encoder = Encoder.init;
            _texPso.release();
            _prog.release();
            _rtv.release();
            _surf.release();
            _device.release();
            _context.doneCurrent();
        }
        _context.dispose();
    }

    void renderFrame(immutable(RenderFrame) frame)
    {
        synchronized(_context)
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
            TexVertex([-1f, -1f], [0f, 1f]),
            TexVertex([1f, -1f], [1f, 1f]),
            TexVertex([1f, 1f], [1f, 0f]),
            TexVertex([-1f, 1f], [0f, 0f])
        ];
        ushort[] quadInds = [0, 1, 2, 0, 2, 3];
        auto vbuf = makeRc!(VertexBuffer!TexVertex)(quadVerts);

        auto slice = VertexBufferSlice(new IndexBuffer!ushort(quadInds));

        switch (img.format) {
        case ImageFormat.rgb:
            _texPso.outColor.info.blend = none!Blend;
            auto data = TexPipeline.Data(
                vbuf, srv, sampler, rc(_rtv)
            );
            _encoder.draw!TexPipeMeta(slice, _texPso, data);
            break;
        case ImageFormat.argb:
            _texPso.outColor.info.blend = some(Blend(
                Equation.Add,
                Factor.makeZeroPlus(BlendValue.SourceAlpha),
                Factor.makeOneMinus(BlendValue.SourceAlpha)
            ));
            auto data = TexPipeline.Data(
                vbuf, srv, sampler, rc(_rtv)
            );
            _encoder.draw!TexPipeMeta(slice, _texPso, data);
            break;
        case ImageFormat.argbPremult:
            _texPso.outColor.info.blend = some(Blend(
                Equation.Add,
                Factor.makeOne(),
                Factor.makeOneMinus(BlendValue.SourceAlpha)
            ));
            auto data = TexPipeline.Data(
                vbuf, srv, sampler, rc(_rtv)
            );
            _encoder.draw!TexPipeMeta(slice, _texPso, data);
            break;
        default:
            assert(false, "unimplemented image format");
        }
    }
}

struct TexVertex {
    @GfxName("a_Pos")       float[2] pos;
    @GfxName("a_TexCoord")  float[2] texCoord;
}

struct TexPipeMeta {
    VertexInput!TexVertex   input;

    @GfxName("t_Sampler")
    ResourceView!Rgba8          texture;

    @GfxName("t_Sampler")
    ResourceSampler             sampler;

    @GfxName("o_Color")
    ColorOutput!Rgba8           outColor;
}
alias TexPipeline = PipelineState!TexPipeMeta;

enum texVShader = `
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