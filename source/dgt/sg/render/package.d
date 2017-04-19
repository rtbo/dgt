module dgt.sg.render;

import dgt.context;
import dgt.geometry;
import dgt.math;
import dgt.image;
import dgt.sg.render.node;
import dgt.sg.render.frame;
import dgt.sg.render.pipelines;

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

    SolidPipeline   _solidPipeline;
    SolidPipeline   _solidBlendPipeline;
    TexPipeline     _texPipeline;
    TexPipeline     _texBlendArgbPipeline;
    TexPipeline     _texBlendArgbPremultPipeline;

    FMat4 _viewProj;
    ISize _size;


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

        Rc!CommandBuffer cmdBuf = _device.makeCommandBuffer();

        _solidPipeline = new SolidPipeline(cmdBuf.obj, none!Blend);
        _solidBlendPipeline = new SolidPipeline(
            cmdBuf.obj, some(Blend(
                Equation.Add,
                Factor.makeZeroPlus(BlendValue.SourceAlpha),
                Factor.makeOneMinus(BlendValue.SourceAlpha)
            ))
        );
        _texPipeline = new TexPipeline(cmdBuf.obj, none!Blend);
        _texBlendArgbPipeline = new TexPipeline(
            cmdBuf.obj, some(Blend(
                Equation.Add,
                Factor.makeZeroPlus(BlendValue.SourceAlpha),
                Factor.makeOneMinus(BlendValue.SourceAlpha)
            ))
        );
        _texBlendArgbPremultPipeline = new TexPipeline(
            cmdBuf.obj, some(Blend(
                Equation.Add,
                Factor.makeOne(),
                Factor.makeOneMinus(BlendValue.SourceAlpha)
            ))
        );

        _encoder = Encoder(cmdBuf.obj);
    }

    void finalize(size_t nativeHandle)
    {
        synchronized(_context) {
            _context.makeCurrent(nativeHandle);
            _encoder = Encoder.init;
            _solidPipeline.dispose();
            _solidBlendPipeline.dispose();
            _texPipeline.dispose();
            _texBlendArgbPipeline.dispose();
            _texBlendArgbPremultPipeline.dispose();
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

            immutable vp = cast(Rect!ushort)frame.viewport;
            _encoder.setViewport(vp.x, vp.y, vp.width, vp.height);

            if (frame.hasClearColor) {
                auto col = frame.clearColor;
                _encoder.clear!Rgba8(_rtv, [col.r, col.g, col.b, col.a]);
            }

            if (frame.root) {
                _viewProj = orthoProj(0, vp.width, vp.height, 0, 1, -1); // Y=0 at the top
                renderNode(frame.root, FMat4.identity);
            }

            _encoder.flush(_device);
            _context.swapBuffers(frame.windowHandle);
        }
    }

    void renderNode(immutable(RenderNode) node, in FMat4 model)
    {
        final switch(node.type)
        {
        case RenderNode.Type.group:
            immutable grNode = unsafeCast!(immutable(GroupRenderNode))(node);
            foreach (immutable n; grNode.children) {
                renderNode(n, model);
            }
            break;
        case RenderNode.Type.transform:
            immutable trNode = unsafeCast!(immutable(TransformRenderNode))(node);
            renderNode(trNode.child, model * trNode.transform);
            break;
        case RenderNode.Type.color:
            renderColorNode(unsafeCast!(immutable(ColorRenderNode))(node), model);
            break;
        case RenderNode.Type.image:
            renderImageNode(unsafeCast!(immutable(ImageRenderNode))(node), model);
            break;
        }
    }

    void renderColorNode(immutable(ColorRenderNode) node, in FMat4 model)
    {
        immutable rect = node.bounds;
        immutable color = node.color;
        auto quadVerts = [
            SolidVertex([rect.left, rect.top]),
            SolidVertex([rect.left, rect.bottom]),
            SolidVertex([rect.right, rect.bottom]),
            SolidVertex([rect.right, rect.top]),
        ];
        ushort[] quadInds = [0, 1, 2, 0, 2, 3];
        auto vbuf = makeRc!(VertexBuffer!SolidVertex)(quadVerts);
        auto slice = VertexBufferSlice(new IndexBuffer!ushort(quadInds));

        immutable mvp = transpose(_viewProj * model);

        SolidPipeline pl = color.a == 1f ?
            _solidPipeline : _solidBlendPipeline;

        pl.updateUniforms(mvp, color);
        pl.draw(vbuf.obj, slice, _rtv);
    }

    void renderImageNode(immutable(ImageRenderNode) node, in FMat4 model)
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

        immutable rect = node.bounds;
        auto quadVerts = [
            TexVertex([rect.left, rect.top], [0f, 0f]),
            TexVertex([rect.left, rect.bottom], [0f, 1f]),
            TexVertex([rect.right, rect.bottom], [1f, 1f]),
            TexVertex([rect.right, rect.top], [1f, 0f]),
        ];
        ushort[] quadInds = [0, 1, 2, 0, 2, 3];
        auto vbuf = makeRc!(VertexBuffer!TexVertex)(quadVerts);

        auto slice = VertexBufferSlice(new IndexBuffer!ushort(quadInds));

        TexPipeline pl;
        switch (img.format) {
        case ImageFormat.rgb:
            pl = _texPipeline;
            break;
        case ImageFormat.argb:
            pl = _texBlendArgbPipeline;
            break;
        case ImageFormat.argbPremult:
            pl = _texBlendArgbPremultPipeline;
            break;
        default:
            assert(false, "unimplemented");
        }

        pl.updateUniforms(transpose(_viewProj * model));
        pl.draw(vbuf.obj, slice, srv.obj, sampler.obj, _rtv);
    }
}

FMat4 orthoProj(float l, float r, float b, float t, float n, float f)
{
    return FMat4(
        2f/(r-l), 0, 0, -(r+l)/(r-l),
        0, 2f/(t-b), 0, -(t+b)/(t-b),
        0, 0, -2f/(f-n), -(f+n)/(f-n),
        0, 0, 0, 1
    );
}
