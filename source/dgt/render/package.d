/// rendering thread management
module dgt.render;

import dgt.application;
import dgt.context;
import dgt.geometry;
import dgt.image;
import dgt.math;
import dgt.render.frame;
import dgt.render.node;
import dgt.render.pipelines;

import gfx.device;
import gfx.device.gl3;
import gfx.foundation.rc;
import gfx.foundation.typecons;
import gfx.foundation.util;
import gfx.pipeline;

import std.concurrency;
import std.exception;
import std.experimental.logger;

/// Interface to the render thread
class RenderThread
{
    /// Get the singleton instance
    static RenderThread instance()
    {
        return _instance;
    }

    /// Whether the render thread is running
    @property bool running() const { return _running; }


    /// Instruct the render thread to delete a cached render data;
    void deleteCache(in ulong cookie)
    {
        send(_tid, DeleteCache(cookie));
    }

    /// Get a new valid cookie for caching render data
    ulong nextCacheCookie()
    {
        if (_cacheCookie == ulong.max) {
            error("Render cache cookie overflow!");
            return 0;
        }
        return ++_cacheCookie;
    }

    package(dgt) this() {}
    package(dgt) static void initialize()
    {
        _instance = new RenderThread;
    }

    /// Start a rendering thread that will use the context passed in argument.
    /// The context is assumed "moved" to the render thread and should not be
    /// used anymore.
    /// Returns the Tid of the rendering thread.
    package(dgt) void start(GlContext context)
    {
        assert(!_running);
        trace("starting rendering loop");
        _tid = spawn(&renderLoop, cast(shared(GlContext))context, thisTid);
    }

    /// Whether the renderer is ready to render a new frame
    /// This will return true after vsync until a new frame is sent
    package(dgt) static @property bool hadVSync()
    {
        import core.atomic : atomicLoad;
        return atomicLoad(_hadVSync);
    }

    /// Render a frame in the rendering thread.
    package(dgt) bool frame(immutable(RenderFrame) frame)
    {
        import core.atomic : atomicStore;
        atomicStore(_hadVSync, false);
        send(_tid, frame);
        return true;
    }

    /// Render a more than one frame in the rendering thread.
    /// Attempt is made to render all frames in the same vsync.
    /// Each frame should be for a different window.
    package(dgt) bool frame(immutable(RenderFrame)[] frames)
    {
        import core.atomic : atomicStore;
        atomicStore(_hadVSync, false);
        send(_tid, frames);
        return true;
    }

    /// End the rendering thread.
    /// The native handle is used to make a context current in order to
    /// free held graphics resources.
    package(dgt) void stop(size_t nativeHandle)
    {
        import core.time : dur;
        trace("terminating render loop");
        prioritySend(_tid, Finalize(nativeHandle));
        if (!receiveTimeout(dur!"msecs"(100), (Finalized f) {})) {
            error("no proper termination of renderer!");
        }
    }

    private Tid _tid;
    private ulong _cacheCookie;
    private bool _running;
}

private:

__gshared RenderThread _instance;
shared bool _hadVSync;


struct DeleteCache {
    ulong cookie;
}

struct Finalize {
    size_t nativeHandle;
}
struct Finalized {}

void renderLoop(shared(GlContext) context, Tid mainLoopTid)
{
    import core.atomic : atomicStore;

    try {
        auto renderer = new Renderer(cast(GlContext)context);
        atomicStore(_hadVSync, true);

        bool exit;
        while (!exit)
        {
            receive(
                (immutable(RenderFrame) frame) {
                    renderer.renderFrame(frame);
                    atomicStore(_hadVSync, true);
                    Application.platform.vsync();
                },
                (immutable(RenderFrame)[] frames) {
                    renderer.renderFrames(frames);
                    atomicStore(_hadVSync, true);
                    Application.platform.vsync();
                },
                (DeleteCache dc) {
                    renderer.markForPrune(dc.cookie);
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
    class PerWindow : Disposable
    {
        Rc!(Texture2D!Rgba8)            bufTex;
        Rc!(RenderTargetView!Rgba8)     bufRtv;
        Rc!(ShaderResourceView!Rgba8)   bufSrv;
        Rc!Sampler                      bufSampler;

        Rc!(BuiltinSurface!Rgba8)       surf;
        Rc!(RenderTargetView!Rgba8)     rtv;

        ISize   size;
        FMat4   viewProj;

        this(in ISize sz)
        {
            surf = new BuiltinSurface!Rgba8(
                _device.builtinSurface,
                cast(ushort)sz.width, cast(ushort)sz.height,
                _context.attribs.samples
            );

            rtv = surf.viewAsRenderTarget();

            updateWithSize(sz);
        }

        void updateWithSize(in ISize sz)
        {
            if (!bufTex || size != sz) {
                TexUsageFlags usage = TextureUsage.ShaderResource | TextureUsage.RenderTarget;
                bufTex = new Texture2D!Rgba8(usage, 1, cast(ushort)sz.width, cast(ushort)sz.height, []);
                bufRtv = bufTex.viewAsRenderTarget(0, none!ubyte);
                bufSrv = bufTex.viewAsShaderResource(0, 0, newSwizzle());
                bufSampler = new Sampler(
                    bufSrv, SamplerInfo(FilterMethod.Anisotropic, WrapMode.init)
                );
            }
            if (size != sz) {
                size = sz;
                viewProj = orthoProj(0, sz.width, sz.height, 0, 1, -1); // Y=0 at the top
            }
        }

        override void dispose()
        {
            bufTex.unload();
            bufRtv.unload();
            bufSrv.unload();
            bufSampler.unload();
            surf.unload();
            rtv.unload();
        }
    }

    GlContext               _context;
    Device                  _device;
    Encoder                 _encoder;

    PerWindow[size_t]       _windowCache;

    SolidPipeline   _solidPipeline;
    SolidPipeline   _solidBlendPipeline;
    TexPipeline     _texPipeline;
    TexPipeline     _texBlendArgbPipeline;
    TexPipeline     _texBlendArgbPremultPipeline;
    TextPipeline    _textPipeline;
    BlitPipeline    _blitPipeline;

    VertexBuffer!P2Vertex   _solidQuadVBuf;
    VertexBuffer!P2T2Vertex _texQuadVBuf;
    IndexBuffer!ushort      _quadIBuf;

    Disposable[ulong]   _objectCache;
    ulong[]             _cachePruneQueue;


    this(GlContext context)
    {
        _context = context;
    }

    void initialize() {
        _device = enforce(createGlDevice());
        _device.retain();

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

        _blitPipeline = new BlitPipeline(cmdBuf.obj);

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
        _blitPipeline.dispose();
        dispose(_windowCache);
        _device.release();

        _context.doneCurrent();
        _context.dispose();
    }

    PerWindow windowCache(size_t handle, in ISize sz)
    {
        auto pwp = handle in _windowCache;
        if (pwp) {
            pwp.updateWithSize(sz);
            return *pwp;
        }
        else {
            auto newPw = new PerWindow(sz);
            _windowCache[handle] = newPw;
            return newPw;
        }
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

    void markForPrune(ulong cookie)
    {
        _cachePruneQueue ~= cookie;
    }

    void pruneCache()
    {
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
    }


    void renderFrames(immutable(RenderFrame)[] frames)
    {
        foreach (i, f; frames) {
            if (!_context.makeCurrent(f.windowHandle)) {
                error("could not make rendering context current!");
                return;
            }
            scope(exit) _context.doneCurrent();

            if (i == 0) {
                pruneCache();
            }

            _context.swapInterval = (i == frames.length-1) ? 1 : 0;

            doFrame(f);
        }
    }

    void renderFrame(immutable(RenderFrame) frame)
    {
        if (!_context.makeCurrent(frame.windowHandle)) {
            error("could not make rendering context current!");
            return;
        }
        scope(exit) _context.doneCurrent();

        pruneCache();
        _context.swapInterval = 1;

        doFrame(frame);
    }

    void doFrame(immutable(RenderFrame) frame)
    {
        if (!_device) {
            initialize();
            log("renderer initialized");
        }

        immutable size = frame.viewport.size;

        auto pw = windowCache(frame.windowHandle, size);

        immutable vp = cast(Rect!ushort)frame.viewport;
        _encoder.setViewport(vp.x, vp.y, vp.width, vp.height);

        if (frame.hasClearColor) {
            auto col = frame.clearColor;
            _encoder.clear!Rgba8(pw.bufRtv, [col.r, col.g, col.b, col.a]);
        }

        if (frame.root) {
            renderNode(frame.root, pw, FMat4.identity);
        }

        // blit from texture to screen
        immutable vpTr =
                        translation!float(0f, size.height, 0f) *
                        scale!float(size.width, -size.height, 1f);
        _blitPipeline.updateUniforms(transpose(pw.viewProj * vpTr));
        _blitPipeline.draw(_texQuadVBuf, VertexBufferSlice(_quadIBuf), pw.bufSrv.obj, pw.bufSampler.obj, pw.rtv);

        _encoder.flush(_device);
        _context.swapBuffers(frame.windowHandle);
    }

    void renderNode(immutable(RenderNode) node, PerWindow pw, in FMat4 model)
    {
        final switch(node.type)
        {
        case RenderNode.Type.group:
            immutable grNode = unsafeCast!(immutable(GroupRenderNode))(node);
            foreach (immutable n; grNode.children) {
                renderNode(n, pw, model);
            }
            break;
        case RenderNode.Type.transform:
            immutable trNode = unsafeCast!(immutable(TransformRenderNode))(node);
            renderNode(trNode.child, pw, model * trNode.transform);
            break;
        case RenderNode.Type.color:
            renderColorNode(unsafeCast!(immutable(ColorRenderNode))(node), pw, model);
            break;
        case RenderNode.Type.image:
            renderImageNode(unsafeCast!(immutable(ImageRenderNode))(node), pw, model);
            break;
        case RenderNode.Type.text:
            renderTextNode(unsafeCast!(immutable(TextRenderNode))(node), pw, model);
        }
    }

    void renderColorNode(immutable(ColorRenderNode) node, PerWindow pw, in FMat4 model)
    {
        immutable color = node.color;
        immutable rect = node.bounds;
        immutable rectTr = translate(
            scale!float(rect.width, rect.height, 1f),
            fvec(rect.topLeft, 0f)
        );
        immutable mvp = transpose(pw.viewProj * model * rectTr);

        SolidPipeline pl = color.a == 1f ?
            _solidPipeline : _solidBlendPipeline;

        pl.updateUniforms(mvp, color);
        pl.draw(_solidQuadVBuf, VertexBufferSlice(_quadIBuf), pw.bufRtv);
    }

    void renderImageNode(immutable(ImageRenderNode) node, PerWindow pw, in FMat4 model)
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
        pl.updateUniforms(transpose(pw.viewProj * model * rectTr));
        pl.draw(_texQuadVBuf, VertexBufferSlice(_quadIBuf), srv.obj, sampler.obj, pw.bufRtv);
    }

    void renderTextNode(immutable(TextRenderNode) node, PerWindow pw, in FMat4 model)
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
                // FilterMethod.Scale maps to GL_NEAREST
                // no need to filter what is already filtered
                sampler = new Sampler(
                    srv, SamplerInfo(FilterMethod.Scale, WrapMode.init)
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
            immutable vertRect = roundRect(
                transformBounds(FRect(
                    gl.layoutPos, txRect.size
                ), model)
            );
            auto quadVerts = [
                P2T2Vertex([vertRect.left, vertRect.top], [normRect.left, normRect.top]),
                P2T2Vertex([vertRect.left, vertRect.bottom], [normRect.left, normRect.bottom]),
                P2T2Vertex([vertRect.right, vertRect.bottom], [normRect.right, normRect.bottom]),
                P2T2Vertex([vertRect.right, vertRect.top], [normRect.right, normRect.top]),
            ];
            auto vbuf = makeRc!(VertexBuffer!P2T2Vertex)(quadVerts);

            _textPipeline.updateMVP(transpose(pw.viewProj));
            _textPipeline.draw(vbuf.obj, VertexBufferSlice(_quadIBuf), srv.obj, sampler.obj, pw.bufRtv);
        }
    }
}

// used for hinting
FRect roundRect(in FRect rect)
{
    import std.math : round;
    return FRect(round(rect.x), round(rect.y), round(rect.width), round(rect.height));
}

FMat4 orthoProj(float l, float r, float b, float t, float n, float f) pure
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