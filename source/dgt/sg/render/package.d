/// Scene graph rendering module
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

/// Instruct the render thread to delete a cached render data;
void deleteRenderCache(Tid renderLoopTid, in ulong cookie)
{
    send(renderLoopTid, DeleteCache(cookie));
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
struct DeleteCache {
    ulong cookie;
}

void renderLoop(shared(GlContext) context, Tid mainLoopTid)
{
    try {
        auto renderer = new Renderer(cast(GlContext)context);

        bool exit;
        while (!exit)
        {
            send(mainLoopTid, ReadyToRender());
            receive(
                (immutable(RenderFrame) frame) {
                    renderer.renderFrame(frame);
                },
                (DeleteCache dc) {
                    renderer.deleteCache(dc.cookie);
                },
                (Finalize f) {
                    renderer.finalize(f.nativeHandle);
                    exit = true;
                }
            );
        }
    }
    catch(Exception ex) {
        errorf("renderer exited due to exception: %s", ex.msg);
    }
    catch(Throwable th) {
        errorf("renderer exited due to error: %s", th.msg);
    }
    finally {
        prioritySend(mainLoopTid, Finalized());
    }
}


class Renderer
{
    GlContext               _context;
    Device                  _device;
    Encoder                 _encoder;
    BuiltinSurface!Rgba8    _surf;
    RenderTargetView!Rgba8  _rtv;

    SolidPipeline   _solidPipeline;
    SolidPipeline   _solidBlendPipeline;
    TexPipeline     _texPipeline;
    TexPipeline     _texBlendArgbPipeline;
    TexPipeline     _texBlendArgbPremultPipeline;
    TextPipeline    _textPipeline;

    VertexBuffer!P2Vertex   _solidQuadVBuf;
    VertexBuffer!P2T2Vertex _texQuadVBuf;
    IndexBuffer!ushort      _quadIBuf;

    Disposable[ulong]   _objectCache;
    ulong[]             _cachePruneQueue;

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
        _textPipeline = new TextPipeline(cmdBuf.obj);

        auto quadSolidVerts = [
            P2Vertex([0f, 0f]),
            P2Vertex([0f, 1f]),
            P2Vertex([1f, 1f]),
            P2Vertex([1f, 0f]),
        ];
        _solidQuadVBuf = new VertexBuffer!P2Vertex(quadSolidVerts);
        _solidQuadVBuf.retain();

        auto quadTexVerts = [
            P2T2Vertex([0f, 0f], [0f, 0f]),
            P2T2Vertex([0f, 1f], [0f, 1f]),
            P2T2Vertex([1f, 1f], [1f, 1f]),
            P2T2Vertex([1f, 0f], [1f, 0f]),
        ];
        _texQuadVBuf = new VertexBuffer!P2T2Vertex(quadTexVerts);
        _texQuadVBuf.retain();

        ushort[] quadInds = [0, 1, 2, 0, 2, 3];
        _quadIBuf = new IndexBuffer!ushort(quadInds);
        _quadIBuf.retain();

        _encoder = Encoder(cmdBuf.obj);
    }

    void finalize(size_t nativeHandle)
    {
        synchronized(_context) {
            _context.makeCurrent(nativeHandle);
            foreach(oc; _objectCache) {
                oc.dispose();
            }
            _encoder = Encoder.init;
            _texQuadVBuf.release();
            _solidQuadVBuf.release();
            _quadIBuf.release();
            _solidPipeline.dispose();
            _solidBlendPipeline.dispose();
            _texPipeline.dispose();
            _texBlendArgbPipeline.dispose();
            _texBlendArgbPremultPipeline.dispose();
            _textPipeline.dispose();
            _rtv.release();
            _surf.release();
            _device.release();
            _context.doneCurrent();
        }
        _context.dispose();
    }

    T retrieveCache(T)(ulong cookie)
    {
        Disposable* d = (cookie in _objectCache);
        if (!d) return null;
        T cachedObj = cast(T)*d;
        if (!cachedObj) {
            error("invalid cache cookie: ", cookie);
        }
        return cachedObj;
    }

    void deleteCache(ulong cookie)
    {
        _cachePruneQueue ~= cookie;
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

            foreach(cookie; _cachePruneQueue) {
                auto d = cookie in _objectCache;
                if (d) {
                    (*d).dispose();
                    _objectCache.remove(cookie);
                }
                else {
                    warning("invalid cookie given for cache prune");
                }
            }
            _cachePruneQueue.length = 0;

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
        case RenderNode.Type.text:
            renderTextNode(unsafeCast!(immutable(TextRenderNode))(node), model);
        }
    }

    void renderColorNode(immutable(ColorRenderNode) node, in FMat4 model)
    {
        immutable color = node.color;
        immutable rect = node.bounds;
        immutable rectTr = translate(
            scale!float(rect.width, rect.height, 1f),
            fvec(rect.topLeft, 0f)
        );
        immutable mvp = transpose(_viewProj * model * rectTr);

        SolidPipeline pl = color.a == 1f ?
            _solidPipeline : _solidBlendPipeline;

        pl.updateUniforms(mvp, color);
        pl.draw(_solidQuadVBuf, VertexBufferSlice(_quadIBuf), _rtv);
    }

    void renderImageNode(immutable(ImageRenderNode) node, in FMat4 model)
    {
        immutable img = node.image;
        Rc!(ShaderResourceView!Rgba8) srv;
        Rc!Sampler sampler;
        TextureObjectCache cache;
        immutable cookie = node.cacheCookie;

        if (cookie) {
            cache = retrieveCache!TextureObjectCache(cookie);
        }
        if (cache) {
            srv = cache.srv;
            sampler = cache.sampler;
        }
        else {
            if (img.format != ImageFormat.argb &&
                    img.format != ImageFormat.argbPremult) {
                errorf("improper texture image format: %s", img.format);
                return;
            }

            auto pixels = retypeSlice!(const(ubyte[4]))(img.data);
            TexUsageFlags usage = TextureUsage.ShaderResource;
            auto tex = makeRc!(Texture2D!Rgba8)(
                usage, ubyte(1), cast(ushort)img.width, cast(ushort)img.height, [pixels]
            );
            srv = tex.viewAsShaderResource(0, 0, newSwizzle());
            sampler = new Sampler(
                srv, SamplerInfo(FilterMethod.Anisotropic, WrapMode.init)
            );
            if (cookie) {
                _objectCache[cookie] = new TextureObjectCache(srv.obj, sampler.obj);
            }
        }

        TexPipeline pl;
        switch (img.format) {
        case ImageFormat.xrgb:
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

        immutable rect = node.bounds;
        immutable rectTr = translate(
            scale!float(rect.width, rect.height, 1f),
            fvec(rect.topLeft, 0f)
        );
        pl.updateUniforms(transpose(_viewProj * model * rectTr));
        pl.draw(_texQuadVBuf, VertexBufferSlice(_quadIBuf), srv.obj, sampler.obj, _rtv);
    }

    void renderTextNode(immutable(TextRenderNode) node, in FMat4 model)
    {
        _textPipeline.updateColor(node.color);
        foreach(gl; node.glyphs) {
            Rc!(ShaderResourceView!Alpha8) srv;
            Rc!Sampler sampler;
            immutable cookie = gl.glyph.cacheCookie;
            auto runImg = gl.glyph.runImg;
            GlyphRunObjectCache cache;
            if (cookie) {
                cache = retrieveCache!GlyphRunObjectCache(cookie);
            }
            if (cache) {
                srv = cache.srv;
                sampler = cache.sampler;
            }
            else {
                if (runImg.format != ImageFormat.a8) {
                    errorf("improper text texture image format: %s", runImg.format);
                    return;
                }
                immutable pixels = runImg.data;
                TexUsageFlags usage = TextureUsage.ShaderResource;
                auto tex = new Texture2D!Alpha8(
                    usage, 1, cast(ushort)runImg.width, cast(ushort)runImg.height, [pixels]
                ).rc();
                srv = tex.viewAsShaderResource(0, 0, newSwizzle());
                sampler = new Sampler(
                    srv, SamplerInfo(FilterMethod.Anisotropic, WrapMode.init)
                );
                if (cookie) {
                    _objectCache[cookie] = new GlyphRunObjectCache(
                        srv.obj, sampler.obj
                    );
                }
            }

            // texel space rect
            immutable txRect = cast(FRect)gl.glyph.rect;
            FVec2 fSize = fvec(runImg.width, runImg.height);
            // normalized rect
            immutable normRect = FRect(
                txRect.topLeft / fSize,
                FSize(txRect.width / fSize.x, txRect.height / fSize.y)
            );
            immutable vertRect = FRect(
                gl.layoutPos, txRect.size
            );
            auto quadVerts = [
                P2T2Vertex([vertRect.left, vertRect.top], [normRect.left, normRect.top]),
                P2T2Vertex([vertRect.left, vertRect.bottom], [normRect.left, normRect.bottom]),
                P2T2Vertex([vertRect.right, vertRect.bottom], [normRect.right, normRect.bottom]),
                P2T2Vertex([vertRect.right, vertRect.top], [normRect.right, normRect.top]),
            ];
            auto vbuf = makeRc!(VertexBuffer!P2T2Vertex)(quadVerts);

            _textPipeline.updateMVP(transpose(_viewProj * model));
            _textPipeline.draw(vbuf.obj, VertexBufferSlice(_quadIBuf), srv.obj, sampler.obj, _rtv);
        }
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

class TextureObjectCache : Disposable
{
    ShaderResourceView!Rgba8 srv;
    Sampler sampler;

    this(ShaderResourceView!Rgba8 srv, Sampler sampler)
    {
        this.srv = srv;
        this.sampler = sampler;
        this.srv.retain();
        this.sampler.retain();
    }

    override void dispose()
    {
        srv.release();
        sampler.release();
    }
}

class GlyphRunObjectCache : Disposable
{
    ShaderResourceView!Alpha8 srv;
    Sampler sampler;

    this(ShaderResourceView!Alpha8 srv, Sampler sampler)
    {
        this.srv = srv;
        this.sampler = sampler;
        this.srv.retain();
        this.sampler.retain();
    }

    override void dispose()
    {
        srv.release();
        sampler.release();
    }
}
