module dgt.sg.renderer;

import dgt.context;
import dgt.geometry;
import dgt.image;
import dgt.math;
import dgt.sg.context;
import dgt.sg.defs;
import dgt.sg.node;
import dgt.sg.pipelines;
import dgt.view.view;
import dgt.window;

import gfx.device;
import gfx.device.gl3;
import gfx.foundation.rc;
import gfx.foundation.typecons;
import gfx.foundation.util;
import gfx.pipeline;

import std.exception;
import std.experimental.logger;

abstract class SGRenderer
{
    static SGRenderer instance()
    {
        if (!g_instance) g_instance = new SGThreadedRenderer;
        return g_instance;
    }

    // GUI thread interface

    void start(GlContext context)
    {
        _context = context;
    }

    abstract void stop(Window w);

    /// Call sync, render and swap in the render thread and
    /// blocks the GUI thread during sync.
    abstract void syncAndRender(Window[] windows);

    // Render thread interface

    /// Called when the GUI thread is blocked to synchronize the scene graph
    /// with the window
    final protected void sync(Window w)
    {
        auto sgData = cast(PerWindow)w.sgData;
        if (!sgData) {
            sgData = new PerWindow;
            _windowCache ~= sgData;
            w.sgData = sgData;
        }

        if (w.root) sgData.root = syncView(w.root);
        else sgData.root = null;

        sgData.nativeHandle = w.nativeHandle;
        sgData.size = w.size;
        sgData.clearColor = w.clearColor.asVec;
        sgData.hasClearColor = w.hasClearColor;
    }

    private SGNode syncView(View view)
    {
        import std.format : format;

        view.sgNode.name = view.name;
        view.sgNode.transform = view.transformToParent;

        if (view.sgBackgroundNode) {
            view.sgBackgroundNode.name = format("%s.bckgnd", view.name);
        }

        if (view.sgBackgroundNode && view.sgBackgroundNode.parent !is view.sgNode) {
            view.sgNode.appendChild(view.sgBackgroundNode);
        }

        if (view.sgHasContent && view.isDirty(Dirty.content)) {
            auto old = view.sgContentNode;
            view.sgContentNode = view.sgUpdateContent(old);
            reparent(view.sgContentNode, view.sgChildrenNode);

            if (view.sgContentNode) {
                view.sgContentNode.name = format("%s.content", view.name);
            }
            view.clean(Dirty.content);
        }
        else if (view.sgContentNode && !view.sgHasContent)
        {
            if (view.sgContentNode.parent) view.sgContentNode.parent.removeChild(view.sgContentNode);
            view.sgContentNode = null;
        }

        enum childrenSyncMask = Dirty.content | Dirty.childrenContent |
                                Dirty.allChildrenMask;

        if (view.isDirty(Dirty.childrenContent | Dirty.childrenFamily)) {
            import std.algorithm : each, filter;
            view.children
                .filter!(c => c.isDirty(childrenSyncMask))
                .each!(c => reparent(syncView(c), view.sgChildrenNode));
            view.clean(Dirty.childMask);
        }

        return view.sgNode;
    }

    final protected void render(Window w)
    {
        auto pw = cast(PerWindow)w.sgData;
        if (!_context.makeCurrent(pw.nativeHandle)) {
            error("could not make rendering context current!");
            return;
        }
        scope(exit) _context.doneCurrent();

        if (!_device) initialize();
        pw.update();

        _context.swapInterval = 1;

        doFrame(pw);
    }

    final protected void swap(Window w)
    {
        auto pw = cast(PerWindow)w.sgData;
        _context.swapBuffers(pw.nativeHandle);
    }

private:

    this() {}

    class PerWindow : Disposable
    {
        this() {}

        @property void size(in ISize sz)
        {
            _prevSize = _size;
            _size = sz;
        }

        @property ISize size()
        {
            return _size;
        }

        @property Rect!ushort viewport()
        {
            return Rect!ushort(0, 0, cast(Size!ushort)_size);
        }

        void update()
        {
            if (!surf) {
                surf = new BuiltinSurface!Rgba8(
                    _device.builtinSurface,
                    cast(ushort)_size.width, cast(ushort)_size.height,
                    _context.attribs.samples
                );

                rtv = surf.viewAsRenderTarget();
            }

            if (!bufTex || _size != _prevSize) {
                TexUsageFlags usage = TextureUsage.shaderResource | TextureUsage.renderTarget;
                bufTex = new Texture2D!Rgba8(usage, 1, cast(ushort)_size.width, cast(ushort)_size.height, []);
                bufRtv = bufTex.viewAsRenderTarget(0, none!ubyte);
                bufSrv = bufTex.viewAsShaderResource(0, 0, newSwizzle());
                bufSampler = new Sampler(
                    bufSrv, SamplerInfo(FilterMethod.anisotropic, WrapMode.init)
                );
            }

            if (_size != _prevSize) {
                viewProj = orthoProj(0, _size.width, _size.height, 0, 1, -1); // Y=0 at the top
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

        size_t  nativeHandle;
        SGNode  root;
        FVec4   clearColor;
        bool    hasClearColor;
        FMat4   viewProj;

        Rc!(Texture2D!Rgba8)            bufTex;
        Rc!(RenderTargetView!Rgba8)     bufRtv;
        Rc!(ShaderResourceView!Rgba8)   bufSrv;
        Rc!Sampler                      bufSampler;

        Rc!(BuiltinSurface!Rgba8)       surf;
        Rc!(RenderTargetView!Rgba8)     rtv;
        ISize   _size;
        ISize   _prevSize;
    }

    GlContext       _context;
    Device          _device;
    Encoder         _encoder;
    CommandBuffer   _cmdBuf;
    PerWindow[]     _windowCache;

    SolidPipeline   _solidPipeline;
    SolidPipeline   _solidBlendPipeline;
    TexPipeline     _texPipeline;
    TexPipeline     _texBlendArgbPipeline;
    TexPipeline     _texBlendArgbPremultPipeline;
    TextPipeline    _textPipeline;
    BlitPipeline    _blitPipeline;
    LinesPipeline   _linesPipeline;

    VertexBuffer!P2Vertex   _solidQuadVBuf;
    VertexBuffer!P2T2Vertex _texQuadVBuf;
    IndexBuffer!ushort      _quadIBuf;
    VertexBuffer!P2Vertex   _frameVBuf;
    enum frameVBufCount = 8;

    void initialize() {
        _device = enforce(createGlDevice());
        _device.retain();

        Rc!CommandBuffer cmdBuf = _device.makeCommandBuffer();

        _solidPipeline = new SolidPipeline(cmdBuf.obj, none!Blend);
        _solidBlendPipeline = new SolidPipeline(
            cmdBuf.obj, some(Blend(
                Equation.add,
                Factor.zeroPlusSrcAlpha,
                Factor.oneMinusSrcAlpha
            ))
        );
        _texPipeline = new TexPipeline(cmdBuf.obj, none!Blend);
        _texBlendArgbPipeline = new TexPipeline(
            cmdBuf.obj, some(Blend(
                Equation.add,
                Factor.zeroPlusSrcAlpha,
                Factor.oneMinusSrcAlpha
            ))
        );
        _texBlendArgbPremultPipeline = new TexPipeline(
            cmdBuf.obj, some(Blend(
                Equation.add, Factor.one, Factor.oneMinusSrcAlpha
            ))
        );
        _textPipeline = new TextPipeline(cmdBuf.obj);

        _blitPipeline = new BlitPipeline(cmdBuf.obj);

        _linesPipeline = new LinesPipeline(cmdBuf.obj, none!Blend);

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

        auto frameVerts = [
            P2Vertex([0f, 0f]), P2Vertex([1f, 0f]),
            P2Vertex([1f, 0f]), P2Vertex([1f, 1f]),
            P2Vertex([1f, 1f]), P2Vertex([0f, 1f]),
            P2Vertex([0f, 1f]), P2Vertex([0f, 0f])
        ];
        _frameVBuf = new VertexBuffer!P2Vertex(frameVerts);
        _frameVBuf.retain();

        _encoder = Encoder(cmdBuf.obj);
        _cmdBuf = cmdBuf;
        _cmdBuf.retain();
    }

    void finalize(size_t nativeHandle)
    {
        _context.makeCurrent(nativeHandle);

        _encoder = Encoder.init;
        _texQuadVBuf.release();
        _solidQuadVBuf.release();
        _quadIBuf.release();
        _frameVBuf.release();
        _solidPipeline.dispose();
        _solidBlendPipeline.dispose();
        _texPipeline.dispose();
        _texBlendArgbPipeline.dispose();
        _texBlendArgbPremultPipeline.dispose();
        _textPipeline.dispose();
        _blitPipeline.dispose();
        _linesPipeline.dispose();
        dispose(_windowCache);
        _device.release();

        _context.doneCurrent();
        _context.dispose();
    }

    void doFrame(PerWindow pw)
    {
        immutable vp = pw.viewport;
        _encoder.setViewport(vp.x, vp.y, vp.width, vp.height);

        if (pw.hasClearColor) {
            auto col = pw.clearColor;
            _encoder.clear!Rgba8(pw.bufRtv, [col.r, col.g, col.b, col.a]);
        }

        if (pw.root) {
            auto ctx = new SGContext;
            scope(exit) ctx.dispose();

            ctx.viewProj = pw.viewProj;
            ctx.renderTarget = pw.bufRtv;
            renderNode(pw.root, ctx, FMat4.identity);
        }

        // blit from texture to screen
        immutable size = pw.size;
        immutable vpTr =
                        translation!float(0f, size.height, 0f) *
                        scale!float(size.width, -size.height, 1f);
        _blitPipeline.updateUniforms(transpose(pw.viewProj * vpTr));
        _blitPipeline.draw(_texQuadVBuf, VertexBufferSlice(_quadIBuf), pw.bufSrv.obj, pw.bufSampler.obj, pw.rtv);

        _encoder.flush(_device);
    }

    void renderNode(SGNode node, SGContext ctx, FMat4 model)
    {
        switch(node.type)
        {
        case SGNode.Type.transform:
            auto trNode = cast(SGTransformNode)node;
            model = model * trNode.transform;
            break;
        case SGNode.Type.image:
            renderImageNode(cast(SGImageNode)node, ctx, model);
            break;
        case SGNode.Type.text:
            renderTextNode(cast(SGTextNode)node, ctx, model);
            break;
        case SGNode.Type.draw:
            auto drNode = cast(SGDrawNode)node;
            drNode.draw(_cmdBuf, ctx, model);
            break;
        default:
            break;
        }

        foreach (c; node.children) {
            renderNode(c, ctx, model);
        }
    }

    void renderImageNode(SGImageNode node, SGContext ctx, in FMat4 model)
    {
        immutable img = node.image;
        Rc!(ShaderResourceView!Rgba8) srv;
        Rc!Sampler sampler;
        TextureObjectCache cache;
        // retrieve cache
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
            TexUsageFlags usage = TextureUsage.shaderResource;
            auto tex = makeRc!(Texture2D!Rgba8)(
                usage, ubyte(1), cast(ushort)img.width, cast(ushort)img.height, [pixels]
            );
            srv = tex.viewAsShaderResource(0, 0, newSwizzle());
            sampler = new Sampler(
                srv, SamplerInfo(FilterMethod.anisotropic, WrapMode.init)
            );

            // store cache
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

        immutable rect = FRect(node.topLeft, cast(FSize)img.size);
        immutable rectTr = translate(
            scale!float(rect.width, rect.height, 1f),
            fvec(rect.topLeft, 0f)
        );
        pl.updateUniforms(transpose(ctx.viewProj * model * rectTr));
        pl.draw(_texQuadVBuf, VertexBufferSlice(_quadIBuf), srv.obj, sampler.obj, ctx.renderTarget);
    }

    void renderTextNode(SGTextNode node, SGContext ctx, in FMat4 model)
    {
        _textPipeline.updateColor(node.color.asVec);
        immutable pos = node.pos;
        foreach(gl; node.glyphs) {
            Rc!(ShaderResourceView!Alpha8) srv;
            Rc!Sampler sampler;
            auto runImg = gl.glyph.runImg;
            GlyphRunObjectCache cache;
            // retrieve cache
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
                TexUsageFlags usage = TextureUsage.shaderResource;
                auto tex = new Texture2D!Alpha8(
                    usage, 1, cast(ushort)runImg.width, cast(ushort)runImg.height, [pixels]
                ).rc();
                srv = tex.viewAsShaderResource(0, 0, newSwizzle());
                // FilterMethod.scale maps to GL_NEAREST
                // no need to filter what is already filtered
                sampler = new Sampler(
                    srv, SamplerInfo(FilterMethod.scale, WrapMode.init)
                );

                // store cache
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
                P2T2Vertex([vertRect.left+pos.x, vertRect.top+pos.y], [normRect.left, normRect.top]),
                P2T2Vertex([vertRect.left+pos.x, vertRect.bottom+pos.y], [normRect.left, normRect.bottom]),
                P2T2Vertex([vertRect.right+pos.x, vertRect.bottom+pos.y], [normRect.right, normRect.bottom]),
                P2T2Vertex([vertRect.right+pos.x, vertRect.top+pos.y], [normRect.right, normRect.top]),
            ];
            auto vbuf = makeRc!(VertexBuffer!P2T2Vertex)(quadVerts);

            _textPipeline.updateMVP(transpose(model), transpose(ctx.viewProj));
            _textPipeline.draw(vbuf.obj, VertexBufferSlice(_quadIBuf), srv.obj, sampler.obj, ctx.renderTarget);
        }
    }
}

private:

__gshared SGRenderer g_instance;

/// Renderer that runs in the GUI thread
class SGDirectRenderer : SGRenderer
{
    override void stop(Window w)
    {
        finalize(w.nativeHandle);
    }
    override void syncAndRender(Window[] windows)
    {
        import std.algorithm : each;
        windows.each!(w => sync(w));
        windows.each!(w => render(w));
        windows.each!(w => swap(w));
    }
}

/// Render that runs in a dedicated thread
class SGThreadedRenderer : SGRenderer
{
    import core.sync.condition;
    import core.sync.mutex;
    import core.thread;
    import dgt.container : ThreadSafeQueue;

    this()
    {
        _mutex = new Mutex;
        _syncDoneCond = new Condition(_mutex);
        _reqQueue = new ThreadSafeQueue!Request;
    }

    override void start(GlContext context)
    {
        assert(!_thread);
        super.start(context);
        _thread = new Thread({
            try {
                renderLoop();
            }
            catch(Exception ex) {
                errorf("exited render thread with exception: %s", ex.msg);
            }
            catch(Throwable th) {
                errorf("exited render thread with error: %s", th.msg);
            }
        }).start();
    }

    override void stop(Window window)
    {
        assert(_thread);
        enforce(_thread.isRunning);

        auto stopReq = new Request;
        stopReq.type = Request.Type.stop;
        stopReq.windows = [window];
        _reqQueue.insertBack(stopReq);

        _thread.join();
        _thread = null;
    }

    override void syncAndRender(Window[] windows)
    {
        assert(_thread);
        enforce(_thread.isRunning);

        auto renderReq = new Request;
        renderReq.type = Request.Type.render;
        renderReq.windows = windows;
        _reqQueue.insertBack(renderReq);

        _mutex.lock();
        scope(exit) _mutex.unlock();

        _syncDoneCond.wait();
    }

    private void renderLoop()
    {
        import core.atomic : atomicLoad;
        import std.algorithm : each;

        logf("starting rendering thread");
        scope(success) logf("exiting rendering thread");

        while(true)
        {
            Request req = _reqQueue.waitAndPop();
            assert(req);
            if (req.type == Request.Type.stop) {
                finalize(req.windows[0].nativeHandle);
                return;
            }
            else if (req.type == Request.Type.render) {
                {
                    _mutex.lock();
                    scope(exit) _mutex.unlock();

                    req.windows.each!(w => sync(w));
                }
                _syncDoneCond.notify();
                req.windows.each!(w => render(w));
                req.windows.each!(w => swap(w));
            }
        }
    }

    private static class Request
    {
        enum Type {
            render, stop
        }
        Type type;
        Window[] windows;
    }


    private Thread                  _thread;
    private ThreadSafeQueue!Request _reqQueue;

    private Mutex       _mutex;
    private Condition   _syncDoneCond;
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
