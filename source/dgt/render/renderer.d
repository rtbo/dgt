module dgt.render.renderer;

import dgt.core.geometry;
import dgt.core.rc;
import dgt.math : FMat4;
import dgt.render.cache;
import dgt.render.framegraph;
import dgt.render.text;
import gfx.device;
import gfx.pipeline;

struct RenderOptions {
    int samples;
}

class RenderContext : Disposable {

    this(RenderCache cache) {
        _cache = cache;
    }

    override void dispose() {
        _renderTarget.unload();
    }

    /// Get the render cache
    @property RenderCache cache() {
        return _cache;
    }

    /// The view - projection transform matrix
    @property FMat4 viewProj()
    {
        return _viewProj;
    }
    /// ditto
    @property void viewProj(in FMat4 proj)
    {
        _viewProj = proj;
    }

    /// The current render target
    @property RenderTargetView!Rgba8 renderTarget()
    {
        return _renderTarget;
    }
    /// ditto
    @property void renderTarget(RenderTargetView!Rgba8 rtv)
    {
        _renderTarget = rtv;
    }

    RenderCache _cache;
    FMat4 _viewProj;
    Rc!(RenderTargetView!Rgba8) _renderTarget;
}

class Renderer : Disposable {

    this(Device device, RenderOptions options) {
        _device = device;
        _options = options;
        _cache = new RenderCache;
    }

    override void dispose() {
        if (_textRenderer) {
            _textRenderer.dispose();
            _textRenderer = null;
        }
        _cache.dispose();
        _cache = null;
        _rtv.unload();
        _surf.unload();
        _cmdBuf.unload();
        _device.unload();
    }

    private void initialize() {
        assert(!_cmdBuf);
        _cmdBuf = _device.makeCommandBuffer();
        // TODO pass actual window size
        _surf = new BuiltinSurface!Rgba8(
            _device.builtinSurface, 1, 1, cast(ubyte)_options.samples
        );
        _rtv = _surf.viewAsRenderTarget();
        _textRenderer = new TextRenderer;
    }

    void renderFrame(immutable(FGFrame) frame) {
        if (!_cmdBuf) {
            initialize();
        }

        // candidate to parallelisation
        _textRenderer.framePreprocess(frame);

        foreach(const c; frame.prune) {
            _cache.prune(c);
        }

        const vpf = cast(FRect)frame.viewport;
        const vps = cast(Rect!ushort)frame.viewport;
        auto encoder = Encoder(_cmdBuf);
        encoder.setViewport(vps.x, vps.y, vps.width, vps.height);

        import std.algorithm : each;
        frame.clearColor.each!(
            c => encoder.clear!Rgba8(_rtv, [c.r, c.g, c.b, c.a])
        );

        if (frame.root) {
            auto ctx = new RenderContext(_cache);
            scope(exit) ctx.dispose();
            ctx.viewProj = orthoProj(vpf.left, vpf.right, vpf.bottom, vpf.top, 1, -1);
            ctx.renderTarget = _rtv;
            renderNode(frame.root, ctx, FMat4.identity);
        }

        encoder.flush(_device);
    }

    void renderNode(immutable(FGNode) node, RenderContext ctx, in FMat4 model)
    {
        switch(node.type)
        {
        case FGNode.Type.group:
            import std.algorithm : each;
            immutable gn = cast(immutable(FGGroupNode))node;
            gn.children.each!(n => renderNode(n, ctx, model));
            break;
        case FGNode.Type.transform:
            immutable tn = cast(immutable(FGTransformNode))node;
            renderNode(tn.child, ctx, model*tn.transform);
            break;
        case FGNode.Type.text:
            _textRenderer.render(cast(immutable(FGTextNode))node, ctx, model, _cmdBuf);
            break;
        default:
            break;
        }
    }

    private Rc!Device _device;
    private RenderOptions _options;
    private RenderCache _cache;

    private Rc!CommandBuffer _cmdBuf;
    private Rc!(BuiltinSurface!Rgba8) _surf;
    private Rc!(RenderTargetView!Rgba8) _rtv;

    private TextRenderer _textRenderer;
}

private:

FMat4 orthoProj(in float l, in float r, in float b, in float t, in float n, in float f) pure
{
    return FMat4(
        2f/(r-l), 0, 0, -(r+l)/(r-l),
        0, 2f/(t-b), 0, -(t+b)/(t-b),
        0, 0, -2f/(f-n), -(f+n)/(f-n),
        0, 0, 0, 1
    );
}
