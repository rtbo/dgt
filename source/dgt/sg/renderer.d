module dgt.sg.renderer;

import dgt.context;
import dgt.geometry;
import dgt.image;
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
import gfx.foundation.util;
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

    void start(GlContext context)
    {
        _context = context;
    }

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

        if (!_device) initialize();

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
        immutable vp = pw.viewport;
        _encoder.setViewport(vp.x, vp.y, vp.width, vp.height);

        if (pw.hasClearColor) {
            auto col = pw.clearColor;
            _encoder.clear!Rgba8(pw.bufRtv, [col.r, col.g, col.b, col.a]);
        }

        if (pw.root) {
            renderNode(pw.root, pw, FMat4.identity);
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

    void renderNode(SGNode node, PerWindow pw, FMat4 model)
    {
        switch(node.type)
        {
        case SGNode.Type.transform:
            auto trNode = cast(SGTransformNode)node;
            model = model * trNode.transform;
            break;
        case SGNode.Type.rectFill:
            renderRectFillNode(cast(SGRectFillNode)node, pw, model);
            break;
        case SGNode.Type.rectStroke:
            renderRectStrokeNode(cast(SGRectStrokeNode)node, pw, model);
            break;
        case SGNode.Type.image:
            renderImageNode(cast(SGImageNode)node, pw, model);
            break;
        case SGNode.Type.text:
            renderTextNode(cast(SGTextNode)node, pw, model);
            break;
        default:
            break;
        }

        foreach (c; node.children) {
            renderNode(c, pw, model);
        }
    }

    void renderRectFillNode(SGRectFillNode node, PerWindow pw, in FMat4 model)
    {
        immutable color = node.color;
        immutable rect = node.rect;
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

    void renderRectStrokeNode(SGRectStrokeNode node, PerWindow pw, in FMat4 model)
    {
        immutable color = node.color;
        immutable rect = node.rect;
        immutable rectTr = translate(
            scale!float(rect.width, rect.height, 1f),
            fvec(rect.topLeft, 0f)
        );
        immutable mvp = transpose(pw.viewProj * model * rectTr);

        _linesPipeline.updateUniforms(mvp, color);
        _linesPipeline.draw(_frameVBuf, VertexBufferSlice(frameVBufCount), pw.bufRtv);
    }

    void renderImageNode(SGImageNode node, PerWindow pw, in FMat4 model)
    {
        immutable img = node.image;
        Rc!(ShaderResourceView!Rgba8) srv;
        Rc!Sampler sampler;
        TextureObjectCache cache;
        immutable cookie = 0; // node.cacheCookie;

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
            TexUsageFlags usage = TextureUsage.shaderResource;
            auto tex = makeRc!(Texture2D!Rgba8)(
                usage, ubyte(1), cast(ushort)img.width, cast(ushort)img.height, [pixels]
            );
            srv = tex.viewAsShaderResource(0, 0, newSwizzle());
            sampler = new Sampler(
                srv, SamplerInfo(FilterMethod.anisotropic, WrapMode.init)
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

        immutable rect = FRect(node.topLeft, cast(FSize)img.size);
        immutable rectTr = translate(
            scale!float(rect.width, rect.height, 1f),
            fvec(rect.topLeft, 0f)
        );
        pl.updateUniforms(transpose(pw.viewProj * model * rectTr));
        pl.draw(_texQuadVBuf, VertexBufferSlice(_quadIBuf), srv.obj, sampler.obj, pw.bufRtv);
    }

    void renderTextNode(SGTextNode node, PerWindow pw, in FMat4 model)
    {
        _textPipeline.updateColor(node.color);
        immutable pos = node.pos;
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
                P2T2Vertex([vertRect.left+pos.x, vertRect.top+pos.y], [normRect.left, normRect.top]),
                P2T2Vertex([vertRect.left+pos.x, vertRect.bottom+pos.y], [normRect.left, normRect.bottom]),
                P2T2Vertex([vertRect.right+pos.x, vertRect.bottom+pos.y], [normRect.right, normRect.bottom]),
                P2T2Vertex([vertRect.right+pos.x, vertRect.top+pos.y], [normRect.right, normRect.top]),
            ];
            auto vbuf = makeRc!(VertexBuffer!P2T2Vertex)(quadVerts);

            _textPipeline.updateMVP(transpose(pw.viewProj));
            _textPipeline.draw(vbuf.obj, VertexBufferSlice(_quadIBuf), srv.obj, sampler.obj, pw.bufRtv);
        }
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
