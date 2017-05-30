module dgt.sg.renderer;

import dgt.context;
import dgt.geometry;
import dgt.math;
import dgt.sg.defs;
import dgt.sg.node;
import dgt.sg.pipelines;
import dgt.view.view;
import dgt.window;

import gfx.device;
import gfx.device.gl3;
import gfx.foundation.rc;
import gfx.foundation.typecons;
import gfx.pipeline;

import std.exception;
import std.experimental.logger;

abstract class SGRenderer
{
    static SGRenderer instance()
    {
        if (!g_instance) g_instance = new SGDirectRenderer;
        return g_instance;
    }

    // GUI thread interface

    void start() {}

    void stop() {}

    /// Responsible to call sync and render and swap in the render thread and to
    /// block the GUI thread during sync
    abstract protected void syncAndRenderImpl(Window w);

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
        sgData.clearColor = w.clearColor;
        sgData.hasClearColor = w.hasClearColor;
    }

    private SGNode syncView(View view)
    {
        view.sgNode.transform = view.transformToParent;
        if (view.sgBackgroundNode && view.sgBackgroundNode.parent !is view.sgNode) {
            view.sgNode.appendChild(view.sgBackgroundNode);
        }
        if (view.sgHasContent && view.isDirty(DirtyFlags.contentMask)) {
            auto old = view.sgContentNode;
            view.sgContentNode = view.sgUpdateContent(old);
            if (old && old.parent) {
                old.parent.removeChild(old);
            }
            if (view.sgContentNode) {
                view.sgChildrenNode.appendChild(view.sgContentNode);
            }
            view.clean(DirtyFlags.contentMask);
        }
        if (view.isDirty(DirtyFlags.childrenMask)) {
            // TODO: appropriate sync
            foreach (c; view.children) {
                if (c.sgNode) {
                    c.sgNode.parent.removeChild(c.sgNode);
                }
                view.sgChildrenNode.appendChild(syncView(c));
            }
            view.clean(DirtyFlags.childrenMask);
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

        pruneCache();
        _context.swapInterval = 1;

        doFrame(pw);
    }

    final protected void swap(Window[] windows)
    {
        foreach (w; windows) {
            _context.swapBuffers(w.nativeHandle);
        }
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

    Disposable[ulong]   _objectCache;
    ulong[]             _cachePruneQueue;

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

    void doFrame(PerWindow pw)
    {

    }
}

private:

__gshared SGRenderer g_instance;

/// Renderer that runs in the GUI thread
class SGDirectRenderer : SGRenderer
{
    protected override void syncAndRenderImpl(Window w)
    {
        sync(w);
        render(w);
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
