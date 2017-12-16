module dgt.render.renderer;

import dgt.core.geometry;
import dgt.core.rc : Disposable, Rc;
import dgt.render.framegraph;
import gfx.device;
import gfx.pipeline;

struct RenderOptions {
    int samples;
}

class Renderer : Disposable {

    this(Device device, RenderOptions options) {
        _device = device;
        _options = options;
    }

    void dispose() {
        if (_cmdBuf.loaded) {
            _rtv.unload();
            _surf.unload();
            _cmdBuf.unload();
        }
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
    }

    void renderFrame(immutable(FGFrame) frame) {
        if (!_cmdBuf) {
            initialize();
        }

        immutable vp = cast(Rect!ushort)frame.viewport;
        auto encoder = Encoder(_cmdBuf);
        encoder.setViewport(vp.x, vp.y, vp.width, vp.height);

        import std.algorithm : each;
        frame.clearColor.each!(
            c => encoder.clear!Rgba8(_rtv, [c.r, c.g, c.b, c.a])
        );

        encoder.flush(_device);
    }

    private Rc!Device _device;
    private RenderOptions _options;
    private Rc!CommandBuffer _cmdBuf;
    private Rc!(BuiltinSurface!Rgba8) _surf;
    private Rc!(RenderTargetView!Rgba8) _rtv;
}
